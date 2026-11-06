extends Node2D
## Đấu trường Cầu Vực Thẳm & Quảng Trường Cổ Ngữ (LoL Spirit Blossom & Bridge of Progress Arena)
## Kết hợp kiến trúc Cầu Linh Hoa (Nửa Trái Tím Huyền Ảo - Nửa Phải Lục Bảo Anh Đào, Thác Nước Vực Thẳm,
## Hốc Bụi Cỏ ARAM) và Quảng Trường Hextech/Chemtech Trung Tâm (Lõi Năng Lượng, Nắp Cống Đồng, Trụ Dẫn Điện, Đèn Đường).

const HALF_W: float = 780.0
const HALF_H: float = 480.0
const GRID_STEP: float = 80.0

var _time: float = 0.0
var _redraw_accum: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	_redraw_accum += delta
	if _redraw_accum >= 0.05:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.4)
	var slow_wave: float = sin(_time * 1.3)

	# =========================================================================
	# 1. VỰC THẲM SƯƠNG MÙ, VÁCH ĐÁ DƯỚI CẦU & THÁC NƯỚC LINH HOA (OUTER CHASM)
	# =========================================================================
	draw_rect(Rect2(-1600.0, -1100.0, 3200.0, 2200.0), Color(0.05, 0.06, 0.12, 1.0), true)

	# Các quầng sương mù tím/lam dưới đáy vực
	draw_circle(Vector2(-520.0, -680.0), 340.0, Color(0.14, 0.11, 0.28, 0.45))
	draw_circle(Vector2(480.0, -650.0), 310.0, Color(0.09, 0.18, 0.25, 0.40))
	draw_circle(Vector2(-460.0, 690.0), 360.0, Color(0.16, 0.10, 0.30, 0.45))
	draw_circle(Vector2(520.0, 680.0), 340.0, Color(0.10, 0.20, 0.26, 0.45))

	# Chân vách đá ngầm đỡ thân cầu
	var cliff_pts_left := PackedVector2Array([
		Vector2(-HALF_W - 30.0, -HALF_H + 20.0),
		Vector2(0.0, -HALF_H + 20.0),
		Vector2(-40.0, HALF_H + 170.0),
		Vector2(-HALF_W - 90.0, HALF_H + 130.0)
	])
	draw_colored_polygon(cliff_pts_left, Color(0.11, 0.09, 0.19, 0.95))

	var cliff_pts_right := PackedVector2Array([
		Vector2(0.0, -HALF_H + 20.0),
		Vector2(HALF_W + 30.0, -HALF_H + 20.0),
		Vector2(HALF_W + 95.0, HALF_H + 140.0),
		Vector2(-40.0, HALF_H + 170.0)
	])
	draw_colored_polygon(cliff_pts_right, Color(0.10, 0.15, 0.14, 0.95))

	# Thác nước đổ xuống vực thẳm (Phía trên bên trái & Phía dưới bên phải như bản đồ LoL)
	_draw_waterfall(Vector2(-120.0, -960.0), Vector2(-60.0, -HALF_H), 115.0)
	_draw_waterfall(Vector2(380.0, HALF_H), Vector2(260.0, 1020.0), 95.0)
	_draw_waterfall(Vector2(-580.0, HALF_H), Vector2(-690.0, 980.0), 70.0)

	# =========================================================================
	# 2. MẶT SÀN ĐẤU TRƯỜNG ĐA VÙNG (DUAL-BIOME BRIDGE FLOOR)
	# =========================================================================
	var arena_rect := Rect2(-HALF_W, -HALF_H, HALF_W * 2.0, HALF_H * 2.0)

	# Nửa Trái: Đá Tím Chạng Vạng (Spirit Blossom Twilight)
	draw_rect(Rect2(-HALF_W, -HALF_H, HALF_W, HALF_H * 2.0), Color(0.20, 0.16, 0.30, 1.0), true)
	# Nửa Phải: Đá Rêu Lục Bảo & Cát Vàng (Progress & Blossom Gardens)
	draw_rect(Rect2(0.0, -HALF_H, HALF_W, HALF_H * 2.0), Color(0.18, 0.25, 0.20, 1.0), true)

	# Dải chuyển màu mượt ở khu vực giữa cầu (-240px .. +240px)
	for i in range(12):
		var t: float = float(i) / 11.0
		var band_x: float = -240.0 + float(i) * 40.0
		var blend_col: Color = Color(0.20, 0.16, 0.30, 1.0).lerp(Color(0.22, 0.26, 0.21, 1.0), t)
		draw_rect(Rect2(band_x, -HALF_H, 42.0, HALF_H * 2.0), blend_col, true)

	# Làn đường chính giữa cầu (Central Lane Roadway)
	var road_pts := PackedVector2Array([
		Vector2(-HALF_W, -230.0),
		Vector2(0.0, -250.0),
		Vector2(HALF_W, -230.0),
		Vector2(HALF_W, 230.0),
		Vector2(0.0, 250.0),
		Vector2(-HALF_W, 230.0)
	])
	draw_colored_polygon(road_pts, Color(0.25, 0.23, 0.29, 0.55))

	# Lưới gạch lát đá cổ (Paving Stone Tiles)
	var grid_col_left := Color(0.28, 0.22, 0.42, 0.42)
	var grid_col_right := Color(0.25, 0.33, 0.27, 0.42)
	var gx: float = -HALF_W + GRID_STEP
	while gx < HALF_W:
		var c: Color = grid_col_left if gx < 0.0 else grid_col_right
		draw_line(Vector2(gx, -HALF_H), Vector2(gx, HALF_H), c, 1.0)
		gx += GRID_STEP

	var gy: float = -HALF_H + GRID_STEP
	while gy < HALF_H:
		draw_line(Vector2(-HALF_W, gy), Vector2(0.0, gy), grid_col_left, 1.0)
		draw_line(Vector2(0.0, gy), Vector2(HALF_W, gy), grid_col_right, 1.0)
		gy += GRID_STEP

	# Đường mạch Linh Khí uốn lượn bên nửa Trái (Spirit Leylines)
	var leyline_col := Color(0.38, 0.68, 1.0, 0.32 + 0.12 * pulse)
	var ley_top := PackedVector2Array([
		Vector2(-740.0, -140.0), Vector2(-560.0, -190.0), Vector2(-390.0, -95.0), Vector2(-210.0, -125.0), Vector2(-95.0, -55.0)
	])
	var ley_bot := PackedVector2Array([
		Vector2(-740.0, 150.0), Vector2(-540.0, 110.0), Vector2(-370.0, 185.0), Vector2(-200.0, 115.0), Vector2(-95.0, 55.0)
	])
	draw_polyline(ley_top, leyline_col, 3.0)
	draw_polyline(ley_bot, leyline_col, 3.0)

	# Đường mạch Hextech vàng đồng bên nửa Phải
	var hex_line_col := Color(0.88, 0.72, 0.28, 0.30 + 0.10 * pulse)
	var hex_top := PackedVector2Array([
		Vector2(740.0, -140.0), Vector2(540.0, -140.0), Vector2(460.0, -85.0), Vector2(240.0, -85.0), Vector2(95.0, -45.0)
	])
	var hex_bot := PackedVector2Array([
		Vector2(740.0, 140.0), Vector2(540.0, 140.0), Vector2(460.0, 85.0), Vector2(240.0, 85.0), Vector2(95.0, 45.0)
	])
	draw_polyline(hex_top, hex_line_col, 2.5)
	draw_polyline(hex_bot, hex_line_col, 2.5)

	# =========================================================================
	# 3. QUẢNG TRƯỜNG CỔ NGỮ & LÕI NĂNG LƯỢNG TRUNG TÂM (BRIDGE OF PROGRESS PLAZA)
	# =========================================================================
	# Nền đá tròn quảng trường trung tâm (Lấy cảm hứng từ ảnh 2)
	draw_circle(Vector2.ZERO, 255.0, Color(0.22, 0.26, 0.28, 0.85))
	draw_arc(Vector2.ZERO, 255.0, 0.0, TAU, 64, Color(0.62, 0.54, 0.36, 0.75), 3.5)
	draw_circle(Vector2.ZERO, 185.0, Color(0.19, 0.22, 0.26, 0.90))
	draw_arc(Vector2.ZERO, 185.0, 0.0, TAU, 64, Color(0.45, 0.62, 0.68, 0.55), 2.0)

	# 8 nan hoa cổ ngữ chia múi quảng trường
	for i in range(8):
		var ang: float = float(i) * (TAU / 8.0)
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(dir * 58.0, dir * 252.0, Color(0.55, 0.50, 0.38, 0.40), 2.0)

	# 4 Nắp cống tròn bằng đồng (Brass Sewer Grates đặc trưng của Zaun/Piltover)
	var grate_positions := [
		Vector2(-155.0, 105.0),
		Vector2(165.0, 115.0),
		Vector2(-160.0, -115.0),
		Vector2(155.0, -110.0)
	]
	for gpos in grate_positions:
		_draw_brass_grate(gpos, 24.0)

	# 4 Trụ Thu Lôi Hextech/Chemtech nối dây năng lượng vào Lõi Trung Tâm
	var pylon_positions := [
		Vector2(-95.0, -82.0),
		Vector2(95.0, -82.0),
		Vector2(-95.0, 82.0),
		Vector2(95.0, 82.0)
	]
	for ppos in pylon_positions:
		# Dây cáp năng lượng nối về tâm
		draw_line(ppos, Vector2.ZERO, Color(0.95, 0.25, 0.68, 0.45 + 0.25 * pulse), 2.5)
		draw_circle(ppos, 16.0, Color(0.16, 0.14, 0.18, 1.0))
		draw_arc(ppos, 16.0, 0.0, TAU, 24, Color(0.75, 0.58, 0.26, 0.9), 2.5)
		draw_circle(ppos, 7.0, Color(0.98, 0.32, 0.75, 0.75 + 0.25 * pulse))

	# Lõi Năng Lượng Cổ Ngữ Hồng/Tím ở Tâm Đấu Trường (Vector2.ZERO)
	draw_circle(Vector2.ZERO, 54.0, Color(0.32, 0.22, 0.28, 0.95))
	draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 40, Color(0.85, 0.62, 0.28, 0.95), 4.0)
	draw_circle(Vector2.ZERO, 36.0 + 3.0 * pulse, Color(0.95, 0.20, 0.62, 0.35 + 0.15 * pulse))
	draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.35, 0.78, 0.85))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.82, 0.95, 0.95))

	# =========================================================================
	# 4. BỆ THỜ CỔ NGỮ HAI ĐẦU CẦU (LEFT & RIGHT NEXUS SHRINES)
	# =========================================================================
	# Bệ Thờ Linh Hoa Bên Trái (-590, 0)
	var left_shrine := Vector2(-590.0, 0.0)
	draw_circle(left_shrine, 92.0, Color(0.15, 0.12, 0.25, 0.92))
	draw_arc(left_shrine, 92.0, 0.0, TAU, 48, Color(0.45, 0.62, 1.0, 0.75), 3.0)
	draw_arc(left_shrine, 64.0, 0.0, TAU, 36, Color(0.62, 0.42, 0.95, 0.55), 2.0)
	draw_circle(left_shrine, 22.0 + 2.0 * pulse, Color(0.35, 0.75, 1.0, 0.80))
	draw_circle(left_shrine, 10.0, Color(0.85, 0.96, 1.0, 1.0))

	# Bệ Thờ Thánh Địa Bên Phải (+590, 0)
	var right_shrine := Vector2(590.0, 0.0)
	draw_circle(right_shrine, 92.0, Color(0.14, 0.21, 0.18, 0.92))
	draw_arc(right_shrine, 92.0, 0.0, TAU, 48, Color(0.92, 0.76, 0.28, 0.80), 3.0)
	draw_arc(right_shrine, 64.0, 0.0, TAU, 36, Color(0.32, 0.85, 0.58, 0.55), 2.0)
	draw_circle(right_shrine, 22.0 + 2.0 * pulse, Color(0.28, 0.92, 0.65, 0.80))
	draw_circle(right_shrine, 10.0, Color(0.92, 1.0, 0.88, 1.0))

	# =========================================================================
	# 5. HỐC BỤI CỎ CHIẾN THUẬT ARAM & THẢM THỰC VẬT HAI BÊN RÌA CẦU
	# =========================================================================
	# Hốc Bụi Cỏ Trung Tâm Phía Trên & Phía Dưới (ARAM Side Brush Alcoves)
	_draw_bush_alcove(Vector2(0.0, -HALF_H + 28.0), true, slow_wave)
	_draw_bush_alcove(Vector2(0.0, HALF_H - 28.0), false, slow_wave)

	# Tán cây Linh Hoa Xanh Lam (Nửa Trái) & Anh Đào Hồng Sakura (Nửa Phải) dọc thành cầu
	var blue_tree_spots := [
		Vector2(-700.0, -435.0), Vector2(-520.0, -445.0), Vector2(-310.0, -440.0),
		Vector2(-680.0, 440.0), Vector2(-470.0, 445.0), Vector2(-280.0, 438.0)
	]
	for pos in blue_tree_spots:
		_draw_blossom_canopy(pos, Color(0.22, 0.42, 0.88, 0.88), Color(0.48, 0.72, 1.0, 0.92), slow_wave)

	var pink_tree_spots := [
		Vector2(290.0, -440.0), Vector2(490.0, -445.0), Vector2(695.0, -435.0),
		Vector2(275.0, 440.0), Vector2(485.0, 445.0), Vector2(690.0, 438.0),
		Vector2(-125.0, -435.0), Vector2(125.0, -435.0)
	]
	for pos in pink_tree_spots:
		_draw_blossom_canopy(pos, Color(0.82, 0.32, 0.48, 0.88), Color(1.0, 0.58, 0.70, 0.92), -slow_wave)

	# =========================================================================
	# 6. LAN CAN SẮT, TƯỜNG ĐÁ BAO QUANH & ĐÈN ĐƯỜNG HEXTECH / LINH HOA
	# =========================================================================
	# Gờ đá dày bao quanh 4 cạnh đấu trường
	var wall_thick: float = 14.0
	draw_rect(Rect2(-HALF_W - wall_thick, -HALF_H - wall_thick, HALF_W * 2.0 + wall_thick * 2.0, wall_thick), Color(0.16, 0.18, 0.22, 1.0), true)
	draw_rect(Rect2(-HALF_W - wall_thick, HALF_H, HALF_W * 2.0 + wall_thick * 2.0, wall_thick), Color(0.16, 0.18, 0.22, 1.0), true)
	draw_rect(Rect2(-HALF_W - wall_thick, -HALF_H, wall_thick, HALF_H * 2.0), Color(0.16, 0.18, 0.22, 1.0), true)
	draw_rect(Rect2(HALF_W, -HALF_H, wall_thick, HALF_H * 2.0), Color(0.16, 0.18, 0.22, 1.0), true)

	# Khung viền kim loại Hextech chuẩn ranh giới va chạm
	draw_rect(arena_rect, Color(0.78, 0.62, 0.28, 0.92), false, 3.5)

	# Cột trụ đá và Đèn lồng phát sáng dọc lan can trên & dưới
	var post_x: float = -HALF_W + 60.0
	while post_x <= HALF_W - 60.0:
		if absf(post_x) > 140.0: # Chừa khoảng trống cho Hốc Bụi Cỏ giữa bản đồ
			var is_left: bool = post_x < 0.0
			var lamp_col: Color = Color(0.42, 0.82, 1.0, 0.85) if is_left else Color(1.0, 0.82, 0.32, 0.85)
			_draw_bridge_lamp_post(Vector2(post_x, -HALF_H), lamp_col, pulse)
			_draw_bridge_lamp_post(Vector2(post_x, HALF_H), lamp_col, pulse)
		post_x += 160.0


