extends Control
## Màn hình Chọn Lớp Nhân vật (CharacterSelect - Giai đoạn 5 Hoàn thiện)
## Hỗ trợ Tick Box (CheckBox) chọn 1 trong 4 Lớp nhân vật (Xạ Thủ, Đấu Sĩ, Đỡ Đòn, Pháp Sư)
## kèm nút Quay lại Menu và Thoát Game.

const GAME_SCENE_PATH: String = "res://scenes/game/Game.tscn"
const MAIN_MENU_PATH: String = "res://scenes/menu/MainMenu.tscn"

const CHAR_PATHS: Array[String] = [
	"res://resources/characters/ad_marksman.tres",
	"res://resources/characters/bruiser.tres",
	"res://resources/characters/tank.tres",
	"res://resources/characters/mage_ap.tres"
]

var _characters: Array[CharacterData] = []
var _selected_index: int = 0

@onready var high_score_label: Label = $Margin/MainVBox/HeaderVBox/HighScoreLabel
@onready var start_btn: Button = $Margin/MainVBox/FooterHBox/StartButton
@onready var quit_btn: Button = $Margin/MainVBox/FooterHBox/QuitButton
@onready var exit_app_btn: Button = $Margin/MainVBox/FooterHBox/ExitAppButton

@onready var card_ad: PanelContainer = $Margin/MainVBox/CardsHBox/CardAD
@onready var card_bruiser: PanelContainer = $Margin/MainVBox/CardsHBox/CardBruiser
@onready var card_tank: PanelContainer = $Margin/MainVBox/CardsHBox/CardTank
@onready var card_ap: PanelContainer = $Margin/MainVBox/CardsHBox/CardAP

@onready var badge_ad: Label = $Margin/MainVBox/CardsHBox/CardAD/Margin/VBox/StatusBadge
@onready var badge_bruiser: Label = $Margin/MainVBox/CardsHBox/CardBruiser/Margin/VBox/StatusBadge
@onready var badge_tank: Label = $Margin/MainVBox/CardsHBox/CardTank/Margin/VBox/StatusBadge
@onready var badge_ap: Label = $Margin/MainVBox/CardsHBox/CardAP/Margin/VBox/StatusBadge

@onready var btn_ad: CheckBox = $Margin/MainVBox/CardsHBox/CardAD/Margin/VBox/SelectButton
@onready var btn_bruiser: CheckBox = $Margin/MainVBox/CardsHBox/CardBruiser/Margin/VBox/SelectButton
@onready var btn_tank: CheckBox = $Margin/MainVBox/CardsHBox/CardTank/Margin/VBox/SelectButton
@onready var btn_ap: CheckBox = $Margin/MainVBox/CardsHBox/CardAP/Margin/VBox/SelectButton

