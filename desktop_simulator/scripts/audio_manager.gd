extends Node

var audio_pool: Array = []
var sound_enabled: bool = true

var hit_stream: AudioStreamWAV
var heavy_hit_stream: AudioStreamWAV
var bow_shoot_stream: AudioStreamWAV
var sword_slash_stream: AudioStreamWAV
var horn_stream: AudioStreamWAV
var win_stream: AudioStreamWAV
var ult_cast_stream: AudioStreamWAV
var explosion_stream: AudioStreamWAV
var emp_stream: AudioStreamWAV
var whirlwind_stream: AudioStreamWAV
var block_stream: AudioStreamWAV
var gunshot_stream: AudioStreamWAV

func _ready() -> void:
	for i in range(28):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_pool.append(p)
		
	hit_stream = generate_punch_wav(false)
	heavy_hit_stream = generate_punch_wav(true)
	bow_shoot_stream = generate_bow_wav()
	sword_slash_stream = generate_sword_wav()
	horn_stream = generate_horn_wav()
	win_stream = generate_win_wav()
	ult_cast_stream = generate_ult_wav()
	explosion_stream = generate_explosion_wav()
	emp_stream = generate_emp_wav()
	whirlwind_stream = generate_whirlwind_wav()
	block_stream = generate_block_wav()
	gunshot_stream = generate_gunshot_wav()

func toggle_sound() -> bool:
	sound_enabled = not sound_enabled
	return sound_enabled

func play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sound_enabled or stream == null:
		return
		
	for p in audio_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
			
	var p0: AudioStreamPlayer = audio_pool[0]
	p0.stream = stream
	p0.volume_db = volume_db
	p0.pitch_scale = pitch
	p0.play()

var last_sound_times: Dictionary = {}

func play_debounced(id: String, stream: AudioStreamWAV, min_interval: float, vol: float, pitch: float) -> void:
	var now = Time.get_ticks_msec() * 0.001
	if last_sound_times.has(id) and (now - float(last_sound_times[id])) < min_interval:
		return
	last_sound_times[id] = now
	play_stream(stream, vol, pitch)

func play_hit(is_heavy: bool = false) -> void:
	var pitch = 0.95 + (randf() - 0.5) * 0.25
	var vol = -4.0 if not is_heavy else -1.0
	play_debounced("hit_heavy" if is_heavy else "hit", heavy_hit_stream if is_heavy else hit_stream, 0.038, vol, pitch)

func play_bow_shoot() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.2
	play_debounced("bow", bow_shoot_stream, 0.05, -3.0, pitch)

func play_sword_slash() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.25
	play_debounced("sword", sword_slash_stream, 0.038, -2.5, pitch)

func play_horn() -> void:
	play_stream(horn_stream, 0.0, 1.0)

func play_victory() -> void:
	play_stream(win_stream, 1.0, 1.0)

func play_ult_cast() -> void:
	var pitch = 0.95 + (randf() - 0.5) * 0.15
	play_debounced("ult_cast", ult_cast_stream, 0.1, 2.0, pitch)

func play_explosion(is_giant: bool = false) -> void:
	var pitch = 0.85 + (randf() - 0.5) * 0.2
	var vol = 3.0 if is_giant else 1.0
	play_debounced("expl", explosion_stream, 0.08, vol, pitch)

func play_emp() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.15
	play_debounced("emp", emp_stream, 0.1, 1.5, pitch)

func play_whirlwind() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.2
	play_debounced("whirl", whirlwind_stream, 0.1, 0.5, pitch)

func play_block() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.2
	play_debounced("block", block_stream, 0.05, 1.5, pitch)

func play_gunshot() -> void:
	var pitch = 1.0 + (randf() - 0.5) * 0.15
	play_debounced("gun", gunshot_stream, 0.035, 0.0, pitch)

