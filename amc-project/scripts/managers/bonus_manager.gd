class_name BonusManager
extends Node
## Hệ thống Phúc lợi Khởi đầu Ngẫu nhiên (BonusManager - Giai đoạn 2)
## Tự động nạp 7 Phúc lợi từ thư mục resources/bonuses/, bốc ngẫu nhiên theo trọng số (weight)
## và áp dụng hiệu ứng lên PlayerStats, CurrencyManager, AugmentManager, ShopManager.

signal bonus_rolled(bonus: BonusData)
signal bonus_applied(bonus: BonusData)
signal wave3_gift_triggered(message: String)

const BONUS_SOURCE: String = "starting_bonus"
const DEFAULT_BONUS_PATHS: Array[String] = [
	"res://resources/bonuses/bonus_1_lucky_ticket.tres",
	"res://resources/bonuses/bonus_2_gold_bag.tres",
	"res://resources/bonuses/bonus_3_pioneer_core.tres",
	"res://resources/bonuses/bonus_4_brave_heart.tres",
	"res://resources/bonuses/bonus_5_vip_customer.tres",
	"res://resources/bonuses/bonus_6_wave3_gift.tres",
	"res://resources/bonuses/bonus_7_bounty_hunter.tres"
]

@export var bonus_pool: Array[BonusData] = []

var active_bonus: BonusData = null
var _pending_wave3_gift: bool = false
var _player_ref: Player = null
var _inventory_ref: Inventory = null
var _shop_ref: ShopManager = null


func _ready() -> void:
	if bonus_pool.is_empty():
		for path in DEFAULT_BONUS_PATHS:
			var res := load(path) as BonusData
			if res != null:
				bonus_pool.append(res)
	CombatEvents.wave_started.connect(_on_wave_started)


func roll_random_bonus() -> BonusData:
	if bonus_pool.is_empty():
		return null

	var total_weight: float = 0.0
	for b in bonus_pool:
		if b != null:
			total_weight += maxf(0.1, b.weight)

	var pick: float = randf() * total_weight
	var accum: float = 0.0
	for b in bonus_pool:
		if b != null:
			accum += maxf(0.1, b.weight)
			if pick <= accum:
				active_bonus = b
				bonus_rolled.emit(b)
				return b

	active_bonus = bonus_pool[0]
	bonus_rolled.emit(active_bonus)
	return active_bonus


func apply_active_bonus(
	player: Player,
	augment_mgr: AugmentManager = null,
	shop_mgr: ShopManager = null,
	inventory: Inventory = null
) -> void:
	if active_bonus == null or player == null:
		return

	_player_ref = player
	_inventory_ref = inventory
	_shop_ref = shop_mgr
	_pending_wave3_gift = false
	player.stats.remove_modifiers_from(BONUS_SOURCE)

	match active_bonus.kind:
		BonusData.BonusKind.EXTRA_REROLL:
			if augment_mgr != null:
				augment_mgr.free_rerolls += int(round(active_bonus.value))
			player.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.CRIT_CHANCE, 0.10, 0.0)

		BonusData.BonusKind.STARTING_GOLD:
			CurrencyManager.add_raw_gold(int(round(active_bonus.value)))

		BonusData.BonusKind.EXTRA_AUGMENT:
			if augment_mgr != null:
				augment_mgr.max_augments += int(round(active_bonus.value))
			player.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.AD, 0.0, 0.15)
			player.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.ATTACK_SPEED, 0.0, 0.15)

		BonusData.BonusKind.MAX_HP_BUFF:
			player.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.MAX_HP, 0.0, active_bonus.value)
			player.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.HP_REGEN, 2.0, 0.0)
			player.heal(9999.0)

		BonusData.BonusKind.SHOP_DISCOUNT:
			if shop_mgr != null:
				shop_mgr.discount_ratio = active_bonus.value
			CurrencyManager.add_raw_gold(35)

		BonusData.BonusKind.GIFT_AT_WAVE_3:
			_pending_wave3_gift = true

		BonusData.BonusKind.GOLD_MULTIPLIER:
			CurrencyManager.bonus_gold_multiplier = 1.0 + active_bonus.value

	bonus_applied.emit(active_bonus)


func _on_wave_started(wave_index: int) -> void:
	if _pending_wave3_gift and wave_index == 3:
		_pending_wave3_gift = false
		CurrencyManager.add_raw_gold(80)
		if _player_ref != null and _player_ref.stats != null:
			_player_ref.stats.add_modifier(BONUS_SOURCE, StatModifier.StatType.AD, 0.0, 0.20)
		if _inventory_ref != null and _shop_ref != null and not _shop_ref.catalog.is_empty() and not _inventory_ref.is_full():
			var rand_item: ItemData = _shop_ref.catalog[randi() % _shop_ref.catalog.size()]
			_inventory_ref.try_add(rand_item)
		wave3_gift_triggered.emit("QUÀ ĐỢT 3 ĐÃ KÍCH HOẠT: +80 Vàng & +20% AD!")
