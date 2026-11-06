class_name PlayerSkill
extends Node
## Hệ thống 3 Kỹ năng Chủ động Đa Lớp ([Q] Kỹ năng Phụ 1, [E] Kỹ năng Phụ 2, [SPACE] Kỹ năng Chính)
## Nguyên mẫu 4 Tướng Biểu tượng: Vayne (AD), Xin Zhao (Đấu Sĩ), Garen (Đỡ Đòn) và Lux (Pháp Sư).
## Hỗ trợ công thức giảm hồi chiêu chuẩn MOBA: CD = CD_0 / (1 + Haste / 100).

signal cooldown_updated(remaining: float, total: float)
signal cooldown_q_updated(remaining: float, total: float)
signal cooldown_e_updated(remaining: float, total: float)
signal skill_activated(skill_id: String, duration: float)

const SKILL_BUFF_SOURCE: String = "active_skill_buff"
const SUB_BUFF_Q_SOURCE: String = "sub_skill_q_buff"
const SUB_BUFF_E_SOURCE: String = "sub_skill_e_buff"

var player: Node = null

# Kỹ năng Chính [SPACE]
var skill_id: String = "ad_dash"
var skill_name: String = "Giờ Khắc Cuối Cùng"
var base_cooldown: float = 10.0
var cooldown_remaining: float = 0.0
var current_total_cooldown: float = 10.0
var buff_remaining: float = 0.0
var is_buff_active: bool = false

# Kỹ năng Phụ 1 [Q]
var skill_q_id: String = "vayne_tumble_q"
var skill_q_name: String = "Nhào Lộn & Tên Bạc"
var base_q_cooldown: float = 3.5
var cooldown_q_remaining: float = 0.0
var current_q_total_cooldown: float = 3.5
var _buff_q_remaining: float = 0.0

# Kỹ năng Phụ 2 [E]
var skill_e_id: String = "vayne_condemn_e"
var skill_e_name: String = "Kết Án"
var base_e_cooldown: float = 7.5
var cooldown_e_remaining: float = 0.0
var current_e_total_cooldown: float = 7.5
var _buff_e_remaining: float = 0.0

# Biến hiệu ứng duy trì (Lux Aura & Garen E Spin)
var _firestorm_tick_timer: float = 0.0
var _firestorm_vfx: Line2D = null
var _garen_spin_remaining: float = 0.0
var _garen_spin_tick_timer: float = 0.0
var _garen_spin_vfx: Line2D = null


func setup(p_player: Node, data: CharacterData) -> void:
	player = p_player
	if data != null:
		skill_id = data.skill_id
		skill_name = data.skill_name
		base_cooldown = maxf(1.0, data.skill_cooldown)
		current_total_cooldown = base_cooldown

		skill_q_id = data.skill_q_id
		skill_q_name = data.skill_q_name
		base_q_cooldown = maxf(0.8, data.skill_q_cooldown)
		current_q_total_cooldown = base_q_cooldown

		skill_e_id = data.skill_e_id
		skill_e_name = data.skill_e_name
		base_e_cooldown = maxf(0.8, data.skill_e_cooldown)
		current_e_total_cooldown = base_e_cooldown

	cooldown_remaining = 0.0
	cooldown_q_remaining = 0.0
	cooldown_e_remaining = 0.0
	_clear_active_buff()
	_clear_sub_buffs()


func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
		cooldown_updated.emit(cooldown_remaining, current_total_cooldown)

	if cooldown_q_remaining > 0.0:
		cooldown_q_remaining = maxf(0.0, cooldown_q_remaining - delta)
		cooldown_q_updated.emit(cooldown_q_remaining, current_q_total_cooldown)

	if cooldown_e_remaining > 0.0:
		cooldown_e_remaining = maxf(0.0, cooldown_e_remaining - delta)
		cooldown_e_updated.emit(cooldown_e_remaining, current_e_total_cooldown)

	if _buff_q_remaining > 0.0:
		_buff_q_remaining -= delta
		if _buff_q_remaining <= 0.0 and player != null and player.get("stats") != null:
			player.stats.remove_modifiers_from(SUB_BUFF_Q_SOURCE)

	if _buff_e_remaining > 0.0:
		_buff_e_remaining -= delta
		if _buff_e_remaining <= 0.0 and player != null and player.get("stats") != null:
			player.stats.remove_modifiers_from(SUB_BUFF_E_SOURCE)

	if _garen_spin_remaining > 0.0:
		_process_garen_judgment(delta)

	if is_buff_active:
		buff_remaining -= delta
		if skill_id == "mage_firestorm":
			_process_firestorm(delta)
		if buff_remaining <= 0.0:
			_clear_active_buff()


