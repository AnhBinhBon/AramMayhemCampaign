class_name Player
extends CharacterBody2D
## Thực thể Nhân vật Người chơi (CharacterBody2D)
## Tạo hình học bằng MeshInstance2D (SphereMesh thân gọn gàng), di chuyển 8 hướng,
## tính sát thương giảm trừ theo Giáp, Hồi máu tự nhiên, Hút máu và Lướt chiến thuật.

signal hp_changed(current_hp: float, max_hp: float)
signal weapon_changed(new_weapon: WeaponData)
signal died()

@export var character_data: CharacterData
@export var equipped_weapon_data: WeaponData = null

var current_hp: float = 100.0
var is_dead: bool = false
var invulnerable_timer: float = 0.0

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _last_move_dir: Vector2 = Vector2.RIGHT
var _walk_anim_time: float = 0.0
var _regen_accum: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var body_mesh: MeshInstance2D = $Visuals/BodyMesh
@onready var stats: PlayerStats = $PlayerStats
@onready var weapon_controller: Node2D = $WeaponController
@onready var skill: PlayerSkill = $PlayerSkill
@onready var inventory: Inventory = $Inventory
@onready var camera: Camera2D = $Camera2D

var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_ensure_subskill_input_actions()
	if character_data == null:
		if GameManager.selected_character is CharacterData:
			character_data = GameManager.selected_character
		else:
			character_data = load("res://resources/characters/ad_marksman.tres") as CharacterData

	_apply_character_setup()
	stats.stats_changed.connect(_on_stats_changed)
	CombatEvents.hit.connect(_on_combat_hit_lifesteal)


func _ensure_subskill_input_actions() -> void:
	if not InputMap.has_action("skill_q"):
		InputMap.add_action("skill_q")
		var ev_q := InputEventKey.new()
		ev_q.physical_keycode = KEY_Q
		ev_q.keycode = KEY_Q
		InputMap.action_add_event("skill_q", ev_q)
	if not InputMap.has_action("skill_e"):
		InputMap.add_action("skill_e")
		var ev_e := InputEventKey.new()
		ev_e.physical_keycode = KEY_E
		ev_e.keycode = KEY_E
		InputMap.action_add_event("skill_e", ev_e)


func _apply_character_setup() -> void:
	stats.setup_from_character(character_data)
	current_hp = get_max_hp()
	is_dead = false

	if character_data != null:
		if body_mesh != null:
			body_mesh.self_modulate = character_data.body_color
		_try_apply_custom_player_sprite(character_data.id)
		var initial_wpn: WeaponData = equipped_weapon_data if equipped_weapon_data != null else character_data.starting_weapon
		equip_weapon(initial_wpn)
		if skill != null:
			skill.setup(self, character_data)

	hp_changed.emit(current_hp, get_max_hp())


## Cho phép Nhân vật nhận và trang bị bất kỳ Dữ liệu Đối tượng Vũ khí (WeaponData) nào
func equip_weapon(new_weapon: WeaponData) -> void:
	if new_weapon == null:
		return
	equipped_weapon_data = new_weapon
	if weapon_controller != null and weapon_controller.has_method("setup"):
		weapon_controller.setup(self, equipped_weapon_data)
	weapon_changed.emit(equipped_weapon_data)


func get_equipped_weapon() -> WeaponData:
	return equipped_weapon_data


func _try_apply_custom_player_sprite(char_id: String) -> void:
	var candidate_path: String = "res://assets/sprites/player/lol_%s.png" % char_id
	if visuals == null:
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(candidate_path):
		tex = load(candidate_path) as Texture2D
	if tex == null:
		var abs_path: String = ProjectSettings.globalize_path(candidate_path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null:
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		return
	for child in visuals.get_children():
		if child is CanvasItem and child.name != "FloatingOrbs":
			child.visible = false
	var spr := Sprite2D.new()
	spr.name = "CustomGeminiSprite"
	spr.texture = tex
	var max_dim: float = maxf(1.0, float(maxi(tex.get_width(), tex.get_height())))
	var target_px: float = 52.0 if char_id in ["bruiser", "tank"] else 48.0
	spr.scale = Vector2.ONE * (target_px / max_dim)
	visuals.add_child(spr)


func get_max_hp() -> float:
	return stats.get_stat(StatModifier.StatType.MAX_HP)


func apply_camera_shake(intensity: float = 6.0, duration: float = 0.22) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)


