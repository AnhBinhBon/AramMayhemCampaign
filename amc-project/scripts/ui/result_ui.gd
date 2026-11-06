class_name ResultUI
extends CanvasLayer
## Màn hình Tổng kết Ván đấu (ResultUI - Giai đoạn 4)
## Hiển thị Tổng điểm, Kỷ lục, Chi tiết điểm số (Quái, Thời gian, Máu, Thưởng Boss, Vàng),
## liệt kê các Lõi và Trang bị đã thu thập, hỗ trợ Chơi lại hoặc Quay về Menu chính.

signal restart_requested()
signal menu_requested()

const MAIN_MENU_PATH: String = "res://scenes/menu/MainMenu.tscn"

@onready var root_control: Control = $Root
@onready var title_label: Label = $Root/Center/CardPanel/Margin/VBox/TitleLabel
@onready var score_label: Label = $Root/Center/CardPanel/Margin/VBox/ScoreBox/ScoreLabel
@onready var high_score_badge: Label = $Root/Center/CardPanel/Margin/VBox/ScoreBox/HighScoreBadge
@onready var details_label: Label = $Root/Center/CardPanel/Margin/VBox/DetailsLabel
@onready var augments_box: HBoxContainer = $Root/Center/CardPanel/Margin/VBox/AugmentsSection/AugmentsHBox
@onready var items_box: HBoxContainer = $Root/Center/CardPanel/Margin/VBox/ItemsSection/ItemsHBox
@onready var restart_btn: Button = $Root/Center/CardPanel/Margin/VBox/ButtonsHBox/RestartButton
@onready var menu_btn: Button = $Root/Center/CardPanel/Margin/VBox/ButtonsHBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.visible = false
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)


func show_result(
	is_victory: bool,
	final_score: int,
	player: Player = null,
	augment_mgr: AugmentManager = null,
	inventory: Inventory = null
) -> void:
	root_control.visible = true
	get_tree().paused = true

	# Tiêu đề kết quả
	if is_victory:
		title_label.text = "CHIẾN THẮNG CHIẾN DỊCH!"
		title_label.modulate = Color(0.35, 1.0, 0.55, 1.0)
	else:
		title_label.text = "THẤT BẠI (GAME OVER)"
		title_label.modulate = Color(1.0, 0.3, 0.35, 1.0)

	# Điểm số & Kỷ lục
	score_label.text = "TỔNG ĐIỂM: %d" % final_score
	if final_score >= ScoreManager.high_score and final_score > 0:
		high_score_badge.visible = true
		high_score_badge.text = "★ KỶ LỤC MỚI ĐÃ ĐƯỢC THIẾT LẬP! ★"
		high_score_badge.modulate = Color(1.0, 0.88, 0.2, 1.0)
	else:
		high_score_badge.visible = true
		high_score_badge.text = "Kỷ lục cao nhất: %d Điểm" % ScoreManager.high_score
		high_score_badge.modulate = Color(0.75, 0.8, 0.9, 1.0)

	# Chi tiết thống kê
	var secs: int = int(ScoreManager.survival_time)
	var time_str: String = "%02d:%02d" % [secs / 60, secs % 60]
	var boss_reward: int = 1000 if ScoreManager.boss_killed else 0
	var rem_hp: int = int(player.current_hp) if (player != null and not player.is_dead) else 0

	details_label.text = (
		"• Quái tiêu diệt: %d (+%d đ)   |   • Thời gian sống: %s (+%d đ)\n" +
		"• Máu còn lại: %d (+%d đ)   |   • Vàng dư: %d (+%d đ)   |   • Thưởng diệt Trùm: +%d đ"
	) % [
		ScoreManager.kills, ScoreManager.kills * 10,
		time_str, secs,
		rem_hp, rem_hp * 5,
		CurrencyManager.gold, CurrencyManager.gold,
		boss_reward
	]

	# Hiển thị Lõi nâng cấp đã thu thập
	_populate_augments(augment_mgr)

	# Hiển thị Trang bị trong Túi đồ 6 ô
	_populate_items(inventory)

	restart_btn.grab_focus()


func _populate_augments(augment_mgr: AugmentManager) -> void:
	for child in augments_box.get_children():
		child.queue_free()

	var list: Array[AugmentData] = augment_mgr.owned_augments if augment_mgr != null else []
	if list.is_empty():
		var lbl := Label.new()
		lbl.text = "[ Chưa chọn Lõi nâng cấp nào ]"
		lbl.modulate = Color(0.5, 0.55, 0.65, 1.0)
		augments_box.add_child(lbl)
		return

	for aug in list:
		if aug == null:
			continue
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(160, 48)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.12, 0.16, 0.9)
		sb.border_color = aug.accent_color
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", sb)

		var hbox := HBoxContainer.new()
		hbox.set("theme_override_constants/separation", 6)
		panel.add_child(hbox)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not aug.icon_path.is_empty() and ResourceLoader.exists(aug.icon_path):
			icon.texture = load(aug.icon_path) as Texture2D
			icon.self_modulate = aug.accent_color
		hbox.add_child(icon)

		var lbl := Label.new()
		lbl.text = aug.augment_name
		lbl.modulate = aug.accent_color
		lbl.add_theme_font_size_override("font_size", 11)
		hbox.add_child(lbl)

		augments_box.add_child(panel)


func _populate_items(inventory: Inventory) -> void:
	for child in items_box.get_children():
		child.queue_free()

	var list: Array[ItemData] = inventory.items if inventory != null else []
	for i in range(Inventory.MAX_SLOTS):
		var has_item: bool = (i < list.size())
		var it: ItemData = list[i] if has_item else null

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(100, 44)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(5)

		if it == null:
			sb.bg_color = Color(0.06, 0.08, 0.1, 0.5)
			sb.border_color = Color(0.2, 0.25, 0.3, 0.5)
			sb.set_border_width_all(1)
			panel.add_theme_stylebox_override("panel", sb)
			var empty_lbl := Label.new()
			empty_lbl.text = "[ Ô %d ]" % (i + 1)
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.modulate = Color(0.35, 0.4, 0.45, 0.7)
			empty_lbl.add_theme_font_size_override("font_size", 10)
			panel.add_child(empty_lbl)
		else:
			var tier_color: Color = Color.WHITE
			match it.tier:
				ItemData.ItemTier.COMMON:
					tier_color = Color(0.85, 0.9, 0.95, 1.0)
				ItemData.ItemTier.RARE:
					tier_color = Color(0.3, 0.65, 1.0, 1.0)
				ItemData.ItemTier.LEGENDARY:
					tier_color = Color(1.0, 0.65, 0.15, 1.0)

			sb.bg_color = Color(0.1, 0.13, 0.18, 0.9)
			sb.border_color = tier_color
			sb.set_border_width_all(1)
			panel.add_theme_stylebox_override("panel", sb)

			var hbox := HBoxContainer.new()
			hbox.set("theme_override_constants/separation", 4)
			panel.add_child(hbox)

			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(26, 26)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if not it.icon_path.is_empty() and ResourceLoader.exists(it.icon_path):
				icon.texture = load(it.icon_path) as Texture2D
				icon.self_modulate = tier_color
			hbox.add_child(icon)

			var name_lbl := Label.new()
			name_lbl.text = it.item_name
			name_lbl.modulate = tier_color
			name_lbl.add_theme_font_size_override("font_size", 10)
			hbox.add_child(name_lbl)

		items_box.add_child(panel)


func _on_restart_pressed() -> void:
	root_control.visible = false
	get_tree().paused = false
	restart_requested.emit()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	root_control.visible = false
	get_tree().paused = false
	menu_requested.emit()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

