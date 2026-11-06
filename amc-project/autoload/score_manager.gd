extends Node
## Hệ thống Tính điểm & Lưu Kỷ lục (Autoload: ScoreManager)

const SAVE_PATH: String = "user://highscore.cfg"

var kills: int = 0
var survival_time: float = 0.0
var boss_killed: bool = false
var last_total_score: int = 0
var high_score: int = 0


func _ready() -> void:
	load_high_score()
	CombatEvents.kill.connect(_on_enemy_killed)
	CombatEvents.boss_defeated.connect(_on_boss_defeated)


func reset_run() -> void:
	kills = 0
	survival_time = 0.0
	boss_killed = false
	last_total_score = 0


func add_survival_time(delta: float) -> void:
	survival_time += delta


func _on_enemy_killed(_enemy: Node) -> void:
	kills += 1


func _on_boss_defeated() -> void:
	boss_killed = true


func calculate_final_score(remaining_hp: float, remaining_gold: int) -> int:
	var kill_score: int = kills * 10
	var time_score: int = int(survival_time)
	var hp_bonus: int = maxi(0, int(remaining_hp * 5.0))
	var boss_bonus: int = 1000 if boss_killed else 0
	var gold_bonus: int = maxi(0, remaining_gold)

	last_total_score = kill_score + time_score + hp_bonus + boss_bonus + gold_bonus
	if last_total_score > high_score:
		high_score = last_total_score
		save_high_score()
	return last_total_score


func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("records", "high_score", high_score)
	config.save(SAVE_PATH)


func load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = int(config.get_value("records", "high_score", 0))

