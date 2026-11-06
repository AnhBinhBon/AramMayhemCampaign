class_name AugmentManager
extends Node
## Hệ thống Quản lý Lõi Nâng cấp (AugmentManager - Giai đoạn 3)
## Tự động nạp 12 Lõi (Bạc / Vàng / Kim Cương), bốc 3 lựa chọn không trùng lặp,
## hỗ trợ Reroll lõi và kích hoạt các hiệu ứng chỉ số & cơ chế đặc biệt lên Player.

signal augments_offered(choices: Array[AugmentData], rarity: int, rerolls_left: int)
signal augment_picked(augment: AugmentData)
signal augment_error(message: String)

const DEFAULT_AUGMENT_PATHS: Array[String] = [
	# 4 Lõi Bạc (Sau Wave 1)
	"res://resources/augments/aug_1_silver_hand.tres",
	"res://resources/augments/aug_2_swift_boots.tres",
	"res://resources/augments/aug_3_thick_skin.tres",
	"res://resources/augments/aug_4_abundant_mana.tres",
	# 4 Lõi Vàng (Sau Wave 3)
	"res://resources/augments/aug_5_thornmail.tres",
	"res://resources/augments/aug_6_ricochet.tres",
	"res://resources/augments/aug_7_multishot.tres",
	"res://resources/augments/aug_8_frenzy_lifesteal.tres",
	# 4 Lõi Kim Cương (Sau Wave 5)
	"res://resources/augments/aug_9_jeweled_gauntlet.tres",
	"res://resources/augments/aug_10_mystic_punch.tres",
	"res://resources/augments/aug_11_headhunter.tres",
	"res://resources/augments/aug_12_supernatural.tres"
]

const EXTRA_REROLL_GOLD_COST: int = 10

@export var all_augments: Array[AugmentData] = []

var owned_augments: Array[AugmentData] = []
var max_augments: int = 3
var free_rerolls: int = 1
var current_choices: Array[AugmentData] = []


func _ready() -> void:
	_ensure_catalog_loaded()


func _ensure_catalog_loaded() -> void:
	if all_augments.is_empty():
		for path in DEFAULT_AUGMENT_PATHS:
			var res := load(path) as AugmentData
			if res != null:
				all_augments.append(res)


func reset_for_run() -> void:
	owned_augments.clear()
	current_choices.clear()
	max_augments = 3
	free_rerolls = 1


func roll_augments(rarity: AugmentData.Rarity) -> Array[AugmentData]:
	_ensure_catalog_loaded()
	current_choices.clear()

	var pool: Array[AugmentData] = []
	for aug in all_augments:
		if aug == null:
			continue
		if aug.rarity == rarity and not owned_augments.has(aug):
			pool.append(aug)

	pool.shuffle()
	var pick_count: int = mini(3, pool.size())
	for i in range(pick_count):
		current_choices.append(pool[i])

	augments_offered.emit(current_choices, int(rarity), free_rerolls)
	return current_choices


func reroll(rarity: AugmentData.Rarity) -> Array[AugmentData]:
	if free_rerolls > 0:
		free_rerolls -= 1
		return roll_augments(rarity)

	if CurrencyManager.spend_gold(EXTRA_REROLL_GOLD_COST):
		return roll_augments(rarity)

	augment_error.emit("HẾT LƯỢT REROLL MIỄN PHÍ! Cần %d Vàng để đổi lại." % EXTRA_REROLL_GOLD_COST)
	return current_choices


func reroll_slot(rarity: AugmentData.Rarity, slot_idx: int) -> Array[AugmentData]:
	if slot_idx < 0 or slot_idx >= current_choices.size():
		return current_choices

	if free_rerolls > 0:
		free_rerolls -= 1
	elif not CurrencyManager.spend_gold(EXTRA_REROLL_GOLD_COST):
		augment_error.emit("HẾT LƯỢT REROLL MIỄN PHÍ! Cần %d Vàng để đổi lại." % EXTRA_REROLL_GOLD_COST)
		return current_choices

	_ensure_catalog_loaded()
	var pool: Array[AugmentData] = []
	for aug in all_augments:
		if aug != null and aug.rarity == rarity and not owned_augments.has(aug) and not current_choices.has(aug):
			pool.append(aug)

	if pool.is_empty():
		# Nếu đã hết lõi khác không trùng trên bàn, cho phép xoay vòng trong nhóm cùng bậc
		for aug in all_augments:
			if aug != null and aug.rarity == rarity and not owned_augments.has(aug) and aug != current_choices[slot_idx]:
				pool.append(aug)

	if not pool.is_empty():
		pool.shuffle()
		current_choices[slot_idx] = pool[0]

	augments_offered.emit(current_choices, int(rarity), free_rerolls)
	return current_choices


func pick_augment(augment: AugmentData, player: Player) -> void:
	if augment == null or owned_augments.size() >= max_augments:
		return

	owned_augments.append(augment)

	if player != null and player.stats != null:
		for mod in augment.modifiers:
			player.stats.apply_stat_modifier_resource(augment, mod)

	for eff in augment.effects:
		if eff != null:
			eff.apply(player)

	augment_picked.emit(augment)
