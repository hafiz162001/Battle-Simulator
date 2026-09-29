extends CanvasLayer

const CharacterData = preload("res://scripts/character_data.gd")
const BattleUnit = preload("res://scripts/unit.gd")

@onready var manager: Node3D = $"../BattleManager"
@onready var camera: Camera3D = $"../Camera3D"
@onready var audio_mgr: Node = $"../AudioManager"

var ult_a_btn: Button = null
var ult_b_btn: Button = null
var super_ult_btn: Button = null

var video_modal: Control = null
var video_player: VideoStreamPlayer = null
var is_cutscene_playing: bool = false
var cutscene_team: int = 0

# Top HUD
@onready var name_a_label: Label = $TopHeader/ScoreBox/Margin/HBox/TeamA/NameA
@onready var count_a_label: Label = $TopHeader/ScoreBox/Margin/HBox/TeamA/CountA
@onready var name_b_label: Label = $TopHeader/ScoreBox/Margin/HBox/TeamB/NameB
@onready var count_b_label: Label = $TopHeader/ScoreBox/Margin/HBox/TeamB/CountB
@onready var timer_label: Label = $TopHeader/ScoreBox/Margin/HBox/VSBox/Timer
@onready var sound_btn: Button = $TopHeader/TopRight/SoundBtn
@onready var toggle_sidebar_btn: Button = $TopHeader/TopRight/ToggleSidebarBtn

# Sidebar
@onready var sidebar: PanelContainer = $Sidebar
@onready var option_a: OptionButton = $Sidebar/Margin/VBox/SecA/OptionA
@onready var model_option_a: OptionButton = $Sidebar/Margin/VBox/SecA/ModelOptionA
@onready var load_custom_a_btn: Button = $Sidebar/Margin/VBox/SecA/LoadCustomA
@onready var val_a_label: Label = $Sidebar/Margin/VBox/SecA/CountWrapA/ValA
@onready var slider_a: HSlider = $Sidebar/Margin/VBox/SecA/SliderA
@onready var q30_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q30
@onready var q60_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q60
@onready var q120_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q120
@onready var q250_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q250

@onready var option_b: OptionButton = $Sidebar/Margin/VBox/SecB/OptionB
@onready var model_option_b: OptionButton = $Sidebar/Margin/VBox/SecB/ModelOptionB
@onready var load_custom_b_btn: Button = $Sidebar/Margin/VBox/SecB/LoadCustomB
@onready var val_b_label: Label = $Sidebar/Margin/VBox/SecB/CountWrapB/ValB
@onready var slider_b: HSlider = $Sidebar/Margin/VBox/SecB/SliderB
@onready var q30_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q30
@onready var q60_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q60
@onready var q120_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q120
@onready var q250_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q250

@onready var preset_btn1: Button = $Sidebar/Margin/VBox/Preset1
@onready var preset_btn2: Button = $Sidebar/Margin/VBox/Preset2
@onready var preset_btn3: Button = $Sidebar/Margin/VBox/Preset3
@onready var preset_btn4: Button = $Sidebar/Margin/VBox/Preset4
@onready var apply_army_btn: Button = $Sidebar/Margin/VBox/ApplyArmyBtn

# File Picker Dialog
@onready var custom_model_dialog: FileDialog = $CustomModelDialog
var importing_team: String = "A"

# Bottom Bar
@onready var reels_btn: Button = $BottomBar/HBox/CamGroup/ReelsBtn
@onready var drone_btn: Button = $BottomBar/HBox/CamGroup/DroneBtn
@onready var action_btn: Button = $BottomBar/HBox/CamGroup/ActionBtn
@onready var topdown_btn: Button = $BottomBar/HBox/CamGroup/TopDownBtn

@onready var start_btn: Button = $BottomBar/HBox/ActionGroup/StartBtn
@onready var pause_btn: Button = $BottomBar/HBox/ActionGroup/PauseBtn
@onready var reset_btn: Button = $BottomBar/HBox/ActionGroup/ResetBtn

