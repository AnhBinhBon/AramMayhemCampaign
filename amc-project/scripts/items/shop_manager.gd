class_name ShopManager
extends Node
## Hệ thống Cửa hàng Giữa Đợt (ShopManager - Giai đoạn 3)
## Bày bán 4 trang bị ngẫu nhiên theo tỷ lệ bậc của Wave, Reroll tăng giá (giảm 50% ở Shop cuối),
## mua vào túi đồ 6 ô và bán hoàn lại 50% vàng.

signal shop_refreshed(offers: Array[ItemData], reroll_cost: int)
signal item_bought(item: ItemData, slot_index: int)
signal item_sold(item: ItemData, refund: int)
signal shop_error(message: String)

const DEFAULT_ITEM_PATHS: Array[String] = [
	"res://resources/items/item_1_long_sword.tres",
	"res://resources/items/item_2_dagger.tres",
	"res://resources/items/item_3_crit_cloak.tres",
	"res://resources/items/item_4_boots.tres",
	"res://resources/items/item_5_cloth_armor.tres",
	"res://resources/items/item_6_bloodthirster.tres",
	"res://resources/items/item_7_last_whisper.tres",
	"res://resources/items/item_8_rapid_firecannon.tres",
	"res://resources/items/item_9_infinity_edge.tres",
	"res://resources/items/item_10_runaans_hurricane.tres"
]

@export var catalog: Array[ItemData] = []

var current_offers: Array[ItemData] = []
var reroll_count: int = 0
var discount_ratio: float = 0.0
var is_final_shop: bool = false


func _ready() -> void:
	if catalog.is_empty():
		for path in DEFAULT_ITEM_PATHS:
			var res := load(path) as ItemData
			if res != null:
				catalog.append(res)


func reset_for_run() -> void:
	reroll_count = 0
	discount_ratio = 0.0
	is_final_shop = false
	current_offers.clear()


func get_reroll_cost() -> int:
	var base_cost: int = 5 + 5 * reroll_count
	if is_final_shop:
		return maxi(2, int(round(float(base_cost) * 0.5)))
	return base_cost


func get_discounted_price(item: ItemData) -> int:
	if item == null:
		return 0
	return maxi(1, int(round(float(item.price) * (1.0 - clampf(discount_ratio, 0.0, 0.5)))))


func open_shop_for_wave(wave_index: int) -> void:
	reroll_count = 0
	is_final_shop = (wave_index == 6)
	generate_offers(wave_index)


func generate_offers(wave_index: int) -> void:
	if catalog.is_empty():
		_ready()

	current_offers.clear()
	var commons: Array[ItemData] = []
	var rares: Array[ItemData] = []
	var legendaries: Array[ItemData] = []

	for it in catalog:
		if it == null:
			continue
		match it.tier:
			ItemData.ItemTier.COMMON:
				commons.append(it)
			ItemData.ItemTier.RARE:
				rares.append(it)
			ItemData.ItemTier.LEGENDARY:
				legendaries.append(it)

	# Tỉ lệ xuất hiện bậc theo wave
	var p_common: float = 0.70
	var p_rare: float = 0.30
	var p_legendary: float = 0.0

	if wave_index >= 6:
		p_common = 0.20
		p_rare = 0.50
		p_legendary = 0.30
	elif wave_index >= 4:
		p_common = 0.40
		p_rare = 0.45
		p_legendary = 0.15

	for _i in range(4):
		var roll: float = randf()
		var chosen_pool: Array[ItemData] = commons
		if roll < p_common or (rares.is_empty() and legendaries.is_empty()):
			chosen_pool = commons
		elif roll < p_common + p_rare or legendaries.is_empty():
			chosen_pool = rares if not rares.is_empty() else commons
		else:
			chosen_pool = legendaries if not legendaries.is_empty() else rares

		if not chosen_pool.is_empty():
			current_offers.append(chosen_pool[randi() % chosen_pool.size()])

	shop_refreshed.emit(current_offers, get_reroll_cost())


func reroll(wave_index: int) -> bool:
	var cost: int = get_reroll_cost()
	if not CurrencyManager.spend_gold(cost):
		shop_error.emit("KHÔNG ĐỦ VÀNG ĐỂ ĐỔI MỚI! (Cần %d Vàng)" % cost)
		return false
	reroll_count += 1
	generate_offers(wave_index)
	return true


func buy_item(offer_index: int, inventory: Inventory) -> bool:
	if offer_index < 0 or offer_index >= current_offers.size():
		return false
	var item: ItemData = current_offers[offer_index]
	if item == null:
		return false

	if inventory == null or inventory.is_full():
		shop_error.emit("TÚI ĐỒ ĐÃ ĐẦY (6/6 Ô)! Hãy bán bớt đồ cũ để mua món mới.")
		return false

	var final_price: int = get_discounted_price(item)
	if not CurrencyManager.spend_gold(final_price):
		shop_error.emit("KHÔNG ĐỦ VÀNG! Cần %d Vàng để mua %s." % [final_price, item.item_name])
		return false

	if inventory.try_add(item):
		current_offers[offer_index] = null
		item_bought.emit(item, offer_index)
		shop_refreshed.emit(current_offers, get_reroll_cost())
		return true

	return false


func sell_item(slot_index: int, inventory: Inventory) -> void:
	if inventory == null:
		return
	if slot_index < 0 or slot_index >= inventory.items.size():
		return
	var item: ItemData = inventory.items[slot_index]
	var refund: int = inventory.sell_at(slot_index)
	item_sold.emit(item, refund)
