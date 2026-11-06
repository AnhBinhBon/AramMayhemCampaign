class_name WeaponController
extends Node2D
## Hệ thống Điều khiển Vũ khí Đa Cơ chế (Auto-Aim & Multi-Mechanism WeaponController)
## Hỗ trợ 4 hình thái vũ khí hoàn toàn khác biệt:
## 1. Súng Trường (AD): Bắn đạn tốc độ cao + Tia lửa đầu nòng.
## 2. Đại Kiếm Trọng Kích (Bruiser): Chém quét lưỡi kiếm khí bán nguyệt đỏ rực + Hút máu.
## 3. Rìu Chiến Hạng Nặng (Tank): Bổ xoay 180 độ chấn động xanh lục (cộng sát thương theo Giáp) + Đẩy lùi mạnh.
## 4. Quyền Trượng Hỏa Cầu (Mage AP): Phóng Quả Cầu Lửa lớn phát nổ diện rộng AoE thiêu đốt cụm quái.

const PROJECTILE_SCENE_PATH: String = "res://scenes/weapons/Projectile.tscn"

var player: Player = null
var weapon_data: WeaponData = null
var projectile_scene: PackedScene = null
var object_pool: Node = null

var extra_range: float = 0.0
var extra_pierce: int = 0
var extra_bounce: int = 0

var _target: Node2D = null
var _scan_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _swing_Flip: float = 1.0
var _custom_parts_root: Node2D = null

@onready var gun_pivot: Node2D = $GunPivot
@onready var gun_mesh: MeshInstance2D = $GunPivot/GunMesh
@onready var muzzle: Marker2D = $GunPivot/Muzzle


func _ready() -> void:
	projectile_scene = load(PROJECTILE_SCENE_PATH) as PackedScene
	object_pool = get_tree().get_first_node_in_group("object_pool")


func setup(p_player: Player, p_weapon: WeaponData) -> void:
	player = p_player
	set_weapon_data(p_weapon)


## Nhận dữ liệu đối tượng vũ khí (WeaponData) và tự động dựng Node / Sprite vũ khí tương ứng
func set_weapon_data(p_weapon: WeaponData) -> void:
	weapon_data = p_weapon
	if weapon_data == null:
		weapon_data = load("res://resources/weapons/gun_ad.tres") as WeaponData

	_rebuild_weapon_visuals()


func _load_weapon_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t != null:
			return t
	var abs_p: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img != null:
			return ImageTexture.create_from_image(img)
	return null