@onready var slow_btn: Button = $BottomBar/HBox/SpeedGroup/SlowBtn
@onready var normal_btn: Button = $BottomBar/HBox/SpeedGroup/NormalBtn
@onready var fast_btn: Button = $BottomBar/HBox/SpeedGroup/FastBtn

# Victory Modal
@onready var victory_modal: Control = $VictoryModal
@onready var winner_lbl: Label = $VictoryModal/Card/Margin/VBox/WinnerLbl
@onready var stats_lbl: Label = $VictoryModal/Card/Margin/VBox/StatsLbl
@onready var rematch_btn: Button = $VictoryModal/Card/Margin/VBox/RematchBtn

var preset_keys: Array = []
var model_keys: Array = []

func _ready() -> void:
	populate_presets_and_models()
	connect_signals()
	setup_ult_ui()
	setup_video_cutscene_modal()

func populate_presets_and_models() -> void:
	preset_keys = CharacterData.PRESETS.keys()
	model_keys = CharacterData.MODELS.keys()
	
	option_a.clear()
	option_b.clear()
	model_option_a.clear()
	model_option_b.clear()
	
	# Character Presets
	for i in range(preset_keys.size()):
		var k = preset_keys[i]
		var data = CharacterData.PRESETS[k]
		var title = data.get("name", k)
		option_a.add_item(title, i)
		option_b.add_item(title, i)
		
	# 3D Models
	for i in range(model_keys.size()):
		var mk = model_keys[i]
		var mdata = CharacterData.MODELS[mk]
		var mtitle = mdata.get("name", mk)
		model_option_a.add_item(mtitle, i)
		model_option_b.add_item(mtitle, i)
		
	# Add any auto-scanned custom models
	if manager and manager.custom_models.size() > 0:
		for cid in manager.custom_models.keys():
			if not model_keys.has(cid):
				model_keys.append(cid)
				var cname = manager.custom_models[cid]
				model_option_a.add_item(cname, model_keys.size() - 1)
				model_option_b.add_item(cname, model_keys.size() - 1)
		
	option_a.select(0)
	model_option_a.select(0)
	
	option_b.select(1)
	model_option_b.select(1)
	
	update_header_names()

