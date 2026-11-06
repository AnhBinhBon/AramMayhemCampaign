class_name MysticPunchEffect
extends AugmentEffect
## Lõi Kim Cương 10: Cú Đấm Thần Bí (MysticPunchEffect)
## Mỗi phát bắn trúng đích giảm 0.3 giây hồi chiêu kỹ năng [Space].

var _player_ref: Player = null


func apply(player: Node) -> void:
	_player_ref = player as Player
	if not CombatEvents.hit.is_connected(_on_hit):
		CombatEvents.hit.connect(_on_hit)


func remove(_player: Node) -> void:
	if CombatEvents.hit.is_connected(_on_hit):
		CombatEvents.hit.disconnect(_on_hit)
	_player_ref = null


func _on_hit(_target: Node, _damage: float, _is_crit: bool) -> void:
	if _player_ref != null and _player_ref.skill != null:
		_player_ref.skill.reduce_cooldown(0.30)

