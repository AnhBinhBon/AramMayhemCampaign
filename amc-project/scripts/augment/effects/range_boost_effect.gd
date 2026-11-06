class_name RangeBoostEffect
extends AugmentEffect
## Item 8: Đại Bác Liên Thanh (RangeBoostEffect)
## Tăng +90 tầm bắn cho vũ khí người chơi.

@export var range_bonus: float = 90.0


func apply(player: Node) -> void:
	var p := player as Player
	if p != null and p.weapon_controller != null:
		p.weapon_controller.extra_range += range_bonus


func remove(player: Node) -> void:
	var p := player as Player
	if p != null and p.weapon_controller != null:
		p.weapon_controller.extra_range = maxf(0.0, p.weapon_controller.extra_range - range_bonus)