func connect_signals() -> void:
	sound_btn.pressed.connect(_on_sound_pressed)
	toggle_sidebar_btn.pressed.connect(_on_toggle_sidebar_pressed)
	
	slider_a.value_changed.connect(func(val): val_a_label.text = str(int(val)))
	slider_b.value_changed.connect(func(val): val_b_label.text = str(int(val)))
	
	q30_a.pressed.connect(func(): set_slider_a(30))
	q60_a.pressed.connect(func(): set_slider_a(60))
	q120_a.pressed.connect(func(): set_slider_a(120))
	q250_a.pressed.connect(func(): set_slider_a(250))
	
	q30_b.pressed.connect(func(): set_slider_b(30))
	q60_b.pressed.connect(func(): set_slider_b(60))
	q120_b.pressed.connect(func(): set_slider_b(120))
	q250_b.pressed.connect(func(): set_slider_b(250))
	
	option_a.item_selected.connect(_on_preset_a_selected)
	option_b.item_selected.connect(_on_preset_b_selected)
	
	load_custom_a_btn.pressed.connect(func(): open_custom_file_dialog("A"))
	load_custom_b_btn.pressed.connect(func(): open_custom_file_dialog("B"))
	custom_model_dialog.file_selected.connect(_on_custom_file_selected)
	
	apply_army_btn.pressed.connect(_on_apply_army_pressed)
	
	# Presets
	preset_btn1.pressed.connect(func(): apply_preset_matchup("archer", "soldier", 60, "swordsman", "soldier", 60))
	preset_btn2.pressed.connect(func(): apply_preset_matchup("archer", "soldier", 100, "cyborg", "xbot", 100))
	preset_btn3.pressed.connect(func(): apply_preset_matchup("titan", "soldier", 1, "archer", "soldier", 150))
	preset_btn4.pressed.connect(func(): apply_preset_matchup("tyson", "robot_expressive", 100, "swordsman", "soldier", 100))
	
	reels_btn.pressed.connect(func(): set_camera(0))
	drone_btn.pressed.connect(func(): set_camera(1))
	action_btn.pressed.connect(func(): set_camera(2))
	topdown_btn.pressed.connect(func(): set_camera(3))
	
	start_btn.pressed.connect(_on_start_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	
	slow_btn.pressed.connect(func(): set_speed(0.2, slow_btn))
	normal_btn.pressed.connect(func(): set_speed(1.0, normal_btn))
	fast_btn.pressed.connect(func(): set_speed(2.5, fast_btn))
	
	rematch_btn.pressed.connect(_on_rematch_pressed)

func setup_ult_ui() -> void:
	var bottom_hbox: HBoxContainer = find_child("HBox", true, false)
	if not bottom_hbox:
		var bb = get_node_or_null("BottomBar")
		if bb:
			bottom_hbox = bb.get_node_or_null("HBox")
	if not bottom_hbox:
		return
		
	var sep = VSeparator.new()
	bottom_hbox.add_child(sep)
	if bottom_hbox.get_child_count() > 3:
		bottom_hbox.move_child(sep, 3)
	
	var ult_group = HBoxContainer.new()
	ult_group.name = "UltGroup"
	ult_group.add_theme_constant_override("separation", 8)
	
	# Team A Ult Button
	ult_a_btn = Button.new()
	ult_a_btn.name = "UltABtn"
	ult_a_btn.custom_minimum_size = Vector2(125, 40)
	ult_a_btn.text = "⚡ ULT A [1]"
	ult_a_btn.add_theme_font_size_override("font_size", 11)
	ult_a_btn.tooltip_text = "Lepaskan Ultimate Skill Pasukan Kubu A! (HotKey: 1)"
	
	var style_a = StyleBoxFlat.new()
	style_a.bg_color = Color(0.92, 0.58, 0.05, 0.95)
	style_a.set_corner_radius_all(10)
	style_a.shadow_color = Color(0.92, 0.58, 0.05, 0.5)
	style_a.shadow_size = 8
	style_a.content_margin_left = 12
	style_a.content_margin_right = 12
	style_a.content_margin_top = 8
	style_a.content_margin_bottom = 8
	ult_a_btn.add_theme_stylebox_override("normal", style_a)
	ult_a_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	
	# Team B Ult Button
	ult_b_btn = Button.new()
	ult_b_btn.name = "UltBBtn"
	ult_b_btn.custom_minimum_size = Vector2(125, 40)
	ult_b_btn.text = "⚡ ULT B [2]"
	ult_b_btn.add_theme_font_size_override("font_size", 11)
	ult_b_btn.tooltip_text = "Lepaskan Ultimate Skill Pasukan Kubu B! (HotKey: 2)"
	
	var style_b = StyleBoxFlat.new()
	style_b.bg_color = Color(0.15, 0.65, 0.95, 0.95)
	style_b.set_corner_radius_all(10)
	style_b.shadow_color = Color(0.15, 0.65, 0.95, 0.5)
	style_b.shadow_size = 8
	style_b.content_margin_left = 12
	style_b.content_margin_right = 12
	style_b.content_margin_top = 8
	style_b.content_margin_bottom = 8
	ult_b_btn.add_theme_stylebox_override("normal", style_b)
	ult_b_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	
	ult_a_btn.pressed.connect(_on_trigger_ult_a)
	ult_b_btn.pressed.connect(_on_trigger_ult_b)
	
	# Super Ult Button (Kereta Whoosh IKN Garuda)
	super_ult_btn = Button.new()
	super_ult_btn.name = "SuperUltBtn"
	super_ult_btn.custom_minimum_size = Vector2(175, 40)
	super_ult_btn.text = "🚄 SUPER ULT: WHOOSH IKN [3]"
	super_ult_btn.add_theme_font_size_override("font_size", 11)
	super_ult_btn.tooltip_text = "Luncurkan Kereta Cepat IKN Garuda Megastructure menabrak pasukan musuh! (HotKey: 3)"
	
	var style_super = StyleBoxFlat.new()
	style_super.bg_color = Color(0.85, 0.15, 0.15, 0.95)
	style_super.set_corner_radius_all(10)
	style_super.border_width_left = 2
	style_super.border_width_top = 2
	style_super.border_width_right = 2
	style_super.border_width_bottom = 2
	style_super.border_color = Color(1.0, 0.85, 0.25, 0.9)
	style_super.shadow_color = Color(0.9, 0.2, 0.2, 0.65)
	style_super.shadow_size = 12
	style_super.content_margin_left = 14
	style_super.content_margin_right = 14
	style_super.content_margin_top = 8
	style_super.content_margin_bottom = 8
	super_ult_btn.add_theme_stylebox_override("normal", style_super)
	super_ult_btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	
	super_ult_btn.pressed.connect(_on_trigger_super_ult)
	
	ult_group.add_child(ult_a_btn)
	ult_group.add_child(ult_b_btn)
	ult_group.add_child(super_ult_btn)
	
	bottom_hbox.add_child(ult_group)
	if bottom_hbox.get_child_count() > 4:
		bottom_hbox.move_child(ult_group, 4)

func setup_video_cutscene_modal() -> void:
	video_modal = Control.new()
	video_modal.name = "VideoCutsceneModal"
	video_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_modal.visible = false
	video_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	video_modal.z_index = 100
	add_child(video_modal)
	
	# Solid dark backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.01, 0.02, 0.98)
	video_modal.add_child(bg)
	
	# Video Stream Player
	video_player = VideoStreamPlayer.new()
	video_player.name = "CutsceneVideoPlayer"
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.loop = false
	video_player.bus = "Master"
	
	# Load the converted Theora video
	if ResourceLoader.exists("res://videos/super_ult.ogv"):
		var stream = load("res://videos/super_ult.ogv")
		if stream:
			video_player.stream = stream
			
	video_player.finished.connect(finish_video_cutscene)
	video_modal.add_child(video_player)
	
	# Top Widescreen Letterbox Bar
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 75)
	
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	top_style.border_width_bottom = 3
	top_style.border_color = Color(0.95, 0.25, 0.25)
	top_bar.add_theme_stylebox_override("panel", top_style)
	
	var top_vbox := VBoxContainer.new()
	top_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title_lbl := Label.new()
	title_lbl.text = "🚨 PERINGATAN: PROTOKOL SUPER ULTIMATE IKN DIAKTIFKAN! 🚨"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	top_vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "⚡ MEMPERSIAPKAN KERETA CEPAT WHOOSH & SAYAP GARUDA NUSANTARA ⚡"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	top_vbox.add_child(sub_lbl)
	
	top_bar.add_child(top_vbox)
	video_modal.add_child(top_bar)
	
	# Bottom Widescreen Letterbox Bar
	var bottom_bar_node := PanelContainer.new()
	bottom_bar_node.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar_node.custom_minimum_size = Vector2(0, 80)
	
	var bot_style := StyleBoxFlat.new()
	bot_style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	bot_style.border_width_top = 2
	bot_style.border_color = Color(1.0, 0.85, 0.25, 0.6)
	bottom_bar_node.add_theme_stylebox_override("panel", bot_style)
	
	var bot_hbox := HBoxContainer.new()
	bot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var skip_btn := Button.new()
	skip_btn.text = "⏩ LEWATI / LUNCURKAN KERETA WHOOSH SEKARANG [ESC]"
	skip_btn.custom_minimum_size = Vector2(340, 42)
	skip_btn.add_theme_font_size_override("font_size", 13)
	
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.85, 0.15, 0.15, 0.95)
	skip_style.set_corner_radius_all(8)
	skip_style.border_width_left = 2
	skip_style.border_width_top = 2
	skip_style.border_width_right = 2
	skip_style.border_width_bottom = 2
	skip_style.border_color = Color(1.0, 0.85, 0.25)
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_color_override("font_color", Color.WHITE)
	skip_btn.pressed.connect(finish_video_cutscene)
	
	bot_hbox.add_child(skip_btn)
	bottom_bar_node.add_child(bot_hbox)
	video_modal.add_child(bottom_bar_node)

