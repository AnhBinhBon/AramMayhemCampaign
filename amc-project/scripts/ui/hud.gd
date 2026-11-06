class_name HUD
extends CanvasLayer
## Giao diện Chiến đấu Phong cách League of Legends (LoL Hextech Bottom HUD Dock)
## Bố cục chuẩn LoL ở đáy màn hình:
## [Bảng Chỉ Số 2 Cột + Avatar Tướng] | [Hàng Kỹ Năng Q-E-SPACE + Thanh Máu Xanh Lá & Thanh Năng Lượng Xanh Dương] | [Khay 6 Ô Trang Bị 3x2 + Vàng]

signal next_wave_requested()
signal restart_requested()
signal menu_requested()

@onready var top_left_panel: PanelContainer = $Root/TopLeftPanel
@onready var hp_bar: ProgressBar = $Root/TopLeftPanel/VBox/HPBar
@onready var hp_label: Label = $Root/TopLeftPanel/VBox/HPBar/HPLabel
@onready var stats_label: Label = $Root/TopLeftPanel/VBox/StatsLabel
@onready var bonus_hbox: HBoxContainer = $Root/TopLeftPanel/VBox/BonusHBox
@onready var bonus_icon: TextureRect = $Root/TopLeftPanel/VBox/BonusHBox/BonusIcon
@onready var bonus_label: Label = $Root/TopLeftPanel/VBox/BonusHBox/BonusLabel

@onready var top_center_panel: PanelContainer = $Root/TopCenterPanel
@onready var wave_title_label: Label = $Root/TopCenterPanel/VBox/WaveTitleLabel
@onready var timer_icon: TextureRect = $Root/TopCenterPanel/VBox/TimerHBox/TimerIcon
@onready var timer_label: Label = $Root/TopCenterPanel/VBox/TimerHBox/TimerLabel

@onready var boss_panel: PanelContainer = $Root/BossPanel
@onready var boss_name_label: Label = $Root/BossPanel/VBox/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $Root/BossPanel/VBox/BossHPBar
@onready var boss_hp_label: Label = $Root/BossPanel/VBox/BossHPBar/BossHPLabel
@onready var boss_phase_label: Label = $Root/BossPanel/VBox/BossPhaseLabel

@onready var gold_icon: TextureRect = $Root/TopRightPanel/VBox/GoldHBox/GoldIcon
@onready var gold_label: Label = $Root/TopRightPanel/VBox/GoldHBox/GoldLabel
@onready var kills_icon: TextureRect = $Root/TopRightPanel/VBox/KillsHBox/KillsIcon
@onready var kills_label: Label = $Root/TopRightPanel/VBox/KillsHBox/KillsLabel
@onready var menu_top_btn: Button = $Root/TopRightPanel/VBox/QuickExitHBox/MenuTopButton
@onready var quit_top_btn: Button = $Root/TopRightPanel/VBox/QuickExitHBox/QuitTopButton

@onready var bottom_center_panel: PanelContainer = $Root/BottomCenterPanel
@onready var skill_icon: TextureRect = $Root/BottomCenterPanel/HBox/SkillIcon
@onready var skill_bar: ProgressBar = $Root/BottomCenterPanel/HBox/SkillBar
@onready var skill_label: Label = $Root/BottomCenterPanel/HBox/SkillBar/SkillLabel

@onready var banner_label: Label = $Root/BannerLabel

@onready var intermission_panel: PanelContainer = $Root/IntermissionPanel
@onready var intermission_title: Label = $Root/IntermissionPanel/VBox/TitleLabel
@onready var intermission_desc: Label = $Root/IntermissionPanel/VBox/DescLabel
@onready var next_wave_btn: Button = $Root/IntermissionPanel/VBox/ButtonsHBox/NextWaveButton
@onready var menu_btn: Button = $Root/IntermissionPanel/VBox/ButtonsHBox/MenuButton

var _player: Player = null
var _is_game_over_mode: bool = false