func generate_bow_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.24)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 16.0)
		var freq = 340.0 * exp(-t * 22.0) + 120.0
		var wave = sin(t * freq * TAU) + (randf() - 0.5) * 0.3 * exp(-t * 30.0)
		var sample_val = int(clamp(wave * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_sword_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.22)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 14.0)
		var freq = 900.0 - t * 2500.0 + (randf() - 0.5) * 200.0
		var wave = sin(t * freq * TAU) * 0.7 + (randf() - 0.5) * 0.5
		var sample_val = int(clamp(wave * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_punch_wav(is_heavy: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.22 if not is_heavy else 0.35
	var samples_count = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * (18.0 if not is_heavy else 10.0))
		var base_freq = 95.0 * (1.0 - t * 3.5) if not is_heavy else 65.0 * (1.0 - t * 2.5)
		var sub = sin(t * base_freq * TAU)
		var noise = (randf() - 0.5) * exp(-t * 45.0) * 0.8
		var wave = sub * 0.7 + noise
		var sample_val = int(clamp(wave * env * 28000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_horn_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 1.6)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = sin(clamp(t / 1.6, 0.0, 1.0) * PI)
		var freq = 145.0 + sin(t * 4.0) * 3.0
		var wave = sin(t * freq * TAU) + 0.6 * sin(t * freq * 2.0 * TAU) + 0.3 * sin(t * freq * 3.0 * TAU)
		var sample_val = int(clamp(wave * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_win_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 2.0)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var note_freq = 261.63
		if t > 0.4:
			note_freq = 329.63
		if t > 0.8:
			note_freq = 392.00
		if t > 1.2:
			note_freq = 523.25
			
		var env = exp(-fmod(t, 0.4) * 4.0)
		if t > 1.2:
			env = exp(-(t - 1.2) * 1.5)
			
		var wave = sin(t * note_freq * TAU) + 0.35 * sin(t * note_freq * 2.0 * TAU)
		var sample_val = int(clamp(wave * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_ult_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.7)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var progress = t / 0.7
		var freq = 120.0 + pow(progress, 2.2) * 650.0
		var env = sin(progress * PI)
		var wave = sin(t * freq * TAU) * 0.7 + 0.3 * sin(t * freq * 2.0 * TAU)
		# Add harmonic shimmering
		wave += sin(t * freq * 3.0 * TAU) * 0.15
		var sample_val = int(clamp(wave * env * 26000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_explosion_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.85)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 5.5)
		var sub_bass = sin(t * (60.0 - t * 35.0) * TAU)
		var noise = (randf() - 0.5) * 2.0 * exp(-t * 8.0)
		var wave = sub_bass * 0.65 + noise * 0.75
		var sample_val = int(clamp(wave * env * 30000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_emp_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.65)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 6.0)
		var freq = 1200.0 - t * 1400.0 + sin(t * 120.0) * 80.0
		var wave = sin(t * freq * TAU) + (randf() - 0.5) * 0.4
		var sample_val = int(clamp(wave * env * 25000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_whirlwind_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.75)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = sin(clamp(t / 0.75, 0.0, 1.0) * PI)
		var mod = sin(t * 22.0 * TAU) * 0.5 + 0.5
		var noise = (randf() - 0.5) * 2.0
		var wave = noise * mod
		var sample_val = int(clamp(wave * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_block_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.25)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 24.0)
		var tone1 = sin(t * 1450.0 * TAU) * 0.6
		var tone2 = sin(t * 2280.0 * TAU) * 0.4
		var clang = (tone1 + tone2) * 0.7 + (randf() - 0.5) * exp(-t * 60.0) * 0.6
		var sample_val = int(clamp(clang * env * 28000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_gunshot_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var samples_count = int(22050 * 0.18)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 28.0)
		var crack = (randf() - 0.5) * 2.0 * exp(-t * 40.0)
		var body = sin(t * 180.0 * TAU * (1.0 - t * 4.0)) * 0.5
		var wave = crack * 0.8 + body * 0.4
		var sample_val = int(clamp(wave * env * 29000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav


