class_name GoldPickup
extends Area2D
## Vật phẩm Vàng rơi ra từ Quái vật (GoldPickup)
## Tự động bay hút vào nhân vật khi nằm trong bán kính 135px và cộng Vàng qua CurrencyManager.

var pool_key: String = "gold_pickup"
var object_pool: Node = null
var base_gold_value: int = 2
var magnet_radius: float = 135.0

var _is_active: bool = false
var _is_magnetized: bool = false
var _fly_speed: float = 420.0
var _player: Node2D = null
var _pulse_time: float = 0.0

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(p_pos: Vector2, p_value: int = 2) -> void:
	global_position = p_pos
	base_gold_value = maxi(1, p_value)
	_is_active = true
	_is_magnetized = false
	_fly_speed = 380.0
	_pulse_time = randf() * TAU
	visible = true
	set_deferred("monitoring", true)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	_pulse_time += delta * 6.0
	if mesh_instance != null:
		var s: float = 1.0 + sin(_pulse_time) * 0.1
		mesh_instance.scale = Vector2(s, s)
		mesh_instance.rotation += delta * 2.2

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= magnet_radius:
		_is_magnetized = true

	if _is_magnetized:
		_fly_speed = minf(900.0, _fly_speed + 950.0 * delta)
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		global_position += dir * _fly_speed * delta
		if dist <= 18.0:
			_collect()


func _on_body_entered(body: Node2D) -> void:
	if not _is_active or body == null:
		return
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if not _is_active:
		return
	CurrencyManager.add_gold(base_gold_value)
	deactivate()


func deactivate() -> void:
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

