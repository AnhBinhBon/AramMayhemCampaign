class_name Inventory
extends Node
## Hệ thống Túi đồ 6 Ô (Inventory - Khung kiến trúc cho Giai đoạn 3)
## Mỗi ô trang bị dùng một đối tượng khóa nguồn (slot_source) riêng để khi bán đồ gỡ đúng chỉ số.

signal inventory_changed(items: Array[ItemData])
signal inventory_full()

const MAX_SLOTS: int = 6

var items: Array[ItemData] = []
var _slot_sources: Array[RefCounted] = []
var player: Player = null


func setup(p_player: Player) -> void:
	player = p_player
	clear_all()


func clear_all() -> void:
	if player != null and player.stats != null:
		for src in _slot_sources:
			player.stats.remove_modifiers_from(src)
	items.clear()
	_slot_sources.clear()
	inventory_changed.emit(items)


func is_full() -> bool:
	return items.size() >= MAX_SLOTS


func try_add(item: ItemData) -> bool:
	if item == null:
		return false
	if is_full():
		inventory_full.emit()
		return false

	var slot_src := RefCounted.new()
	items.append(item)
	_slot_sources.append(slot_src)

	if player != null and player.stats != null:
		for mod in item.modifiers:
			player.stats.apply_stat_modifier_resource(slot_src, mod)
	if item.passive_effect != null and player != null:
		item.passive_effect.apply(player)

	inventory_changed.emit(items)
	return true


func sell_at(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= items.size():
		return 0

	var item: ItemData = items[slot_index]
	var slot_src: RefCounted = _slot_sources[slot_index]

	if player != null and player.stats != null:
		player.stats.remove_modifiers_from(slot_src)
	if item.passive_effect != null and player != null:
		item.passive_effect.remove(player)

	var refund: int = maxi(1, int(round(float(item.price) * 0.5)))
	CurrencyManager.add_raw_gold(refund)

	items.remove_at(slot_index)
	_slot_sources.remove_at(slot_index)
	inventory_changed.emit(items)
	return refund