# Các nút giao diện thuộc Thanh HUD Đáy chuẩn LoL (LoL Bottom HUD Dock)
var _lol_stat_labels: Dictionary = {}
var _lol_avatar_icon: TextureRect = null
var _lol_avatar_frame_sb: StyleBoxFlat = null
var _lol_class_badge: Label = null
var _lol_hp_bar: ProgressBar = null
var _lol_hp_center_lbl: Label = null
var _lol_hp_regen_lbl: Label = null
var _lol_mana_bar: ProgressBar = null
var _lol_mana_center_lbl: Label = null
var _lol_skill_icons: Array[TextureRect] = []
var _lol_skill_cd_labels: Array[Label] = []
var _lol_item_slots: Array[TextureRect] = []
var _lol_gold_lbl: Label = null


func _ready() -> void:
	intermission_panel.visible = false
	banner_label.visible = false
	bonus_hbox.visible = false
	if boss_panel != null:
		boss_panel.visible = false

	_load_tex(gold_icon, "res://assets/sprites/ui/ui_gold.png", Color(1.0, 0.88, 0.18, 1.0))
	_load_tex(kills_icon, "res://assets/sprites/ui/ui_kills.png", Color(0.95, 0.42, 0.42, 1.0))
	_load_tex(timer_icon, "res://assets/sprites/ui/ui_timer.png", Color(0.75, 0.88, 1.0, 1.0))

	_build_lol_bottom_dock()

	next_wave_btn.pressed.connect(_on_action_button_pressed)
	menu_btn.pressed.connect(_on_menu_button_pressed)
	if menu_top_btn != null:
		menu_top_btn.pressed.connect(_on_menu_button_pressed)
	if quit_top_btn != null:
		quit_top_btn.pressed.connect(func(): get_tree().quit())

	CombatEvents.gold_changed.connect(_on_gold_changed)
	CombatEvents.kill.connect(_on_enemy_killed)
	CombatEvents.boss_spawned.connect(_on_boss_spawned)
	CombatEvents.boss_hp_changed.connect(_on_boss_hp_changed)
	CombatEvents.boss_defeated.connect(_on_boss_defeated)
	_on_gold_changed(CurrencyManager.gold)
	_update_kills_display()