func reduce_cooldown(seconds: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - seconds)
		cooldown_updated.emit(cooldown_remaining, current_total_cooldown)
	if cooldown_q_remaining > 0.0:
		cooldown_q_remaining = maxf(0.0, cooldown_q_remaining - seconds)
		cooldown_q_updated.emit(cooldown_q_remaining, current_q_total_cooldown)
	if cooldown_e_remaining > 0.0:
		cooldown_e_remaining = maxf(0.0, cooldown_e_remaining - seconds)
		cooldown_e_updated.emit(cooldown_e_remaining, current_e_total_cooldown)


func _get_haste() -> float:
	if player != null and player.get("stats") != null:
		return player.stats.get_stat(StatModifier.StatType.ABILITY_HASTE)
	return 0.0


## Kích hoạt Kỹ năng Phụ 1 [Q]
func try_cast_q() -> bool:
	if cooldown_q_remaining > 0.0 or player == null:
		return false

	var haste: float = _get_haste()
	current_q_total_cooldown = base_q_cooldown / maxf(0.2, 1.0 + haste / 100.0)
	cooldown_q_remaining = current_q_total_cooldown
	cooldown_q_updated.emit(cooldown_q_remaining, current_q_total_cooldown)

	_execute_skill_q()
	CombatEvents.skill_cast.emit(skill_q_id)
	return true


## Kích hoạt Kỹ năng Phụ 2 [E]
func try_cast_e() -> bool:
	if cooldown_e_remaining > 0.0 or player == null:
		return false

	var haste: float = _get_haste()
	current_e_total_cooldown = base_e_cooldown / maxf(0.2, 1.0 + haste / 100.0)
	cooldown_e_remaining = current_e_total_cooldown
	cooldown_e_updated.emit(cooldown_e_remaining, current_e_total_cooldown)

	_execute_skill_e()
	CombatEvents.skill_cast.emit(skill_e_id)
	return true


## Kích hoạt Kỹ năng Chính [SPACE]
func try_cast() -> bool:
	if cooldown_remaining > 0.0 or player == null:
		return false

	var haste: float = _get_haste()
	current_total_cooldown = base_cooldown / maxf(0.2, 1.0 + haste / 100.0)
	cooldown_remaining = current_total_cooldown
	cooldown_updated.emit(cooldown_remaining, current_total_cooldown)

	_execute_skill()
	CombatEvents.skill_cast.emit(skill_id)
	return true


func is_damage_reduction_active() -> bool:
	return is_buff_active and skill_id == "tank_reflect_shield"