func play_super_ult_cutscene(team_idx: int = 0) -> void:
	cutscene_team = team_idx
	is_cutscene_playing = true
	
	if video_modal:
		video_modal.visible = true
		
	if video_player and video_player.stream:
		video_player.play()
	else:
		finish_video_cutscene()

func finish_video_cutscene() -> void:
	if not is_cutscene_playing:
		return
	is_cutscene_playing = false
	
	if video_player:
		video_player.stop()
		
	if video_modal:
		video_modal.visible = false
		
	# Spawn the colossal train crashing across the battlefield!
	if manager and manager.has_method("spawn_super_ult_train"):
		manager.spawn_super_ult_train(cutscene_team)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if is_cutscene_playing and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE):
			finish_video_cutscene()
		elif event.keycode == KEY_H:
			visible = not visible
		elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_on_trigger_ult_a()
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_on_trigger_ult_b()
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_on_trigger_super_ult()

func _on_trigger_super_ult() -> void:
	play_super_ult_cutscene(0)

func _on_trigger_ult_a() -> void:
	if manager:
		manager.trigger_team_ultimate(BattleUnit.Team.A)

func _on_trigger_ult_b() -> void:
	if manager:
		manager.trigger_team_ultimate(BattleUnit.Team.B)

func open_custom_file_dialog(team_side: String) -> void:
	importing_team = team_side
	custom_model_dialog.popup_centered()