func _build_lol_bottom_dock() -> void:
	if bottom_center_panel == null:
		return

	# Ẩn HBox cũ trong BottomCenterPanel nhưng vẫn giữ node để tương thích
	var old_hbox := bottom_center_panel.get_node_or_null("HBox") as Control
	if old_hbox != null:
		old_hbox.visible = false

	# Thu gọn TopLeftPanel chỉ để hiển thị Huy hiệu Phúc lợi Đầu trận & Tóm tắt Tướng
	if hp_bar != null:
		hp_bar.visible = false
	if top_left_panel != null:
		top_left_panel.offset_right = 310.0
		top_left_panel.offset_bottom = 86.0

	# Định vị Thanh HUD Đáy kiểu LoL (Rộng 860px, cao 118px ở chính giữa đáy màn hình)
	bottom_center_panel.offset_left = -435.0
	bottom_center_panel.offset_top = -124.0
	bottom_center_panel.offset_right = 435.0
	bottom_center_panel.offset_bottom = -6.0

	var dock_sb := StyleBoxFlat.new()
	dock_sb.bg_color = Color(0.03, 0.07, 0.09, 0.96)
	dock_sb.border_color = Color(0.58, 0.46, 0.20, 1.0) # Viền Vàng Đồng Hextech
	dock_sb.set_border_width_all(2)
	dock_sb.set_corner_radius_all(6)
	dock_sb.content_margin_left = 10.0
	dock_sb.content_margin_right = 10.0
	dock_sb.content_margin_top = 8.0
	dock_sb.content_margin_bottom = 8.0
	bottom_center_panel.add_theme_stylebox_override("panel", dock_sb)

	var main_hbox := HBoxContainer.new()
	main_hbox.name = "LoLDockHBox"
	main_hbox.set("theme_override_constants/separation", 12)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_center_panel.add_child(main_hbox)

	# =========================================================================
	# PHẦN 1 (TRÁI): BẢNG CHỈ SỐ 2 CỘT + AVATAR TƯỚNG (Giống hệt góc trái HUD LoL)
	# =========================================================================
	var stats_panel := PanelContainer.new()
	var sub_sb := StyleBoxFlat.new()
	sub_sb.bg_color = Color(0.02, 0.05, 0.07, 0.95)
	sub_sb.border_color = Color(0.26, 0.34, 0.38, 0.85)
	sub_sb.set_border_width_all(1)
	sub_sb.set_corner_radius_all(4)
	sub_sb.set_content_margin_all(6.0)
	stats_panel.add_theme_stylebox_override("panel", sub_sb)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.set("theme_override_constants/h_separation", 14)
	stats_grid.set("theme_override_constants/v_separation", 3)

	var stat_defs := [
		["ad", "⚔ AD: 18", Color(1.0, 0.58, 0.22)],
		["as", "⚡ Tốc: 1.85", Color(1.0, 0.88, 0.28)],
		["ap", "✦ AP: 0", Color(0.68, 0.50, 1.0)],
		["crit", "💥 Crit: 15%", Color(1.0, 0.38, 0.38)],
		["armor", "🛡 Giáp: 5", Color(0.45, 0.92, 0.55)],
		["ls", "🩸 Hút: 0%", Color(0.95, 0.32, 0.45)],
		["haste", "⏳ Hồi: 0", Color(0.42, 0.85, 1.0)],
		["spd", "👟 Chạy: 240", Color(0.85, 0.92, 0.98)]
	]
	for s_def in stat_defs:
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(86, 0)
		lbl.text = s_def[1]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", s_def[2])
		stats_grid.add_child(lbl)
		_lol_stat_labels[s_def[0]] = lbl

	stats_panel.add_child(stats_grid)
	main_hbox.add_child(stats_panel)

	# Khung Chân dung Tướng (Avatar Portrait với viền tròn/bo góc vàng Hextech)
	var avatar_vbox := VBoxContainer.new()
	avatar_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	avatar_vbox.set("theme_override_constants/separation", 2)

	var avatar_panel := PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(68, 68)
	_lol_avatar_frame_sb = StyleBoxFlat.new()
	_lol_avatar_frame_sb.bg_color = Color(0.06, 0.11, 0.15, 1.0)
	_lol_avatar_frame_sb.border_color = Color(0.85, 0.68, 0.24, 1.0)
	_lol_avatar_frame_sb.set_border_width_all(3)
	_lol_avatar_frame_sb.set_corner_radius_all(34)
	_lol_avatar_frame_sb.set_content_margin_all(10.0)
	avatar_panel.add_theme_stylebox_override("panel", _lol_avatar_frame_sb)

	_lol_avatar_icon = TextureRect.new()
	_lol_avatar_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lol_avatar_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_panel.add_child(_lol_avatar_icon)
	avatar_vbox.add_child(avatar_panel)

	_lol_class_badge = Label.new()
	_lol_class_badge.text = "XẠ THỦ"
	_lol_class_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lol_class_badge.add_theme_font_size_override("font_size", 10)
	_lol_class_badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	avatar_vbox.add_child(_lol_class_badge)
	main_hbox.add_child(avatar_vbox)

	# =========================================================================
	# PHẦN 2 (GIỮA): HÀNG KỸ NĂNG (P - Q - E - SPACE) + THANH MÁU & NĂNG LƯỢNG
	# =========================================================================
	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.set("theme_override_constants/separation", 6)

	# Hàng 4 Ô Kỹ năng (Nội tại Vũ khí + [Q] Skill Phụ 1 + [E] Skill Phụ 2 + [SPACE] Chiêu Chính)
	var skills_hbox := HBoxContainer.new()
	skills_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_hbox.set("theme_override_constants/separation", 10)

	var slot_keys := ["P", "Q", "E", "SPACE"]
	var slot_titles := ["Vũ Khí", "Kỹ Năng Phụ 1", "Kỹ Năng Phụ 2", "Tuyệt Kỹ Chính"]
	for i in range(4):
		var is_ult: bool = (i == 3)
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(54 if is_ult else 46, 50)
		slot_panel.tooltip_text = slot_titles[i]

		var s_sb := StyleBoxFlat.new()
		s_sb.bg_color = Color(0.05, 0.12, 0.18, 0.98) if is_ult else Color(0.04, 0.08, 0.12, 0.95)
		s_sb.border_color = Color(0.92, 0.74, 0.25, 1.0) if is_ult else Color(0.42, 0.52, 0.58, 0.9)
		s_sb.set_border_width_all(2 if is_ult else 1)
		s_sb.set_corner_radius_all(4)
		s_sb.set_content_margin_all(4.0)
		slot_panel.add_theme_stylebox_override("panel", s_sb)

		var slot_vbox := VBoxContainer.new()
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_vbox.set("theme_override_constants/separation", 1)

		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(26, 26)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_vbox.add_child(ic)
		_lol_skill_icons.append(ic)

		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % slot_keys[i]
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 9)
		key_lbl.add_theme_color_override(
			"font_color",
			Color(1.0, 0.88, 0.25) if is_ult else Color(0.68, 0.78, 0.88)
		)
		slot_vbox.add_child(key_lbl)
		_lol_skill_cd_labels.append(key_lbl)

		slot_panel.add_child(slot_vbox)
		skills_hbox.add_child(slot_panel)

	center_vbox.add_child(skills_hbox)

	# Thanh Máu Xanh Lá (LoL Emerald HP Bar)
	_lol_hp_bar = ProgressBar.new()
	_lol_hp_bar.custom_minimum_size = Vector2(340, 20)
	_lol_hp_bar.show_percentage = false
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.05, 0.14, 0.08, 0.95)
	hp_bg.border_color = Color(0.22, 0.45, 0.28, 1.0)
	hp_bg.set_border_width_all(1)
	var hp_fg := StyleBoxFlat.new()
	hp_fg.bg_color = Color(0.12, 0.72, 0.28, 1.0)
	_lol_hp_bar.add_theme_stylebox_override("background", hp_bg)
	_lol_hp_bar.add_theme_stylebox_override("fill", hp_fg)

	_lol_hp_center_lbl = Label.new()
	_lol_hp_center_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lol_hp_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lol_hp_center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lol_hp_center_lbl.add_theme_font_size_override("font_size", 12)
	_lol_hp_center_lbl.text = "100 / 100"
	_lol_hp_bar.add_child(_lol_hp_center_lbl)

	_lol_hp_regen_lbl = Label.new()
	_lol_hp_regen_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lol_hp_regen_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lol_hp_regen_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lol_hp_regen_lbl.add_theme_font_size_override("font_size", 11)
	_lol_hp_regen_lbl.add_theme_color_override("font_color", Color(0.75, 1.0, 0.80))
	_lol_hp_regen_lbl.text = "+1.0/s  "
	_lol_hp_bar.add_child(_lol_hp_regen_lbl)
	center_vbox.add_child(_lol_hp_bar)

	# Thanh Năng Lượng / Hồi Chiêu Xanh Dương (LoL Cobalt Mana/Skill Bar)
	_lol_mana_bar = ProgressBar.new()
	_lol_mana_bar.custom_minimum_size = Vector2(340, 16)
	_lol_mana_bar.show_percentage = false
	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.05, 0.10, 0.20, 0.95)
	mp_bg.border_color = Color(0.22, 0.38, 0.62, 1.0)
	mp_bg.set_border_width_all(1)
	var mp_fg := StyleBoxFlat.new()
	mp_fg.bg_color = Color(0.14, 0.52, 0.92, 1.0)
	_lol_mana_bar.add_theme_stylebox_override("background", mp_bg)
	_lol_mana_bar.add_theme_stylebox_override("fill", mp_fg)

	_lol_mana_center_lbl = Label.new()
	_lol_mana_center_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lol_mana_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lol_mana_center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lol_mana_center_lbl.add_theme_font_size_override("font_size", 11)
	_lol_mana_center_lbl.text = "[SPACE] SẴN SÀNG"
	_lol_mana_bar.add_child(_lol_mana_center_lbl)
	center_vbox.add_child(_lol_mana_bar)

	main_hbox.add_child(center_vbox)

	# =========================================================================
	# PHẦN 3 (PHẢI): KHAY 6 Ô TRANG BỊ (LƯỚI 3x2) + THANH VÀNG (Giống hệt góc phải HUD LoL)
	# =========================================================================
	var inv_vbox := VBoxContainer.new()
	inv_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_vbox.set("theme_override_constants/separation", 4)

	var inv_grid := GridContainer.new()
	inv_grid.columns = 3
	inv_grid.set("theme_override_constants/h_separation", 4)
	inv_grid.set("theme_override_constants/v_separation", 4)

	for idx in range(6):
		var slot_p := PanelContainer.new()
		slot_p.custom_minimum_size = Vector2(36, 36)
		var slot_sb := StyleBoxFlat.new()
		slot_sb.bg_color = Color(0.03, 0.06, 0.09, 0.96)
		slot_sb.border_color = Color(0.45, 0.38, 0.20, 0.90)
		slot_sb.set_border_width_all(1)
		slot_sb.set_corner_radius_all(3)
		slot_sb.set_content_margin_all(3.0)
		slot_p.add_theme_stylebox_override("panel", slot_sb)

		var item_ic := TextureRect.new()
		item_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_p.add_child(item_ic)
		_lol_item_slots.append(item_ic)

		var num_lbl := Label.new()
		num_lbl.text = str(idx + 1)
		num_lbl.add_theme_font_size_override("font_size", 8)
		num_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.50, 0.8))
		slot_p.add_child(num_lbl)

		inv_grid.add_child(slot_p)

	inv_vbox.add_child(inv_grid)

	# Thanh Vàng bên dưới 6 ô đồ
	var gold_bar_panel := PanelContainer.new()
	var g_sb := StyleBoxFlat.new()
	g_sb.bg_color = Color(0.04, 0.06, 0.08, 0.98)
	g_sb.border_color = Color(0.68, 0.54, 0.18, 0.95)
	g_sb.set_border_width_all(1)
	g_sb.set_corner_radius_all(3)
	g_sb.content_margin_top = 1.0
	g_sb.content_margin_bottom = 1.0
	gold_bar_panel.add_theme_stylebox_override("panel", g_sb)

	_lol_gold_lbl = Label.new()
	_lol_gold_lbl.text = "🪙 0"
	_lol_gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lol_gold_lbl.add_theme_font_size_override("font_size", 12)
	_lol_gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22))
	gold_bar_panel.add_child(_lol_gold_lbl)
	inv_vbox.add_child(gold_bar_panel)

	main_hbox.add_child(inv_vbox)


