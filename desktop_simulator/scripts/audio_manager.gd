extends Node

# Audio pool for non-blocking simultaneous sound playback
var audio_pool: Array[AudioStreamPlayer] = []
var sound_enabled: bool = true

# Dedicated Background Music (BGM) player
var bgm_player: AudioStreamPlayer = null

# Custom User Assets
var sound_voice_kubu_1: AudioStream = null  # jokowi-saya-akan-lawan.mp3
var sound_voice_kubu_2: AudioStream = null  # hey-antek-antek-asing-prabowo.mp3
var sound_mage_kubu_1: AudioStream = null   # serangan kubu 1.mp3 (Khusus Kelas Mage Kubu 1)
var sound_mage_kubu_2: AudioStream = null   # serangan kubu 2.mp3 (Khusus Kelas Mage Kubu 2)
var sound_kereta: AudioStream = null        # kereta.mp3 (Super Ulti Kubu A)
var sound_tsunami: AudioStream = null       # tsunami.mp3 (Super Ulti Kubu B)
var sound_background: AudioStream = null    # baclround sound.mp3 (Background Sound BGM)

# Compatibility aliases
var sound_attack_kubu_1: AudioStream:
	get: return sound_mage_kubu_1
	set(v): sound_mage_kubu_1 = v
var sound_attack_kubu_2: AudioStream:
	get: return sound_mage_kubu_2
	set(v): sound_mage_kubu_2 = v
var super_ult_a_voice: AudioStream:
	get: return sound_voice_kubu_1
	set(v): sound_voice_kubu_1 = v
var super_ult_b_voice: AudioStream:
	get: return sound_voice_kubu_2
	set(v): sound_voice_kubu_2 = v
var super_ult_a_attack: AudioStream:
	get: return sound_kereta
	set(v): sound_kereta = v
var super_ult_b_attack: AudioStream:
	get: return sound_tsunami
	set(v): sound_tsunami = v

# Clean, organic non-metallic combat sounds for non-mage classes
var hit_stream: AudioStreamWAV = null
var heavy_hit_stream: AudioStreamWAV = null
var bow_shoot_stream: AudioStreamWAV = null
var sword_slash_stream: AudioStreamWAV = null
var gunshot_stream: AudioStreamWAV = null

# Synthetic ambient drones & tin can sounds are strictly eliminated
var block_stream: AudioStream = null
var super_ult_whoosh_stream: AudioStream = null
var super_ult_tsunami_stream: AudioStream = null
var horn_stream: AudioStream = null
var win_stream: AudioStream = null
var ult_cast_stream: AudioStream = null
var explosion_stream: AudioStream = null
var emp_stream: AudioStream = null
var whirlwind_stream: AudioStream = null

var is_super_ult_active: bool = false
var super_ult_active_timer: float = 0.0
var last_sound_times: Dictionary = {}

func set_super_ult_active(active: bool) -> void:
	is_super_ult_active = active
	if active:
		super_ult_active_timer = 15.0 # Safety timeout in seconds
		# Pause background sound during super ult cutscene / animation so voice and SFX are crystal clear
		if bgm_player and bgm_player.playing:
			bgm_player.stop()
		# Cut off all playing combat sounds
		for p in audio_pool:
			if is_instance_valid(p) and p.playing:
				# Keep only the custom leader voice or super ult SFX
				if p.stream != sound_voice_kubu_1 and p.stream != sound_voice_kubu_2 and p.stream != sound_kereta and p.stream != sound_tsunami:
					p.stop()
	else:
		super_ult_active_timer = 0.0
		# Resume background sound when super ult finishes
		if sound_enabled and sound_background != null and bgm_player != null and not bgm_player.playing:
			bgm_player.play()

func _process(delta: float) -> void:
	if is_super_ult_active:
		super_ult_active_timer -= delta
		if super_ult_active_timer <= 0.0:
			set_super_ult_active(false)

func _ready() -> void:
	# Dedicated BGM / Background sound player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)
	
	for i in range(32):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_pool.append(p)
		
	# Generate clean organic, non-metallic physical sounds
	sword_slash_stream = generate_clean_air_slash_wav()
	hit_stream = generate_clean_punch_wav(false)
	heavy_hit_stream = generate_clean_punch_wav(true)
	gunshot_stream = generate_clean_gunshot_wav()
	bow_shoot_stream = generate_clean_bow_wav()
	
	load_user_audio_assets()

