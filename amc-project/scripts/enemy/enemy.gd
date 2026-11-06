class_name Enemy
extends CharacterBody2D
## Thực thể Quái vật (Hỗ trợ 3 chủng loại: Quái bộ Đỏ, Quái nhanh Vàng, Quái bắn xa Xanh lục)
## Có lực đẩy tách đàn (Separation), gây sát thương chạm, bắn đạn tầm xa và rơi Vàng khi chết.

signal died(enemy: Enemy)

enum EnemyType {
	BASIC,
	FAST,
	RANGED,
	CANNON
}

const ENEMY_PROJECTILE_PATH: String = "res://scenes/weapons/EnemyProjectile.tscn"
const GOLD_PICKUP_PATH: String = "res://scenes/pickups/GoldPickup.tscn"

@export var enemy_type: EnemyType = EnemyType.BASIC
@export var base_max_hp: float = 35.0
@export var move_speed: float = 125.0
@export var contact_damage: float = 12.0
@export var gold_drop_value: int = 3
@export var body_color: Color = Color(0.92, 0.28, 0.28, 1.0)
@export var preferred_range: float = 250.0
@export var shoot_interval: float = 2.2
@export var custom_sprite_path: String = ""

var pool_key: String = "enemy_basic"
var object_pool: Node = null
var max_hp: float = 35.0
var current_hp: float = 35.0
var is_dead: bool = false

var _player: Node2D = null
var _shoot_timer: float = 1.5
var _knockback_velocity: Vector2 = Vector2.ZERO
var _stun_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_ratio: float = 0.0
var _base_contact_damage: float = 0.0
var _enemy_proj_scene: PackedScene = null
var _gold_pickup_scene: PackedScene = null

@onready var visuals: Node2D = $Visuals
@onready var body_mesh: MeshInstance2D = $Visuals/BodyMesh
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemies")
	_base_contact_damage = contact_damage
	_enemy_proj_scene = load(ENEMY_PROJECTILE_PATH) as PackedScene
	_gold_pickup_scene = load(GOLD_PICKUP_PATH) as PackedScene
	if body_mesh != null:
		body_mesh.self_modulate = body_color
	_try_apply_custom_sprite()


func _try_apply_custom_sprite() -> void:
	if visuals == null or custom_sprite_path.is_empty():
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(custom_sprite_path):
		tex = load(custom_sprite_path) as Texture2D
	if tex == null:
		var abs_path: String = ProjectSettings.globalize_path(custom_sprite_path)
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
	spr.name = "CustomGeminiSprite"
	spr.texture = tex
	var max_dim: float = maxf(1.0, float(maxi(tex.get_width(), tex.get_height())))
	var target_px: float = 46.0
	match enemy_type:
		EnemyType.FAST:
			target_px = 54.0
		EnemyType.CANNON:
			target_px = 64.0
		_:
			target_px = 46.0
	spr.scale = Vector2.ONE * (target_px / max_dim)
	visuals.add_child(spr)


func setup(p_pos: Vector2, hp_scale: float = 1.0) -> void:
	global_position = p_pos
	max_hp = maxf(5.0, base_max_hp * hp_scale)
	current_hp = max_hp
	if _base_contact_damage <= 0.0:
		_base_contact_damage = contact_damage
	contact_damage = _base_contact_damage * maxf(1.0, 0.65 + hp_scale * 0.35)
	is_dead = false
	_knockback_velocity = Vector2.ZERO
	_stun_timer = 0.0
	_slow_timer = 0.0
	_slow_ratio = 0.0
	_shoot_timer = randf_range(0.8, shoot_interval)
	visible = true
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)
	if visuals != null:
		visuals.modulate = Color.WHITE
		visuals.scale = Vector2.ONE
	if body_mesh != null:
		body_mesh.self_modulate = body_color


func _physics_process(delta: float) -> void:
	if is_dead or not visible:
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist_to_player: float = to_player.length()
	var move_dir: Vector2 = to_player.normalized() if dist_to_player > 0.01 else Vector2.ZERO

	if visuals != null and move_dir.length_squared() > 0.01:
		visuals.rotation = lerp_angle(visuals.rotation, move_dir.angle(), delta * 12.0)

	if _stun_timer > 0.0:
		_stun_timer = maxf(0.0, _stun_timer - delta)
	if _slow_timer > 0.0:
		_slow_timer = maxf(0.0, _slow_timer - delta)
		if _slow_timer <= 0.0:
			_slow_ratio = 0.0

	var eff_move_speed: float = move_speed * (1.0 - clampf(_slow_ratio, 0.0, 0.85))
	if _stun_timer > 0.0:
		velocity = Vector2.ZERO
	elif enemy_type in [EnemyType.RANGED, EnemyType.CANNON]:
		if dist_to_player > preferred_range + 25.0:
			velocity = move_dir * eff_move_speed
		elif dist_to_player < preferred_range - 45.0:
			velocity = -move_dir * (eff_move_speed * 0.75)
		else:
			velocity = Vector2.ZERO

		_shoot_timer -= delta
		if _shoot_timer <= 0.0 and dist_to_player <= preferred_range + 130.0:
			_shoot_timer = shoot_interval
			_fire_enemy_projectile(move_dir)
	else:
		velocity = move_dir * eff_move_speed

	# Lực đẩy tách đàn nhẹ để quái không chồng khít lên nhau + lực đẩy lùi từ vũ khí cận chiến
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, delta * 950.0)
	velocity += _compute_separation_force() + _knockback_velocity
	move_and_slide()
	global_position.x = clampf(global_position.x, -760.0, 760.0)
	global_position.y = clampf(global_position.y, -460.0, 460.0)

	# Kiểm tra gây sát thương chạm lên người chơi
	if _stun_timer <= 0.0 and dist_to_player <= 27.0 and _player.has_method("take_hit"):
		_player.take_hit(contact_damage, self)