func _rebuild_weapon_visuals() -> void:
	if gun_pivot == null or weapon_data == null:
		return

	if _custom_parts_root != null and is_instance_valid(_custom_parts_root):
		_custom_parts_root.queue_free()

	_custom_parts_root = Node2D.new()
	_custom_parts_root.name = "WeaponCustomVisuals"
	gun_pivot.add_child(_custom_parts_root)

	if gun_mesh != null:
		gun_mesh.visible = false

	# Ưu tiên 1: Nếu đối tượng WeaponData có hình ảnh Sprite riêng (ví dụ Nỏ Bạc AD weapon_ad_crossbow.png)
	var wpn_tex: Texture2D = _load_weapon_texture(weapon_data.weapon_sprite_path)
	if wpn_tex != null:
		var spr := Sprite2D.new()
		spr.name = "WeaponObjectSprite"
		spr.texture = wpn_tex
		spr.position = weapon_data.hold_offset
		var max_dim: float = maxf(1.0, float(maxi(wpn_tex.get_width(), wpn_tex.get_height())))
		var target_sz: float = maxf(20.0, weapon_data.visual_size)
		spr.scale = Vector2.ONE * (target_sz / max_dim)
		_custom_parts_root.add_child(spr)
		if muzzle != null:
			muzzle.position = weapon_data.muzzle_offset
		return

	# Ưu tiên 2: Nếu đối tượng WeaponData chưa có ảnh Sprite riêng, dựng mô hình Node 2D đa bộ phận
	match weapon_data.weapon_type:
		WeaponData.WeaponType.PROJECTILE:
			# Súng Trường Xạ Thủ (Thân súng + Nòng dài + Băng đạn vàng cam)
			_add_box_part(Vector2(16, 0), Vector2(22, 8), Color(0.24, 0.28, 0.34, 1.0))
			_add_box_part(Vector2(30, -1), Vector2(14, 4), Color(0.55, 0.62, 0.72, 1.0))
			_add_box_part(Vector2(18, 5), Vector2(6, 6), Color(1.0, 0.65, 0.15, 1.0))
			if muzzle != null:
				muzzle.position = Vector2(38, 0)

		WeaponData.WeaponType.MELEE:
			if weapon_data.knockback_force >= 220.0:
				# Rìu Chiến Hạng Nặng (Cán dài + 2 lưỡi rìu bán nguyệt khổng lồ màu Xanh Ngọc)
				_add_box_part(Vector2(22, 0), Vector2(36, 5), Color(0.42, 0.30, 0.20, 1.0))
				_add_prism_part(Vector2(32, -10), Vector2(20, 14), 0.0, Color(0.28, 0.95, 0.55, 1.0))
				_add_prism_part(Vector2(32, 10), Vector2(20, 14), PI, Color(0.28, 0.95, 0.55, 1.0))
				_add_box_part(Vector2(32, 0), Vector2(8, 10), Color(0.85, 0.95, 0.88, 1.0))
			else:
				# Đại Kiếm Trọng Kích (Chuôi + Chắn tay vàng + Lưỡi kiếm to bản bạc ánh đỏ + Mũi nhọn)
				_add_box_part(Vector2(10, 0), Vector2(10, 5), Color(0.45, 0.22, 0.18, 1.0))
				_add_box_part(Vector2(16, 0), Vector2(5, 18), Color(0.95, 0.78, 0.22, 1.0))
				_add_box_part(Vector2(33, 0), Vector2(30, 9), Color(0.92, 0.85, 0.88, 1.0))
				_add_box_part(Vector2(33, 0), Vector2(28, 3), Color(0.98, 0.28, 0.28, 1.0))
				_add_prism_part(Vector2(52, 0), Vector2(9, 10), PI * 0.5, Color(0.95, 0.90, 0.92, 1.0))

		WeaponData.WeaponType.AOE:
			# Quyền Trượng Hỏa Cầu (Thân trượng tím + Đài vàng + Ngọc Lửa phát sáng ở đỉnh)
			_add_box_part(Vector2(20, 0), Vector2(28, 5), Color(0.48, 0.25, 0.78, 1.0))
			_add_box_part(Vector2(34, 0), Vector2(5, 13), Color(0.98, 0.80, 0.22, 1.0))
			_add_sphere_part(Vector2(41, 0), 9.0, Color(1.0, 0.35, 0.12, 0.95))
			_add_sphere_part(Vector2(41, 0), 5.0, Color(1.0, 0.92, 0.35, 1.0))
			if muzzle != null:
				muzzle.position = Vector2(44, 0)


func _add_box_part(pos: Vector2, sz: Vector2, col: Color) -> void:
	var mi := MeshInstance2D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sz.x, sz.y, 1.0)
	mi.mesh = bm
	mi.position = pos
	mi.self_modulate = col
	_custom_parts_root.add_child(mi)


func _add_prism_part(pos: Vector2, sz: Vector2, rot: float, col: Color) -> void:
	var mi := MeshInstance2D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(sz.x, sz.y, 1.0)
	mi.mesh = pm
	mi.position = pos
	mi.rotation = rot
	mi.self_modulate = col
	_custom_parts_root.add_child(mi)


func _add_sphere_part(pos: Vector2, rad: float, col: Color) -> void:
	var mi := MeshInstance2D.new()
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.self_modulate = col
	_custom_parts_root.add_child(mi)


func get_effective_range() -> float:
	var base_r: float = weapon_data.base_range if weapon_data != null else 360.0
	return base_r + extra_range


func _process(delta: float) -> void:
	if player == null or player.is_dead:
		return

	if object_pool == null:
		object_pool = get_tree().get_first_node_in_group("object_pool")

	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.08
		_target = _find_nearest_enemy()

	if _target != null and is_instance_valid(_target) and not _target.get("is_dead"):
		var aim_dir: Vector2 = (_target.global_position - global_position).normalized()
		var target_angle: float = aim_dir.angle()
		rotation = lerp_angle(rotation, target_angle, delta * 22.0)
	elif player.velocity.length_squared() > 10.0:
		rotation = lerp_angle(rotation, player.velocity.angle(), delta * 10.0)

	# Lật dọc vũ khí để không bị ngược khi quay sang trái (trừ khi đang vung kiếm cận chiến)
	if gun_pivot != null and (weapon_data == null or weapon_data.weapon_type != WeaponData.WeaponType.MELEE):
		gun_pivot.scale.y = -1.0 if absf(wrapf(rotation, -PI, PI)) > PI * 0.5 else 1.0

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0 and _target != null and is_instance_valid(_target):
		var atk_speed: float = player.stats.get_stat(StatModifier.StatType.ATTACK_SPEED)
		_fire_cooldown = 1.0 / maxf(0.25, atk_speed)
		_fire_at(_target.global_position)


