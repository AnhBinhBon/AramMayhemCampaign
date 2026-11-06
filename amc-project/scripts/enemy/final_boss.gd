class_name FinalBoss
extends CharacterBody2D
## Thực thể Trùm Cuối Chiến Hạm (FinalBoss - Giai đoạn 4)
## Điều khiển bằng Máy trạng thái hữu hạn (FSM): ENTERING -> IDLE -> RING_SHOT -> CHARGE -> SUMMON -> DEAD
## Có 2 Pha chiến đấu (Pha 2 cuồng nộ khi HP <= 50%), tích hợp vệt ngắm cảnh báo (Telegraph) và vòng gai xoay tròn.

enum BossState {
	ENTERING,
	IDLE,
	RING_SHOT,
	CHARGE_TELEGRAPH,
	CHARGE,
	SUMMON,
	DEAD
}

const ENEMY_PROJECTILE_PATH: String = "res://scenes/weapons/EnemyProjectile.tscn"
const ENEMY_BASIC_PATH: String = "res://scenes/entities/enemies/EnemyBasic.tscn"
const ENEMY_FAST_PATH: String = "res://scenes/entities/enemies/EnemyFast.tscn"
const BOSS_CUSTOM_SPRITE_PATH: String = "res://assets/sprites/enemies/lol_rift_herald_boss.png"

@export var max_hp: float = 100000.0
@export var base_move_speed: float = 115.0
@export var contact_damage: float = 55.0
@export var charge_damage: float = 110.0

var current_hp: float = 100000.0
var state: BossState = BossState.ENTERING
var is_phase_2: bool = false
var is_dead: bool = false

var _target_player: Player = null
var _state_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.DOWN
var _action_cooldown: float = 2.4
var _cc_mark_timer: float = 0.0
var _ring_spikes_node: Node2D = null
var _enemy_proj_scene: PackedScene = null
var _enemy_basic_scene: PackedScene = null
var _enemy_fast_scene: PackedScene = null

@onready var visuals: Node2D = $Visuals
@onready var core_mesh: MeshInstance2D = $Visuals/CoreMesh
@onready var body_mesh: MeshInstance2D = $Visuals/BodyMesh
@onready var ring_spikes: Node2D = $Visuals/RingSpikes
@onready var telegraph_line: Line2D = $TelegraphLine
@onready var hitbox_area: Area2D = $HitboxArea


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")

	_enemy_proj_scene = load(ENEMY_PROJECTILE_PATH) as PackedScene
	_enemy_basic_scene = load(ENEMY_BASIC_PATH) as PackedScene
	_enemy_fast_scene = load(ENEMY_FAST_PATH) as PackedScene

	current_hp = max_hp
	telegraph_line.visible = false
	_try_apply_custom_boss_sprite()

	if hitbox_area != null:
		hitbox_area.body_entered.connect(_on_hitbox_body_entered)

	_target_player = get_tree().get_first_node_in_group("player") as Player

	# Xuất hiện: Thông báo cho hệ thống HUD và CombatEvents
	CombatEvents.boss_spawned.emit(self)
	CombatEvents.boss_hp_changed.emit(current_hp, max_hp, is_phase_2)

	_enter_state(BossState.ENTERING)


func setup_hp(_scale_factor: float = 1.0) -> void:
	max_hp = 100000.0
	current_hp = max_hp
	CombatEvents.boss_hp_changed.emit(current_hp, max_hp, is_phase_2)