@onready var icon_ad: TextureRect = $Margin/MainVBox/CardsHBox/CardAD/Margin/VBox/IconRect
@onready var icon_bruiser: TextureRect = $Margin/MainVBox/CardsHBox/CardBruiser/Margin/VBox/IconRect
@onready var icon_tank: TextureRect = $Margin/MainVBox/CardsHBox/CardTank/Margin/VBox/IconRect
@onready var icon_ap: TextureRect = $Margin/MainVBox/CardsHBox/CardAP/Margin/VBox/IconRect


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	high_score_label.text = "★ KỶ LỤC ĐIỂM CAO NHẤT: %d ĐIỂM ★" % ScoreManager.high_score

	for path in CHAR_PATHS:
		var c := load(path) as CharacterData
		_characters.append(c)

	_set_champion_icon(icon_ad, "res://assets/sprites/player/lol_ad_marksman.png", "res://assets/sprites/classes/class_ad.png", Color(1.0, 0.65, 0.18, 1.0))
	_set_champion_icon(icon_bruiser, "res://assets/sprites/player/lol_bruiser.png", "res://assets/sprites/classes/class_bruiser.png", Color(0.95, 0.35, 0.35, 1.0))
	_set_champion_icon(icon_tank, "res://assets/sprites/player/lol_tank.png", "res://assets/sprites/classes/class_tank.png", Color(0.35, 0.92, 0.52, 1.0))
	_set_champion_icon(icon_ap, "res://assets/sprites/player/lol_mage_ap.png", "res://assets/sprites/classes/class_ap.png", Color(0.74, 0.52, 1.0, 1.0))

	btn_ad.pressed.connect(func(): _select_character(0, true))
	btn_bruiser.pressed.connect(func(): _select_character(1, true))
	btn_tank.pressed.connect(func(): _select_character(2, true))
	btn_ap.pressed.connect(func(): _select_character(3, true))

	# Cho phép bấm vào bất kỳ vị trí nào trên toàn bộ thẻ tướng để Tick chọn nhanh
	var cards_arr: Array[PanelContainer] = [card_ad, card_bruiser, card_tank, card_ap]
	for i in range(cards_arr.size()):
		var card_idx: int = i
		_enable_pass_mouse_filter_recursive(cards_arr[i], [btn_ad, btn_bruiser, btn_tank, btn_ap])
		cards_arr[i].gui_input.connect(func(ev): _on_card_gui_input(ev, card_idx))

	start_btn.pressed.connect(_on_start_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	if exit_app_btn != null:
		exit_app_btn.pressed.connect(func(): get_tree().quit())

	# Giữ lại nhân vật đã chọn ở ván trước nếu có
	var init_idx: int = 0
	if GameManager.selected_character is CharacterData:
		for i in range(_characters.size()):
			if _characters[i] != null and _characters[i].id == GameManager.selected_character.id:
				init_idx = i
				break

	_select_character(init_idx, false)
	start_btn.grab_focus()


func _enable_pass_mouse_filter_recursive(node: Node, skip_nodes: Array) -> void:
	for child in node.get_children():
		if child in skip_nodes:
			continue
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_enable_pass_mouse_filter_recursive(child, skip_nodes)


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_character(index, true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_on_start_pressed()
		elif event.keycode == KEY_1:
			_select_character(0, true)
		elif event.keycode == KEY_2:
			_select_character(1, true)
		elif event.keycode == KEY_3:
			_select_character(2, true)
		elif event.keycode == KEY_4:
			_select_character(3, true)
		elif event.keycode == KEY_ESCAPE:
			_on_quit_pressed()


func _set_champion_icon(rect: TextureRect, custom_path: String, fallback_path: String, fallback_tint: Color) -> void:
	if rect == null:
		return
	if ResourceLoader.exists(custom_path):
		_set_icon(rect, custom_path, Color.WHITE)
	else:
		_set_icon(rect, fallback_path, fallback_tint)


func _set_icon(rect: TextureRect, path: String, tint: Color) -> void:
	if rect != null and ResourceLoader.exists(path):
		rect.texture = load(path) as Texture2D
		rect.self_modulate = tint


func _select_character(index: int, play_sound: bool = false) -> void:
	_selected_index = clampi(index, 0, _characters.size() - 1)
	var chosen: CharacterData = _characters[_selected_index]
	GameManager.selected_character = chosen
	if play_sound and AudioManager != null and AudioManager.has_method("play_buy"):
		AudioManager.play_buy()

	var cards_arr: Array[PanelContainer] = [card_ad, card_bruiser, card_tank, card_ap]
	var badges_arr: Array[Label] = [badge_ad, badge_bruiser, badge_tank, badge_ap]
	var btns_arr: Array[CheckBox] = [btn_ad, btn_bruiser, btn_tank, btn_ap]

	for i in range(4):
		var is_selected: bool = (i == _selected_index)
		var c_data: CharacterData = _characters[i]
		var accent: Color = c_data.body_color if c_data != null else Color(1, 0.7, 0.2, 1)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.18, 0.26, 0.98) if is_selected else Color(0.08, 0.09, 0.13, 0.90)
		style.border_color = accent if is_selected else Color(0.24, 0.27, 0.34, 0.75)
		var bw: int = 3 if is_selected else 1
		style.set_border_width_all(bw)
		style.set_corner_radius_all(10)
		cards_arr[i].add_theme_stylebox_override("panel", style)

		badges_arr[i].text = "[ ✓ ĐANG ĐƯỢC CHỌN ]" if is_selected else "[ NHẤN ĐỂ TÍCH CHỌN ]"
		badges_arr[i].add_theme_color_override(
			"font_color",
			Color(0.32, 0.98, 0.55, 1.0) if is_selected else Color(0.62, 0.68, 0.78, 1.0)
		)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.12, 0.32, 0.20, 0.95) if is_selected else Color(0.14, 0.16, 0.22, 0.95)
		btn_style.border_color = Color(0.35, 0.95, 0.55, 1.0) if is_selected else Color(0.38, 0.44, 0.54, 0.85)
		btn_style.set_border_width_all(2 if is_selected else 1)
		btn_style.set_corner_radius_all(6)
		btn_style.content_margin_left = 10
		btn_style.content_margin_right = 10
		btns_arr[i].add_theme_stylebox_override("normal", btn_style)
		btns_arr[i].add_theme_stylebox_override("pressed", btn_style)
		btns_arr[i].add_theme_stylebox_override("hover", btn_style)
		btns_arr[i].add_theme_stylebox_override("hover_pressed", btn_style)

		btns_arr[i].set_pressed_no_signal(is_selected)
		btns_arr[i].text = (
			" ĐÃ CHỌN: %s" % c_data.display_name.to_upper()
			if is_selected
			else " Chọn %s" % c_data.display_name
		)
		btns_arr[i].add_theme_color_override(
			"font_color",
			Color(0.42, 1.0, 0.62, 1.0) if is_selected else Color(0.88, 0.92, 0.98, 1.0)
		)
		btns_arr[i].add_theme_color_override(
			"font_pressed_color",
			Color(0.42, 1.0, 0.62, 1.0) if is_selected else Color(0.88, 0.92, 0.98, 1.0)
		)
		btns_arr[i].add_theme_color_override(
			"font_hover_color",
			Color(1.0, 0.92, 0.35, 1.0)
		)

	start_btn.text = "XUẤT KÍCH VỚI %s (ENTER)" % chosen.display_name.to_upper()


func _on_start_pressed() -> void:
	GameManager.start_new_run(_characters[_selected_index])
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_quit_pressed() -> void:
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
	else:
		get_tree().quit()