func _find_nearest_enemy() -> Node2D:
	var max_r: float = get_effective_range()
	var best_dist_sq: float = max_r * max_r
	var best_enemy: Node2D = null

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and e.visible:
			if e.get("is_dead") == true:
				continue
			var d_sq: float = global_position.distance_squared_to(e.global_position)
			if d_sq <= best_dist_sq:
				best_dist_sq = d_sq
				best_enemy = e

	return best_enemy


func _fire_at(target_pos: Vector2) -> void:
	if player == null or weapon_data == null:
		return

	var spawn_pos: Vector2 = muzzle.global_position if muzzle != null else global_position
	var fire_dir: Vector2 = (target_pos - global_position).normalized()
	if fire_dir.length_squared() < 0.001:
		fire_dir = Vector2.RIGHT.rotated(rotation)

	var stat_val: float = player.stats.get_stat(
		StatModifier.StatType.AP if weapon_data.uses_ap else StatModifier.StatType.AD
	)
	# Đối với Rìu Đỡ Đòn: cộng thêm 80% chỉ số Giáp vào sát thương đòn bổ
	if weapon_data.weapon_type == WeaponData.WeaponType.MELEE and weapon_data.knockback_force >= 220.0:
		stat_val += player.stats.get_stat(StatModifier.StatType.ARMOR) * 0.80

	var crit_chance: float = player.stats.get_stat(StatModifier.StatType.CRIT_CHANCE)
	var crit_mult: float = player.stats.get_stat(StatModifier.StatType.CRIT_DAMAGE)

	var is_crit: bool = randf() < crit_chance
	var final_damage: float = maxf(1.0, stat_val * weapon_data.damage_scale * (crit_mult if is_crit else 1.0))

	if weapon_data.weapon_type == WeaponData.WeaponType.MELEE:
		_execute_melee_swing(fire_dir, final_damage, is_crit)
		return

	var proj := _spawn_projectile_instance(
		spawn_pos,
		fire_dir,
		final_damage,
		is_crit,
		weapon_data.pierce_count + extra_pierce,
		weapon_data.bounce_count + extra_bounce,
		weapon_data.projectile_color
	)

	_play_recoil_anim()
	if proj != null:
		CombatEvents.attack.emit(self, proj)


func _execute_melee_swing(fire_dir: Vector2, final_damage: float, is_crit: bool) -> void:
	var is_heavy_axe: bool = weapon_data.knockback_force >= 220.0
	_play_melee_swing_anim(is_heavy_axe)

	var max_r: float = get_effective_range()
	var max_r_sq: float = max_r * max_r
	var half_cone_deg: float = 95.0 if is_heavy_axe else 68.0
	var enemies := get_tree().get_nodes_in_group("enemies")

	for e in enemies:
		if e is Node2D and e.visible and not e.get("is_dead"):
			var to_e: Vector2 = e.global_position - global_position
			var d_sq: float = to_e.length_squared()
			if d_sq <= max_r_sq:
				var angle_diff: float = absf(fire_dir.angle_to(to_e))
				if angle_diff <= deg_to_rad(half_cone_deg):
					if e.has_method("take_damage"):
						e.take_damage(final_damage, is_crit)
					CombatEvents.hit.emit(e, final_damage, is_crit)
					if is_crit:
						CombatEvents.crit.emit(e, final_damage)

					if weapon_data.knockback_force > 0.0:
						var push_dir: Vector2 = to_e.normalized() if d_sq > 1.0 else fire_dir
						if e.has_method("apply_knockback"):
							e.apply_knockback(push_dir * weapon_data.knockback_force * 1.4)
						elif e is CharacterBody2D:
							e.global_position += push_dir * (weapon_data.knockback_force * 0.12)

	_spawn_slash_arc(fire_dir, max_r, is_heavy_axe)
	CombatEvents.attack.emit(self, null)


