class_name BonusRevealUI
extends CanvasLayer
## Giao diện Lật Thẻ Phúc lợi Khởi đầu Ngẫu nhiên (BonusRevealUI - Giai đoạn 2)
## Hoạt động ở chế độ PROCESS_MODE_ALWAYS khi đấu trường tạm dừng (paused = true).

signal bonus_confirmed(bonus: BonusData)

@onready var root_control: Control = $Root
@onready var card_panel: PanelContainer = $Root/CenterContainer/CardPanel
@onready var header_label: Label = $Root/CenterContainer/CardPanel/Margin/VBox/HeaderLabel
@onready var icon_rect: TextureRect = $Root/CenterContainer/CardPanel/Margin/VBox/IconContainer/IconRect
@onready var bonus_name_label: Label = $Root/CenterContainer/CardPanel/Margin/VBox/BonusNameLabel
@onready var desc_label: Label = $Root/CenterContainer/CardPanel/Margin/VBox/DescLabel
@onready var hint_label: Label = $Root/CenterContainer/CardPanel/Margin/VBox/HintLabel
@onready var confirm_btn: Button = $Root/CenterContainer/CardPanel/Margin/VBox/ConfirmButton

var _current_bonus: BonusData = null
var _can_confirm: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.visible = false
	confirm_btn.pressed.connect(_on_confirm_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not root_control.visible or not _can_confirm:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_on_confirm_pressed()


func show_bonus_reveal(bonus: BonusData) -> void:
	if bonus == null:
		bonus_confirmed.emit(null)
		return

	_current_bonus = bonus
	_can_confirm = false
	root_control.visible = true
	get_tree().paused = true

	# Trạng thái mặt úp trước khi lật thẻ
	card_panel.pivot_offset = card_panel.size * 0.5
	if card_panel.pivot_offset.length_squared() < 10.0:
		card_panel.pivot_offset = Vector2(230.0, 190.0)
	card_panel.scale = Vector2.ONE

	header_label.text = "PHÚC LỢI ĐẦU TRẬN (HỆ THỐNG PHÁT NGẪU NHIÊN)"
	bonus_name_label.text = "ĐANG LẬT THẺ ĐỊNH MỆNH..."
	bonus_name_label.modulate = Color(0.9, 0.9, 0.9, 1.0)
	desc_label.text = "Mỗi chiến dịch khởi đầu với 1 Phúc lợi ngẫu nhiên.\nHãy thích nghi chiến thuật theo Phúc lợi bạn nhận được!"
	hint_label.text = ""
	confirm_btn.disabled = true
	confirm_btn.text = "ĐANG MỞ THẺ..."
	icon_rect.texture = null

	# Hiệu ứng lật thẻ 2 pha bằng Tween
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.28)
	tw.tween_property(card_panel, "scale:x", 0.04, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_populate_revealed_card)
	tw.tween_property(card_panel, "scale:x", 1.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_enable_confirm)


func _populate_revealed_card() -> void:
	if _current_bonus == null:
		return
	bonus_name_label.text = _current_bonus.bonus_name.to_upper()
	bonus_name_label.modulate = _current_bonus.accent_color
	desc_label.text = _current_bonus.description
	hint_label.text = _current_bonus.playstyle_hint
	hint_label.modulate = _current_bonus.accent_color.lightened(0.25)

	if not _current_bonus.icon_path.is_empty() and ResourceLoader.exists(_current_bonus.icon_path):
		icon_rect.texture = load(_current_bonus.icon_path) as Texture2D
		icon_rect.self_modulate = _current_bonus.accent_color


func _enable_confirm() -> void:
	_can_confirm = true
	confirm_btn.disabled = false
	confirm_btn.text = "NHẬN PHÚC LỢI & XUẤT KÍCH (ENTER / CLICK)"
	confirm_btn.grab_focus()


func _on_confirm_pressed() -> void:
	if not _can_confirm:
		return
	_can_confirm = false
	root_control.visible = false
	get_tree().paused = false
	bonus_confirmed.emit(_current_bonus)