func _draw_waterfall(start_pos: Vector2, end_pos: Vector2, width: float) -> void:
	var dir: Vector2 = (end_pos - start_pos).normalized()
	var perp: Vector2 = dir.orthogonal()
	var poly := PackedVector2Array([
		start_pos - perp * (width * 0.5),
		start_pos + perp * (width * 0.5),
		end_pos + perp * (width * 0.68),
		end_pos - perp * (width * 0.68)
	])
	draw_colored_polygon(poly, Color(0.32, 0.68, 0.92, 0.38))

	# Các dải bọt nước trắng chảy dọc thác
	for i in range(-1, 2):
		var offset: Vector2 = perp * (float(i) * width * 0.24)
		draw_line(start_pos + offset, end_pos + offset, Color(0.78, 0.95, 1.0, 0.42), 6.0)

	# Quầng bọt tung trắng xóa ở chân và đỉnh thác
	draw_circle(start_pos, width * 0.55, Color(0.75, 0.94, 1.0, 0.35))
	draw_circle(end_pos, width * 0.70, Color(0.75, 0.94, 1.0, 0.28))


func _draw_brass_grate(pos: Vector2, radius: float) -> void:
	draw_circle(pos, radius, Color(0.12, 0.14, 0.15, 0.95))
	draw_arc(pos, radius, 0.0, TAU, 24, Color(0.68, 0.54, 0.26, 0.85), 3.0)
	for i in range(-2, 3):
		var off: float = float(i) * (radius * 0.34)
		var half_len: float = sqrt(maxf(0.0, radius * radius - off * off)) - 3.0
		draw_line(pos + Vector2(-half_len, off), pos + Vector2(half_len, off), Color(0.55, 0.44, 0.22, 0.8), 2.0)