func _load_tex(rect: TextureRect, path: String, tint: Color) -> void:
	if rect != null and not path.is_empty() and ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
		rect.self_modulate = tint


func bind_player(player: Player) -> void:
	_player = player
	if _player == null:
		return

	_player.hp_changed.connect(_on_player_hp_changed)
	_player.stats.stats_changed.connect(_on_player_stats_changed)
	if _player.skill != null:
		_player.skill.cooldown_updated.connect(_on_skill_cooldown_updated)
		_player.skill.cooldown_q_updated.connect(_on_skill_q_cooldown_updated)
		_player.skill.cooldown_e_updated.connect(_on_skill_e_cooldown_updated)
		_player.skill.skill_activated.connect(_on_skill_activated)

	var p_inv := _player.get_node_or_null("Inventory") as Inventory
	if p_inv != null and not p_inv.inventory_changed.is_connected(_refresh_lol_inventory_slots):
		p_inv.inventory_changed.connect(_refresh_lol_inventory_slots)

	if _player.character_data != null:
		var c_data: CharacterData = _player.character_data
		_load_tex(skill_icon, c_data.skill_icon_path, c_data.body_color)
		if _lol_avatar_icon != null:
			var custom_avatar_path: String = "res://assets/sprites/player/lol_%s.png" % c_data.id
			if ResourceLoader.exists(custom_avatar_path):
				_load_tex(_lol_avatar_icon, custom_avatar_path, Color.WHITE)
			else:
				_load_tex(_lol_avatar_icon, c_data.icon_path, c_data.body_color)
		if _lol_avatar_frame_sb != null:
			_lol_avatar_frame_sb.border_color = c_data.body_color
		if _lol_class_badge != null:
			_lol_class_badge.text = c_data.display_name.to_upper()
			_lol_class_badge.add_theme_color_override("font_color", c_data.body_color)

		# Gán biểu tượng & chú thích cho 4 ô kỹ năng trên thanh LoL HUD (P, Q, E, SPACE)
		if _lol_skill_icons.size() >= 4:
			_load_tex(_lol_skill_icons[0], c_data.icon_path, c_data.body_color)
			_load_tex(_lol_skill_icons[1], c_data.skill_q_icon_path, Color(0.55, 0.88, 1.0, 0.95))
			_load_tex(_lol_skill_icons[2], c_data.skill_e_icon_path, Color(1.0, 0.72, 0.35, 0.95))
			_load_tex(_lol_skill_icons[3], c_data.skill_icon_path, c_data.body_color)

	_on_player_hp_changed(_player.current_hp, _player.get_max_hp())
	_refresh_stats_text()
	_refresh_lol_inventory_slots()
	_on_skill_q_cooldown_updated(0.0, _player.skill.base_q_cooldown if _player.skill != null else 4.0)
	_on_skill_e_cooldown_updated(0.0, _player.skill.base_e_cooldown if _player.skill != null else 6.0)
	_on_skill_cooldown_updated(0.0, _player.skill.base_cooldown if _player.skill != null else 10.0)