func _process(delta: float) -> void:
	if visuals != null:
		var orbs := visuals.get_node_or_null("FloatingOrbs") as Node2D
		if orbs != null:
			orbs.rotation += delta * 2.4
		if weapon_controller != null:
			visuals.rotation = lerp_angle(visuals.rotation, weapon_controller.rotation, delta * 14.0)

	if _shake_timer > 0.0:
		_shake_timer -= delta
		if camera != null:
			camera.offset = Vector2(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity, _shake_intensity)
			)
		if _shake_timer <= 0.0:
			if camera != null:
				camera.offset = Vector2.ZERO
			_shake_intensity = 0.0


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(0.0, invulnerable_timer - delta)

	# Hồi máu tự nhiên mỗi giây (HP_REGEN)
	var regen: float = stats.get_stat(StatModifier.StatType.HP_REGEN)
	if regen > 0.0 and current_hp < get_max_hp():
		_regen_accum += regen * delta
		if _regen_accum >= 0.5:
			heal(_regen_accum)
			_regen_accum = 0.0

	# Kích hoạt Hệ thống 3 Kỹ năng chủ động ([Q] Skill Phụ 1, [E] Skill Phụ 2, [SPACE] Skill Chính)
	if skill != null:
		if Input.is_action_just_pressed("skill_q"):
			skill.try_cast_q()
		if Input.is_action_just_pressed("skill_e"):
			skill.try_cast_e()
		if Input.is_action_just_pressed("skill"):
			skill.try_cast()

	# Xử lý di chuyển hoặc Lướt (Dash)
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_velocity
		if _dash_timer <= 0.0:
			_is_dashing = false
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir.length_squared() > 0.01:
			_last_move_dir = input_dir.normalized()
			var move_spd: float = stats.get_stat(StatModifier.StatType.MOVE_SPEED)
			velocity = _last_move_dir * move_spd
			_animate_walking(delta, true)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 1600.0 * delta)
			_animate_walking(delta, false)

	move_and_slide()
	# Giới hạn an toàn trong phạm vi đấu trường Arena (1600x1000, tâm tại 0,0)
	global_position.x = clampf(global_position.x, -755.0, 755.0)
	global_position.y = clampf(global_position.y, -455.0, 455.0)


func _animate_walking(delta: float, is_moving: bool) -> void:
	if visuals == null:
		return
	if is_moving:
		_walk_anim_time += delta * 14.0
		var bob: float = sin(_walk_anim_time) * 0.06
		visuals.scale = Vector2(1.0 + bob, 1.0 - bob)
	else:
		_walk_anim_time += delta * 3.5
		var breath: float = sin(_walk_anim_time) * 0.025
		visuals.scale = visuals.scale.lerp(Vector2(1.0 + breath, 1.0 - breath), delta * 10.0)


func perform_dash(distance: float, duration: float) -> void:
	if duration <= 0.01:
		return
	_is_dashing = true
	_dash_timer = duration
	_dash_velocity = _last_move_dir * (distance / duration)
	invulnerable_timer = maxf(invulnerable_timer, duration + 0.1)

	if visuals != null:
		var tw := create_tween()
		tw.tween_property(visuals, "modulate", Color(1.4, 1.4, 1.0, 0.75), duration * 0.5)
		tw.tween_property(visuals, "modulate", Color.WHITE, duration * 0.5)


func take_hit(raw_damage: float, attacker: Node = null) -> void:
	if is_dead or invulnerable_timer > 0.0 or raw_damage <= 0.0:
		return

	# Công thức giảm sát thương theo Giáp: Dmg = Raw * 100 / (100 + Armor * 5)
	var armor: float = stats.get_stat(StatModifier.StatType.ARMOR)
	var mitigation: float = 100.0 / maxf(20.0, 100.0 + armor * 5.0)
	var final_damage: float = maxf(1.0, raw_damage * mitigation)

	if skill != null and skill.is_damage_reduction_active():
		final_damage *= 0.50
		skill.trigger_shield_counter_damage(self)

	current_hp = maxf(0.0, current_hp - final_damage)
	invulnerable_timer = 0.35
	hp_changed.emit(current_hp, get_max_hp())
	CombatEvents.take_damage.emit(final_damage, attacker)

	_play_hit_flash()
	apply_camera_shake(5.5, 0.20)

	if current_hp <= 0.0:
		die()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	var max_hp_val: float = get_max_hp()
	current_hp = minf(max_hp_val, current_hp + amount)
	hp_changed.emit(current_hp, max_hp_val)


func _on_combat_hit_lifesteal(_target: Node, damage: float, _is_crit: bool) -> void:
	if is_dead or damage <= 0.0:
		return
	var lifesteal_ratio: float = stats.get_stat(StatModifier.StatType.LIFESTEAL)
	if lifesteal_ratio > 0.0:
		heal(damage * lifesteal_ratio)


func _on_stats_changed(stat_type: int) -> void:
	if stat_type == StatModifier.StatType.MAX_HP:
		var max_hp_val: float = get_max_hp()
		current_hp = minf(current_hp, max_hp_val)
		hp_changed.emit(current_hp, max_hp_val)


func _play_hit_flash() -> void:
	if visuals == null:
		return
	var tw := create_tween()
	tw.tween_property(visuals, "modulate", Color(2.5, 0.35, 0.35, 1.0), 0.06)
	tw.tween_property(visuals, "modulate", Color.WHITE, 0.14)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	died.emit()
	GameManager.end_run(false, 0.0)

