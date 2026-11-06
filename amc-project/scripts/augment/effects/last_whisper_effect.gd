class_name LastWhisperEffect
extends AugmentEffect
## Item 7: Cung Xanh (LastWhisperEffect)
## Mỗi đòn bắn thứ 3 trúng đích gây thêm 45 sát thương xuyên thấu mục tiêu.

var _player_ref: Player = null
var _hit_counter: int = 0


func apply(player: Node) -> void:
	_player_ref = player as Player
	_hit_counter = 0
	if not CombatEvents.hit.is_connected(_on_hit):
		CombatEvents.hit.connect(_on_hit)


func remove(_player: Node) -> void:
	if CombatEvents.hit.is_connected(_on_hit):
		CombatEvents.hit.disconnect(_on_hit)
	_player_ref = null


func _on_hit(target: Node, _damage: float, _is_crit: bool) -> void:
	if _player_ref == null or _player_ref.is_dead or target == null:
		return
	_hit_counter += 1
	if _hit_counter % 3 == 0:
		if target.has_method("take_damage"):
			target.take_damage(45.0, true)
		CombatEvents.crit.emit(target, 45.0)

