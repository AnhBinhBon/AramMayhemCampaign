class_name HeadhunterEffect
extends AugmentEffect
## Lõi Kim Cương 11: Săn Đầu Người (HeadhunterEffect)
## Mỗi 10 quái vật tiêu diệt cộng dồn vĩnh viễn +2% Sức mạnh công kích (AD) và +2% Tốc độ đánh.

const HEADHUNTER_SOURCE: String = "headhunter_stack"

var _player_ref: Player = null
var _kill_count: int = 0
var _current_stacks: int = 0


func apply(player: Node) -> void:
	_player_ref = player as Player
	_kill_count = 0
	_current_stacks = 0
	if not CombatEvents.kill.is_connected(_on_kill):
		CombatEvents.kill.connect(_on_kill)


func remove(player: Node) -> void:
	if CombatEvents.kill.is_connected(_on_kill):
		CombatEvents.kill.disconnect(_on_kill)
	var p := player as Player
	if p != null and p.stats != null:
		p.stats.remove_modifiers_from(HEADHUNTER_SOURCE)
	_player_ref = null


func _on_kill(_enemy: Node) -> void:
	if _player_ref == null or _player_ref.stats == null:
		return
	_kill_count += 1
	if _kill_count % 10 == 0:
		_current_stacks += 1
		_player_ref.stats.remove_modifiers_from(HEADHUNTER_SOURCE)
		_player_ref.stats.add_modifier(HEADHUNTER_SOURCE, StatModifier.StatType.AD, 0.0, 0.02 * _current_stacks)
		_player_ref.stats.add_modifier(HEADHUNTER_SOURCE, StatModifier.StatType.ATTACK_SPEED, 0.0, 0.02 * _current_stacks)