func apply_knockback(impulse: Vector2) -> void:
	_knockback_velocity = impulse


func apply_stun(duration: float) -> void:
	_stun_timer = maxf(_stun_timer, duration)
	if visuals != null:
		visuals.modulate = Color(1.4, 1.4, 0.55, 1.0)


func apply_slow(ratio: float, duration: float) -> void:
	_slow_ratio = maxf(_slow_ratio, clampf(ratio, 0.0, 0.85))
	_slow_timer = maxf(_slow_timer, duration)


func is_cc_marked() -> bool:
	return _stun_timer > 0.0 or _slow_timer > 0.0


func _compute_separation_force() -> Vector2:
	var push := Vector2.ZERO
	var neighbors := get_tree().get_nodes_in_group("enemies")
	var checked: int = 0
	for other in neighbors:
		if other == self or not (other is Node2D) or not other.visible:
			continue
		var diff: Vector2 = global_position - other.global_position
		var d_sq: float = diff.length_squared()
		if d_sq > 0.1 and d_sq < 900.0: # Bán kính 30px
			push += diff.normalized() * (45.0 * (1.0 - sqrt(d_sq) / 30.0))
			checked += 1
			if checked >= 6:
				break
	return push


func _fire_enemy_projectile(dir: Vector2) -> void:
	if _enemy_proj_scene == null:
		return
	var proj_node: Node = null
	if object_pool != null and object_pool.has_method("acquire"):
		proj_node = object_pool.acquire("enemy_projectile", _enemy_proj_scene)
	else:
		proj_node = _enemy_proj_scene.instantiate()
		get_tree().current_scene.add_child(proj_node)

	var proj := proj_node as Projectile
	if proj != null:
		proj.pool_key = "enemy_projectile"
		proj.object_pool = object_pool
		proj.is_enemy_projectile = true
		var is_cannon: bool = (enemy_type == EnemyType.CANNON)
		proj.setup(
			global_position + dir * (26.0 if is_cannon else 18.0),
			dir,
			contact_damage * (1.35 if is_cannon else 1.0),
			340.0 if is_cannon else 310.0,
			540.0 if is_cannon else 460.0,
			false,
			0,
			0,
			Color(1.0, 0.58, 0.14, 1.0) if is_cannon else Color(0.35, 0.82, 1.0, 1.0)
		)


func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead or amount <= 0.0:
		return

	current_hp -= amount
	_play_hit_flash(is_crit)

	if current_hp <= 0.0:
		die()


func _play_hit_flash(is_crit: bool) -> void:
	if visuals == null:
		return
	var flash_col: Color = Color(2.4, 2.1, 0.4, 1.0) if is_crit else Color(2.2, 2.2, 2.2, 1.0)
	visuals.modulate = flash_col
	var tw := create_tween()
	tw.tween_property(visuals, "modulate", Color.WHITE, 0.10)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	call_deferred("_handle_death_deferred")


func _handle_death_deferred() -> void:
	_spawn_gold_drop()
	died.emit(self)
	CombatEvents.kill.emit(self)
	deactivate()


func _spawn_gold_drop() -> void:
	if _gold_pickup_scene == null:
		return
	var gold_node: Node = null
	if object_pool != null and object_pool.has_method("acquire"):
		gold_node = object_pool.acquire("gold_pickup", _gold_pickup_scene)
	else:
		gold_node = _gold_pickup_scene.instantiate()
		get_tree().current_scene.add_child(gold_node)

	var pickup := gold_node as GoldPickup
	if pickup != null:
		pickup.pool_key = "gold_pickup"
		pickup.object_pool = object_pool
		pickup.setup(global_position, gold_drop_value)


func deactivate() -> void:
	is_dead = true
	visible = false
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if object_pool != null and object_pool.has_method("release"):
		object_pool.release(pool_key, self)
	else:
		queue_free()