func _on_custom_file_selected(file_path: String) -> void:
	var fname = file_path.get_file()
	if manager:
		var custom_id = manager.load_custom_model_from_file(file_path, fname)
		if custom_id != "":
			if not model_keys.has(custom_id):
				model_keys.append(custom_id)
				var label_text = "📁 " + fname
				model_option_a.add_item(label_text, model_keys.size() - 1)
				model_option_b.add_item(label_text, model_keys.size() - 1)
				
			var target_idx = model_keys.find(custom_id)
			if importing_team == "A":
				model_option_a.select(target_idx)
			else:
				model_option_b.select(target_idx)
				
			_on_apply_army_pressed()

func _on_preset_a_selected(idx: int) -> void:
	var pk = preset_keys[idx]
	var pconf = CharacterData.PRESETS[pk]
	var def_model = pconf.get("model_id", "soldier")
	var midx = model_keys.find(def_model)
	if midx >= 0:
		model_option_a.select(midx)

func _on_preset_b_selected(idx: int) -> void:
	var pk = preset_keys[idx]
	var pconf = CharacterData.PRESETS[pk]
	var def_model = pconf.get("model_id", "xbot")
	var midx = model_keys.find(def_model)
	if midx >= 0:
		model_option_b.select(midx)

func set_slider_a(val: int) -> void:
	slider_a.value = val
	val_a_label.text = str(val)

func set_slider_b(val: int) -> void:
	slider_b.value = val
	val_b_label.text = str(val)

func _on_sound_pressed() -> void:
	if audio_mgr:
		var enabled = audio_mgr.toggle_sound()
		sound_btn.text = "🔊 Suara" if enabled else "🔇 Mute"

func _on_toggle_sidebar_pressed() -> void:
	sidebar.visible = not sidebar.visible
	toggle_sidebar_btn.text = "✖ Tutup Formasi" if sidebar.visible else "⚙️ Formasi Pasukan"

func _on_apply_army_pressed() -> void:
	var key_a = preset_keys[option_a.selected]
	var model_a = model_keys[model_option_a.selected]
	var count_a = int(slider_a.value)
	
	var key_b = preset_keys[option_b.selected]
	var model_b = model_keys[model_option_b.selected]
	var count_b = int(slider_b.value)
	
	update_header_names()
	if manager:
		manager.set_army_config(count_a, key_a, model_a, count_b, key_b, model_b)
		start_btn.text = "⚔️ MULAI PERANG!"
		
	# Smoothly auto-collapse sidebar to maximize battlefield visibility
	sidebar.visible = false
	toggle_sidebar_btn.text = "⚙️ Formasi Pasukan"

