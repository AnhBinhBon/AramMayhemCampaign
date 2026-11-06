class_name LowHpBerserkEffect
extends AugmentEffect
## Lõi Vàng 8: Hút Máu Cuồng Loạn (LowHpBerserkEffect)
## Khi Máu dưới 30%, nhận ngay +100% Tốc độ đánh và +20% Hút máu.

const BERSERK_SOURCE: String = "berserk_low_hp_buff"

var _player_ref: Player = null
var _is_active: bool = false


func apply(player: Node) -> void:
	_player_ref = player as Player
	if _player_ref != null:
		_player_ref.hp_changed.connect(_on_hp_changed)
		_check_hp(_player_ref.current_hp, _player_ref.get_max_hp())


func remove(player: Node) -> void:
	var p := player as Player
	if p != null:
		if p.hp_changed.is_connected(_on_hp_changed):
			p.hp_changed.disconnect(_on_hp_changed)
		if p.stats != null:
			p.stats.remove_modifiers_from(BERSERK_SOURCE)
	_is_active = false
	_player_ref = null


func _on_hp_changed(cur_hp: float, max_hp_val: float) -> void:
	_check_hp(cur_hp, max_hp_val)


func _check_hp(cur_hp: float, max_hp_val: float) -> void:
	if _player_ref == null or _player_ref.stats == null:
		return
	var ratio: float = cur_hp / maxf(1.0, max_hp_val)
	if ratio <= 0.30 and not _is_active:
		_is_active = true
		_player_ref.stats.add_modifier(BERSERK_SOURCE, StatModifier.StatType.ATTACK_SPEED, 0.0, 1.0)
		_player_ref.stats.add_modifier(BERSERK_SOURCE, StatModifier.StatType.LIFESTEAL, 0.20, 0.0)
	elif ratio > 0.30 and _is_active:
		_is_active = false
		_player_ref.stats.remove_modifiers_from(BERSERK_SOURCE)