# =============================================================================
# THỰC THI KỸ NĂNG PHỤ 1 [Q] (VAYNE / XIN ZHAO / GAREN / LUX)
# =============================================================================
func _execute_skill_q() -> void:
	match skill_q_id:
		"vayne_tumble_q":
			# Vayne [Q] Nhào Lộn & Mũi Tên Bạc: Lướt 150px và bắn Mũi Tên Bạc gây 140% AD + 8% Máu tối đa mục tiêu
			if player.has_method("perform_dash"):
				player.perform_dash(150.0, 0.14)
			var target: Node2D = _find_nearest_enemy(420.0)
			if target != null:
				var ad_val: float = _get_stat(StatModifier.StatType.AD, 18.0)
				var enemy_max_hp: float = float(target.get("max_hp")) if target.get("max_hp") != null else 100.0
				var bonus_silver: float = minf(600.0, enemy_max_hp * 0.08)
				var total_dmg: float = ad_val * 1.40 + bonus_silver
				_deal_skill_damage(target, total_dmg, true)
				_spawn_beam_vfx((player as Node2D).global_position, target.global_position, Color(0.85, 0.95, 1.0, 0.95), 5.0, 0.18)
			skill_activated.emit(skill_q_id, 0.25)

		"xinzhao_talon_q":
			# Xin Zhao [Q] Liên Hoàn Tam Kích: Đâm 3 mũi thương liên tiếp gây 210% AD, hất tung 0.75s và giảm 1s hồi chiêu E & SPACE
			var origin: Vector2 = (player as Node2D).global_position
			var aim_dir: Vector2 = _get_aim_direction()
			var ad_val: float = _get_stat(StatModifier.StatType.AD, 22.0)
			var strike_dmg: float = ad_val * 0.70

			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e is Node2D and e.visible and not e.get("is_dead"):
					var to_e: Vector2 = e.global_position - origin
					var dist: float = to_e.length()
					if dist <= 195.0 and (dist < 35.0 or aim_dir.dot(to_e.normalized()) >= 0.35):
						_deal_skill_damage(e, strike_dmg * 3.0, false)
						if e.has_method("apply_stun"):
							e.apply_stun(0.75)
						if e.has_method("apply_knockback"):
							e.apply_knockback(aim_dir * 160.0)

			# Giảm 1.0s hồi chiêu của E và SPACE
			if cooldown_e_remaining > 0.0:
				cooldown_e_remaining = maxf(0.0, cooldown_e_remaining - 1.0)
				cooldown_e_updated.emit(cooldown_e_remaining, current_e_total_cooldown)
			if cooldown_remaining > 0.0:
				cooldown_remaining = maxf(0.0, cooldown_remaining - 1.0)
				cooldown_updated.emit(cooldown_remaining, current_total_cooldown)

			_spawn_beam_vfx(origin, origin + aim_dir * 190.0, Color(1.0, 0.78, 0.25, 0.95), 14.0, 0.20)
			skill_activated.emit(skill_q_id, 0.3)

		"garen_strike_q":
			# Garen [Q] Đòn Quyết Định: Tăng +35% Tốc chạy trong 1.5s và bổ đại kiếm gây 145% AD + 80% Giáp kèm Câm lặng 1.0s
			if player.get("stats") != null:
				player.stats.remove_modifiers_from(SUB_BUFF_Q_SOURCE)
				player.stats.add_modifier(SUB_BUFF_Q_SOURCE, StatModifier.StatType.MOVE_SPEED, 0.0, 0.35)
				_buff_q_remaining = 1.5

			var origin: Vector2 = (player as Node2D).global_position
			var aim_dir: Vector2 = _get_aim_direction()
			var ad_val: float = _get_stat(StatModifier.StatType.AD, 16.0)
			var armor_val: float = _get_stat(StatModifier.StatType.ARMOR, 18.0)
			var dmg: float = ad_val * 1.45 + armor_val * 0.80

			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e is Node2D and e.visible and not e.get("is_dead"):
					var to_e: Vector2 = e.global_position - origin
					var dist: float = to_e.length()
					if dist <= 155.0 and (dist < 40.0 or aim_dir.dot(to_e.normalized()) >= 0.15):
						_deal_skill_damage(e, dmg, false)
						if e.has_method("apply_stun"):
							e.apply_stun(1.0)

			_spawn_ring_vfx(origin + aim_dir * 60.0, 90.0, Color(0.95, 0.88, 0.32, 0.9), 0.22)
			skill_activated.emit(skill_q_id, 1.5)

		"lux_binding_q":
			# Lux [Q] Khóa Ánh Sáng: Bắn cầu ánh sáng 340px xuyên tối đa 2 kẻ địch, gây 145% AP và Trói chân 1.5s
			var origin: Vector2 = (player as Node2D).global_position
			var aim_dir: Vector2 = _get_aim_direction()
			var ap_val: float = _get_stat(StatModifier.StatType.AP, 35.0)
			var dmg: float = maxf(25.0, ap_val * 1.45)

			var hit_count: int = 0
			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if hit_count >= 2:
					break
				if e is Node2D and e.visible and not e.get("is_dead"):
					var rel: Vector2 = e.global_position - origin
					var proj_len: float = rel.dot(aim_dir)
					if proj_len >= -15.0 and proj_len <= 345.0:
						var perp_dist: float = absf(rel.cross(aim_dir))
						if perp_dist <= 52.0:
							_deal_skill_damage(e, dmg, false)
							if e.has_method("apply_stun"):
								e.apply_stun(1.5)
							_spawn_ring_vfx(e.global_position, 32.0, Color(1.0, 0.95, 0.45, 0.95), 0.45)
							hit_count += 1

			_spawn_beam_vfx(origin, origin + aim_dir * 340.0, Color(1.0, 0.92, 0.42, 0.92), 12.0, 0.22)
			skill_activated.emit(skill_q_id, 0.3)


