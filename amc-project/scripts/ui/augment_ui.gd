class_name AugmentUI
extends CanvasLayer
## Giao diện Chọn Lõi Nâng cấp Phong cách League of Legends Arena / Mayhem (AugmentUI)
## Thiết kế khung thẻ kim loại kép, huy hiệu tròn, nhãn phân loại (Tags) và nút Reroll [ ↻ ] riêng dưới từng thẻ.

signal augment_chosen(augment: AugmentData)

@onready var root_control: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/VBox/HeaderBox/TitleLabel
@onready var rarity_label: Label = $Root/CenterContainer/VBox/HeaderBox/RarityLabel
@onready var subtitle_label: Label = $Root/CenterContainer/VBox/HeaderBox/SubtitleLabel
@onready var cards_container: HBoxContainer = $Root/CenterContainer/VBox/CardsHBox
@onready var reroll_btn: Button = $Root/CenterContainer/VBox/BottomHBox/RerollButton
@onready var menu_btn: Button = $Root/CenterContainer/VBox/BottomHBox/MenuButton
@onready var quit_btn: Button = $Root/CenterContainer/VBox/BottomHBox/QuitButton
@onready var error_label: Label = $Root/CenterContainer/VBox/ErrorLabel

var _current_rarity: AugmentData.Rarity = AugmentData.Rarity.SILVER
var _current_choices: Array[AugmentData] = []
var _augment_manager: AugmentManager = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.visible = false
	error_label.text = ""
	reroll_btn.pressed.connect(_on_reroll_pressed)
	if menu_btn != null:
		menu_btn.pressed.connect(func():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")
		)
	if quit_btn != null:
		quit_btn.pressed.connect(func(): get_tree().quit())


func setup_manager(mgr: AugmentManager) -> void:
	_augment_manager = mgr
	if _augment_manager != null and not _augment_manager.augment_error.is_connected(_on_augment_error):
		_augment_manager.augment_error.connect(_on_augment_error)


func show_selection(choices: Array[AugmentData], rarity: AugmentData.Rarity, rerolls_left: int) -> void:
	_current_choices = choices
	_current_rarity = rarity
	error_label.text = ""
	root_control.visible = true
	get_tree().paused = true

	var rarity_name: String = ""
	var rarity_color: Color = Color.WHITE
	match rarity:
		AugmentData.Rarity.SILVER:
			rarity_name = "BẬC BẠC (SILVER AUGMENT)"
			rarity_color = Color(0.80, 0.86, 0.94, 1.0)
		AugmentData.Rarity.GOLD:
			rarity_name = "BẬC VÀNG (GOLD AUGMENT)"
			rarity_color = Color(0.96, 0.78, 0.24, 1.0)
		AugmentData.Rarity.PRISMATIC:
			rarity_name = "BẬC KIM CƯƠNG (PRISMATIC AUGMENT)"
			rarity_color = Color(0.86, 0.66, 1.0, 1.0)

	title_label.text = "CHỌN LÕI NÂNG CẤP CHIẾN DỊCH"
	rarity_label.text = "[ %s ]" % rarity_name
	rarity_label.modulate = rarity_color
	subtitle_label.text = "Nhấp trực tiếp vào Thẻ Lõi để chọn hoặc nhấn nút [ ↻ ] dưới từng thẻ để đổi riêng thẻ đó:"

	_update_reroll_button(rerolls_left)
	_build_cards()


func _update_reroll_button(rerolls_left: int) -> void:
	if rerolls_left > 0:
		reroll_btn.text = "↻ ĐỔI TẤT CẢ (Miễn phí: %d)" % rerolls_left
		reroll_btn.modulate = Color(0.45, 0.95, 0.62, 1.0)
	else:
		reroll_btn.text = "↻ ĐỔI TẤT CẢ (%d Vàng)" % AugmentManager.EXTRA_REROLL_GOLD_COST
		reroll_btn.modulate = Color(0.95, 0.78, 0.28, 1.0)


func _build_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for i in range(_current_choices.size()):
		var aug: AugmentData = _current_choices[i]
		if aug == null:
			continue
		var col := _create_lol_augment_column(aug, i)
		cards_container.add_child(col)


func _get_tags_for_augment(aug: AugmentData) -> Array[String]:
	match aug.id:
		"silver_hand":
			return ["Sát thương", "Công kích"]
		"swift_boots":
			return ["Tốc độ", "Cơ động"]
		"thick_skin":
			return ["Chống chịu", "Sinh tồn"]
		"abundant_mana":
			return ["Phép thuật", "Hồi chiêu"]
		"thornmail":
			return ["Phòng thủ", "Phản đòn"]
		"ricochet":
			return ["Đòn đánh", "Đạn nảy"]
		"multishot":
			return ["Đòn đánh", "Đa mục tiêu"]
		"frenzy_lifesteal":
			return ["Cuồng chiến", "Hút máu"]
		"jeweled_gauntlet":
			return ["Chí mạng", "Bùng nổ"]
		"mystic_punch":
			return ["Đòn đánh", "Giảm hồi chiêu"]
		"headhunter":
			return ["Tích lũy", "Sát thương"]
		"supernatural_weapon":
			return ["Kỹ năng", "Đột phá"]
		_:
			return ["Chiến thuật", "Cường hóa"]