func _try_apply_custom_boss_sprite() -> void:
	if visuals == null:
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(BOSS_CUSTOM_SPRITE_PATH):
		tex = load(BOSS_CUSTOM_SPRITE_PATH) as Texture2D
	if tex == null:
		var abs_path: String = ProjectSettings.globalize_path(BOSS_CUSTOM_SPRITE_PATH)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null:
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		return
	for child in visuals.get_children():
		if child is CanvasItem:
			child.visible = false
	var spr := Sprite2D.new()
	spr.name = "CustomGeminiBossSprite"
	spr.texture = tex
	var max_dim: float = maxf(1.0, float(maxi(tex.get_width(), tex.get_height())))
	spr.scale = Vector2.ONE * (124.0 / max_dim)
	visuals.add_child(spr)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _cc_mark_timer > 0.0:
		_cc_mark_timer = maxf(0.0, _cc_mark_timer - delta)

	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = get_tree().get_first_node_in_group("player") as Player

	# Xoay vòng gai bảo vệ xung quanh thân và hướng mặt Sứ Giả Khe Nứt về phía người chơi
	if ring_spikes != null:
		var rot_speed: float = 3.6 if is_phase_2 else 1.8
		ring_spikes.rotation += rot_speed * delta
	if visuals != null:
		if state in [BossState.CHARGE_TELEGRAPH, BossState.CHARGE] and _charge_dir.length_squared() > 0.01:
			visuals.rotation = lerp_angle(visuals.rotation, _charge_dir.angle(), delta * 14.0)
		elif _target_player != null and is_instance_valid(_target_player):
			var aim_to_p: Vector2 = _target_player.global_position - global_position
			if aim_to_p.length_squared() > 1.0:
				visuals.rotation = lerp_angle(visuals.rotation, aim_to_p.angle(), delta * 6.0)

	# Máy trạng thái hữu hạn (FSM)
	_state_timer -= delta
	match state:
		BossState.ENTERING:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if _state_timer <= 0.0:
				_enter_state(BossState.IDLE)

		BossState.IDLE:
			_process_idle_movement(delta)
			if _state_timer <= 0.0:
				_pick_next_action()

		BossState.RING_SHOT:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			if _state_timer <= 0.0:
				_enter_state(BossState.IDLE)

		BossState.CHARGE_TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			_update_telegraph_aim()
			if _state_timer <= 0.0:
				_enter_state(BossState.CHARGE)

		BossState.CHARGE:
			velocity = _charge_dir * (720.0 if is_phase_2 else 600.0)
			if _state_timer <= 0.0:
				if _target_player != null:
					_target_player.apply_camera_shake(7.0, 0.25)
				_enter_state(BossState.IDLE)

		BossState.SUMMON:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if _state_timer <= 0.0:
				_enter_state(BossState.IDLE)

	move_and_slide()
	# Giữ boss trong sân đấu
	global_position.x = clampf(global_position.x, -720.0, 720.0)
	global_position.y = clampf(global_position.y, -420.0, 420.0)


func _enter_state(new_state: BossState) -> void:
	state = new_state
	match state:
		BossState.ENTERING:
			_state_timer = 1.4
			if _target_player != null:
				_target_player.apply_camera_shake(8.0, 0.6)

		BossState.IDLE:
			_state_timer = _action_cooldown * (0.65 if is_phase_2 else 1.0)
			telegraph_line.visible = false

		BossState.RING_SHOT:
			_state_timer = 0.8 if is_phase_2 else 0.5
			_execute_ring_shot()

		BossState.CHARGE_TELEGRAPH:
			_state_timer = 0.8 if is_phase_2 else 1.0
			telegraph_line.visible = true
			if _target_player != null:
				_charge_dir = (_target_player.global_position - global_position).normalized()
			_update_telegraph_aim()

		BossState.CHARGE:
			_state_timer = 0.38
			telegraph_line.visible = false

		BossState.SUMMON:
			_state_timer = 0.6
			_execute_summon()

		BossState.DEAD:
			telegraph_line.visible = false


func _process_idle_movement(delta: float) -> void:
	if _target_player == null:
		return
	var to_player: Vector2 = _target_player.global_position - global_position
	var dist: float = to_player.length()

	# Di chuyển áp sát nhưng giữ cự ly chiến thuật ~160px
	var desired_dir: Vector2 = Vector2.ZERO
	if dist > 210.0:
		desired_dir = to_player.normalized()
	elif dist < 120.0:
		desired_dir = -to_player.normalized()
	else:
		desired_dir = to_player.orthogonal().normalized()

	var speed: float = base_move_speed * (1.35 if is_phase_2 else 1.0)
	velocity = velocity.lerp(desired_dir * speed, 5.0 * delta)


func _pick_next_action() -> void:
	var roll: float = randf()
	if roll < 0.38:
		_enter_state(BossState.RING_SHOT)
	elif roll < 0.76:
		_enter_state(BossState.CHARGE_TELEGRAPH)
	else:
		_enter_state(BossState.SUMMON)


func _update_telegraph_aim() -> void:
	if not telegraph_line.visible:
		return
	telegraph_line.clear_points()
	telegraph_line.add_point(Vector2.ZERO)
	telegraph_line.add_point(_charge_dir * 700.0)


func _execute_ring_shot() -> void:
	var count: int = 20 if is_phase_2 else 16
	var bullet_speed: float = 380.0 if is_phase_2 else 320.0
	var bullet_dmg: float = 42.0 if is_phase_2 else 30.0
	var pool := get_tree().get_first_node_in_group("object_pool") as ObjectPool

	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU
		var dir := Vector2.RIGHT.rotated(angle)
		_spawn_boss_projectile(dir, bullet_dmg, bullet_speed, pool)

	# Pha 2: Bắn thêm vòng đạn thứ 2 lệch góc sau 0.22s
	if is_phase_2:
		var tw := create_tween()
		tw.tween_interval(0.22)
		tw.tween_callback(func():
			if is_dead:
				return
			for i in range(count):
				var angle: float = (float(i) / float(count)) * TAU + (TAU / float(count * 2))
				var dir := Vector2.RIGHT.rotated(angle)
				_spawn_boss_projectile(dir, bullet_dmg, bullet_speed, pool)
		)