# =============================================================================
# THỰC THI KỸ NĂNG PHỤ 2 [E] (VAYNE / XIN ZHAO / GAREN / LUX)
# =============================================================================
func _execute_skill_e() -> void:
	match skill_e_id:
		"vayne_condemn_e":
			# Vayne [E] Kết Án: Bắn tên hạng nặng gây 115% AD, đẩy lùi mạnh (380) và làm choáng 1.2s (+100% AD nếu va tường/quái)
			var origin: Vector2 = (player as Node2D).global_position
			var target: Node2D = _find_nearest_enemy(400.0)
			var ad_val: float = _get_stat(StatModifier.StatType.AD, 18.0)
			if target != null:
				var push_dir: Vector2 = (target.global_position - origin).normalized()
				if push_dir.length_squared() < 0.01:
					push_dir = Vector2.RIGHT
				var base_dmg: float = ad_val * 1.15
				var predicted_pos: Vector2 = target.global_position + push_dir * 165.0
				var hit_wall: bool = (absf(predicted_pos.x) >= 675.0 or absf(predicted_pos.y) >= 385.0)
				if target.has_method("apply_knockback"):
					target.apply_knockback(push_dir * 380.0)
				if hit_wall:
					base_dmg += ad_val * 1.00
				if target.has_method("apply_stun"):
					target.apply_stun(1.2)
				_deal_skill_damage(target, base_dmg, hit_wall)
				_spawn_beam_vfx(origin, target.global_position, Color(0.95, 0.35, 0.45, 0.95), 8.0, 0.22)
			skill_activated.emit(skill_e_id, 0.3)

		"xinzhao_charge_e":
			# Xin Zhao [E] Can Trường: Lao tới mục tiêu trong tầm 260px, gây 110% AD + 60% AP xung kích 120px, làm chậm và +45% Tốc đánh
			var p2d := player as Node2D
			var target: Node2D = _find_nearest_enemy(265.0)
			var dash_pos: Vector2 = p2d.global_position + _get_aim_direction() * 160.0
			if target != null:
				dash_pos = target.global_position
			dash_pos.x = clampf(dash_pos.x, -745.0, 745.0)
			dash_pos.y = clampf(dash_pos.y, -445.0, 445.0)
			_spawn_beam_vfx(p2d.global_position, dash_pos, Color(1.0, 0.45, 0.25, 0.85), 10.0, 0.18)
			p2d.global_position = dash_pos

			var ad_val: float = _get_stat(StatModifier.StatType.AD, 22.0)
			var ap_val: float = _get_stat(StatModifier.StatType.AP, 0.0)
			var aoe_dmg: float = ad_val * 1.10 + ap_val * 0.60

			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e is Node2D and e.visible and not e.get("is_dead"):
					if dash_pos.distance_squared_to(e.global_position) <= 125.0 * 125.0:
						_deal_skill_damage(e, aoe_dmg, false)
						if e.has_method("apply_slow"):
							e.apply_slow(0.40, 2.0)

			if player.get("stats") != null:
				player.stats.remove_modifiers_from(SUB_BUFF_E_SOURCE)
				player.stats.add_modifier(SUB_BUFF_E_SOURCE, StatModifier.StatType.ATTACK_SPEED, 0.0, 0.45)
				_buff_e_remaining = 3.5

			_spawn_ring_vfx(dash_pos, 120.0, Color(1.0, 0.42, 0.22, 0.9), 0.25)
			skill_activated.emit(skill_e_id, 3.5)

		"garen_judgment_e":
			# Garen [E] Phán Quyết: Xoay đại kiếm quanh thân liên tục trong 3.0s (bán kính 155px)
			_garen_spin_remaining = 3.0
			_garen_spin_tick_timer = 0.0
			_create_garen_spin_vfx()
			skill_activated.emit(skill_e_id, 3.0)

		"lux_singularity_e":
			# Lux [E] Quả Cầu Ánh Sáng: Quăng cầu quang năng tới cụm địch trong tầm 280px, làm chậm 40% và nổ 185% AP AoE (130px)
			var origin: Vector2 = (player as Node2D).global_position
			var target: Node2D = _find_nearest_enemy(290.0)
			var center_pos: Vector2 = target.global_position if target != null else (origin + _get_aim_direction() * 210.0)
			var ap_val: float = _get_stat(StatModifier.StatType.AP, 35.0)
			var aoe_dmg: float = maxf(30.0, ap_val * 1.85)

			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e is Node2D and e.visible and not e.get("is_dead"):
					if center_pos.distance_squared_to(e.global_position) <= 135.0 * 135.0:
						if e.has_method("apply_slow"):
							e.apply_slow(0.40, 2.0)
						_deal_skill_damage(e, aoe_dmg, false)

			_spawn_ring_vfx(center_pos, 130.0, Color(0.88, 0.65, 1.0, 0.95), 0.35)
			skill_activated.emit(skill_e_id, 0.35)


