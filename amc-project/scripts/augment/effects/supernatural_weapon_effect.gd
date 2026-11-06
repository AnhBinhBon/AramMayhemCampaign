class_name SupernaturalWeaponEffect
extends AugmentEffect
## Lõi Kim Cương 12: Vũ Khí Siêu Nhiên (SupernaturalWeaponEffect)
## Mỗi khi kích hoạt kỹ năng [Space], phóng một loạt 8 tia đạn cường hóa tỏa tròn 360 độ xung quanh.

var _player_ref: Player = null


func apply(player: Node) -> void:
	_player_ref = player as Player
	if not CombatEvents.skill_cast.is_connected(_on_skill_cast):
		CombatEvents.skill_cast.connect(_on_skill_cast)


func remove(_player: Node) -> void:
	if CombatEvents.skill_cast.is_connected(_on_skill_cast):
		CombatEvents.skill_cast.disconnect(_on_skill_cast)
	_player_ref = null


func _on_skill_cast(_skill_id: String) -> void:
	if _player_ref == null or _player_ref.is_dead or _player_ref.weapon_controller == null:
		return

	var wc: WeaponController = _player_ref.weapon_controller
	for i in range(8):
		var angle: float = float(i) * 45.0
		wc.spawn_extra_projectile(angle, 0.85)

