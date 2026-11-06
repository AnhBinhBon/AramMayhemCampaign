class_name ShopUI
extends CanvasLayer
## Giao diện Cửa hàng Giữa Đợt 6 Ô (ShopUI - Giai đoạn 3)
## Bày bán 4 vật phẩm ngẫu nhiên theo bậc, hỗ trợ Reroll tăng giá (giảm 50% ở Shop cuối Wave 6),
## hiển thị Túi đồ 6 ô, mua/bán hoàn tiền 50% và chuyển tiếp sang Đợt kế tiếp.

signal shop_closed()

@onready var root_control: Control = $Root
@onready var title_label: Label = $Root/Panel/VBox/HeaderHBox/TitleLabel
@onready var gold_label: Label = $Root/Panel/VBox/HeaderHBox/GoldHBox/GoldLabel
@onready var gold_icon: TextureRect = $Root/Panel/VBox/HeaderHBox/GoldHBox/GoldIcon
@onready var reroll_btn: Button = $Root/Panel/VBox/HeaderHBox/RerollButton
@onready var offers_container: HBoxContainer = $Root/Panel/VBox/OffersContainer
@onready var inventory_container: HBoxContainer = $Root/Panel/VBox/InventoryContainer
@onready var stats_summary_label: Label = $Root/Panel/VBox/StatsSummaryLabel
@onready var error_label: Label = $Root/Panel/VBox/ErrorLabel
@onready var continue_btn: Button = $Root/Panel/VBox/FooterHBox/ContinueButton
@onready var menu_btn: Button = $Root/Panel/VBox/FooterHBox/MenuButton
@onready var quit_btn: Button = $Root/Panel/VBox/FooterHBox/QuitButton