# =============================================================================
# THỰC THI KỸ NĂNG CHÍNH [SPACE] (VAYNE / XIN ZHAO / GAREN / LUX)
# =============================================================================
func _execute_skill() -> void:
	_clear_active_buff()

	match skill_id:
		"ad_dash":
			# Vayne [SPACE] Giờ Khắc Cuối Cùng: Ẩn thân/Lướt ngắn + Tăng +35% AD, +50% Tốc đánh, +25% Tốc chạy trong 4.5s
			if player.has_method("perform_dash"):
				player.perform_dash(165.0, 0.16)
			if player.get("invulnerable_timer") != null:
				player.invulnerable_timer = maxf(player.invulnerable_timer, 0.8)
			if player.get("stats") != null:
				player.stats.add_modifier(SKILL_BUFF_SOURCE, StatModifier.StatType.AD, 0.0, 0.35)
				player.stats.add_modifier(SKILL_BUFF_SOURCE, StatModifier.StatType.ATTACK_SPEED, 0.0, 0.50)
				player.stats.add_modifier(SKILL_BUFF_SOURCE, StatModifier.StatType.MOVE_SPEED, 0.0, 0.25)
			is_buff_active = true
			buff_remaining = 4.5
			skill_activated.emit(skill_id, 4.5)

		"bruiser_war_cry":
			# Xin Zhao [SPACE] Bán Nguyệt Thương: Quét thương 180px gây 160% AD + 15% máu hiện tại, hất văng & nhận +35% Tốc chạy, +20% Hút máu trong 4s
			if player.get("stats") != null:
				player.stats.add_modifier(SKILL_BUFF_SOURCE, StatModifier.StatType.MOVE_SPEED, 0.0, 0.35)
				player.stats.add_modifier(SKILL_BUFF_SOURCE, StatModifier.StatType.LIFESTEAL, 0.20, 0.0)
			if player != null and player is Node2D:
				var origin: Vector2 = (player as Node2D).global_position
				var ad_val: float = _get_stat(StatModifier.StatType.AD, 22.0)
				var enemies := get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if e is Node2D and e.visible and not e.get("is_dead"):
						var to_e: Vector2 = e.global_position - origin
						if to_e.length_squared() <= 185.0 * 185.0:
							var cur_hp: float = float(e.get("current_hp")) if e.get("current_hp") != null else 50.0
							var sweep_dmg: float = ad_val * 1.60 + minf(750.0, cur_hp * 0.15)
							_deal_skill_damage(e, sweep_dmg, false)
							if e.has_method("apply_knockback"):
								e.apply_knockback(to_e.normalized() * 340.0)
				_spawn_ring_vfx(origin, 180.0, Color(1.0, 0.32, 0.28, 0.95), 0.35)
			if player.has_method("apply_camera_shake"):
				player.apply_camera_shake(5.0, 0.2)
			is_buff_active = true
			buff_remaining = 4.0
			skill_activated.emit(skill_id, 4.0)

		"tank_reflect_shield":
			# Garen [SPACE] Công Lý Demacia: Bật Khiên Dũng Cảm giảm 50% sát thương trong 4s + giáng Đại Kiếm Ánh Sáng kết liễu mục tiêu
			is_buff_active = true
			buff_remaining = 4.0
			trigger_shield_counter_damage(player)
			_cast_demacian_justice_sword()
			skill_activated.emit(skill_id, 4.0)

		"mage_firestorm":
			# Lux [SPACE] Cầu Vồng Tối Thượng: Phóng tia đại pháo ánh sáng dài 520px gây 300% AP (+25% nếu mục tiêu bị trói) + Vòng Quang Năng 3.5s
			is_buff_active = true
			buff_remaining = 3.5
			_firestorm_tick_timer = 0.0
			_cast_final_spark_laser()
			_create_firestorm_vfx()
			skill_activated.emit(skill_id, 3.5)

		_:
			if player.has_method("perform_dash"):
				player.perform_dash(160.0, 0.16)
			is_buff_active = true
			buff_remaining = 3.0
			skill_activated.emit(skill_id, 3.0)


