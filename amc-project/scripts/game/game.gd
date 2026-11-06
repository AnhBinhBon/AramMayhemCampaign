extends Node2D
## Bộ điều phối Màn chơi Chính (Game.gd - Cập nhật Giai đoạn 3)
## Tích hợp toàn diện Chu trình: Khởi đầu -> Phúc lợi -> Chiến đấu Wave 1..7 -> Lõi Nâng cấp (Bạc/Vàng/Kim Cương) -> Cửa hàng 6 Ô.

const CHAR_SELECT_SCENE_PATH: String = "res://scenes/menu/CharacterSelect.tscn"

@onready var player: Player = $Player
@onready var object_pool: ObjectPool = $Managers/ObjectPool
@onready var enemy_spawner: EnemySpawner = $Managers/EnemySpawner
@onready var wave_manager: WaveManager = $Managers/WaveManager
@onready var bonus_manager: BonusManager = $Managers/BonusManager
@onready var augment_manager: AugmentManager = $Managers/AugmentManager
@onready var shop_manager: ShopManager = $Managers/ShopManager
@onready var hud: HUD = $HUD
@onready var bonus_reveal_ui: BonusRevealUI = $BonusRevealUI
@onready var augment_ui: AugmentUI = $AugmentUI
@onready var shop_ui: ShopUI = $ShopUI
@onready var result_ui: ResultUI = $ResultUI
@onready var floating_text_container: Node2D = $FloatingTexts

var _pending_next_wave: int = 1
var _is_pioneer_bonus_active: bool = false


func _ready() -> void:
	_spawn_selected_character_node()

	# Kết nối ObjectPool với các nhánh chứa thực thể
	object_pool.projectiles_container = $Projectiles
	object_pool.enemies_container = $Enemies
	object_pool.pickups_container = $Pickups

	# Prewarm ObjectPool
	var proj_scene: PackedScene = load("res://scenes/weapons/Projectile.tscn")
	var enemy_proj_scene: PackedScene = load("res://scenes/weapons/EnemyProjectile.tscn")
	var gold_scene: PackedScene = load("res://scenes/pickups/GoldPickup.tscn")
	var enemy_basic_scene: PackedScene = load("res://scenes/entities/enemies/EnemyBasic.tscn")
	var enemy_fast_scene: PackedScene = load("res://scenes/entities/enemies/EnemyFast.tscn")
	var enemy_ranged_scene: PackedScene = load("res://scenes/entities/enemies/EnemyRanged.tscn")
	var enemy_cannon_scene: PackedScene = load("res://scenes/entities/enemies/EnemyCannon.tscn")

	object_pool.prewarm("player_projectile", proj_scene, 40)
	object_pool.prewarm("enemy_projectile", enemy_proj_scene, 25)
	object_pool.prewarm("gold_pickup", gold_scene, 50)
	object_pool.prewarm("enemy_basic", enemy_basic_scene, 25)
	object_pool.prewarm("enemy_fast", enemy_fast_scene, 15)
	object_pool.prewarm("enemy_ranged", enemy_ranged_scene, 12)
	object_pool.prewarm("enemy_cannon", enemy_cannon_scene, 6)

	# Kết nối WaveManager, BonusManager, AugmentUI, ShopUI và HUD
	wave_manager.enemy_spawner = enemy_spawner
	wave_manager.wave_timer_updated.connect(hud.update_wave_timer)
	wave_manager.wave_intermission_ready.connect(_on_wave_intermission_ready)

	bonus_manager.wave3_gift_triggered.connect(_on_wave3_gift_triggered)
	bonus_reveal_ui.bonus_confirmed.connect(_on_bonus_confirmed)

	augment_ui.setup_manager(augment_manager)
	augment_ui.augment_chosen.connect(_on_augment_chosen)

	shop_ui.setup(shop_manager, player)
	shop_ui.shop_closed.connect(_on_shop_closed)

	hud.bind_player(player)
	hud.restart_requested.connect(_on_hud_restart_requested)
	hud.menu_requested.connect(_on_hud_menu_requested)

	CombatEvents.wave_started.connect(_on_wave_started)
	CombatEvents.hit.connect(_on_combat_hit_floating_text)
	GameManager.run_ended.connect(_on_run_ended)

	# Khởi tạo ván mới
	GameManager.start_new_run(player.character_data)
	augment_manager.reset_for_run()
	shop_manager.reset_for_run()

	var player_inv := player.get_node_or_null("Inventory") as Inventory
	if player_inv != null:
		player_inv.setup(player)

	GameManager.change_state(GameManager.GameState.BONUS_REVEAL)
	var rolled_bonus: BonusData = bonus_manager.roll_random_bonus()
	bonus_reveal_ui.show_bonus_reveal(rolled_bonus)


func _spawn_selected_character_node() -> void:
	var chosen_data: CharacterData = GameManager.selected_character
	if chosen_data == null:
		chosen_data = load("res://resources/characters/ad_marksman.tres") as CharacterData
	if chosen_data == null or chosen_data.character_scene_path.is_empty():
		return
	if not ResourceLoader.exists(chosen_data.character_scene_path):
		return

	var char_packed := load(chosen_data.character_scene_path) as PackedScene
	if char_packed == null:
		return

	var new_player := char_packed.instantiate() as Player
	if new_player == null:
		return

	var spawn_pos: Vector2 = player.global_position if player != null else Vector2.ZERO
	var player_idx: int = player.get_index() if player != null else get_child_count()
	if player != null:
		remove_child(player)
		player.queue_free()

	new_player.name = "Player"
	new_player.character_data = chosen_data
	new_player.global_position = spawn_pos
	add_child(new_player)
	move_child(new_player, player_idx)
	player = new_player