func load_user_audio_assets() -> void:
	var candidate_dirs: Array[String] = [
		"res://sounds",
		ProjectSettings.globalize_path("res://sounds").simplify_path(),
		ProjectSettings.globalize_path("res://").path_join("../custom_models").simplify_path(),
		ProjectSettings.globalize_path("res://custom_models").simplify_path(),
		OS.get_executable_path().get_base_dir().path_join("../custom_models").simplify_path(),
		OS.get_executable_path().get_base_dir().path_join("custom_models").simplify_path(),
		"custom_models"
	]
	
	# 1. Voice / Super Ult Kubu 1
	sound_voice_kubu_1 = find_and_load_audio_file([
		"jokowi-saya-akan-lawan.mp3",
		"saya-akan-lawan.mp3",
		"super_ult_a.mp3"
	], candidate_dirs)
	
	# 2. Voice / Super Ult Kubu 2
	sound_voice_kubu_2 = find_and_load_audio_file([
		"hey-antek-antek-asing-prabowo.mp3",
		"antek-antek-asing.mp3",
		"super_ult_b.mp3"
	], candidate_dirs)
	
	# 3. Mage Attack Sound Kubu 1
	sound_mage_kubu_1 = find_and_load_audio_file([
		"serangan kubu 1.mp3",
		"serangan_kubu_1.mp3",
		"serangankubu1.mp3",
		"serangan_a.mp3"
	], candidate_dirs)
	
	# 4. Mage Attack Sound Kubu 2
	sound_mage_kubu_2 = find_and_load_audio_file([
		"serangan kubu 2.mp3",
		"serangan_kubu_2.mp3",
		"serangankubu2.mp3",
		"serangan_b.mp3"
	], candidate_dirs)
	
	# 5. Super Ulti Kubu A SFX (kereta.mp3)
	sound_kereta = find_and_load_audio_file([
		"kereta.mp3",
		"kereta.wav",
		"whoosh.mp3"
	], candidate_dirs)
	
	# 6. Super Ulti Kubu B SFX (tsunami.mp3)
	sound_tsunami = find_and_load_audio_file([
		"tsunami.mp3",
		"tsunami.wav",
		"sawit.mp3"
	], candidate_dirs)
	
	# 7. Background Sound (baclround sound.mp3)
	sound_background = find_and_load_audio_file([
		"baclround sound.mp3",
		"background sound.mp3",
		"background_sound.mp3",
		"baclround_sound.mp3",
		"bgm.mp3"
	], candidate_dirs)
	
	start_background_music()

func start_background_music() -> void:
	if sound_background and sound_enabled and bgm_player:
		bgm_player.stream = sound_background
		bgm_player.volume_db = -5.0 # Comfortable ambient level
		if not bgm_player.playing:
			bgm_player.play()

func _on_bgm_finished() -> void:
	if sound_enabled and not is_super_ult_active and bgm_player and sound_background:
		bgm_player.play()

func find_and_load_audio_file(file_names: Array[String], candidate_dirs: Array[String]) -> AudioStream:
	for fname in file_names:
		# 1. Check ResourceLoader
		var res_p = "res://sounds/" + fname
		if ResourceLoader.exists(res_p):
			var res = load(res_p)
			if res is AudioStream:
				return res
				
		# 2. Check candidate directories directly
		for cdir in candidate_dirs:
			var full_path = cdir.path_join(fname).replace("\\", "/")
			if FileAccess.file_exists(full_path):
				var f = FileAccess.open(full_path, FileAccess.READ)
				if f:
					var buf = f.get_buffer(f.get_length())
					if fname.ends_with(".mp3"):
						var s = AudioStreamMP3.new()
						s.data = buf
						return s
					elif fname.ends_with(".wav"):
						var s = AudioStreamWAV.new()
						s.data = buf
						return s
	return null

func toggle_sound() -> bool:
	sound_enabled = not sound_enabled
	if not sound_enabled:
		if bgm_player:
			bgm_player.stop()
		for p in audio_pool:
			if is_instance_valid(p):
				p.stop()
	else:
		if bgm_player and sound_background:
			bgm_player.play()
	return sound_enabled