func _cast_demacian_justice_sword() -> void:
	if player == null or not (player is Node2D):
		return
	var target: Node2D = _find_nearest_enemy(360.0)
	var strike_pos: Vector2 = target.global_position if target != null else (player as Node2D).global_position
	var ad_val: float = _get_stat(StatModifier.StatType.AD, 16.0)

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and e.visible and not e.get("is_dead"):
			if strike_pos.distance_squared_to(e.global_position) <= 165.0 * 165.0:
				var max_e: float = float(e.get("max_hp")) if e.get("max_hp") != null else 100.0
				var cur_e: float = float(e.get("current_hp")) if e.get("current_hp") != null else 50.0
				var missing_hp: float = maxf(0.0, max_e - cur_e)
				var justice_dmg: float = ad_val * 1.50 + minf(1200.0, missing_hp * 0.25)
				_deal_skill_damage(e, justice_dmg, true)

	_spawn_beam_vfx(strike_pos + Vector2(0, -260.0), strike_pos, Color(1.0, 0.92, 0.32, 0.98), 22.0, 0.38)
	_spawn_ring_vfx(strike_pos, 165.0, Color(1.0, 0.88, 0.28, 0.95), 0.38)
	if player.has_method("apply_camera_shake"):
		player.apply_camera_shake(7.5, 0.28)


func _cast_final_spark_laser() -> void:
	if player == null or not (player is Node2D):
		return
	var origin: Vector2 = (player as Node2D).global_position
	var aim_dir: Vector2 = _get_aim_direction()
	var ap_val: float = _get_stat(StatModifier.StatType.AP, 35.0)
	var base_laser_dmg: float = maxf(65.0, ap_val * 3.00)

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and e.visible and not e.get("is_dead"):
			var rel: Vector2 = e.global_position - origin
			var proj_len: float = rel.dot(aim_dir)
			if proj_len >= -20.0 and proj_len <= 525.0:
				var perp_dist: float = absf(rel.cross(aim_dir))
				if perp_dist <= 55.0:
					var final_dmg: float = base_laser_dmg
					if e.has_method("is_cc_marked") and e.is_cc_marked():
						final_dmg *= 1.25
					_deal_skill_damage(e, final_dmg, true)

	_spawn_beam_vfx(origin, origin + aim_dir * 520.0, Color(1.0, 0.95, 0.55, 0.98), 28.0, 0.35)
	if player.has_method("apply_camera_shake"):
		player.apply_camera_shake(6.5, 0.25)