func _create_lol_augment_column(aug: AugmentData, index: int) -> Control:
	var col_vbox := VBoxContainer.new()
	col_vbox.set("theme_override_constants/separation", 10)
	col_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Màu khung viền kim loại chuẩn LoL theo bậc
	var frame_outer_col: Color
	var frame_bg_col: Color
	var inner_border_col: Color
	match aug.rarity:
		AugmentData.Rarity.SILVER:
			frame_outer_col = Color(0.76, 0.82, 0.90, 1.0)
			frame_bg_col = Color(0.55, 0.62, 0.70, 1.0)
			inner_border_col = Color(0.32, 0.44, 0.52, 1.0)
		AugmentData.Rarity.GOLD:
			frame_outer_col = Color(0.95, 0.78, 0.32, 1.0)
			frame_bg_col = Color(0.68, 0.52, 0.18, 1.0)
			inner_border_col = Color(0.52, 0.42, 0.20, 1.0)
		AugmentData.Rarity.PRISMATIC:
			frame_outer_col = Color(0.88, 0.74, 1.0, 1.0)
			frame_bg_col = Color(0.66, 0.54, 0.86, 1.0)
			inner_border_col = Color(0.45, 0.62, 0.78, 1.0)

	# 1. Khung viền ngoài dày kiểu LoL (Outer Metallic Frame)
	var outer_panel := PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(284, 376)
	outer_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var outer_sb := StyleBoxFlat.new()
	outer_sb.bg_color = frame_bg_col
	outer_sb.border_color = frame_outer_col
	outer_sb.set_border_width_all(4)
	outer_sb.set_corner_radius_all(14)
	outer_sb.set_content_margin_all(7.0)
	outer_sb.shadow_color = Color(frame_outer_col.r, frame_outer_col.g, frame_outer_col.b, 0.25)
	outer_sb.shadow_size = 10
	outer_panel.add_theme_stylebox_override("panel", outer_sb)

	# 2. Lòng thẻ tối sâu kiểu LoL (Inner Dark-Teal Obsidian Canvas)
	var inner_panel := PanelContainer.new()
	inner_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var inner_sb := StyleBoxFlat.new()
	inner_sb.bg_color = Color(0.03, 0.08, 0.10, 0.98)
	inner_sb.border_color = inner_border_col
	inner_sb.set_border_width_all(2)
	inner_sb.set_corner_radius_all(10)
	inner_sb.set_content_margin_all(16.0)
	inner_panel.add_theme_stylebox_override("panel", inner_sb)
	outer_panel.add_child(inner_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.set("theme_override_constants/separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_panel.add_child(vbox)

	# 3. Huy hiệu Vòng nguyệt quế tròn & Biểu tượng Lõi (Emblem Medallion)
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_center.custom_minimum_size = Vector2(0, 96)

	var crest_panel := PanelContainer.new()
	crest_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	crest_panel.custom_minimum_size = Vector2(88, 88)
	var crest_sb := StyleBoxFlat.new()
	crest_sb.bg_color = Color(0.06, 0.13, 0.17, 1.0)
	crest_sb.border_color = Color(frame_outer_col.r, frame_outer_col.g, frame_outer_col.b, 0.65)
	crest_sb.set_border_width_all(3)
	crest_sb.set_corner_radius_all(44)
	crest_sb.set_content_margin_all(12.0)
	crest_panel.add_theme_stylebox_override("panel", crest_sb)

	var icon_rect := TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not aug.icon_path.is_empty() and ResourceLoader.exists(aug.icon_path):
		icon_rect.texture = load(aug.icon_path) as Texture2D
		icon_rect.self_modulate = frame_outer_col
	crest_panel.add_child(icon_rect)
	icon_center.add_child(crest_panel)
	vbox.add_child(icon_center)

	# 4. Tên Lõi (Centered Bold Ivory Title)
	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	name_lbl.text = aug.augment_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_lbl)

	# 5. Hàng Nhãn Phân Loại (LoL Category Tag Pills)
	var tags_hbox := HBoxContainer.new()
	tags_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	tags_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tags_hbox.set("theme_override_constants/separation", 6)
	for tag_str in _get_tags_for_augment(aug):
		var tag_panel := PanelContainer.new()
		tag_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var tag_sb := StyleBoxFlat.new()
		tag_sb.bg_color = Color(0.20, 0.22, 0.26, 0.95)
		tag_sb.border_color = Color(0.45, 0.46, 0.50, 0.85)
		tag_sb.set_border_width_all(1)
		tag_sb.set_corner_radius_all(3)
		tag_sb.content_margin_left = 8.0
		tag_sb.content_margin_right = 8.0
		tag_sb.content_margin_top = 2.0
		tag_sb.content_margin_bottom = 2.0
		tag_panel.add_theme_stylebox_override("panel", tag_sb)

		var tag_lbl := Label.new()
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		tag_lbl.text = tag_str
		tag_lbl.add_theme_color_override("font_color", Color(0.84, 0.82, 0.76, 1.0))
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_panel.add_child(tag_lbl)
		tags_hbox.add_child(tag_panel)
	vbox.add_child(tags_hbox)

	# 6. Nội dung mô tả Lõi (Căn giữa sạch sẽ như LoL)
	var desc_lbl := Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	desc_lbl.text = aug.description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.76, 0.82, 0.86, 1.0))
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_lbl)

	# 7. Nút / Thanh kích hoạt chọn Lõi dưới đáy thẻ
	var choose_btn := Button.new()
	choose_btn.text = "CHỌN LÕI NÀY"
	choose_btn.custom_minimum_size = Vector2(0, 34)
	choose_btn.add_theme_font_size_override("font_size", 13)
	var choose_sb := StyleBoxFlat.new()
	choose_sb.bg_color = Color(0.08, 0.22, 0.26, 0.95)
	choose_sb.border_color = frame_outer_col
	choose_sb.set_border_width_all(1)
	choose_sb.set_corner_radius_all(5)
	choose_btn.add_theme_stylebox_override("normal", choose_sb)
	choose_btn.pressed.connect(func(): _on_card_chosen(aug))
	vbox.add_child(choose_btn)

	# Cho phép click vào toàn bộ thẻ Lõi như trong LoL
	outer_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_on_card_chosen(aug)
	)
	outer_panel.mouse_entered.connect(func():
		outer_sb.border_color = Color.WHITE
		outer_sb.shadow_size = 16
	)
	outer_panel.mouse_exited.connect(func():
		outer_sb.border_color = frame_outer_col
		outer_sb.shadow_size = 10
	)

	col_vbox.add_child(outer_panel)

	# 8. Nút Reroll [ ↻ ] màu Đồng Hextech nằm ngay bên dưới từng thẻ (Giống hệt LoL Arena)
	var slot_reroll_center := CenterContainer.new()
	var slot_reroll_btn := Button.new()
	slot_reroll_btn.custom_minimum_size = Vector2(96, 36)
	slot_reroll_btn.text = "↻"
	slot_reroll_btn.tooltip_text = "Đổi lại riêng thẻ Lõi này"
	slot_reroll_btn.add_theme_font_size_override("font_size", 20)
	slot_reroll_btn.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1.0))

	var rr_sb := StyleBoxFlat.new()
	rr_sb.bg_color = Color(0.28, 0.21, 0.11, 0.96)
	rr_sb.border_color = Color(0.78, 0.61, 0.24, 1.0)
	rr_sb.set_border_width_all(2)
	rr_sb.set_corner_radius_all(4)
	slot_reroll_btn.add_theme_stylebox_override("normal", rr_sb)

	var rr_hover_sb := rr_sb.duplicate() as StyleBoxFlat
	rr_hover_sb.bg_color = Color(0.40, 0.30, 0.15, 1.0)
	rr_hover_sb.border_color = Color(1.0, 0.85, 0.38, 1.0)
	slot_reroll_btn.add_theme_stylebox_override("hover", rr_hover_sb)
	slot_reroll_btn.add_theme_stylebox_override("pressed", rr_hover_sb)

	var slot_idx: int = index
	slot_reroll_btn.pressed.connect(func(): _on_slot_reroll_pressed(slot_idx))
	slot_reroll_center.add_child(slot_reroll_btn)
	col_vbox.add_child(slot_reroll_center)

	return col_vbox


func _on_card_chosen(aug: AugmentData) -> void:
	if AudioManager != null and AudioManager.has_method("play_buy"):
		AudioManager.play_buy()
	root_control.visible = false
	augment_chosen.emit(aug)


func _on_slot_reroll_pressed(slot_idx: int) -> void:
	if _augment_manager == null:
		return
	var new_choices: Array[AugmentData] = _augment_manager.reroll_slot(_current_rarity, slot_idx)
	if not new_choices.is_empty():
		if AudioManager != null and AudioManager.has_method("play_buy"):
			AudioManager.play_buy()
		_current_choices = new_choices
		_update_reroll_button(_augment_manager.free_rerolls)
		_build_cards()


func _on_reroll_pressed() -> void:
	if _augment_manager == null:
		return
	var new_choices: Array[AugmentData] = _augment_manager.reroll(_current_rarity)
	if not new_choices.is_empty():
		if AudioManager != null and AudioManager.has_method("play_buy"):
			AudioManager.play_buy()
		_current_choices = new_choices
		_update_reroll_button(_augment_manager.free_rerolls)
		_build_cards()


func _on_augment_error(msg: String) -> void:
	error_label.text = msg
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(3.0)
	tw.tween_callback(func(): error_label.text = "")