func _refresh_lol_inventory_slots(_items: Array = []) -> void:
	if _player == null:
		return
	var p_inv := _player.get_node_or_null("Inventory") as Inventory
	if p_inv == null:
		return
	for i in range(_lol_item_slots.size()):
		var slot_tex: TextureRect = _lol_item_slots[i]
		if i < p_inv.items.size() and p_inv.items[i] != null:
			var it: ItemData = p_inv.items[i]
			_load_tex(slot_tex, it.icon_path, it.get_tier_color())
		else:
			slot_tex.texture = null


func show_active_bonus(bonus: BonusData) -> void:
	if bonus == null or bonus_hbox == null:
		return
	bonus_hbox.visible = true
	bonus_label.text = "Phúc lợi: %s" % bonus.bonus_name
	bonus_label.modulate = bonus.accent_color
	_load_tex(bonus_icon, bonus.icon_path, bonus.accent_color)


func show_toast_banner(msg: String, color: Color = Color(1.0, 0.88, 0.25, 1.0)) -> void:
	if banner_label == null:
		return
	banner_label.visible = true
	banner_label.text = msg
	banner_label.modulate = color
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): banner_label.visible = false)


func update_wave_header(title: String) -> void:
	if wave_title_label != null:
		wave_title_label.text = title


func update_wave_timer(time_left: float, _total_duration: float) -> void:
	if timer_label != null:
		var secs: int = maxi(0, int(ceil(time_left)))
		timer_label.text = "%02d:%02d" % [secs / 60, secs % 60]