func _spawn_boss_projectile(dir: Vector2, dmg: float, spd: float, pool: ObjectPool) -> void:
	var proj_node: Node = null
	if pool != null:
		proj_node = pool.acquire("enemy_projectile", _enemy_proj_scene)
	elif _enemy_proj_scene != null:
		proj_node = _enemy_proj_scene.instantiate()
		get_tree().current_scene.add_child(proj_node)

	var proj := proj_node as Projectile
	if proj != null:
		proj.pool_key = "enemy_projectile"
		proj.object_pool = pool
		proj.setup(
			global_position + dir * 52.0,
			dir,
			dmg,
			spd,
			750.0,
			false,
			0,
			0,
			Color(1.0, 0.2, 0.35, 1.0) if is_phase_2 else Color(0.9, 0.3, 0.85, 1.0)
		)


func _execute_summon() -> void:
	var pool := get_tree().get_first_node_in_group("object_pool") as ObjectPool
	var count: int = 6 if is_phase_2 else 4
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU
		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * 110.0
		var spawn_pos: Vector2 = global_position + offset

		var pool_key: String = "enemy_fast" if (i % 2 == 0) else "enemy_basic"
		var chosen_scene: PackedScene = _enemy_fast_scene if (i % 2 == 0) else _enemy_basic_scene

		var enemy_node: Node = null
		if pool != null:
			enemy_node = pool.acquire(pool_key, chosen_scene)
		elif chosen_scene != null:
			enemy_node = chosen_scene.instantiate()
			get_tree().current_scene.add_child(enemy_node)

		var enemy := enemy_node as Enemy
		if enemy != null:
			enemy.pool_key = pool_key
			enemy.object_pool = pool
			enemy.setup(spawn_pos, 2.5)


func apply_knockback(impulse: Vector2) -> void:
	velocity += impulse * 0.25


func apply_stun(duration: float) -> void:
	_cc_mark_timer = maxf(_cc_mark_timer, duration)


func apply_slow(_ratio: float, duration: float) -> void:
	_cc_mark_timer = maxf(_cc_mark_timer, duration)


func is_cc_marked() -> bool:
	return _cc_mark_timer > 0.0


func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead:
		return

	current_hp = maxf(0.0, current_hp - amount)
	CombatEvents.hit.emit(self, amount, is_crit)
	CombatEvents.boss_hp_changed.emit(current_hp, max_hp, is_phase_2)

	_play_hit_flash()

	# Kích hoạt Pha 2 khi Máu <= 50%
	if not is_phase_2 and current_hp <= max_hp * 0.5:
		_trigger_phase_2()

	if current_hp <= 0.0:
		die()


func _trigger_phase_2() -> void:
	is_phase_2 = true
	CombatEvents.boss_hp_changed.emit(current_hp, max_hp, is_phase_2)

	if core_mesh != null:
		core_mesh.self_modulate = Color(2.5, 0.2, 0.2, 1.0)
	if body_mesh != null:
		body_mesh.self_modulate = Color(0.7, 0.1, 0.15, 1.0)

	if _target_player != null:
		_target_player.apply_camera_shake(10.0, 0.5)

	# Bắn một vòng đạn giải tỏa khi chuyển Pha
	_execute_ring_shot()


func _play_hit_flash() -> void:
	if visuals == null:
		return
	var tw := create_tween()
	tw.tween_property(visuals, "modulate", Color(2.2, 0.4, 0.4, 1.0), 0.05)
	tw.tween_property(visuals, "modulate", Color.WHITE, 0.12)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead or body == null:
		return
	if body.is_in_group("player") and body.has_method("take_hit"):
		var dmg: float = charge_damage if state == BossState.CHARGE else contact_damage
		body.take_hit(dmg, self)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	_enter_state(BossState.DEAD)
	velocity = Vector2.ZERO

	CombatEvents.boss_defeated.emit()

	if _target_player != null:
		_target_player.apply_camera_shake(14.0, 1.0)

	# Hiệu ứng nổ tung nhiều giai đoạn
	var tw := create_tween()
	tw.tween_property(visuals, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_property(visuals, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(queue_free)

