extends Node
## Quản lý Trạng thái Toàn cục & Ánh xạ Phím (Autoload: GameManager)

enum GameState {
	MENU,
	CHARACTER_SELECT,
	BONUS_REVEAL,
	WAVE_COMBAT,
	AUGMENT_PICK,
	SHOP,
	PREP_WAVE,
	FINAL_SHOP,
	BOSS_WAVE,
	RESULT
}

signal state_changed(new_state: GameState)
signal run_ended(is_victory: bool, final_score: int)

var current_state: GameState = GameState.WAVE_COMBAT
var selected_character: Resource = null
var current_wave: int = 1
var max_waves: int = 7
var is_run_active: bool = false
var last_run_victory: bool = false


func _enter_tree() -> void:
	_setup_input_map()


func _setup_input_map() -> void:
	_register_key_action("move_left", [KEY_A, KEY_LEFT])
	_register_key_action("move_right", [KEY_D, KEY_RIGHT])
	_register_key_action("move_up", [KEY_W, KEY_UP])
	_register_key_action("move_down", [KEY_S, KEY_DOWN])
	_register_key_action("skill", [KEY_SPACE])
	_register_key_action("pause", [KEY_ESCAPE])


func _register_key_action(action_name: String, keys: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)


func start_new_run(character_res: Resource = null) -> void:
	if character_res != null:
		selected_character = character_res
	current_wave = 1
	is_run_active = true
	last_run_victory = false
	CurrencyManager.reset()
	ScoreManager.reset_run()
	change_state(GameState.WAVE_COMBAT)


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(current_state)


func end_run(is_victory: bool, remaining_hp: float = 0.0) -> void:
	if not is_run_active:
		return
	is_run_active = false
	last_run_victory = is_victory
	var final_score: int = ScoreManager.calculate_final_score(remaining_hp, CurrencyManager.gold)
	change_state(GameState.RESULT)
	run_ended.emit(is_victory, final_score)