func show_intermission(completed_wave: int, next_wave: int, is_augment_milestone: bool) -> void:
	_is_game_over_mode = false
	intermission_panel.visible = true
	intermission_title.text = "HOÀN THÀNH ĐỢT %d!" % completed_wave

	var milestone_note: String = (
		"Mốc bốc Lõi Nâng cấp + Cửa hàng Trang bị"
		if is_augment_milestone
		else "Mốc mở Cửa hàng Trang bị 6 Ô"
	)
	intermission_desc.text = (
		"Vàng hiện có: %d   |   Quái đã hạ: %d\n%s\n\nNhấn nút bên dưới để bước sang Đợt %d."
		% [CurrencyManager.gold, ScoreManager.kills, milestone_note, next_wave]
	)
	next_wave_btn.text = "BẮT ĐẦU ĐỢT %d" % next_wave


func show_run_result(is_victory: bool, final_score: int) -> void:
	_is_game_over_mode = true
	intermission_panel.visible = true
	intermission_title.text = "CHIẾN THẮNG CHIẾN DỊCH!" if is_victory else "THẤT BẠI (GAME OVER)"
	intermission_desc.text = (
		"Tổng Điểm: %d   |   Kỷ lục (High Score): %d\nQuái tiêu diệt: %d   |   Vàng thu thập: %d"
		% [final_score, ScoreManager.high_score, ScoreManager.kills, CurrencyManager.gold]
	)
	next_wave_btn.text = "CHƠI LẠI TỪ ĐẦU"


func hide_intermission() -> void:
	intermission_panel.visible = false


