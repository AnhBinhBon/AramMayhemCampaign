class_name MultishotEffect
extends AugmentEffect
## Lõi Vàng 7: Xả Đạn Hàng Loạt & Item 10: Cuồng Cung (MultishotEffect)
## Mỗi khi khai hỏa, bắn kèm các tia đạn phụ lệch góc sang 2 bên.

@export var extra_shots: int = 2
@export var damage_ratio: float = 0.60
@export var angle_spread: float = 14.0

var _player_ref: Player = null


func apply(player: Node) -> void:
	_player_ref = player as Player
	if not CombatEvents.attack.is_connected(_on_attack):
		CombatEvents.attack.connect(_on_attack)


func remove(_player: Node) -> void:
	if CombatEvents.attack.is_connected(_on_attack):
		CombatEvents.attack.disconnect(_on_attack)
	_player_ref = null


func _on_attack(weapon: Node, _projectile: Node) -> void:
	if _player_ref == null or _player_ref.is_dead or weapon == null:
		return
	if not weapon.has_method("spawn_extra_projectile"):
		return

	if extra_shots == 1:
		weapon.spawn_extra_projectile(angle_spread, damage_ratio)
	else:
		weapon.spawn_extra_projectile(-angle_spread, damage_ratio)
		weapon.spawn_extra_projectile(angle_spread, damage_ratio)