func _draw_bush_alcove(center: Vector2, is_top: bool, sway: float) -> void:
	var sign_y: float = 1.0 if is_top else -1.0
	# Bệ đất bán nguyệt ôm lấy bụi cỏ
	draw_circle(center, 78.0, Color(0.14, 0.24, 0.16, 0.85))
	draw_arc(center, 78.0, 0.0, TAU, 32, Color(0.45, 0.58, 0.36, 0.70), 2.5)

	# Cụm bụi cỏ xanh ngọc ARAM đung đưa nhẹ
	for i in range(-3, 4):
		var bx: float = float(i) * 19.0 + sway * 2.0
		var by: float = absf(float(i)) * 4.5 * sign_y
		var bpos := center + Vector2(bx, by)
		draw_circle(bpos, 20.0, Color(0.16, 0.46, 0.26, 0.82))
		draw_circle(bpos + Vector2(-3.0, -3.0), 13.0, Color(0.28, 0.68, 0.38, 0.85))
	# Đốm hoa đom đóm phát sáng trong bụi cỏ
	draw_circle(center + Vector2(-24.0, 6.0 * sign_y), 3.5, Color(0.45, 0.95, 1.0, 0.9))
	draw_circle(center + Vector2(26.0, 4.0 * sign_y), 3.5, Color(0.45, 0.95, 1.0, 0.9))


