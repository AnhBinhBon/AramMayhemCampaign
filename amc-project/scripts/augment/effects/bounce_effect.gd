class_name BounceEffect
extends AugmentEffect
## Lõi Vàng 6: Đạn Nảy (BounceEffect)
## Tăng +1 số lần đạn nảy sang mục tiêu kế cận cho vũ khí người chơi.

var _player_ref: Player = null


func apply(player: Node) -> void:
	_player_ref = player as Player
	if _player_ref != null and _player_ref.weapon_controller != null:
		_player_ref.weapon_controller.extra_bounce += 1


func remove(player: Node) -> void:
	var p := player as Player
	if p != null and p.weapon_controller != null:
		p.weapon_controller.extra_bounce = maxi(0, p.weapon_controller.extra_bounce - 1)
	_player_ref = null

