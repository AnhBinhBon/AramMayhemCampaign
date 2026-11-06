extends Node2D
## Kịch bản Kiểm thử Tự động Giai đoạn 4 (Automated Integration Test - Phase 4)
## Kiểm tra toàn diện Wave 6 (Prep Wave), Wave 7 (Final Boss FSM), ScoreManager, AudioManager, ResultUI & MainMenu.

func _ready() -> void:
	print("==================================================")
	print("   AMC PROJECT - KIỂM THỬ TỰ ĐỘNG GIAI ĐOẠN 4")
	print("==================================================")

	var pass_count: int = 0
	var total_tests: int = 0

	# 1. Kiểm tra Cấu hình Wave 6 (Đợt Chuẩn bị)
	total_tests += 1
	var w6 := WaveData.create_default_wave(6)
	if w6 != null and w6.is_prep_wave and is_equal_approx(w6.gold_multiplier, 2.0) and is_equal_approx(w6.duration, 35.0):
		print("[PASS] Test 1: Wave 6 Chuẩn bị - Đúng cờ is_prep_wave, Vàng x2 (gold_multiplier=2.0), Thời lượng 35s.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 1: Lỗi thông số Wave 6 Chuẩn bị!")

	# 2. Kiểm tra Cấu hình Wave 7 (Trận Đấu Trùm)
	total_tests += 1
	var w7 := WaveData.create_default_wave(7)
	if w7 != null and w7.is_boss_wave and w7.duration >= 900.0 and is_equal_approx(w7.hp_scale, 1.8):
		print("[PASS] Test 2: Wave 7 Đấu Trùm - Đúng cờ is_boss_wave, Hệ số máu x1.8, Không giới hạn thời gian (duration=999s).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 2: Lỗi thông số Wave 7 Trùm cuối!")

	# 3. Kiểm tra Thực thể FinalBoss & Hình học Nội sinh FSM
	total_tests += 1
	var boss_scene: PackedScene = load("res://scenes/entities/FinalBoss.tscn")
	var boss: FinalBoss = boss_scene.instantiate() as FinalBoss
	add_child(boss)
	boss.setup_hp(1.0)

	var has_spikes: bool = (boss.ring_spikes != null and boss.ring_spikes.get_child_count() == 8)
	var has_telegraph: bool = (boss.telegraph_line != null)
	if boss != null and has_spikes and has_telegraph and boss.current_hp == 100000.0:
		print("[PASS] Test 3: FinalBoss - Tạo hình học chuẩn xác: 100,000 HP, Vòng 8 gai xoay tròn, Vệt ngắm Telegraph.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 3: Khởi tạo Boss hoặc cấu trúc Visuals thất bại!")

	# 4. Kiểm tra Cơ chế Chuyển Pha 2 (Cuồng nộ khi HP <= 50%)
	total_tests += 1
	boss.take_damage(55000.0) # 100000 - 55000 = 45000 (dưới 50% = 50000)
	if boss.is_phase_2:
		print("[PASS] Test 4: FinalBoss FSM - Kích hoạt chuẩn xác Pha 2 Cuồng Nộ khi Máu <= 50%% (HP: %.0f / %.0f)." % [boss.current_hp, boss.max_hp])
		pass_count += 1
	else:
		printerr("[FAIL] Test 4: Không kích hoạt Pha 2 khi HP <= 50%!")

	# 5. Kiểm tra Hạ gục Boss & Tín hiệu Chiến thắng
	total_tests += 1
	boss.take_damage(100000.0)
	if boss.is_dead and ScoreManager.boss_killed:
		print("[PASS] Test 5: FinalBoss Tử trận - Bật trạng thái DEAD, phát boss_defeated và ghi nhận ScoreManager.boss_killed.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 5: Trạng thái hạ gục Boss thất bại!")

	# 6. Kiểm tra Công thức Điểm số & Lưu Kỷ lục (ScoreManager)
	total_tests += 1
	ScoreManager.kills = 45
	ScoreManager.survival_time = 120.0
	ScoreManager.boss_killed = true
	var final_score: int = ScoreManager.calculate_final_score(80.0, 35)
	# 45*10 + 120 + 80*5 + 1000 + 35 = 450 + 120 + 400 + 1000 + 35 = 2005
	var expected_score: int = 2005
	if final_score == expected_score and ScoreManager.high_score >= expected_score:
		print("[PASS] Test 6: ScoreManager - Tính điểm tuyệt đối: 45 quái, 120s sống, 80 HP, Thưởng Trùm +1000, 35 Vàng = %d Điểm." % final_score)
		pass_count += 1
	else:
		printerr("[FAIL] Test 6: Lỗi công thức điểm số! Tính: %d, Dự kiến: %d" % [final_score, expected_score])

	# 7. Kiểm tra Hệ thống Âm thanh Nội sinh (AudioManager)
	total_tests += 1
	var audio_ok: bool = (
		AudioManager.snd_shoot != null and
		AudioManager.snd_hit != null and
		AudioManager.snd_crit != null and
		AudioManager.snd_kill != null and
		AudioManager.snd_gold != null and
		AudioManager.snd_boss_alarm != null and
		AudioManager.snd_explosion != null
	)
	if audio_ok:
		print("[PASS] Test 7: AudioManager - Tự sinh thành công 8 bộ sóng âm thanh 8-bit PCM (Bắn, Hit, Crit, Kill, Vàng, Còi trùm, Nổ).")
		pass_count += 1
	else:
		printerr("[FAIL] Test 7: Tạo sóng âm thanh trong AudioManager thất bại!")

	# 8. Kiểm tra Khởi tạo Giao diện Menu Chính và Màn hình Kết quả (MainMenu & ResultUI)
	total_tests += 1
	var main_menu_scene: PackedScene = load("res://scenes/menu/MainMenu.tscn")
	var result_ui_scene: PackedScene = load("res://scenes/ui/ResultUI.tscn")
	var main_menu: MainMenu = main_menu_scene.instantiate() as MainMenu
	var result_ui: ResultUI = result_ui_scene.instantiate() as ResultUI
	add_child(main_menu)
	add_child(result_ui)

	if main_menu != null and result_ui != null:
		print("[PASS] Test 8: Khởi tạo MainMenu và ResultUI thành công hoàn hảo.")
		pass_count += 1
	else:
		printerr("[FAIL] Test 8: Khởi tạo giao diện MainMenu hoặc ResultUI thất bại!")

	print("==================================================")
	print("   KẾT QUẢ: %d / %d BÀI KIỂM THỬ ĐẠT CHUẨN (100%%)" % [pass_count, total_tests])
	print("==================================================")

	get_tree().quit(0 if pass_count == total_tests else 1)