func _draw_blossom_canopy(pos: Vector2, dark_col: Color, bright_col: Color, sway: float) -> void:
	var shift := Vector2(sway * 2.5, 0.0)
	draw_circle(pos + Vector2(0.0, 6.0), 34.0, Color(0.06, 0.05, 0.10, 0.45))
	draw_circle(pos + shift, 30.0, dark_col)
	draw_circle(pos + shift + Vector2(-14.0, -6.0), 22.0, bright_col)
	draw_circle(pos + shift + Vector2(15.0, 4.0), 20.0, bright_col)
	draw_circle(pos + shift + Vector2(2.0, -12.0), 16.0, bright_col.lightened(0.18))


func _draw_bridge_lamp_post(pos: Vector2, glow_col: Color, pulse: float) -> void:
	draw_rect(Rect2(pos.x - 8.0, pos.y - 8.0, 16.0, 16.0), Color(0.26, 0.28, 0.34, 1.0), true)
	draw_rect(Rect2(pos.x - 8.0, pos.y - 8.0, 16.0, 16.0), Color(0.68, 0.56, 0.30, 0.9), false, 1.5)
	draw_circle(pos, 18.0 + 4.0 * pulse, Color(glow_col.r, glow_col.g, glow_col.b, 0.22))
	draw_circle(pos, 5.5, glow_col)
	draw_circle(pos, 2.5, Color.WHITE)


