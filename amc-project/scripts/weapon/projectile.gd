class_name Projectile
extends Area2D
## Thực thể Đạn (Dùng cho cả Đạn Người chơi và Đạn Quái/Boss)
## Hỗ trợ Xuyên mục tiêu (Pierce), Nảy mục tiêu (Bounce) và tái sử dụng qua ObjectPool.

@export var is_enemy_projectile: bool = false

var pool_key: String = "player_projectile"
var object_pool: Node = null

var damage: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var speed: float = 640.0
var max_distance: float = 450.0
var is_crit: bool = false
var pierce_remaining: int = 0
var bounce_remaining: int = 0
var aoe_radius: float = 0.0

var _traveled_distance: float = 0.0
var _is_active: bool = false
var _hit_targets: Array[Node] = []

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(
	p_pos: Vector2,
	p_dir: Vector2,
	p_damage: float,
	p_speed: float = 640.0,
	p_max_dist: float = 450.0,
	p_is_crit: bool = false,
	p_pierce: int = 0,
	p_bounce: int = 0,
	p_color: Color = Color(1.0, 0.92, 0.25, 1.0),
	p_aoe_radius: float = 0.0
) -> void:
	global_position = p_pos
	direction = p_dir.normalized() if p_dir.length_squared() > 0.001 else Vector2.RIGHT
	rotation = direction.angle()
	damage = p_damage
	speed = p_speed
	max_distance = p_max_dist
	is_crit = p_is_crit
	pierce_remaining = p_pierce
	bounce_remaining = p_bounce
	aoe_radius = p_aoe_radius
	_traveled_distance = 0.0
	_hit_targets.clear()
	_is_active = true
	visible = true
	set_deferred("monitoring", true)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)

	if mesh_instance != null:
		mesh_instance.self_modulate = Color(1.0, 0.45, 0.15, 1.0) if p_is_crit else p_color
		if p_aoe_radius > 0.0:
			mesh_instance.scale = Vector2(2.1, 1.7)
		else:
			mesh_instance.scale = Vector2(1.35, 1.35) if p_is_crit else Vector2.ONE


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	var step: float = speed * delta
	global_position += direction * step
	_traveled_distance += step

	# Tự thu hồi khi bay hết tầm hoặc chạm tường đấu trường
	if _traveled_distance >= max_distance or absf(global_position.x) > 790.0 or absf(global_position.y) > 490.0:
		_deactivate()


func _on_body_entered(body: Node2D) -> void:
	if not _is_active or body == null:
		return

	if is_enemy_projectile:
		if body.is_in_group("player") and body.has_method("take_hit"):
			body.take_hit(damage, self)
			_deactivate()
		return

	# Đạn người chơi trúng Quái/Boss
	if body.is_in_group("enemies") and not _hit_targets.has(body):
		_hit_targets.append(body)

		if body.has_method("take_damage"):
			body.take_damage(damage, is_crit)

		CombatEvents.hit.emit(body, damage, is_crit)
		if is_crit:
			CombatEvents.crit.emit(body, damage)

		if aoe_radius > 0.0:
			_explode_aoe(global_position, aoe_radius, damage * 0.75, is_crit)

		# Kiểm tra cơ chế Đạn Nảy (Bounce)
		if bounce_remaining > 0:
			var next_target := _find_bounce_target(body.global_position)
			if next_target != null:
				bounce_remaining -= 1
				direction = (next_target.global_position - global_position).normalized()
				rotation = direction.angle()
				_traveled_distance = 0.0
				damage *= 0.85
				return

		# Kiểm tra cơ chế Xuyên phá (Pierce)
		if pierce_remaining > 0:
			pierce_remaining -= 1
			return

		_deactivate()


func _explode_aoe(center: Vector2, radius: float, splash_dmg: float, crit_flag: bool) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var rad_sq: float = radius * radius
	for e in enemies:
		if e is Node2D and not _hit_targets.has(e) and e.visible and not e.get("is_dead"):
			if center.distance_squared_to(e.global_position) <= rad_sq:
				_hit_targets.append(e)
				if e.has_method("take_damage"):
					e.take_damage(splash_dmg, crit_flag)
				CombatEvents.hit.emit(e, splash_dmg, crit_flag)

	# Hiệu ứng cầu lửa phát nổ diện rộng (Fireball Explosion Polygon + Shockwave Ring)
	AudioManager.play_explosion()
	var fx_root := Node2D.new()
	fx_root.global_position = center
	get_tree().current_scene.add_child(fx_root)

	var blast_poly := Polygon2D.new()
	blast_poly.color = Color(1.0, 0.38, 0.12, 0.42)
	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = Color(1.0, 0.72, 0.22, 0.95)

	var poly_pts := PackedVector2Array()
	var ring_pts := PackedVector2Array()
	for i in range(21):
		var ang: float = float(i) / 20.0 * TAU
		var pt := Vector2(cos(ang), sin(ang)) * (radius * 0.35)
		if i < 20:
			poly_pts.append(pt)
		ring_pts.append(pt)
	blast_poly.polygon = poly_pts
	ring.points = ring_pts
	fx_root.add_child(blast_poly)
	fx_root.add_child(ring)

	var tw := fx_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fx_root, "scale", Vector2(2.85, 2.85), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx_root, "modulate:a", 0.0, 0.24)
	tw.chain().tween_callback(fx_root.queue_free)


func _find_bounce_target(from_pos: Vector2) -> Node2D:
	var best_enemy: Node2D = null
	var best_dist_sq: float = 240.0 * 240.0
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and not _hit_targets.has(e) and e.visible:
			if e.get("is_dead") == true:
				continue
			var d_sq: float = from_pos.distance_squared_to(e.global_position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_enemy = e
	return best_enemy


func _deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	visible = false
	set_deferred("monitoring", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if object_pool != null and object_pool.has_method("release"):
		object_pool.release(pool_key, self)
	else:
		queue_free()