func play_stream(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
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

func play_debounced(id: String, stream: AudioStream, min_interval: float, vol: float, pitch: float) -> void:
	var now = Time.get_ticks_msec() * 0.001
	if last_sound_times.has(id) and (now - float(last_sound_times[id])) < min_interval:
		return
	last_sound_times[id] = now
	play_stream(stream, vol, pitch)

# ==============================================================================
# SUPER ULTIMATE SOUNDS (HANYA kereta.mp3 UNTUK KUBU A & tsunami.mp3 UNTUK KUBU B)
# ==============================================================================
func play_super_ult_a_voice() -> void:
	if sound_kereta:
		play_stream(sound_kereta, 4.0, 1.0)

func play_super_ult_b_voice() -> void:
	if sound_tsunami:
		play_stream(sound_tsunami, 4.0, 1.0)

func play_super_ult_a() -> void:
	# Super Ulti Kubu A: HANYA kereta.mp3 doang!
	if sound_kereta:
		play_stream(sound_kereta, 4.0, 1.0)

func play_super_ult_b() -> void:
	# Super Ulti Kubu B: HANYA tsunami.mp3 doang!
	if sound_tsunami:
		play_stream(sound_tsunami, 4.0, 1.0)

# ==============================================================================
# MAGE ATTACK SOUNDS (KHUSUS KELAS MAGE: serangan kubu 1 & serangan kubu 2)
# ==============================================================================
func play_mage_attack(p_team: int) -> void:
	if is_super_ult_active or not sound_enabled:
		return
	if p_team == 0 and sound_mage_kubu_1:
		var pitch = 1.0 + (randf() - 0.5) * 0.08
		play_debounced("mage_attack_a", sound_mage_kubu_1, 0.09, 1.0, pitch)
	elif p_team == 1 and sound_mage_kubu_2:
		var pitch = 1.0 + (randf() - 0.5) * 0.08
		play_debounced("mage_attack_b", sound_mage_kubu_2, 0.12, 1.0, pitch)

func play_attack_team_a() -> void:
	play_mage_attack(0)

func play_attack_team_b() -> void:
	play_mage_attack(1)

func play_serangan_kubu_1() -> void:
	play_mage_attack(0)

func play_serangan_kubu_2() -> void:
	play_mage_attack(1)

# ==============================================================================
# CLASS-AWARE COMBAT ATTACK DISPATCHER
# ==============================================================================
func play_unit_attack(p_team: int, p_weapon_type: String = "", is_heavy: bool = false) -> void:
	if is_super_ult_active or not sound_enabled:
		return
		
	# 1. KELAS MAGE -> Khusus memainkan MP3 serangan kubu 1 & serangan kubu 2
	if p_weapon_type.begins_with("staff_") or p_weapon_type.begins_with("mage_"):
		play_mage_attack(p_team)
		return
		
	# 2. KELAS NON-MAGE -> Suara fisik natural organik (Bukan suara mage & bukan suara kaleng!)
	match p_weapon_type:
		"rifle":
			play_gunshot()
		"bow":
			play_bow_shoot()
		"sword_shield", "spear":
			play_sword_slash()
		_:
			play_hit(is_heavy)

func play_gunshot(_p_team: int = -1) -> void:
	if is_super_ult_active or not sound_enabled or gunshot_stream == null:
		return
	var pitch = 1.0 + (randf() - 0.5) * 0.14
	play_debounced("gun", gunshot_stream, 0.038, -1.0, pitch)

func play_bow_shoot(_p_team: int = -1) -> void:
	if is_super_ult_active or not sound_enabled or bow_shoot_stream == null:
		return
	var pitch = 1.0 + (randf() - 0.5) * 0.18
	play_debounced("bow", bow_shoot_stream, 0.05, -3.0, pitch)

func play_sword_slash(_p_team: int = -1) -> void:
	if is_super_ult_active or not sound_enabled or sword_slash_stream == null:
		return
	var pitch = 1.0 + (randf() - 0.5) * 0.2
	play_debounced("sword", sword_slash_stream, 0.04, -2.5, pitch)

func play_hit(is_heavy: bool = false, _p_team: int = -1) -> void:
	if is_super_ult_active or not sound_enabled:
		return
	var stream = heavy_hit_stream if is_heavy else hit_stream
	if stream == null:
		return
	var pitch = 1.0 + (randf() - 0.5) * 0.2
	var vol = -2.5 if not is_heavy else 0.0
	play_debounced("hit_heavy" if is_heavy else "hit", stream, 0.04, vol, pitch)

# ==============================================================================
# ELIMINATED / SILENT CALLS (TIDAK ADA SUARA KALENG)
# ==============================================================================
func play_block() -> void:
	# Dihapus / sunyi total: Menghilangkan suara berdenting mirip kaleng!
	pass

func play_ult_cast() -> void:
	pass

func play_horn() -> void:
	pass

func play_victory() -> void:
	pass

func play_explosion(_is_giant: bool = false) -> void:
	pass

func play_emp() -> void:
	pass

func play_whirlwind() -> void:
	pass

# ==============================================================================
# PROCEDURAL NATURAL SOUND SYNTHESIZERS (ORGANIK, NON-METALLIC, NO CLANG)
# ==============================================================================
func generate_clean_air_slash_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.16
	var samples_count = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var lp: float = 0.0
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = sin(clamp(t / duration, 0.0, 1.0) * PI)
		var noise = (randf() - 0.5) * 2.0
		lp = lerp(lp, noise, 0.18)
		var sample_val = int(clamp(lp * env * 19000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_clean_punch_wav(is_heavy: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.15 if not is_heavy else 0.22
	var samples_count = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * (24.0 if not is_heavy else 16.0))
		var thud = sin(t * 68.0 * TAU * (1.0 - t * 2.0)) * 0.85
		var impact = (randf() - 0.5) * exp(-t * 90.0) * 0.35
		var sample_val = int(clamp((thud + impact) * env * 24000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_clean_gunshot_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.12
	var samples_count = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 30.0)
		var crack = (randf() - 0.5) * exp(-t * 95.0) * 1.1
		var sub = sin(t * 88.0 * TAU) * 0.65
		var sample_val = int(clamp((crack + sub) * env * 25000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav

func generate_clean_bow_wav() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var duration = 0.14
	var samples_count = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 22.0)
		var twang = sin(t * 180.0 * TAU) * 0.7
		var whoosh = (randf() - 0.5) * exp(-t * 45.0) * 0.4
		var sample_val = int(clamp((twang + whoosh) * env * 21000.0, -32000.0, 32000.0))
		data.encode_s16(i * 2, sample_val)
		
	wav.data = data
	return wav
