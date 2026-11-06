class_name MainMenu
extends Control
## Giao diện Menu Chính (MainMenu - Giai đoạn 4)
## Cổng vào chiến dịch, hiển thị Kỷ lục điểm cao, cửa sổ hướng dẫn và nút xuất kích.

const CHAR_SELECT_PATH: String = "res://scenes/menu/CharacterSelect.tscn"

@onready var high_score_label: Label = $Center/MainVBox/HighScoreLabel
@onready var start_btn: Button = $Center/MainVBox/ButtonsVBox/StartButton
@onready var guide_btn: Button = $Center/MainVBox/ButtonsVBox/GuideButton
@onready var quit_btn: Button = $Center/MainVBox/ButtonsVBox/QuitButton
@onready var guide_dialog: PanelContainer = $GuideDialog
@onready var close_guide_btn: Button = $GuideDialog/Margin/VBox/CloseGuideButton


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	guide_dialog.visible = false

	high_score_label.text = "★ KỶ LỤC CHIẾN DỊCH: %d ĐIỂM ★" % ScoreManager.high_score

	start_btn.pressed.connect(_on_start_pressed)
	guide_btn.pressed.connect(_on_guide_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	close_guide_btn.pressed.connect(_on_close_guide_pressed)

	start_btn.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(CHAR_SELECT_PATH)


func _on_guide_pressed() -> void:
	guide_dialog.visible = true


func _on_close_guide_pressed() -> void:
	guide_dialog.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()

