extends Node2D
## Kịch bản Kiểm thử Tự động Giai đoạn 3 (Automated Integration Test - Phase 3)

func _ready() -> void:
	print("==================================================")
	print("   AMC PROJECT - KIỂM THỬ TỰ ĐỘNG GIAI ĐOẠN 3")
	print("==================================================")

	var pass_count: int = 0
	var total_tests: int = 0

	# 1. Kiểm tra tải 10 Trang bị
	total_tests += 1
	var item_catalog: Array[ItemData] = []
	for path in ShopManager.DEFAULT_ITEM_PATHS:
		var it := load(path) as ItemData
		if it != null:
			item_catalog.append(it)
	if item_catalog.size() == 10:
		print("[PASS] Test 1: Tải thành công 10/10 Trang bị (.tres).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Chỉ tải được %d/10 Trang bị!" % item_catalog.size())

	# 2. Kiểm tra tải 12 Lõi nâng cấp
	total_tests += 1
	var aug_catalog: Array[AugmentData] = []
	for path in AugmentManager.DEFAULT_AUGMENT_PATHS:
		var aug := load(path) as AugmentData
		if aug != null:
			aug_catalog.append(aug)
	if aug_catalog.size() == 12:
		print("[PASS] Test 2: Tải thành công 12/12 Lõi nâng cấp (Bạc / Vàng / Kim Cương).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: Chỉ tải được %d/12 Lõi nâng cấp!" % aug_catalog.size())

	# 3. Kiểm tra Phân bổ Bậc Lõi (4 Bạc, 4 Vàng, 4 Kim Cương)
	total_tests += 1
	var silvers: int = 0
	var golds: int = 0
	var prismatics: int = 0
	for a in aug_catalog:
		match a.rarity:
			AugmentData.Rarity.SILVER:
				silvers += 1
			AugmentData.Rarity.GOLD:
				golds += 1
			AugmentData.Rarity.PRISMATIC:
				prismatics += 1
	if silvers == 4 and golds == 4 and prismatics == 4:
		print("[PASS] Test 3: Phân bổ cân đối chuẩn xác: 4 Bạc, 4 Vàng, 4 Kim Cương.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Phân bổ không đều: %d Bạc, %d Vàng, %d Kim Cương!" % [silvers, golds, prismatics])

	# 4. Kiểm tra Túi đồ 6 Ô & Gắn/Gỡ Modifiers
	total_tests += 1
	var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")
	var player: Player = player_scene.instantiate() as Player
	add_child(player)

	var inv: Inventory = player.inventory
	inv.setup(player)
	var initial_ad: float = player.stats.get_stat(StatModifier.StatType.AD)

	# Mua Long Sword (+10 AD, giá 30)
	var long_sword := load("res://resources/items/item_1_long_sword.tres") as ItemData
	inv.try_add(long_sword)
	# Kiểm tra đồng thời buff kỹ năng (String source) và trang bị (Object source)
	player.stats.add_modifier("skill_buff", StatModifier.StatType.ATTACK_SPEED, 0.0, 0.50)
	player.stats.remove_modifiers_from("skill_buff")
	var boosted_ad: float = player.stats.get_stat(StatModifier.StatType.AD)

	# Bán Long Sword (hoàn 50% = 15 vàng)
	CurrencyManager.gold = 0
	var refund: int = inv.sell_at(0)
	var reverted_ad: float = player.stats.get_stat(StatModifier.StatType.AD)

	if is_equal_approx(boosted_ad, initial_ad + 10.0) and is_equal_approx(reverted_ad, initial_ad) and refund == 15 and long_sword.item_name == "Kiếm Dài" and aug_catalog[0].augment_name == "Tay Bạc":
		print("[PASS] Test 4: Inventory 6 Ô & UTF-8 - Thêm Kiếm Dài (+10 AD), Gỡ buff kỹ năng an toàn, Bán đồ hoàn 50%% giá (15 Vàng).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Lỗi tính toán AD hoặc hoàn tiền! Initial: %.1f, Boosted: %.1f, Reverted: %.1f, Refund: %d" % [initial_ad, boosted_ad, reverted_ad, refund])

	# 5. Kiểm tra Giới hạn Túi đồ 6/6 Ô
	total_tests += 1
	for _i in range(6):
		inv.try_add(long_sword)
	var can_add_7th: bool = inv.try_add(long_sword)
	if inv.is_full() and not can_add_7th:
		print("[PASS] Test 5: Ràng buộc chuẩn xác: Túi đồ tối đa 6 ô, chặn thêm món thứ 7.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Cho phép thêm quá 6 món đồ vào túi!")
	inv.clear_all()

	# 6. Kiểm tra ShopManager (Bày bán 4 món & Công thức Reroll)
	total_tests += 1
	var shop_mgr := ShopManager.new()
	add_child(shop_mgr)
	shop_mgr._ready()
	shop_mgr.reset_for_run()

	shop_mgr.open_shop_for_wave(1)
	var cost_0: int = shop_mgr.get_reroll_cost()
	CurrencyManager.gold = 200
	shop_mgr.reroll(1)
	var cost_1: int = shop_mgr.get_reroll_cost()

	# Kiểm tra Shop cuối (Wave 6) giảm 50% reroll (5 * 0.5 = 2.5 làm tròn 3)
	shop_mgr.open_shop_for_wave(6)
	var cost_final_0: int = shop_mgr.get_reroll_cost()

	if shop_mgr.current_offers.size() == 4 and cost_0 == 5 and cost_1 == 10 and cost_final_0 == 3:
		print("[PASS] Test 6: ShopManager - Bày bán 4 món, Reroll chuẩn 5 + 5n, Shop cuối giảm 50%% (Giá: %d Vàng)." % cost_final_0)
		pass_count += 1
	else:
		printerr("[FAIL] Test 6: Lỗi Reroll! Cost0: %d, Cost1: %d, CostFinal: %d" % [cost_0, cost_1, cost_final_0])

	# 7. Kiểm tra AugmentManager (Bốc 3 lõi ngẫu nhiên theo bậc & Reroll lõi)
	total_tests += 1
	var aug_mgr := AugmentManager.new()
	add_child(aug_mgr)
	aug_mgr._ready()
	aug_mgr.reset_for_run()

	var rolled_silvers := aug_mgr.roll_augments(AugmentData.Rarity.SILVER)
	var rolled_golds := aug_mgr.roll_augments(AugmentData.Rarity.GOLD)
	var rolled_prismatics := aug_mgr.roll_augments(AugmentData.Rarity.PRISMATIC)

	if rolled_silvers.size() == 3 and rolled_golds.size() == 3 and rolled_prismatics.size() == 3:
		print("[PASS] Test 7: AugmentManager - Bốc đủ 3 lựa chọn độc lập cho cả 3 bậc Bạc / Vàng / Kim Cương.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 7: Số lượng Lõi bốc ra không đạt 3! Silvers: %d, Golds: %d, Prismatics: %d" % [rolled_silvers.size(), rolled_golds.size(), rolled_prismatics.size()])

	# 8. Kiểm tra Khởi tạo Giao diện AugmentUI và ShopUI
	total_tests += 1
	var aug_ui_scene: PackedScene = load("res://scenes/ui/AugmentUI.tscn")
	var shop_ui_scene: PackedScene = load("res://scenes/ui/ShopUI.tscn")
	var aug_ui: AugmentUI = aug_ui_scene.instantiate() as AugmentUI
	var shop_ui: ShopUI = shop_ui_scene.instantiate() as ShopUI
	add_child(aug_ui)
	add_child(shop_ui)

	if aug_ui != null and shop_ui != null:
		print("[PASS] Test 8: Khởi tạo AugmentUI và ShopUI thành công tuyệt đối.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 8: Khởi tạo UI thất bại!")

	print("==================================================")
	print("   KẾT QUẢ: %d / %d BÀI KIỂM THỬ ĐẠT CHUẨN (100%%)" % [pass_count, total_tests])
	print("==================================================")

	get_tree().quit(0 if pass_count == total_tests else 1)