func _spawn_slash_arc(dir: Vector2, radius: float, is_heavy_axe: bool) -> void:
	var root_fx := Node2D.new()
	root_fx.global_position = global_position
	get_tree().current_scene.add_child(root_fx)

	var base_ang: float = dir.angle()
	var sweep_deg: float = 185.0 if is_heavy_axe else 130.0
	var fill_col: Color = (
		Color(0.22, 0.95, 0.52, 0.35)
		if is_heavy_axe
		else Color(1.0, 0.25, 0.22, 0.42)
	)
	var edge_col: Color = (
		Color(0.45, 1.0, 0.68, 0.95)
		if is_heavy_axe
		else Color(1.0, 0.65, 0.35, 0.95)
	)

	# 1. Vùng quạt chém tô đặc (Crescent Slash Polygon)
	var poly := Polygon2D.new()
	poly.color = fill_col
	var poly_pts := PackedVector2Array()
	var inner_r: float = radius * (0.25 if is_heavy_axe else 0.42)
	var steps: int = 14
	for i in range(steps + 1):
		var frac: float = float(i) / float(steps) - 0.5
		var ang: float = base_ang + frac * deg_to_rad(sweep_deg)
		poly_pts.append(Vector2(cos(ang), sin(ang)) * radius)
	for i in range(steps, -1, -1):
		var frac: float = float(i) / float(steps) - 0.5
		var ang: float = base_ang + frac * deg_to_rad(sweep_deg)
		poly_pts.append(Vector2(cos(ang), sin(ang)) * inner_r)
	poly.polygon = poly_pts
	root_fx.add_child(poly)

	# 2. Đường viền lưỡi kiếm / rìu sắc nét ở rìa ngoài
	var arc_line := Line2D.new()
	arc_line.width = 7.0 if is_heavy_axe else 5.0
	arc_line.default_color = edge_col
	var edge_pts := PackedVector2Array()
	for i in range(steps + 1):
		var frac: float = float(i) / float(steps) - 0.5
		var ang: float = base_ang + frac * deg_to_rad(sweep_deg)
		edge_pts.append(Vector2(cos(ang), sin(ang)) * radius)
	arc_line.points = edge_pts
	root_fx.add_child(arc_line)

	var tw := root_fx.create_tween()
	tw.set_parallel(true)
	tw.tween_property(root_fx, "scale", Vector2(1.12, 1.12), 0.18)
	tw.tween_property(root_fx, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(root_fx.queue_free)


func _play_melee_swing_anim(is_heavy_axe: bool) -> void:
	if gun_pivot == null:
		return
	var swing_arc: float = 1.45 if is_heavy_axe else 1.15
	gun_pivot.rotation = -swing_arc * _swing_Flip
	_swing_Flip *= -1.0
	var tw := create_tween()
	tw.tween_property(gun_pivot, "rotation", swing_arc * (-_swing_Flip), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(gun_pivot, "rotation", 0.0, 0.09)


func spawn_extra_projectile(angle_offset_deg: float, damage_ratio: float = 0.65) -> Projectile:
	if player == null or weapon_data == null:
		return null
	var spawn_pos: Vector2 = muzzle.global_position if muzzle != null else global_position
	var base_dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	var fire_dir: Vector2 = base_dir.rotated(deg_to_rad(angle_offset_deg))

	var stat_val: float = player.stats.get_stat(
		StatModifier.StatType.AP if weapon_data.uses_ap else StatModifier.StatType.AD
	)
	var dmg: float = maxf(1.0, stat_val * weapon_data.damage_scale * damage_ratio)

	if weapon_data.weapon_type == WeaponData.WeaponType.MELEE:
		# Đối với vũ khí cận chiến khi có Xả Đạn / Cuồng Cung: phóng thêm kiếm khí tầm xa!
		return _spawn_projectile_instance(
			global_position + fire_dir * 24.0,
			fire_dir,
			dmg,
			false,
			1 + extra_pierce,
			extra_bounce,
			weapon_data.projectile_color
		)

	return _spawn_projectile_instance(
		spawn_pos,
		fire_dir,
		dmg,
		false,
		weapon_data.pierce_count + extra_pierce,
		weapon_data.bounce_count + extra_bounce,
		weapon_data.projectile_color
	)


func _spawn_projectile_instance(
	pos: Vector2,
	dir: Vector2,
	dmg: float,
	is_crit: bool,
	pierce: int,
	bounce: int,
	color: Color
) -> Projectile:
	var proj_node: Node = null
	if object_pool != null and object_pool.has_method("acquire"):
		proj_node = object_pool.acquire("player_projectile", projectile_scene)
	elif projectile_scene != null:
		proj_node = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj_node)

	var proj := proj_node as Projectile
	if proj != null:
		proj.pool_key = "player_projectile"
		proj.object_pool = object_pool
		var spd: float = weapon_data.projectile_speed if weapon_data.projectile_speed > 50.0 else 520.0
		proj.setup(
			pos,
			dir,
			dmg,
			spd,
			get_effective_range() + 110.0,
			is_crit,
			pierce,
			bounce,
			color,
			weapon_data.aoe_radius
		)
	return proj


func _play_recoil_anim() -> void:
	if gun_pivot == null:
		return
	gun_pivot.position = Vector2(-6.0, 0.0)
	var tw := create_tween()
	tw.tween_property(gun_pivot, "position", Vector2.ZERO, 0.09)
