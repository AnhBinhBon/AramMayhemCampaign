class_name ObjectPool
extends Node
## Hệ thống Tái sử dụng Đối tượng (ObjectPool)
## Quản lý hàng đợi tái sử dụng Đạn người chơi, Đạn quái, Quái vật và Vật phẩm Vàng.

@export var projectiles_container: Node2D
@export var enemies_container: Node2D
@export var pickups_container: Node2D

var _pools: Dictionary = {}


func _ready() -> void:
	add_to_group("object_pool")


func prewarm(pool_key: String, scene: PackedScene, count: int) -> void:
	if scene == null or count <= 0:
		return
	if not _pools.has(pool_key):
		_pools[pool_key] = []
	var parent_node := _get_target_container(pool_key)
	for i in range(count):
		var inst := scene.instantiate()
		parent_node.add_child(inst)
		release(pool_key, inst)


func acquire(pool_key: String, scene: PackedScene) -> Node:
	if scene == null:
		return null

	if not _pools.has(pool_key):
		_pools[pool_key] = []

	var queue: Array = _pools[pool_key]
	while not queue.is_empty():
		var candidate = queue.pop_back()
		if is_instance_valid(candidate):
			candidate.set_process(true)
			candidate.set_physics_process(true)
			return candidate

	var inst := scene.instantiate()
	var parent_node := _get_target_container(pool_key)
	parent_node.add_child(inst)
	return inst


func release(pool_key: String, node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	if not _pools.has(pool_key):
		_pools[pool_key] = []

	node.set_process(false)
	node.set_physics_process(false)
	if node is CanvasItem:
		node.visible = false
	if node is Area2D:
		node.set_deferred("monitoring", false)
	if node is CollisionObject2D:
		for child in node.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)

	var queue: Array = _pools[pool_key]
	if not queue.has(node):
		queue.append(node)


func _get_target_container(pool_key: String) -> Node:
	if pool_key.begins_with("enemy_") and not pool_key.contains("projectile"):
		if enemies_container != null:
			return enemies_container
	elif pool_key.contains("projectile"):
		if projectiles_container != null:
			return projectiles_container
	elif pool_key.contains("gold") or pool_key.contains("pickup"):
		if pickups_container != null:
			return pickups_container

	return get_tree().current_scene

