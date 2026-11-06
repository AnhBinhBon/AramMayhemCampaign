extends Node
## Hệ thống Quản lý Kinh tế & Vàng (Autoload: CurrencyManager)

var gold: int = 0
var bonus_gold_multiplier: float = 1.0
var wave_gold_multiplier: float = 1.0


func reset() -> void:
	gold = 0
	bonus_gold_multiplier = 1.0
	wave_gold_multiplier = 1.0
	CombatEvents.gold_changed.emit(gold)


func get_total_gold_multiplier() -> float:
	return bonus_gold_multiplier * wave_gold_multiplier


func add_gold(base_amount: int) -> int:
	var final_amount: int = maxi(1, int(round(float(base_amount) * get_total_gold_multiplier())))
	gold += final_amount
	CombatEvents.gold_changed.emit(gold)
	return final_amount


func add_raw_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	CombatEvents.gold_changed.emit(gold)


func can_afford(cost: int) -> bool:
	return gold >= cost


func spend_gold(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	CombatEvents.gold_changed.emit(gold)
	return true