func _on_boss_spawned(_boss: Node) -> void:
	if top_center_panel != null:
		top_center_panel.visible = false
	if boss_panel != null:
		boss_panel.visible = true
	if boss_phase_label != null:
		boss_phase_label.text = "PHA 1: VÒNG ĐẠN & LAO HÚC TỐC ĐỘ CAO"
		boss_phase_label.modulate = Color(0.9, 0.55, 1.0, 1.0)
	show_toast_banner("CẢNH BÁO: CHIẾN HẠM TRÙM CUỐI ĐÃ XUẤT HIỆN!", Color(1.0, 0.25, 0.35, 1.0))


func _on_boss_hp_changed(curr: float, max_v: float, is_p2: bool) -> void:
	if boss_hp_bar != null:
		boss_hp_bar.max_value = maxf(1.0, max_v)
		boss_hp_bar.value = clampf(curr, 0.0, max_v)
	if boss_hp_label != null:
		boss_hp_label.text = "%d / %d" % [int(ceil(curr)), int(round(max_v))]
	if is_p2 and boss_phase_label != null:
		boss_phase_label.text = "PHA 2: CUỒNG NỘ - TỐC ĐỘ +35%, X2 VÒNG ĐẠN!"
		boss_phase_label.modulate = Color(1.0, 0.25, 0.25, 1.0)
		if boss_hp_bar != null:
			boss_hp_bar.modulate = Color(1.0, 0.2, 0.25, 1.0)


func _on_boss_defeated() -> void:
	if boss_panel != null:
		boss_panel.visible = false
	if top_center_panel != null:
		top_center_panel.visible = true
	show_toast_banner("CHIẾN THẮNG! TRÙM CUỐI ĐÃ BỊ HẠ GỤC!", Color(0.3, 1.0, 0.45, 1.0))


func _on_action_button_pressed() -> void:
	if _is_game_over_mode:
		restart_requested.emit()
	else:
		hide_intermission()
		next_wave_requested.emit()


func _on_menu_button_pressed() -> void:
	menu_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		menu_requested.emit()


func _on_player_hp_changed(current_hp: float, max_hp: float) -> void:
	if hp_bar != null:
		hp_bar.max_value = maxf(1.0, max_hp)
		hp_bar.value = clampf(current_hp, 0.0, max_hp)
	if hp_label != null:
		hp_label.text = "MÁU: %d / %d" % [int(ceil(current_hp)), int(round(max_hp))]

	if _lol_hp_bar != null:
		_lol_hp_bar.max_value = maxf(1.0, max_hp)
		_lol_hp_bar.value = clampf(current_hp, 0.0, max_hp)
	if _lol_hp_center_lbl != null:
		_lol_hp_center_lbl.text = "%d / %d" % [int(ceil(current_hp)), int(round(max_hp))]


func _on_player_stats_changed(_stat_type: int) -> void:
	_refresh_stats_text()


func _refresh_stats_text() -> void:
	if _player == null or _player.stats == null:
		return
	var s: PlayerStats = _player.stats
	var ad_val: float = s.get_stat(StatModifier.StatType.AD)
	var ap_val: float = s.get_stat(StatModifier.StatType.AP)
	var as_val: float = s.get_stat(StatModifier.StatType.ATTACK_SPEED)
	var crit_val: float = s.get_stat(StatModifier.StatType.CRIT_CHANCE) * 100.0
	var ls_val: float = s.get_stat(StatModifier.StatType.LIFESTEAL) * 100.0
	var armor_val: float = s.get_stat(StatModifier.StatType.ARMOR)
	var haste_val: float = s.get_stat(StatModifier.StatType.ABILITY_HASTE)
	var spd_val: float = s.get_stat(StatModifier.StatType.MOVE_SPEED)
	var regen_val: float = s.get_stat(StatModifier.StatType.HP_REGEN)

	var char_title: String = _player.character_data.display_name if _player.character_data != null else "Xạ Thủ"
	var wpn_title: String = (
		_player.character_data.starting_weapon.weapon_name
		if _player.character_data != null and _player.character_data.starting_weapon != null
		else "Súng Trường"
	)
	if stats_label != null:
		stats_label.text = "★ %s  |  %s" % [char_title.to_upper(), wpn_title]

	if _lol_stat_labels.has("ad"):
		_lol_stat_labels["ad"].text = "⚔ AD: %.0f" % ad_val
		_lol_stat_labels["as"].text = "⚡ Tốc: %.2f" % as_val
		_lol_stat_labels["ap"].text = "✦ AP: %.0f" % ap_val
		_lol_stat_labels["crit"].text = "💥 Crit: %.0f%%" % crit_val
		_lol_stat_labels["armor"].text = "🛡 Giáp: %.0f" % armor_val
		_lol_stat_labels["ls"].text = "🩸 Hút: %.0f%%" % ls_val
		_lol_stat_labels["haste"].text = "⏳ Hồi: %.0f" % haste_val
		_lol_stat_labels["spd"].text = "👟 Chạy: %.0f" % spd_val

	if _lol_hp_regen_lbl != null:
		_lol_hp_regen_lbl.text = "+%.1f/s  " % regen_val