var _shop_manager: ShopManager = null
var _inventory: Inventory = null
var _player: Player = null
var _wave_index: int = 1
var _next_wave: int = 2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.visible = false
	error_label.text = ""

	if ResourceLoader.exists("res://assets/sprites/ui/ui_gold.png"):
		gold_icon.texture = load("res://assets/sprites/ui/ui_gold.png") as Texture2D
		gold_icon.self_modulate = Color(1.0, 0.88, 0.18, 1.0)

	reroll_btn.pressed.connect(_on_reroll_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	if menu_btn != null:
		menu_btn.pressed.connect(func():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")
		)
	if quit_btn != null:
		quit_btn.pressed.connect(func(): get_tree().quit())
	CombatEvents.gold_changed.connect(_on_gold_changed)


func setup(shop_mgr: ShopManager, player: Player) -> void:
	_shop_manager = shop_mgr
	_player = player
	if _player != null:
		_inventory = _player.get_node_or_null("Inventory") as Inventory

	if _shop_manager != null:
		if not _shop_manager.shop_refreshed.is_connected(_on_shop_refreshed):
			_shop_manager.shop_refreshed.connect(_on_shop_refreshed)
		if not _shop_manager.shop_error.is_connected(_on_shop_error):
			_shop_manager.shop_error.connect(_on_shop_error)

	if _inventory != null:
		if not _inventory.inventory_changed.is_connected(_on_inventory_changed):
			_inventory.inventory_changed.connect(_on_inventory_changed)


func open_shop(next_wave_index: int) -> void:
	_next_wave = next_wave_index
	_wave_index = maxf(1, next_wave_index - 1)
	error_label.text = ""
	root_control.visible = true
	get_tree().paused = true

	var is_final: bool = (_wave_index == 6)
	if is_final:
		title_label.text = "CỬA HÀNG CUỐI CÙNG (ƯU ĐÃI GIẢM 50% GIÁ REROLL)"
		title_label.modulate = Color(1.0, 0.45, 0.45, 1.0)
		continue_btn.text = "TIẾN VÀO TRẬN ĐẤU TRÙM (WAVE 7)"
		continue_btn.modulate = Color(1.0, 0.35, 0.35, 1.0)
	else:
		title_label.text = "CỬA HÀNG CHIẾN DỊCH (Sau Đợt %d)" % _wave_index
		title_label.modulate = Color(0.9, 0.95, 1.0, 1.0)
		continue_btn.text = "BẮT ĐẦU ĐỢT %d" % _next_wave
		continue_btn.modulate = Color(0.3, 0.85, 0.5, 1.0)

	_update_gold_display(CurrencyManager.gold)

	if _shop_manager != null:
		_shop_manager.open_shop_for_wave(_wave_index)

	_refresh_inventory_slots()
	_refresh_stats_summary()


func close_shop() -> void:
	root_control.visible = false
	get_tree().paused = false
	shop_closed.emit()


func _on_continue_pressed() -> void:
	close_shop()


func _on_reroll_pressed() -> void:
	if _shop_manager != null:
		_shop_manager.reroll(_wave_index)


func _on_gold_changed(new_gold: int) -> void:
	_update_gold_display(new_gold)
	if root_control.visible and _shop_manager != null:
		_build_offer_cards(_shop_manager.current_offers)


func _update_gold_display(gold: int) -> void:
	if gold_label != null:
		gold_label.text = "%d" % gold


func _on_shop_refreshed(offers: Array[ItemData], reroll_cost: int) -> void:
	if reroll_btn != null:
		if _shop_manager != null and _shop_manager.is_final_shop:
			reroll_btn.text = "ĐỔI HÀNG (-50%%: %d Vàng)" % reroll_cost
		else:
			reroll_btn.text = "ĐỔI HÀNG (Giá: %d Vàng)" % reroll_cost
	_build_offer_cards(offers)
	_refresh_stats_summary()


func _build_offer_cards(offers: Array[ItemData]) -> void:
	for child in offers_container.get_children():
		child.queue_free()

	for i in range(offers.size()):
		var item: ItemData = offers[i]
		var card := _create_offer_card(item, i)
		offers_container.add_child(card)


func _create_offer_card(item: ItemData, offer_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 260)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12.0)

	if item == null:
		# Món hàng đã bán
		sb.bg_color = Color(0.06, 0.07, 0.09, 0.65)
		sb.border_color = Color(0.2, 0.22, 0.26, 1.0)
		sb.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", sb)

		var empty_lbl := Label.new()
		empty_lbl.text = "[ ĐÃ MUA ]"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_lbl.modulate = Color(0.4, 0.45, 0.5, 1.0)
		panel.add_child(empty_lbl)
		return panel

	# Thẻ vật phẩm đang bày bán
	var tier_color: Color = Color.WHITE
	var tier_text: String = "THƯỜNG"
	match item.tier:
		ItemData.ItemTier.COMMON:
			tier_color = Color(0.85, 0.88, 0.95, 1.0)
			tier_text = "★ BẬC THƯỜNG"
		ItemData.ItemTier.RARE:
			tier_color = Color(0.25, 0.65, 1.0, 1.0)
			tier_text = "★★ BẬC HIẾM"
		ItemData.ItemTier.LEGENDARY:
			tier_color = Color(1.0, 0.65, 0.15, 1.0)
			tier_text = "★★★ TRUYỀN THUYẾT"

	sb.bg_color = Color(0.09, 0.11, 0.15, 0.96)
	sb.border_color = tier_color
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 6)
	panel.add_child(vbox)

	# Nhãn bậc
	var tier_lbl := Label.new()
	tier_lbl.text = tier_text
	tier_lbl.modulate = tier_color
	tier_lbl.add_theme_font_size_override("font_size", 11)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tier_lbl)

	# Biểu tượng
	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 52)
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path):
		icon_rect.texture = load(item.icon_path) as Texture2D
		icon_rect.self_modulate = tier_color
	icon_center.add_child(icon_rect)
	vbox.add_child(icon_center)

	# Tên vật phẩm
	var name_lbl := Label.new()
	name_lbl.text = item.item_name
	name_lbl.modulate = Color.WHITE
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Mô tả chỉ số
	var desc_lbl := Label.new()
	desc_lbl.text = item.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.modulate = Color(0.8, 0.85, 0.9, 1.0)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)

	# Nút Mua
	var final_price: int = _shop_manager.get_discounted_price(item) if _shop_manager != null else item.price
	var can_afford: bool = CurrencyManager.gold >= final_price
	var is_full: bool = _inventory != null and _inventory.is_full()

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(0, 36)
	buy_btn.add_theme_font_size_override("font_size", 12)
	if is_full:
		buy_btn.text = "TÚI ĐỒ ĐẦY"
		buy_btn.disabled = true
	elif not can_afford:
		buy_btn.text = "MUA: %d VÀNG" % final_price
		buy_btn.disabled = true
	else:
		buy_btn.text = "MUA: %d VÀNG" % final_price
		buy_btn.modulate = Color(0.3, 0.9, 0.5, 1.0)
		buy_btn.pressed.connect(func(): _on_buy_clicked(offer_index))

	vbox.add_child(buy_btn)
	return panel


