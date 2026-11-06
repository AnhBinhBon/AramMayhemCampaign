class_name WaveManager
extends Node
## Hệ thống Quản lý Đợt đấu (WaveManager)
## Điều phối thời gian đếm ngược Wave 1..7, hệ số vàng Wave 6 và tín hiệu chuyển pha (Lõi / Shop / Boss).

signal wave_timer_updated(time_left: float, total_duration: float)
signal wave_intermission_ready(completed_wave: int, next_wave: int, is_augment_milestone: bool)

@export var enemy_spawner: EnemySpawner
@export var waves: Array[WaveData] = []

var current_wave_index: int = 1
var current_wave_data: WaveData = null
var time_remaining: float = 45.0
var is_wave_running: bool = false


func _ready() -> void:
	if waves.is_empty():
		for i in range(1, 8):
			waves.append(WaveData.create_default_wave(i))
	CombatEvents.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	if is_wave_running and current_wave_data != null and current_wave_data.is_boss_wave:
		complete_current_wave()


func start_wave(wave_idx: int) -> void:
	current_wave_index = clampi(wave_idx, 1, waves.size())
	GameManager.current_wave = current_wave_index
	current_wave_data = waves[current_wave_index - 1]
	time_remaining = current_wave_data.duration
	is_wave_running = true

	CurrencyManager.wave_gold_multiplier = current_wave_data.gold_multiplier
	if current_wave_data.is_prep_wave:
		GameManager.change_state(GameManager.GameState.PREP_WAVE)
	elif current_wave_data.is_boss_wave:
		GameManager.change_state(GameManager.GameState.BOSS_WAVE)
	else:
		GameManager.change_state(GameManager.GameState.WAVE_COMBAT)

	if enemy_spawner != null:
		enemy_spawner.start_spawning(current_wave_data)

	CombatEvents.wave_started.emit(current_wave_index)
	wave_timer_updated.emit(time_remaining, current_wave_data.duration)


func _process(delta: float) -> void:
	if not is_wave_running or current_wave_data == null:
		return

	ScoreManager.add_survival_time(delta)

	if not current_wave_data.is_boss_wave:
		time_remaining = maxf(0.0, time_remaining - delta)
		wave_timer_updated.emit(time_remaining, current_wave_data.duration)
		if time_remaining <= 0.0:
			complete_current_wave()


func complete_current_wave() -> void:
	if not is_wave_running:
		return
	is_wave_running = false

	if enemy_spawner != null:
		enemy_spawner.stop_spawning()
		enemy_spawner.clear_all_enemies_and_projectiles()

	CombatEvents.wave_ended.emit(current_wave_index)

	if current_wave_index >= waves.size():
		var player := get_tree().get_first_node_in_group("player") as Player
		var rem_hp: float = player.current_hp if player != null else 0.0
		GameManager.end_run(true, rem_hp)
		return

	var has_augment: bool = current_wave_index in [1, 3, 5]
	wave_intermission_ready.emit(current_wave_index, current_wave_index + 1, has_augment)


func proceed_to_next_wave() -> void:
	start_wave(current_wave_index + 1)

