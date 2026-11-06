class_name PlayerStats
extends Node
## Hệ thống Quản lý Chỉ số Động (Dynamic StatSystem)
## Công thức: Stat = (base + sum(add)) * max(0.1, 1.0 + sum(mult))
## Hỗ trợ gắn và gỡ modifier theo nguồn (source) phục vụ Lõi, Trang bị, Phúc lợi và Kỹ năng.

signal stats_changed(stat_type: int)

var base_stats: Dictionary = {}
var _modifiers: Array[Dictionary] = []


func _init() -> void:
	_reset_defaults()


func _reset_defaults() -> void:
	base_stats[StatModifier.StatType.MAX_HP] = 100.0
	base_stats[StatModifier.StatType.HP_REGEN] = 1.0
	base_stats[StatModifier.StatType.LIFESTEAL] = 0.0
	base_stats[StatModifier.StatType.AD] = 18.0
	base_stats[StatModifier.StatType.AP] = 0.0
	base_stats[StatModifier.StatType.ATTACK_SPEED] = 1.85
	base_stats[StatModifier.StatType.CRIT_CHANCE] = 0.15
	base_stats[StatModifier.StatType.CRIT_DAMAGE] = 1.75
	base_stats[StatModifier.StatType.ABILITY_HASTE] = 0.0
	base_stats[StatModifier.StatType.MOVE_SPEED] = 240.0
	base_stats[StatModifier.StatType.ARMOR] = 5.0


func setup_from_character(data: CharacterData) -> void:
	_modifiers.clear()
	if data == null:
		_reset_defaults()
		return

	base_stats[StatModifier.StatType.MAX_HP] = data.base_max_hp
	base_stats[StatModifier.StatType.HP_REGEN] = data.base_hp_regen
	base_stats[StatModifier.StatType.LIFESTEAL] = data.base_lifesteal
	base_stats[StatModifier.StatType.AD] = data.base_ad
	base_stats[StatModifier.StatType.AP] = data.base_ap
	base_stats[StatModifier.StatType.ATTACK_SPEED] = data.base_attack_speed
	base_stats[StatModifier.StatType.CRIT_CHANCE] = data.base_crit_chance
	base_stats[StatModifier.StatType.CRIT_DAMAGE] = data.base_crit_damage
	base_stats[StatModifier.StatType.ABILITY_HASTE] = data.base_ability_haste
	base_stats[StatModifier.StatType.MOVE_SPEED] = data.base_move_speed
	base_stats[StatModifier.StatType.ARMOR] = data.base_armor

	for k in base_stats.keys():
		stats_changed.emit(int(k))


func get_stat(stat_type: StatModifier.StatType) -> float:
	var base_val: float = float(base_stats.get(stat_type, 0.0))
	var sum_add: float = 0.0
	var sum_mult: float = 0.0

	for entry in _modifiers:
		if entry["stat"] == stat_type:
			sum_add += float(entry["add"])
			sum_mult += float(entry["mult"])

	var final_val: float = (base_val + sum_add) * maxf(0.1, 1.0 + sum_mult)

	if stat_type == StatModifier.StatType.CRIT_CHANCE:
		return clampf(final_val, 0.0, 1.0)
	if stat_type == StatModifier.StatType.LIFESTEAL:
		return clampf(final_val, 0.0, 0.85)
	if stat_type == StatModifier.StatType.MAX_HP:
		return maxf(10.0, final_val)
	if stat_type == StatModifier.StatType.ATTACK_SPEED:
		return maxf(0.25, final_val)
	if stat_type == StatModifier.StatType.MOVE_SPEED:
		return maxf(60.0, final_val)

	return final_val


func add_modifier(source: Variant, stat_type: StatModifier.StatType, add_val: float = 0.0, mult_val: float = 0.0) -> void:
	_modifiers.append({
		"source": source,
		"stat": stat_type,
		"add": add_val,
		"mult": mult_val
	})
	stats_changed.emit(int(stat_type))


func apply_stat_modifier_resource(source: Variant, mod: StatModifier) -> void:
	if mod == null:
		return
	add_modifier(source, mod.stat, mod.add, mod.mult)


func remove_modifiers_from(source: Variant) -> void:
	var affected: Dictionary = {}
	var remaining: Array[Dictionary] = []

	for entry in _modifiers:
		if typeof(entry["source"]) == typeof(source) and entry["source"] == source:
			affected[entry["stat"]] = true
		else:
			remaining.append(entry)

	_modifiers = remaining
	for stat_key in affected.keys():
		stats_changed.emit(int(stat_key))

