class_name ThornsEffect
extends AugmentEffect
## Lõi Vàng 5: Giáp Gai (ThornsEffect)
## Lắng nghe CombatEvents.take_damage -> Phản sát thương diện rộng ra xung quanh người chơi.

var _player_ref: Player = null
var _thorns_damage: float = 30.0


func apply(player: Node) -> void:
	_player_ref = player as Player
	if not CombatEvents.take_damage.is_connected(_on_take_damage):
		CombatEvents.take_damage.connect(_on_take_damage)


func remove(_player: Node) -> void:
	if CombatEvents.take_damage.is_connected(_on_take_damage):
		CombatEvents.take_damage.disconnect(_on_take_damage)
	_player_ref = null


func _on_take_damage(_amount: float, _attacker: Node) -> void:
	if _player_ref == null or _player_ref.is_dead:
		return

	var armor: float = _player_ref.stats.get_stat(StatModifier.StatType.ARMOR)
	var reflect_dmg: float = _thorns_damage + armor * 2.5
	var center: Vector2 = _player_ref.global_position

	var enemies := _player_ref.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and e.visible and not e.get("is_dead"):
			if center.distance_to(e.global_position) <= 165.0:
				if e.has_method("take_damage"):
					e.take_damage(reflect_dmg, false)
				CombatEvents.hit.emit(e, reflect_dmg, false)