func _on_buy_clicked(offer_index: int) -> void:
	if _shop_manager != null and _inventory != null:
		if _shop_manager.buy_item(offer_index, _inventory):
			_refresh_inventory_slots()
			_refresh_stats_summary()


func _on_inventory_changed(_items: Array[ItemData]) -> void:
	_refresh_inventory_slots()
	_refresh_stats_summary()
	if _shop_manager != null:
		_build_offer_cards(_shop_manager.current_offers)


func _refresh_inventory_slots() -> void:
	for child in inventory_container.get_children():
		child.queue_free()

	var current_items: Array[ItemData] = _inventory.items if _inventory != null else []
	for i in range(Inventory.MAX_SLOTS):
		var has_item: bool = (i < current_items.size())
		var item: ItemData = current_items[i] if has_item else null
		var slot_card := _create_inventory_slot_card(item, i)
		inventory_container.add_child(slot_card)


func _create_inventory_slot_card(item: ItemData, slot_index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 95)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8.0)

	if item == null:
		sb.bg_color = Color(0.06, 0.08, 0.1, 0.6)
		sb.border_color = Color(0.18, 0.22, 0.28, 0.8)
		sb.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", sb)

		var lbl := Label.new()
		lbl.text = "Ô %d: [ TRỐNG ]" % (slot_index + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl.modulate = Color(0.35, 0.4, 0.48, 0.8)
		lbl.add_theme_font_size_override("font_size", 11)
		panel.add_child(lbl)
		return panel

	# Ô có đồ
	var tier_col: Color = Color.WHITE
	match item.tier:
		ItemData.ItemTier.COMMON:
			tier_col = Color(0.85, 0.88, 0.95, 1.0)
		ItemData.ItemTier.RARE:
			tier_col = Color(0.25, 0.65, 1.0, 1.0)
		ItemData.ItemTier.LEGENDARY:
			tier_col = Color(1.0, 0.65, 0.15, 1.0)

	sb.bg_color = Color(0.1, 0.13, 0.18, 0.95)
	sb.border_color = tier_col
	sb.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 8)
	panel.add_child(hbox)

	# Icon
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(36, 36)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path):
		icon_rect.texture = load(item.icon_path) as Texture2D
		icon_rect.self_modulate = tier_col
	hbox.add_child(icon_rect)

	# Info + Nút Bán
	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.item_name
	name_lbl.modulate = tier_col
	name_lbl.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(name_lbl)

	var refund: int = maxi(1, int(round(float(item.price) * 0.5)))
	var sell_btn := Button.new()
	sell_btn.text = "BÁN (+%d V)" % refund
	sell_btn.add_theme_font_size_override("font_size", 10)
	sell_btn.modulate = Color(1.0, 0.55, 0.45, 1.0)
	sell_btn.pressed.connect(func(): _on_sell_clicked(slot_index))
	info_vbox.add_child(sell_btn)

	return panel


func _on_sell_clicked(slot_index: int) -> void:
	if _shop_manager != null and _inventory != null:
		_shop_manager.sell_item(slot_index, _inventory)


func _refresh_stats_summary() -> void:
	if _player == null or _player.stats == null or stats_summary_label == null:
		return
	var s: PlayerStats = _player.stats
	var ad_val: float = s.get_stat(StatModifier.StatType.AD)
	var as_val: float = s.get_stat(StatModifier.StatType.ATTACK_SPEED)
	var crit_val: float = s.get_stat(StatModifier.StatType.CRIT_CHANCE) * 100.0
	var ls_val: float = s.get_stat(StatModifier.StatType.LIFESTEAL) * 100.0
	var armor_val: float = s.get_stat(StatModifier.StatType.ARMOR)
	var spd_val: float = s.get_stat(StatModifier.StatType.MOVE_SPEED)

	stats_summary_label.text = (
		"CHỈ SỐ TỔNG:  Sát thương: %d   |   Tốc đánh: %.2f/s   |   Chí mạng: %d%%   |   Hút máu: %d%%   |   Giáp: %d   |   Tốc chạy: %d"
		% [int(round(ad_val)), as_val, int(round(crit_val)), int(round(ls_val)), int(round(armor_val)), int(round(spd_val))]
	)


func _on_shop_error(msg: String) -> void:
	error_label.text = msg
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(3.0)
	tw.tween_callback(func(): error_label.text = "")

