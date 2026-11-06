class_name EnemySpawner
extends Node2D
## Hệ thống Sinh Quái vật quanh rìa Đấu trường theo cấu hình WaveData (EnemySpawner)

const ENEMY_BASIC_PATH: String = "res://scenes/entities/enemies/EnemyBasic.tscn"
const ENEMY_FAST_PATH: String = "res://scenes/entities/enemies/EnemyFast.tscn"
const ENEMY_RANGED_PATH: String = "res://scenes/entities/enemies/EnemyRanged.tscn"
const ENEMY_CANNON_PATH: String = "res://scenes/entities/enemies/EnemyCannon.tscn"
const FINAL_BOSS_PATH: String = "res://scenes/entities/enemies/FinalBoss.tscn"

var object_pool: ObjectPool = null
var active_wave_data: WaveData = null
var is_spawning: bool = false

var _spawn_timer: float = 0.0
var _basic_scene: PackedScene = null
var _fast_scene: PackedScene = null
var _ranged_scene: PackedScene = null
var _cannon_scene: PackedScene = null
var _boss_scene: PackedScene = null


func _ready() -> void:
	_basic_scene = load(ENEMY_BASIC_PATH) as PackedScene
	_fast_scene = load(ENEMY_FAST_PATH) as PackedScene
	_ranged_scene = load(ENEMY_RANGED_PATH) as PackedScene
	_cannon_scene = load(ENEMY_CANNON_PATH) as PackedScene
	_boss_scene = load(FINAL_BOSS_PATH) as PackedScene
	object_pool = get_tree().get_first_node_in_group("object_pool") as ObjectPool


func start_spawning(wave_data: WaveData) -> void:
	active_wave_data = wave_data
	is_spawning = true
	_spawn_timer = 0.25

	if active_wave_data != null and active_wave_data.is_boss_wave:
		_spawn_final_boss()


func stop_spawning() -> void:
	is_spawning = false


func get_alive_enemy_count() -> int:
	var count: int = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and e.visible and not e.get("is_dead"):
			count += 1
	return count


func clear_all_enemies_and_projectiles() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != null and e.has_method("deactivate") and e.visible:
			e.deactivate()


func _process(delta: float) -> void:
	if not is_spawning or active_wave_data == null:
		return

	if object_pool == null:
		object_pool = get_tree().get_first_node_in_group("object_pool") as ObjectPool

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(0.20, active_wave_data.spawn_interval)
		if get_alive_enemy_count() < active_wave_data.max_alive_enemies:
			_spawn_random_enemy()


func _spawn_random_enemy() -> void:
	if active_wave_data == null:
		return

	var w_basic: float = maxf(0.0, active_wave_data.basic_weight)
	var w_fast: float = maxf(0.0, active_wave_data.fast_weight)
	var w_ranged: float = maxf(0.0, active_wave_data.ranged_weight)
	var w_cannon: float = maxf(0.0, active_wave_data.cannon_weight)
	var total_w: float = w_basic + w_fast + w_ranged + w_cannon
	if total_w <= 0.01:
		return

	var roll: float = randf() * total_w
	var pool_key: String = "enemy_basic"
	var chosen_scene: PackedScene = _basic_scene

	if roll < w_basic:
		pool_key = "enemy_basic"
		chosen_scene = _basic_scene
	elif roll < w_basic + w_fast:
		pool_key = "enemy_fast"
		chosen_scene = _fast_scene
	elif roll < w_basic + w_fast + w_ranged:
		pool_key = "enemy_ranged"
		chosen_scene = _ranged_scene
	else:
		pool_key = "enemy_cannon"
		chosen_scene = _cannon_scene

	if chosen_scene == null:
		return

	var spawn_pos: Vector2 = _get_random_perimeter_position()
	var enemy_node: Node = null
	if object_pool != null:
		enemy_node = object_pool.acquire(pool_key, chosen_scene)
	else:
		enemy_node = chosen_scene.instantiate()
		get_tree().current_scene.add_child(enemy_node)

	var enemy := enemy_node as Enemy
	if enemy != null:
		enemy.pool_key = pool_key
		enemy.object_pool = object_pool
		enemy.setup(spawn_pos, active_wave_data.hp_scale)


func _get_random_perimeter_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var player_pos: Vector2 = player.global_position if player != null else Vector2.ZERO

	for _attempt in range(8):
		var pos := Vector2(randf_range(-710.0, 710.0), randf_range(-410.0, 410.0))
		# Ưu tiên sinh gần rìa bản đồ và cách người chơi ít nhất 260px
		if randf() < 0.75:
			if randf() < 0.5:
				pos.x = -700.0 if randf() < 0.5 else 700.0
			else:
				pos.y = -400.0 if randf() < 0.5 else 400.0
		if pos.distance_to(player_pos) >= 260.0:
			return pos

	return Vector2(680.0, 380.0)


func _spawn_final_boss() -> void:
	if _boss_scene == null:
		_boss_scene = load(FINAL_BOSS_PATH) as PackedScene
	if _boss_scene == null:
		return

	var boss_node: Node = _boss_scene.instantiate()
	var boss := boss_node as FinalBoss
	if boss != null:
		boss.global_position = Vector2(0.0, -180.0)
		boss.setup_hp(active_wave_data.hp_scale if active_wave_data != null else 1.8)

	var enemies_container := get_tree().current_scene.get_node_or_null("Enemies")
	if enemies_container != null:
		enemies_container.add_child(boss_node)
	else:
		get_tree().current_scene.add_child(boss_node)