func _process_garen_judgment(delta: float) -> void:
	_garen_spin_remaining -= delta
	if player != null and player is Node2D:
		var player_pos: Vector2 = (player as Node2D).global_position
		if _garen_spin_vfx != null and is_instance_valid(_garen_spin_vfx):
			_garen_spin_vfx.global_position = player_pos
			_garen_spin_vfx.rotation += 16.0 * delta

		_garen_spin_tick_timer -= delta
		if _garen_spin_tick_timer <= 0.0:
			_garen_spin_tick_timer = 0.35
			var ad_val: float = _get_stat(StatModifier.StatType.AD, 16.0)
			var armor_val: float = _get_stat(StatModifier.StatType.ARMOR, 18.0)
			var tick_dmg: float = ad_val * 0.45 + armor_val * 0.35
			var enemies := get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e is Node2D and e.visible and not e.get("is_dead"):
					if player_pos.distance_squared_to(e.global_position) <= 155.0 * 155.0:
						_deal_skill_damage(e, tick_dmg, false)

	if _garen_spin_remaining <= 0.0:
		if _garen_spin_vfx != null and is_instance_valid(_garen_spin_vfx):
			_garen_spin_vfx.queue_free()
			_garen_spin_vfx = null


func _create_garen_spin_vfx() -> void:
	if _garen_spin_vfx != null and is_instance_valid(_garen_spin_vfx):
		_garen_spin_vfx.queue_free()
	if get_tree() == null or get_tree().current_scene == null:
		return

	_garen_spin_vfx = Line2D.new()
	_garen_spin_vfx.width = 8.0
	_garen_spin_vfx.default_color = Color(0.95, 0.85, 0.28, 0.88)

	var pts := PackedVector2Array()
	var count: int = 24
	for i in range(count + 1):
		var ang: float = float(i) / float(count) * TAU
		pts.append(Vector2(cos(ang), sin(ang)) * 150.0)
	_garen_spin_vfx.points = pts

	if player != null and player is Node2D:
		_garen_spin_vfx.global_position = (player as Node2D).global_position
	get_tree().current_scene.add_child(_garen_spin_vfx)


func trigger_shield_counter_damage(origin: Node) -> void:
	if origin == null or not (origin is Node2D) or get_tree() == null:
		return
	var origin_pos: Vector2 = (origin as Node2D).global_position
	var p: Player = player as Player
	var counter_dmg: float = 35.0
	if p != null and p.stats != null:
		var max_hp: float = p.get_max_hp()
		var armor: float = p.stats.get_stat(StatModifier.StatType.ARMOR)
		counter_dmg = maxf(25.0, max_hp * 0.15 + armor * 2.0)

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and e.visible and not e.get("is_dead"):
			if origin_pos.distance_squared_to(e.global_position) <= 165.0 * 165.0:
				_deal_skill_damage(e, counter_dmg, false)


func _process_firestorm(delta: float) -> void:
	if player == null or not (player is Node2D) or get_tree() == null:
		return
	var player_pos: Vector2 = (player as Node2D).global_position

	if _firestorm_vfx != null and is_instance_valid(_firestorm_vfx):
		_firestorm_vfx.global_position = player_pos
		_firestorm_vfx.rotation += 8.0 * delta

	_firestorm_tick_timer -= delta
	if _firestorm_tick_timer <= 0.0:
		_firestorm_tick_timer = 0.25
		var ap_val: float = _get_stat(StatModifier.StatType.AP, 35.0)
		var tick_damage: float = maxf(8.0, 15.0 + ap_val * 0.30)

		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e is Node2D and e.visible and not e.get("is_dead"):
				if player_pos.distance_squared_to(e.global_position) <= 145.0 * 145.0:
					_deal_skill_damage(e, tick_damage, false)


