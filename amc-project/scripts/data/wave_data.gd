class_name WaveData
extends Resource
## Dữ liệu cấu hình từng Đợt đấu (Wave 1..5, Wave 6 Chuẩn bị, Wave 7 Final Boss)

@export var wave_index: int = 1
@export var wave_title: String = "ĐỢT 1"
@export var duration: float = 45.0
@export var spawn_interval: float = 1.15
@export var max_alive_enemies: int = 40
@export var hp_scale: float = 1.0
@export var gold_multiplier: float = 1.0
@export var is_prep_wave: bool = false
@export var is_boss_wave: bool = false

@export_group("Enemy Spawn Weights")
@export var basic_weight: float = 65.0
@export var fast_weight: float = 15.0
@export var ranged_weight: float = 12.0
@export var cannon_weight: float = 8.0


static func create_default_wave(idx: int) -> WaveData:
	var w := WaveData.new()
	w.wave_index = idx
	if idx <= 5:
		w.wave_title = "ĐỢT %d / 7" % idx
		w.duration = 45.0
		w.spawn_interval = maxf(0.26, 0.70 - float(idx - 1) * 0.10)
		w.max_alive_enemies = mini(95, 42 + (idx - 1) * 10)
		# Quái khỏe gấp đôi hiện tại và tăng tuyến tính theo từng đợt (+0.5 mỗi đợt, không nhân cấp số nhân)
		w.hp_scale = 2.0 + 0.50 * float(idx - 1)
		w.gold_multiplier = 1.0
		w.basic_weight = maxf(35.0, 72.0 - float(idx - 1) * 8.0)
		w.fast_weight = 12.0 + float(idx - 1) * 4.0
		w.ranged_weight = 10.0 + float(idx - 1) * 4.0
		w.cannon_weight = 6.0 + float(idx - 1) * 3.0
	elif idx == 6:
		w.wave_title = "ĐỢT 6: CHUẨN BỊ (VÀNG x2)"
		w.duration = 35.0
		w.spawn_interval = 0.22
		w.max_alive_enemies = 75
		w.hp_scale = 1.30
		w.gold_multiplier = 2.0
		w.is_prep_wave = true
		w.basic_weight = 42.0
		w.fast_weight = 26.0
		w.ranged_weight = 16.0
		w.cannon_weight = 16.0
	else:
		w.wave_title = "ĐỢT 7: CHIẾN HẠM TRÙM CUỐI"
		w.duration = 999.0
		w.spawn_interval = 2.2
		w.max_alive_enemies = 24
		w.hp_scale = 1.8
		w.gold_multiplier = 1.0
		w.is_boss_wave = true
	return w

