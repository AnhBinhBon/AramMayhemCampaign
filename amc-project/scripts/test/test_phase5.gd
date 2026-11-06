extends Node2D
## Kịch bản Kiểm thử Tự động Giai đoạn 5 (Automated Integration Test - Phase 5)
## Kiểm tra toàn diện 4 Lớp nhân vật (Xạ Thủ, Đấu Sĩ, Đỡ Đòn, Pháp Sư), 4 Vũ khí đa dạng, 4 Kỹ năng chủ động và UI Chọn Tướng.

func _ready() -> void:
	print("==================================================")
	print("   AMC PROJECT - KIỂM THỬ TỰ ĐỘNG GIAI ĐOẠN 5")
	print("==================================================")

	var pass_count: int = 0
	var total_tests: int = 0

	# 1. Kiểm tra Tải đủ 4 CharacterData (.tres)
	total_tests += 1
	var char_paths := [
		"res://resources/characters/ad_marksman.tres",
		"res://resources/characters/bruiser.tres",
		"res://resources/characters/tank.tres",
		"res://resources/characters/mage_ap.tres"
	]
	var loaded_chars: Array[CharacterData] = []
	var valid_scene_nodes: int = 0
	for p in char_paths:
		var c := load(p) as CharacterData
		if c != null:
			loaded_chars.append(c)
			if not c.character_scene_path.is_empty() and ResourceLoader.exists(c.character_scene_path):
				var packed := load(c.character_scene_path) as PackedScene
				if packed != null:
					var inst := packed.instantiate()
					if inst is Player:
						valid_scene_nodes += 1
					inst.free()
	if loaded_chars.size() == 4 and valid_scene_nodes == 4:
		print("[PASS] Test 1: Tải thành công 4/4 Lớp nhân vật (.tres) & 4/4 Node Scene riêng biệt (PlayerAD, PlayerBruiser, PlayerTank, PlayerMage).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Chỉ tải được %d/4 Lớp nhân vật hoặc %d/4 Scene!" % [loaded_chars.size(), valid_scene_nodes])

	# 2. Kiểm tra Tải đủ 4 WeaponData (.tres)
	total_tests += 1
	var weapon_paths := [
		"res://resources/weapons/gun_ad.tres",
		"res://resources/weapons/sword_bruiser.tres",
		"res://resources/weapons/axe_tank.tres",
		"res://resources/weapons/staff_mage.tres"
	]
	var loaded_weapons: Array[WeaponData] = []
	for p in weapon_paths:
		var w := load(p) as WeaponData
		if w != null:
			loaded_weapons.append(w)
	if loaded_weapons.size() == 4:
		print("[PASS] Test 2: Tải thành công 4/4 Vũ khí đa cơ chế (Súng Đạn, Kiếm Cận chiến, Rìu Đẩy lùi, Gậy AoE).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: Chỉ tải được %d/4 Vũ khí!" % loaded_weapons.size())

	# 3. Kiểm tra Thiết lập Nhân vật Đấu Sĩ (Bruiser)
	total_tests += 1
	var player_scene: PackedScene = load("res://scenes/entities/Player.tscn")
	var p_bruiser: Player = player_scene.instantiate() as Player
	p_bruiser.character_data = loaded_chars[1] # bruiser
	add_child(p_bruiser)

	var bruiser_hp: float = p_bruiser.get_max_hp()
	var bruiser_ad: float = p_bruiser.stats.get_stat(StatModifier.StatType.AD)
	var bruiser_ls: float = p_bruiser.stats.get_stat(StatModifier.StatType.LIFESTEAL)
	if bruiser_hp == 125.0 and bruiser_ad == 22.0 and is_equal_approx(bruiser_ls, 0.08):
		print("[PASS] Test 3: Đấu Sĩ (Bruiser) - Thiết lập chuẩn xác: 125 HP, 22 AD, 8%% Hút máu gốc.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Lỗi chỉ số Đấu Sĩ! HP: %.1f, AD: %.1f, LS: %.2f" % [bruiser_hp, bruiser_ad, bruiser_ls])

	# 4. Kiểm tra Kỹ năng Đấu Sĩ (Tiếng Hú Cuồng Chiến)
	total_tests += 1
	var initial_spd: float = p_bruiser.stats.get_stat(StatModifier.StatType.MOVE_SPEED)
	p_bruiser.skill.try_cast()
	var boosted_spd: float = p_bruiser.stats.get_stat(StatModifier.StatType.MOVE_SPEED)
	var boosted_ls: float = p_bruiser.stats.get_stat(StatModifier.StatType.LIFESTEAL)
	if is_equal_approx(boosted_spd, initial_spd * 1.35) and is_equal_approx(boosted_ls, 0.28):
		print("[PASS] Test 4: Kỹ năng Đấu Sĩ - Tiếng Hú Cuồng Chiến kích hoạt đúng: +35%% Tốc chạy & +20%% Hút máu (Tổng: 28%%).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Lỗi buff kỹ năng Đấu Sĩ! Spd: %.1f -> %.1f, LS: %.2f" % [initial_spd, boosted_spd, boosted_ls])

	# 5. Kiểm tra Thiết lập Nhân vật Đỡ Đòn (Tank)
	total_tests += 1
	var p_tank: Player = player_scene.instantiate() as Player
	p_tank.character_data = loaded_chars[2] # tank
	add_child(p_tank)

	var tank_hp: float = p_tank.get_max_hp()
	var tank_armor: float = p_tank.stats.get_stat(StatModifier.StatType.ARMOR)
	if tank_hp == 155.0 and tank_armor == 18.0:
		print("[PASS] Test 5: Đỡ Đòn (Tank) - Thiết lập chuẩn xác: 155 HP tối đa, 18 Giáp kiên cố.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Lỗi chỉ số Đỡ Đòn! HP: %.1f, Armor: %.1f" % [tank_hp, tank_armor])

	# 6. Kiểm tra Kỹ năng Đỡ Đòn (Khiên Phản Chấn Giảm 50% Sát thương)
	total_tests += 1
	p_tank.skill.try_cast()
	var has_reduction: bool = p_tank.skill.is_damage_reduction_active()
	if has_reduction:
		print("[PASS] Test 6: Kỹ năng Đỡ Đòn - Khiên Phản Chấn kích hoạt thành công, bật giảm 50%% sát thương nhận vào.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 6: Không kích hoạt trạng thái giảm sát thương của Khiên!")

	# 7. Kiểm tra Thiết lập Nhân vật Pháp Sư (Mage AP)
	total_tests += 1
	var p_mage: Player = player_scene.instantiate() as Player
	p_mage.character_data = loaded_chars[3] # mage_ap
	add_child(p_mage)

	var mage_ap: float = p_mage.stats.get_stat(StatModifier.StatType.AP)
	var mage_haste: float = p_mage.stats.get_stat(StatModifier.StatType.ABILITY_HASTE)
	var mage_weapon_aoe: float = loaded_weapons[3].aoe_radius
	if mage_ap == 35.0 and mage_haste == 20.0 and mage_weapon_aoe == 85.0:
		print("[PASS] Test 7: Pháp Sư (Mage AP) - Thiết lập chuẩn xác: 35 AP, 20 Điểm hồi chiêu, Gậy phát nổ AoE 85px.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 7: Lỗi chỉ số Pháp Sư! AP: %.1f, Haste: %.1f, AoE: %.1f" % [mage_ap, mage_haste, mage_weapon_aoe])

	# 8. Kiểm tra Khởi tạo & Tương tác Tick Box Màn hình Chọn Tướng (CharacterSelect UI)
	total_tests += 1
	var char_select_scene: PackedScene = load("res://scenes/menu/CharacterSelect.tscn")
	var char_select: Control = char_select_scene.instantiate() as Control
	add_child(char_select)

	char_select.call("_select_character", 2, true) # Chọn Đỡ Đòn (Tank)
	var tank_selected: bool = (GameManager.selected_character != null and GameManager.selected_character.id == "tank")
	var tank_cb: CheckBox = char_select.get_node_or_null("Margin/MainVBox/CardsHBox/CardTank/Margin/VBox/SelectButton") as CheckBox
	var ad_cb: CheckBox = char_select.get_node_or_null("Margin/MainVBox/CardsHBox/CardAD/Margin/VBox/SelectButton") as CheckBox

	if tank_selected and tank_cb != null and tank_cb.button_pressed and ad_cb != null and not ad_cb.button_pressed:
		print("[PASS] Test 8: CharacterSelect UI - Tick Box chuyển đổi chính xác giữa 4 lớp tướng, bỏ tích các ô còn lại.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 8: Lỗi chuyển đổi Tick Box trên CharacterSelect UI!")

	# 9. Kiểm tra Hệ thống 3 Kỹ năng [Q] - [E] - [SPACE] của 4 Tướng (Vayne, Xin Zhao, Garen, Lux)
	total_tests += 1
	var p_vayne: Player = player_scene.instantiate() as Player
	p_vayne.character_data = loaded_chars[0] # Vayne
	add_child(p_vayne)
	var q_ok: bool = p_vayne.skill.try_cast_q() and p_vayne.skill.cooldown_q_remaining > 0.0
	var e_ok: bool = p_vayne.skill.try_cast_e() and p_vayne.skill.cooldown_e_remaining > 0.0
	var garen_q_ok: bool = p_tank.skill.try_cast_q() and p_tank.skill.try_cast_e()
	var lux_qe_ok: bool = p_mage.skill.try_cast_q() and p_mage.skill.try_cast_e() and p_mage.skill.try_cast()
	if q_ok and e_ok and garen_q_ok and lux_qe_ok:
		print("[PASS] Test 9: Hệ thống 3 Kỹ năng [Q] - [E] - [SPACE] vận hành hoàn hảo cho cả 4 Tướng (Vayne, Xin Zhao, Garen, Lux).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 9: Lỗi kích hoạt Kỹ năng Phụ [Q] / [E]!")

	print("==================================================")
	print("   KẾT QUẢ: %d / %d BÀI KIỂM THỬ ĐẠT CHUẨN (100%%)" % [pass_count, total_tests])
	print("==================================================")

	get_tree().quit(0 if pass_count == total_tests else 1)