func apply_preset_matchup(p_a: String, m_a: String, c_a: int, p_b: String, m_b: String, c_b: int) -> void:
	var idx_a = preset_keys.find(p_a)
	if idx_a >= 0:
		option_a.select(idx_a)
	var midx_a = model_keys.find(m_a)
	if midx_a >= 0:
		model_option_a.select(midx_a)
	set_slider_a(c_a)
	
	var idx_b = preset_keys.find(p_b)
	if idx_b >= 0:
		option_b.select(idx_b)
	var midx_b = model_keys.find(m_b)
	if midx_b >= 0:
		model_option_b.select(midx_b)
	set_slider_b(c_b)
	
	_on_apply_army_pressed()

func update_header_names() -> void:
	if preset_keys.size() > option_a.selected:
		name_a_label.text = CharacterData.PRESETS[preset_keys[option_a.selected]].get("name", "Kubu A")
	if preset_keys.size() > option_b.selected:
		name_b_label.text = CharacterData.PRESETS[preset_keys[option_b.selected]].get("name", "Kubu B")

func set_camera(mode_idx: int) -> void:
	if camera and camera.has_method("set_mode"):
		camera.set_mode(mode_idx)

func _on_start_pressed() -> void:
	if manager:
		manager.start_battle()
		start_btn.text = "🔥 PERANG SEDANG BERLANGSUNG"

func _on_pause_pressed() -> void:
	if manager:
		var is_running = manager.toggle_pause()
		pause_btn.text = "▶️" if not is_running else "⏸️"

func _on_reset_pressed() -> void:
	victory_modal.visible = false
	if manager:
		manager.setup_battle()
		start_btn.text = "⚔️ MULAI PERANG!"
		pause_btn.text = "⏸️"

func set_speed(speed: float, _active_btn: Button) -> void:
	if manager:
		manager.set_speed(speed)

func show_victory(winner: String, survivors: int, time_sec: float) -> void:
	victory_modal.visible = true
	winner_lbl.text = "🏆 " + winner + " MENANG!"
	var mins = int(time_sec / 60.0)
	var secs = int(time_sec) % 60
	stats_lbl.text = "Sisa Pasukan: %d | Durasi Perang: %02d:%02d" % [survivors, mins, secs]
	start_btn.text = "🏆 " + winner + " MENANG!"

func _on_rematch_pressed() -> void:
	victory_modal.visible = false
	_on_reset_pressed()

func update_stats(alive_a: int, total_a: int, alive_b: int, total_b: int, time_sec: float, running: bool, energy_a: float = 0.0, energy_b: float = 0.0) -> void:
	if count_a_label:
		count_a_label.text = str(alive_a) + " / " + str(total_a)
	if count_b_label:
		count_b_label.text = str(alive_b) + " / " + str(total_b)
		
	if timer_label:
		var mins = int(time_sec / 60.0)
		var secs = int(time_sec) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		
	if ult_a_btn:
		if energy_a >= 100.0:
			ult_a_btn.text = "🔥 ULT A SIAP! [1]"
		else:
			ult_a_btn.text = "⚡ ULT A %d%% [1]" % int(energy_a)
			
	if ult_b_btn:
		if energy_b >= 100.0:
			ult_b_btn.text = "🔥 ULT B SIAP! [2]"
		else:
			ult_b_btn.text = "⚡ ULT B %d%% [2]" % int(energy_b)
		
	if not running and start_btn and not victory_modal.visible:
		if alive_a == 0 or alive_b == 0:
			var winner = name_a_label.text if alive_a > 0 else name_b_label.text
			start_btn.text = "🏆 " + winner + " MENANG!"
		else:
			start_btn.text = "⚔️ MULAI PERANG!"