func _create_firestorm_vfx() -> void:
	if _firestorm_vfx != null and is_instance_valid(_firestorm_vfx):
		_firestorm_vfx.queue_free()
	if get_tree() == null or get_tree().current_scene == null:
		return

	_firestorm_vfx = Line2D.new()
	_firestorm_vfx.width = 6.0
	_firestorm_vfx.default_color = Color(1.0, 0.85, 0.32, 0.85)

	var pts := PackedVector2Array()
	var count: int = 24
	for i in range(count + 1):
		var ang: float = float(i) / float(count) * TAU
		pts.append(Vector2(cos(ang), sin(ang)) * 135.0)
	_firestorm_vfx.points = pts

	if player != null and player is Node2D:
		_firestorm_vfx.global_position = (player as Node2D).global_position
	get_tree().current_scene.add_child(_firestorm_vfx)


func _get_stat(stat_type: int, fallback: float) -> float:
	if player != null and player.get("stats") != null:
		return player.stats.get_stat(stat_type)
	return fallback


func _find_nearest_enemy(max_range: float) -> Node2D:
	if player == null or not (player is Node2D) or get_tree() == null:
		return null
	var origin: Vector2 = (player as Node2D).global_position
	var best: Node2D = null
	var best_d2: float = max_range * max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and e.visible and not e.get("is_dead"):
			var d2: float = origin.distance_squared_to(e.global_position)
			if d2 <= best_d2:
				best_d2 = d2
				best = e
	return best


func _get_aim_direction() -> Vector2:
	var nearest: Node2D = _find_nearest_enemy(520.0)
	if nearest != null and player is Node2D:
		var dir: Vector2 = nearest.global_position - (player as Node2D).global_position
		if dir.length_squared() > 0.01:
			return dir.normalized()
	if player != null and player.get("weapon_controller") != null:
		var wc: Node2D = player.weapon_controller
		return Vector2.RIGHT.rotated(wc.rotation)
	return Vector2.RIGHT


func _deal_skill_damage(target: Node, dmg: float, is_crit: bool = false) -> void:
	if target == null or dmg <= 0.0:
		return
	if target.has_method("take_damage"):
		target.take_damage(dmg, is_crit)
	CombatEvents.hit.emit(target, dmg, is_crit)


func _spawn_beam_vfx(from_pos: Vector2, to_pos: Vector2, col: Color, width: float, duration: float) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var line := Line2D.new()
	line.width = width
	line.default_color = col
	line.points = PackedVector2Array([from_pos, to_pos])
	get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, duration)
	tw.tween_callback(line.queue_free)


func _spawn_ring_vfx(center: Vector2, radius: float, col: Color, duration: float) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = col
	var pts := PackedVector2Array()
	var segs: int = 24
	for i in range(segs + 1):
		var a: float = (float(i) / float(segs)) * TAU
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	ring.points = pts
	get_tree().current_scene.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, duration)
	tw.tween_callback(ring.queue_free)


func _clear_sub_buffs() -> void:
	if player != null and player.get("stats") != null:
		player.stats.remove_modifiers_from(SUB_BUFF_Q_SOURCE)
		player.stats.remove_modifiers_from(SUB_BUFF_E_SOURCE)
	_buff_q_remaining = 0.0
	_buff_e_remaining = 0.0
	_garen_spin_remaining = 0.0
	if _garen_spin_vfx != null and is_instance_valid(_garen_spin_vfx):
		_garen_spin_vfx.queue_free()
		_garen_spin_vfx = null


func _clear_active_buff() -> void:
	if is_buff_active and player != null and player.get("stats") != null:
		player.stats.remove_modifiers_from(SKILL_BUFF_SOURCE)
	is_buff_active = false
	buff_remaining = 0.0
	if _firestorm_vfx != null and is_instance_valid(_firestorm_vfx):
		_firestorm_vfx.queue_free()
		_firestorm_vfx = null
