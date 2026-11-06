extends Node
## Bộ quản trị Âm thanh Nội sinh Tự sinh (Procedural Audio Synthesizer - Autoload: AudioManager)
## Tạo các hiệu ứng âm thanh 8-bit / Arcade trực tiếp bằng mã nguồn thông qua AudioStreamWAV PCM,
## loại bỏ hoàn toàn rủi ro thiếu tệp âm thanh bên ngoài và mang lại âm hưởng sống động.

var _sfx_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

var snd_shoot: AudioStreamWAV
var snd_hit: AudioStreamWAV
var snd_crit: AudioStreamWAV
var snd_kill: AudioStreamWAV
var snd_gold: AudioStreamWAV
var snd_buy: AudioStreamWAV
var snd_boss_alarm: AudioStreamWAV
var snd_explosion: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_sfx_pool()
	_generate_all_sounds()
	_connect_events()


func _create_sfx_pool() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)


func _get_available_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


func play_sfx(stream: AudioStreamWAV, volume_db: float = -6.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_buy() -> void:
	play_sfx(snd_buy, -6.0, randf_range(0.96, 1.06))


func play_explosion() -> void:
	play_sfx(snd_explosion, -4.0, randf_range(0.92, 1.05))


func play_shoot() -> void:
	play_sfx(snd_shoot, -10.0, randf_range(0.92, 1.08))


func play_hit() -> void:
	play_sfx(snd_hit, -12.0, randf_range(0.9, 1.1))


func play_crit() -> void:
	play_sfx(snd_crit, -6.0, randf_range(0.95, 1.15))


func play_kill() -> void:
	play_sfx(snd_kill, -8.0, randf_range(0.9, 1.1))


func play_gold() -> void:
	play_sfx(snd_gold, -10.0, randf_range(0.98, 1.05))


func play_boss_siren() -> void:
	play_sfx(snd_boss_alarm, -4.0, 1.0)


func _connect_events() -> void:
	CombatEvents.attack.connect(func(_w, _p): play_sfx(snd_shoot, -10.0, randf_range(0.92, 1.08)))
	CombatEvents.hit.connect(func(_t, _d, is_crit):
		if is_crit:
			play_sfx(snd_crit, -6.0, randf_range(0.95, 1.15))
		else:
			play_sfx(snd_hit, -12.0, randf_range(0.9, 1.1))
	)
	CombatEvents.kill.connect(func(_e): play_sfx(snd_kill, -8.0, randf_range(0.9, 1.1)))
	CombatEvents.gold_changed.connect(func(_g): play_sfx(snd_gold, -10.0, randf_range(0.98, 1.05)))
	CombatEvents.boss_spawned.connect(func(_b): play_sfx(snd_boss_alarm, -4.0, 1.0))
	CombatEvents.boss_defeated.connect(func(): play_sfx(snd_explosion, -2.0, 0.9))


func _generate_all_sounds() -> void:
	snd_shoot = _gen_sweep_sound(650.0, 180.0, 0.08, 0.7, 0)
	snd_hit = _gen_noise_burst(0.05, 0.5)
	snd_crit = _gen_arpeggio([587.33, 880.0, 1174.66], 0.12, 0.8)
	snd_kill = _gen_sweep_sound(240.0, 60.0, 0.15, 0.8, 1)
	snd_gold = _gen_arpeggio([987.77, 1318.51], 0.10, 0.7)
	snd_buy = _gen_arpeggio([523.25, 659.25, 783.99, 1046.50], 0.16, 0.75)
	snd_boss_alarm = _gen_alarm_siren(320.0, 680.0, 0.65, 0.9)
	snd_explosion = _gen_noise_burst(0.55, 1.0, true)


## Sinh âm thanh lướt tần số (Sweep - Bắn súng, Quái chết)
func _gen_sweep_sound(start_freq: float, end_freq: float, duration: float, volume: float = 0.8, wave_type: int = 0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += 2.0 * PI * freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI

		var sample: float = 0.0
		if wave_type == 0: # Square wave
			sample = 1.0 if phase < PI else -1.0
		else: # Sine wave
			sample = sin(phase)

		var env: float = 1.0 - t
		var val_8bit: int = clampi(int(128.0 + sample * env * volume * 120.0), 0, 255)
		data[i] = val_8bit

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


## Sinh âm thanh Hợp âm / Leng keng (Arpeggio - Vàng, Chí mạng, Mua đồ)
func _gen_arpeggio(notes: Array[float], duration: float, volume: float = 0.8) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples)

	var note_count: int = notes.size()
	var samples_per_note: int = total_samples / note_count
	var phase: float = 0.0

	for i in range(total_samples):
		var note_idx: int = mini(i / samples_per_note, note_count - 1)
		var freq: float = notes[note_idx]
		phase += 2.0 * PI * freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI

		var t_in_note: float = float(i % samples_per_note) / float(samples_per_note)
		var env: float = (1.0 - t_in_note) * (1.0 - float(i) / float(total_samples) * 0.4)
		var sample: float = sin(phase)
		var val_8bit: int = clampi(int(128.0 + sample * env * volume * 120.0), 0, 255)
		data[i] = val_8bit

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


## Sinh tiếng ồn va chạm / Tiếng nổ (Noise Burst - Hit, Explosion)
func _gen_noise_burst(duration: float, volume: float = 0.8, is_explosion: bool = false) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples)

	var last_val: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var noise: float = randf_range(-1.0, 1.0)
		if is_explosion:
			# Bộ lọc thông thấp (Low-pass) cho tiếng nổ trầm hùng
			last_val = lerpf(last_val, noise, 0.12)
			noise = last_val
		var env: float = pow(1.0 - t, 1.8 if is_explosion else 2.5)
		var val_8bit: int = clampi(int(128.0 + noise * env * volume * 120.0), 0, 255)
		data[i] = val_8bit

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


## Sinh tiếng còi cảnh báo Trùm (Alarm Siren)
func _gen_alarm_siren(low_freq: float, high_freq: float, duration: float, volume: float = 0.8) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(total_samples)

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		# Tần số dao động hình sin lên xuống 2 chu kỳ
		var mod: float = (sin(t * 4.0 * PI) + 1.0) * 0.5
		var freq: float = lerpf(low_freq, high_freq, mod)
		phase += 2.0 * PI * freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI

		var sample: float = 1.0 if phase < PI else -1.0 # Square
		var env: float = sin(t * PI)
		var val_8bit: int = clampi(int(128.0 + sample * env * volume * 120.0), 0, 255)
		data[i] = val_8bit

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