func _on_gold_changed(total_gold: int) -> void:
	if gold_label != null:
		gold_label.text = "VÀNG: %d" % total_gold
	if _lol_gold_lbl != null:
		_lol_gold_lbl.text = "🪙 %d" % total_gold


func _on_enemy_killed(_enemy: Node) -> void:
	_update_kills_display()


func _update_kills_display() -> void:
	if kills_label != null:
		kills_label.text = "TIÊU DIỆT: %d" % ScoreManager.kills


func _on_skill_q_cooldown_updated(remaining: float, _total: float) -> void:
	if _lol_skill_cd_labels.size() >= 2:
		if remaining <= 0.01:
			_lol_skill_cd_labels[1].text = "[Q]"
			_lol_skill_cd_labels[1].add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
		else:
			_lol_skill_cd_labels[1].text = "%.1fs" % remaining
			_lol_skill_cd_labels[1].add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))


func _on_skill_e_cooldown_updated(remaining: float, _total: float) -> void:
	if _lol_skill_cd_labels.size() >= 3:
		if remaining <= 0.01:
			_lol_skill_cd_labels[2].text = "[E]"
			_lol_skill_cd_labels[2].add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
		else:
			_lol_skill_cd_labels[2].text = "%.1fs" % remaining
			_lol_skill_cd_labels[2].add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))


func _on_skill_cooldown_updated(remaining: float, total: float) -> void:
	var sk_name: String = _player.skill.skill_name if _player != null and _player.skill != null else "Kỹ Năng"
	var q_name: String = _player.skill.skill_q_name if _player != null and _player.skill != null else "Chiêu Q"
	var e_name: String = _player.skill.skill_e_name if _player != null and _player.skill != null else "Chiêu E"
	if skill_bar != null and skill_label != null:
		skill_bar.max_value = maxf(0.1, total)
		if remaining <= 0.01:
			skill_bar.value = skill_bar.max_value
			skill_label.text = "[SPACE] %s - SẴN SÀNG" % sk_name
		else:
			skill_bar.value = maxf(0.0, total - remaining)
			skill_label.text = "[SPACE] Hồi chiêu: %.1fs" % remaining

	if _lol_mana_bar != null and _lol_mana_center_lbl != null:
		_lol_mana_bar.max_value = maxf(0.1, total)
		if remaining <= 0.01:
			_lol_mana_bar.value = _lol_mana_bar.max_value
			_lol_mana_center_lbl.text = "[Q] %s  |  [E] %s  |  [SPACE] %s" % [q_name, e_name, sk_name]
			if _lol_skill_cd_labels.size() >= 4:
				_lol_skill_cd_labels[3].text = "[SPACE]"
		else:
			_lol_mana_bar.value = maxf(0.0, total - remaining)
			_lol_mana_center_lbl.text = "[SPACE] %s: %.1fs" % [sk_name, remaining]
			if _lol_skill_cd_labels.size() >= 4:
				_lol_skill_cd_labels[3].text = "%.1fs" % remaining


func _on_skill_activated(activated_id: String, _duration: float) -> void:
	if _lol_skill_icons.size() < 4:
		return
	var slot_idx: int = 3
	if _player != null and _player.skill != null:
		if activated_id == _player.skill.skill_q_id:
			slot_idx = 1
		elif activated_id == _player.skill.skill_e_id:
			slot_idx = 2
	var ic: TextureRect = _lol_skill_icons[slot_idx]
	if ic != null:
		var tw := create_tween()
		tw.tween_property(ic, "scale", Vector2(1.25, 1.25), 0.1)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.18)