func _on_bonus_confirmed(bonus: BonusData) -> void:
	var player_inv := player.get_node_or_null("Inventory") as Inventory
	bonus_manager.apply_active_bonus(player, augment_manager, shop_manager, player_inv)

	if bonus != null:
		hud.show_active_bonus(bonus)
		hud.show_toast_banner("ĐÃ KÍCH HOẠT PHÚC LỢI: %s" % bonus.bonus_name.to_upper(), bonus.accent_color)

	# Nếu trúng Phúc lợi Lõi Tiên Phong (EXTRA_AUGMENT): Mở ngay bảng chọn 1 Lõi Bạc trước Wave 1
	if bonus != null and bonus.kind == BonusData.BonusKind.EXTRA_AUGMENT:
		_is_pioneer_bonus_active = true
		_pending_next_wave = 1
		var choices: Array[AugmentData] = augment_manager.roll_augments(AugmentData.Rarity.SILVER)
		augment_ui.show_selection(choices, AugmentData.Rarity.SILVER, augment_manager.free_rerolls)
	else:
		wave_manager.start_wave(1)


func _on_wave3_gift_triggered(message: String) -> void:
	hud.show_toast_banner(message, Color(0.85, 0.55, 1.0, 1.0))


func _on_wave_started(wave_index: int) -> void:
	if wave_manager.current_wave_data != null:
		hud.update_wave_header(wave_manager.current_wave_data.wave_title)
	else:
		hud.update_wave_header("ĐỢT %d / 7" % wave_index)

	if wave_index == 6:
		hud.show_toast_banner("ĐỢT CHUẨN BỊ: DỌN LÍNH TÍCH VÀNG TRƯỚC TRẬN ĐẤU TRÙM! (VÀNG x2)", Color(1.0, 0.88, 0.2, 1.0))


func _on_wave_intermission_ready(completed_wave: int, next_wave: int, is_augment_milestone: bool) -> void:
	_pending_next_wave = next_wave
	_is_pioneer_bonus_active = false

	# Hồi phục 20% lượng máu đã mất giữa mỗi đợt
	if player != null and not player.is_dead:
		var missing_hp: float = maxf(0.0, player.get_max_hp() - player.current_hp)
		player.heal(missing_hp * 0.20)

	# Luồng chuyển pha:
	# - Wave 1, 3, 5: Bốc Lõi Nâng Cấp -> Sau đó mở Cửa hàng Shop
	# - Wave 2, 4, 6: Mở Cửa hàng Shop trực tiếp
	if is_augment_milestone:
		var rarity: AugmentData.Rarity = AugmentData.Rarity.SILVER
		match completed_wave:
			1:
				rarity = AugmentData.Rarity.SILVER
			3:
				rarity = AugmentData.Rarity.GOLD
			5:
				rarity = AugmentData.Rarity.PRISMATIC

		var choices: Array[AugmentData] = augment_manager.roll_augments(rarity)
		augment_ui.show_selection(choices, rarity, augment_manager.free_rerolls)
	else:
		shop_ui.open_shop(next_wave)


func _on_augment_chosen(augment: AugmentData) -> void:
	augment_manager.pick_augment(augment, player)

	if augment != null:
		hud.show_toast_banner("ĐÃ KÍCH HOẠT LÕI: %s" % augment.augment_name.to_upper(), augment.accent_color)

	if _is_pioneer_bonus_active:
		_is_pioneer_bonus_active = false
		wave_manager.start_wave(1)
	else:
		shop_ui.open_shop(_pending_next_wave)


func _on_shop_closed() -> void:
	wave_manager.proceed_to_next_wave()


func _on_hud_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_hud_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(CHAR_SELECT_SCENE_PATH)


func _on_run_ended(is_victory: bool, final_score: int) -> void:
	enemy_spawner.stop_spawning()
	var player_inv: Inventory = player.inventory if player != null else null
	if result_ui != null:
		result_ui.show_result(is_victory, final_score, player, augment_manager, player_inv)
	else:
		hud.show_run_result(is_victory, final_score)


func _on_combat_hit_floating_text(target: Node, damage: float, is_crit: bool) -> void:
	if not (target is Node2D) or floating_text_container == null:
		return

	var lbl := Label.new()
	lbl.text = "%d!" % int(round(damage)) if is_crit else "%d" % int(round(damage))
	lbl.modulate = Color(1.0, 0.85, 0.15, 1.0) if is_crit else Color(0.95, 0.95, 0.95, 1.0)
	lbl.scale = Vector2(1.25, 1.25) if is_crit else Vector2.ONE
	lbl.global_position = (target as Node2D).global_position + Vector2(randf_range(-16.0, 16.0), -28.0)
	floating_text_container.add_child(lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 34.0, 0.42)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.42)
	tw.chain().tween_callback(lbl.queue_free)
