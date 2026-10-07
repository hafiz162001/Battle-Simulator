extends CanvasLayer

const CharacterData = preload("res://scripts/character_data.gd")
const BattleUnit = preload("res://scripts/unit.gd")

@onready var manager: Node3D = $"../BattleManager"
@onready var camera: Camera3D = $"../Camera3D"
@onready var audio_mgr: Node = $"../AudioManager"
@onready var arena: Node3D = $"../DesertArena"

@onready var ult_a_btn: Button = $BottomBar/HBox/UltGroup/UltABtn
@onready var ult_b_btn: Button = $BottomBar/HBox/UltGroup/UltBBtn
@onready var super_ult_btn: Button = $BottomBar/HBox/UltGroup/SuperUltBtn
var fps_label: Label = null
var perf_mode_btn: Button = null

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
@onready var toggle_sidebar_btn: Button = get_node_or_null("TopHeader/TopRight/ToggleSidebarBtn")

var super_ult_ready: bool = false
var super_ult_pulse_tween: Tween = null
var super_mana_val: float = 0.0

# Retro Pixel GUI Elements & StyleBoxes
var hp_bar_a: TextureProgressBar = null
var hp_bar_b: TextureProgressBar = null
var sub_a_label: Label = null
var sub_b_label: Label = null
var avatar_a_rect: TextureRect = null
var avatar_b_rect: TextureRect = null

var sbox_parchment: StyleBoxTexture = null
var sbox_wood_dark: StyleBoxTexture = null
var sbox_avatar_box: StyleBoxTexture = null
var sbox_banner_pill: StyleBoxTexture = null
var sbox_btn_wood: StyleBoxTexture = null
var sbox_btn_wood_hover: StyleBoxTexture = null
var sbox_btn_wood_pressed: StyleBoxTexture = null
var sbox_btn_gold: StyleBoxTexture = null
var sbox_btn_gold_hover: StyleBoxTexture = null
var sbox_btn_gold_pressed: StyleBoxTexture = null
var sbox_pill: StyleBoxTexture = null
var sbox_capsule_gold: StyleBoxTexture = null
var sbox_capsule_blue: StyleBoxTexture = null
var sbox_capsule_red: StyleBoxTexture = null
var sbox_capsule_bg: StyleBoxTexture = null

var exp_bar_a: TextureProgressBar = null
var exp_bar_b: TextureProgressBar = null
var exp_label_a: Label = null
var exp_label_b: Label = null
var banner_pill_a: PanelContainer = null
var banner_pill_b: PanelContainer = null
var kill_counter_label: Label = null
var tempo_counter_label: Label = null
var current_preset_idx: int = 0
var current_cam_idx: int = 0

# Sidebar
@onready var sidebar: PanelContainer = $Sidebar
@onready var option_a: OptionButton = $Sidebar/Margin/VBox/SecA/OptionA
@onready var model_option_a: OptionButton = $Sidebar/Margin/VBox/SecA/ModelOptionA
@onready var load_custom_a_btn: Button = $Sidebar/Margin/VBox/SecA/LoadCustomA
@onready var val_a_input: LineEdit = $Sidebar/Margin/VBox/SecA/CountWrapA/ValA
@onready var slider_a: HSlider = $Sidebar/Margin/VBox/SecA/SliderA
@onready var q60_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q60
@onready var q150_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q150
@onready var q300_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q300
@onready var q500_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q500
@onready var q1000_a: Button = $Sidebar/Margin/VBox/SecA/QuickA/Q1000

@onready var option_b: OptionButton = $Sidebar/Margin/VBox/SecB/OptionB
@onready var model_option_b: OptionButton = $Sidebar/Margin/VBox/SecB/ModelOptionB
@onready var load_custom_b_btn: Button = $Sidebar/Margin/VBox/SecB/LoadCustomB
@onready var val_b_input: LineEdit = $Sidebar/Margin/VBox/SecB/CountWrapB/ValB
@onready var slider_b: HSlider = $Sidebar/Margin/VBox/SecB/SliderB
@onready var q60_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q60
@onready var q150_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q150
@onready var q300_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q300
@onready var q500_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q500
@onready var q1000_b: Button = $Sidebar/Margin/VBox/SecB/QuickB/Q1000

@onready var preset_btn1: Button = $Sidebar/Margin/VBox/Preset1
@onready var preset_btn2: Button = $Sidebar/Margin/VBox/Preset2
@onready var preset_btn3: Button = $Sidebar/Margin/VBox/Preset3
@onready var preset_btn4: Button = $Sidebar/Margin/VBox/Preset4
@onready var preset_btn5: Button = $Sidebar/Margin/VBox/Preset5
@onready var preset_btn6: Button = $Sidebar/Margin/VBox/Preset6
@onready var apply_army_btn: Button = $Sidebar/Margin/VBox/ApplyArmyBtn

# File Picker Dialog
@onready var custom_model_dialog: FileDialog = $CustomModelDialog
var importing_team: String = "A"

# Custom Model & Element Center Modal
var custom_model_modal: Control = null
var modal_model_opt_a: OptionButton = null
var modal_elem_opt_a: OptionButton = null
var modal_model_opt_b: OptionButton = null
var modal_elem_opt_b: OptionButton = null
var modal_apply_btn: Button = null
var modal_close_btn: Button = null

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
@onready var winner_lbl: Label = $VictoryModal/Card/Margin/HBox/InfoVBox/WinnerLbl
@onready var stats_lbl: Label = $VictoryModal/Card/Margin/HBox/InfoVBox/StatsLbl
@onready var rematch_btn: Button = $VictoryModal/Card/Margin/HBox/BtnHBox/RematchBtn
@onready var victory_close_btn: Button = $VictoryModal/Card/Margin/HBox/BtnHBox/CloseBtn

var preset_keys: Array = []
var model_keys: Array = []

func _ready() -> void:
	setup_retro_pixel_gui_theme()
	populate_presets_and_models()
	connect_signals()
	setup_video_cutscene_modal()
	setup_fps_and_performance_ui()
	setup_custom_model_modal()

func _process(_delta: float) -> void:
	if fps_label:
		var fps = Engine.get_frames_per_second()
		fps_label.text = "%d FPS" % fps
		if fps >= 50:
			fps_label.add_theme_color_override("font_color", Color(0.18, 0.52, 0.22))
		elif fps >= 30:
			fps_label.add_theme_color_override("font_color", Color(0.72, 0.48, 0.12))
		else:
			fps_label.add_theme_color_override("font_color", Color(0.85, 0.18, 0.18))

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
	if sound_btn:
		sound_btn.pressed.connect(_on_sound_pressed)
	if toggle_sidebar_btn:
		toggle_sidebar_btn.pressed.connect(_on_toggle_sidebar_pressed)
	
	slider_a.value_changed.connect(func(val): val_a_input.text = str(int(val)))
	slider_b.value_changed.connect(func(val): val_b_input.text = str(int(val)))
	
	val_a_input.text_submitted.connect(func(new_text):
		var v = clamp(int(new_text), 10, 1000)
		set_slider_a(v)
	)
	val_a_input.focus_exited.connect(func():
		var v = clamp(int(val_a_input.text), 10, 1000)
		set_slider_a(v)
	)
	
	val_b_input.text_submitted.connect(func(new_text):
		var v = clamp(int(new_text), 10, 1000)
		set_slider_b(v)
	)
	val_b_input.focus_exited.connect(func():
		var v = clamp(int(val_b_input.text), 10, 1000)
		set_slider_b(v)
	)
	
	q60_a.pressed.connect(func(): set_slider_a(60))
	q150_a.pressed.connect(func(): set_slider_a(150))
	q300_a.pressed.connect(func(): set_slider_a(300))
	q500_a.pressed.connect(func(): set_slider_a(500))
	q1000_a.pressed.connect(func(): set_slider_a(1000))
	
	q60_b.pressed.connect(func(): set_slider_b(60))
	q150_b.pressed.connect(func(): set_slider_b(150))
	q300_b.pressed.connect(func(): set_slider_b(300))
	q500_b.pressed.connect(func(): set_slider_b(500))
	q1000_b.pressed.connect(func(): set_slider_b(1000))
	
	option_a.item_selected.connect(_on_preset_a_selected)
	option_b.item_selected.connect(_on_preset_b_selected)
	
	load_custom_a_btn.pressed.connect(func(): open_custom_file_dialog("A"))
	load_custom_b_btn.pressed.connect(func(): open_custom_file_dialog("B"))
	custom_model_dialog.file_selected.connect(_on_custom_file_selected)
	
	apply_army_btn.pressed.connect(_on_apply_army_pressed)
	
	# Presets
	preset_btn1.pressed.connect(func(): apply_preset_matchup("archer", "soldier", 60, "swordsman", "soldier", 60))
	preset_btn2.pressed.connect(func(): apply_preset_matchup("archer", "soldier", 150, "cyborg", "xbot", 150))
	preset_btn3.pressed.connect(func(): apply_preset_matchup("titan", "soldier", 1, "archer", "soldier", 300))
	preset_btn4.pressed.connect(func(): apply_preset_matchup("tyson", "robot_expressive", 200, "swordsman", "soldier", 200))
	preset_btn5.pressed.connect(func(): apply_preset_matchup("archer", "soldier", 500, "swordsman", "soldier", 500))
	preset_btn6.pressed.connect(func(): apply_preset_matchup("commando", "soldier", 1000, "cyborg", "xbot", 1000))
	
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
	
	if rematch_btn:
		rematch_btn.pressed.connect(_on_rematch_pressed)
	if victory_close_btn:
		victory_close_btn.pressed.connect(func(): victory_modal.visible = false)
		
	if ult_a_btn:
		ult_a_btn.pressed.connect(_on_trigger_ult_a)
		ult_a_btn.pivot_offset = Vector2(55, 19)
		apply_regular_ult_style(ult_a_btn, "A")
	if ult_b_btn:
		ult_b_btn.pressed.connect(_on_trigger_ult_b)
		ult_b_btn.pivot_offset = Vector2(55, 19)
		apply_regular_ult_style(ult_b_btn, "B")
	if super_ult_btn:
		super_ult_btn.pressed.connect(_on_trigger_super_ult)
		super_ult_btn.pivot_offset = Vector2(105, 19)
		apply_super_ult_charging_style(0.0)

func make_sbox(tex: Texture2D, margin: Vector4, pad: Vector4 = Vector4.ZERO) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.texture_margin_left = margin.x
	s.texture_margin_top = margin.y
	s.texture_margin_right = margin.z
	s.texture_margin_bottom = margin.w
	if pad != Vector4.ZERO:
		s.content_margin_left = pad.x
		s.content_margin_top = pad.y
		s.content_margin_right = pad.z
		s.content_margin_bottom = pad.w
	return s

func style_pixel_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return
	var norm = sbox_btn_gold if is_primary else sbox_btn_wood
	var hov = sbox_btn_gold_hover if is_primary else sbox_btn_wood_hover
	var press = sbox_btn_gold_pressed if is_primary else sbox_btn_wood_pressed
	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("focus", hov)
	btn.add_theme_constant_override("outline_size", 0)
	if is_primary:
		btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.75))
	else:
		btn.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
		btn.add_theme_color_override("font_hover_color", Color(0.12, 0.06, 0.02))
		btn.add_theme_color_override("font_pressed_color", Color(0.38, 0.22, 0.14))

func style_pixel_input(inp: LineEdit) -> void:
	if not inp:
		return
	if sbox_pill:
		inp.add_theme_stylebox_override("normal", sbox_pill)
		inp.add_theme_stylebox_override("focus", sbox_pill)
	inp.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
	inp.add_theme_color_override("caret_color", Color(0.24, 0.14, 0.08))

func style_pixel_slider(slider: HSlider) -> void:
	if not slider:
		return
	var track_sbox := StyleBoxFlat.new()
	track_sbox.bg_color = Color(0.24, 0.14, 0.08, 0.95)
	track_sbox.border_color = Color(0.12, 0.06, 0.03, 1.0)
	track_sbox.border_width_left = 1
	track_sbox.border_width_top = 1
	track_sbox.border_width_right = 1
	track_sbox.border_width_bottom = 1
	track_sbox.set_corner_radius_all(3)
	track_sbox.content_margin_top = 4
	track_sbox.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track_sbox)

func setup_retro_pixel_gui_theme() -> void:
	var tex_parchment = load("res://ui/assets/frame_parchment.png")
	var tex_wood_dark = load("res://ui/assets/frame_wood_dark.png")
	var tex_btn_wood = load("res://ui/assets/button_wood.png")
	var tex_btn_wood_hov = load("res://ui/assets/button_wood_hover.png")
	var tex_btn_wood_prs = load("res://ui/assets/button_wood_pressed.png")
	var tex_btn_gold = load("res://ui/assets/button_gold.png")
	var tex_btn_gold_hov = load("res://ui/assets/button_gold_hover.png")
	var tex_btn_gold_prs = load("res://ui/assets/button_gold_pressed.png")
	var tex_pill = load("res://ui/assets/pill_badge.png")
	var tex_cap_gold = load("res://ui/assets/capsule_tube_gold.png")
	var tex_cap_blue = load("res://ui/assets/capsule_tube_blue.png")
	var tex_cap_red = load("res://ui/assets/capsule_tube_red.png")
	var tex_cap_bg = load("res://ui/assets/capsule_tube_bg.png")
	var tex_bar_groove = load("res://ui/assets/bar_groove.png")
	var tex_bar_green = load("res://ui/assets/bar_green.png")
	var tex_bar_blue = load("res://ui/assets/bar_blue.png")
	var tex_avatar_a = load("res://ui/icons/avatar_a.png")
	var tex_avatar_b = load("res://ui/icons/avatar_b.png")
	var tex_clock = load("res://ui/icons/icon_clock.png")
	var tex_swords = load("res://ui/icons/icon_swords.png")
	
	sbox_parchment = make_sbox(tex_parchment, Vector4(16, 16, 16, 16), Vector4(14, 10, 14, 10))
	sbox_wood_dark = make_sbox(tex_wood_dark, Vector4(14, 14, 14, 14), Vector4(12, 10, 12, 10))
	sbox_btn_wood = make_sbox(tex_btn_wood, Vector4(6, 6, 6, 6), Vector4(8, 4, 8, 4))
	sbox_btn_wood_hover = make_sbox(tex_btn_wood_hov, Vector4(6, 6, 6, 6), Vector4(8, 4, 8, 4))
	var tex_avatar_box = load("res://ui/assets/frame_avatar_box.png")
	var tex_banner_pill = load("res://ui/assets/banner_title_pill.png")
	var tex_bar_orange = load("res://ui/assets/bar_orange.png")
	var tex_plinth = load("res://ui/assets/pedestal_plinth.png")
	var tex_bag = load("res://ui/icons/icon_backpack.png")
	var tex_scroll = load("res://ui/icons/icon_scroll.png")
	var tex_map = load("res://ui/icons/icon_map.png")
	var tex_shop = load("res://ui/icons/icon_shop.png")
	var tex_coin = load("res://ui/icons/icon_coin.png")
	var tex_gem = load("res://ui/icons/icon_gem.png")
	
	sbox_parchment = make_sbox(tex_parchment, Vector4(16, 16, 16, 16), Vector4(14, 10, 14, 10))
	sbox_wood_dark = make_sbox(tex_wood_dark, Vector4(14, 14, 14, 14), Vector4(12, 10, 12, 10))
	sbox_avatar_box = make_sbox(tex_avatar_box, Vector4(10, 10, 10, 10), Vector4(4, 4, 4, 4))
	sbox_banner_pill = make_sbox(tex_banner_pill, Vector4(10, 8, 10, 8), Vector4(10, 2, 10, 2))
	sbox_btn_wood = make_sbox(tex_btn_wood, Vector4(6, 6, 6, 6), Vector4(8, 4, 8, 4))
	sbox_btn_wood_hover = make_sbox(tex_btn_wood_hov, Vector4(6, 6, 6, 6), Vector4(8, 4, 8, 4))
	sbox_btn_wood_pressed = make_sbox(tex_btn_wood_prs, Vector4(6, 6, 6, 6), Vector4(8, 5, 8, 3))
	sbox_btn_gold = make_sbox(tex_btn_gold, Vector4(6, 6, 6, 6), Vector4(14, 7, 14, 7))
	sbox_btn_gold_hover = make_sbox(tex_btn_gold_hov, Vector4(6, 6, 6, 6), Vector4(14, 7, 14, 7))
	sbox_btn_gold_pressed = make_sbox(tex_btn_gold_prs, Vector4(6, 6, 6, 6), Vector4(14, 8, 14, 6))
	sbox_pill = make_sbox(tex_pill, Vector4(12, 8, 12, 8), Vector4(8, 3, 8, 3))
	sbox_capsule_gold = make_sbox(tex_cap_gold, Vector4(12, 8, 12, 8), Vector4(12, 5, 12, 5))
	sbox_capsule_blue = make_sbox(tex_cap_blue, Vector4(12, 8, 12, 8), Vector4(12, 5, 12, 5))
	sbox_capsule_red = make_sbox(tex_cap_red, Vector4(12, 8, 12, 8), Vector4(12, 5, 12, 5))
	sbox_capsule_bg = make_sbox(tex_cap_bg, Vector4(12, 8, 12, 8), Vector4(12, 5, 12, 5))
	
	# 1. Logo Panel
	var logo_panel = get_node_or_null("TopHeader/LogoPanel")
	if logo_panel:
		logo_panel.add_theme_stylebox_override("panel", sbox_parchment)
		var logo_title = logo_panel.find_child("Title")
		if logo_title:
			logo_title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
			logo_title.text = "⚔️ VILLAGE WARZ 3D"
		var logo_sub = logo_panel.find_child("Sub")
		if logo_sub:
			logo_sub.add_theme_color_override("font_color", Color(0.6, 0.4, 0.25))
			logo_sub.text = "PEDESAAN ASRI • PASTORAL VALLEY"

	# 2. ScoreBox (Main Player Profile Card inspired by SIMPLE PIXEL GUI #1)
	var score_box = get_node_or_null("TopHeader/ScoreBox")
	if score_box:
		score_box.add_theme_stylebox_override("panel", sbox_parchment)
		score_box.custom_minimum_size = Vector2(980, 96)
		score_box.offset_left = -490.0
		score_box.offset_right = 490.0
		score_box.offset_top = 8.0
		score_box.offset_bottom = 104.0
		
		var hbox = score_box.find_child("HBox")
		if hbox:
			hbox.add_theme_constant_override("separation", 14)
			
			# Avatar Team A Box (Left)
			if not hbox.has_node("AvatarA_Box"):
				var av_box_a = PanelContainer.new()
				av_box_a.name = "AvatarA_Box"
				av_box_a.add_theme_stylebox_override("panel", sbox_avatar_box)
				av_box_a.custom_minimum_size = Vector2(52, 52)
				avatar_a_rect = TextureRect.new()
				avatar_a_rect.name = "AvatarA"
				avatar_a_rect.texture = tex_avatar_a
				avatar_a_rect.custom_minimum_size = Vector2(46, 46)
				avatar_a_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				avatar_a_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				av_box_a.add_child(avatar_a_rect)
				hbox.add_child(av_box_a)
				hbox.move_child(av_box_a, 0)
				
			# Team A Info
			var team_a_box = hbox.find_child("TeamA")
			if team_a_box:
				team_a_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				team_a_box.alignment = BoxContainer.ALIGNMENT_CENTER
				team_a_box.add_theme_constant_override("separation", 2)
				
				# Terracotta Banner Pill for Title
				if not team_a_box.has_node("BannerPillA") and name_a_label:
					banner_pill_a = PanelContainer.new()
					banner_pill_a.name = "BannerPillA"
					banner_pill_a.add_theme_stylebox_override("panel", sbox_banner_pill)
					banner_pill_a.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					name_a_label.reparent(banner_pill_a)
					name_a_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
					name_a_label.add_theme_font_size_override("font_size", 11)
					name_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					name_a_label.text = "• URBAN SNIPER • 32"
					team_a_box.add_child(banner_pill_a)
					team_a_box.move_child(banner_pill_a, 0)
				
				if not team_a_box.has_node("SubA"):
					sub_a_label = Label.new()
					sub_a_label.name = "SubA"
					sub_a_label.text = "PEMANAH TAKTIS KOTA"
					sub_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					sub_a_label.add_theme_color_override("font_color", Color(0.55, 0.35, 0.2))
					sub_a_label.add_theme_font_size_override("font_size", 9)
					team_a_box.add_child(sub_a_label)
					team_a_box.move_child(sub_a_label, 1)
					
				# Slender HP Bar Row
				if not team_a_box.has_node("BarWrapA"):
					var bar_wrap = HBoxContainer.new()
					bar_wrap.name = "BarWrapA"
					bar_wrap.add_theme_constant_override("separation", 6)
					
					var hp_lbl = Label.new()
					hp_lbl.text = "HP"
					hp_lbl.add_theme_color_override("font_color", Color(0.55, 0.32, 0.18))
					hp_lbl.add_theme_font_size_override("font_size", 9)
					bar_wrap.add_child(hp_lbl)
					
					hp_bar_a = TextureProgressBar.new()
					hp_bar_a.name = "HpBarA"
					hp_bar_a.nine_patch_stretch = true
					hp_bar_a.stretch_margin_left = 6
					hp_bar_a.stretch_margin_top = 3
					hp_bar_a.stretch_margin_right = 6
					hp_bar_a.stretch_margin_bottom = 3
					hp_bar_a.custom_minimum_size = Vector2(130, 10)
					hp_bar_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					hp_bar_a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					hp_bar_a.texture_under = tex_bar_groove
					hp_bar_a.texture_progress = tex_bar_green
					hp_bar_a.value = 100.0
					bar_wrap.add_child(hp_bar_a)
					
					if count_a_label:
						count_a_label.reparent(bar_wrap)
						count_a_label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
						count_a_label.add_theme_font_size_override("font_size", 10)
						
					team_a_box.add_child(bar_wrap)

				# Slender EXP Bar Row
				if not team_a_box.has_node("ExpWrapA"):
					var exp_wrap = HBoxContainer.new()
					exp_wrap.name = "ExpWrapA"
					exp_wrap.add_theme_constant_override("separation", 6)
					
					var exp_lbl = Label.new()
					exp_lbl.text = "EXP"
					exp_lbl.add_theme_color_override("font_color", Color(0.55, 0.32, 0.18))
					exp_lbl.add_theme_font_size_override("font_size", 8)
					exp_wrap.add_child(exp_lbl)
					
					exp_bar_a = TextureProgressBar.new()
					exp_bar_a.name = "ExpBarA"
					exp_bar_a.nine_patch_stretch = true
					exp_bar_a.stretch_margin_left = 6
					exp_bar_a.stretch_margin_top = 3
					exp_bar_a.stretch_margin_right = 6
					exp_bar_a.stretch_margin_bottom = 3
					exp_bar_a.custom_minimum_size = Vector2(130, 8)
					exp_bar_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					exp_bar_a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					exp_bar_a.texture_under = tex_bar_groove
					exp_bar_a.texture_progress = tex_bar_orange
					exp_bar_a.value = 100.0
					exp_wrap.add_child(exp_bar_a)
					
					exp_label_a = Label.new()
					exp_label_a.text = "100%"
					exp_label_a.add_theme_color_override("font_color", Color(0.45, 0.28, 0.15))
					exp_label_a.add_theme_font_size_override("font_size", 8)
					exp_wrap.add_child(exp_label_a)
					
					team_a_box.add_child(exp_wrap)

			# VS & Clock Pill
			var vs_box = hbox.find_child("VSBox")
			if vs_box:
				vs_box.alignment = BoxContainer.ALIGNMENT_CENTER
				vs_box.add_theme_constant_override("separation", 2)
				var vs_txt = vs_box.find_child("VSText")
				if vs_txt:
					vs_txt.text = "⚔️ VS ⚔️"
					vs_txt.add_theme_color_override("font_color", Color(0.75, 0.48, 0.18))
					vs_txt.add_theme_font_size_override("font_size", 9)
					
				if timer_label and not vs_box.has_node("ClockPill"):
					var clock_pill = PanelContainer.new()
					clock_pill.name = "ClockPill"
					clock_pill.add_theme_stylebox_override("panel", sbox_pill)
					var pill_hbox = HBoxContainer.new()
					pill_hbox.add_theme_constant_override("separation", 4)
					pill_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
					
					var clock_ico = TextureRect.new()
					clock_ico.texture = tex_clock
					clock_ico.custom_minimum_size = Vector2(16, 16)
					clock_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					clock_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					pill_hbox.add_child(clock_ico)
					
					timer_label.reparent(pill_hbox)
					timer_label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
					timer_label.add_theme_font_size_override("font_size", 12)
					
					clock_pill.add_child(pill_hbox)
					vs_box.add_child(clock_pill)

			# Team B Info
			var team_b_box = hbox.find_child("TeamB")
			if team_b_box:
				team_b_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				team_b_box.alignment = BoxContainer.ALIGNMENT_CENTER
				team_b_box.add_theme_constant_override("separation", 2)
				
				# Terracotta Banner Pill for Title
				if not team_b_box.has_node("BannerPillB") and name_b_label:
					banner_pill_b = PanelContainer.new()
					banner_pill_b.name = "BannerPillB"
					banner_pill_b.add_theme_stylebox_override("panel", sbox_banner_pill)
					banner_pill_b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					name_b_label.reparent(banner_pill_b)
					name_b_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
					name_b_label.add_theme_font_size_override("font_size", 11)
					name_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					name_b_label.text = "32 • URBAN ENFORCER •"
					team_b_box.add_child(banner_pill_b)
					team_b_box.move_child(banner_pill_b, 0)
					
				if not team_b_box.has_node("SubB"):
					sub_b_label = Label.new()
					sub_b_label.name = "SubB"
					sub_b_label.text = "PENGAWAL PERISAI KOTA"
					sub_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					sub_b_label.add_theme_color_override("font_color", Color(0.3, 0.45, 0.6))
					sub_b_label.add_theme_font_size_override("font_size", 9)
					team_b_box.add_child(sub_b_label)
					team_b_box.move_child(sub_b_label, 1)
					
				# Slender HP Bar Row
				if not team_b_box.has_node("BarWrapB"):
					var bar_wrap_b = HBoxContainer.new()
					bar_wrap_b.name = "BarWrapB"
					bar_wrap_b.add_theme_constant_override("separation", 6)
					
					if count_b_label:
						count_b_label.reparent(bar_wrap_b)
						count_b_label.add_theme_color_override("font_color", Color(0.12, 0.24, 0.4))
						count_b_label.add_theme_font_size_override("font_size", 10)
						
					hp_bar_b = TextureProgressBar.new()
					hp_bar_b.name = "HpBarB"
					hp_bar_b.nine_patch_stretch = true
					hp_bar_b.stretch_margin_left = 6
					hp_bar_b.stretch_margin_top = 3
					hp_bar_b.stretch_margin_right = 6
					hp_bar_b.stretch_margin_bottom = 3
					hp_bar_b.custom_minimum_size = Vector2(130, 10)
					hp_bar_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					hp_bar_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					hp_bar_b.texture_under = tex_bar_groove
					hp_bar_b.texture_progress = tex_bar_blue
					hp_bar_b.value = 100.0
					bar_wrap_b.add_child(hp_bar_b)
					
					var hp_lbl_b = Label.new()
					hp_lbl_b.text = "HP"
					hp_lbl_b.add_theme_color_override("font_color", Color(0.2, 0.35, 0.5))
					hp_lbl_b.add_theme_font_size_override("font_size", 9)
					bar_wrap_b.add_child(hp_lbl_b)
					
					team_b_box.add_child(bar_wrap_b)

				# Slender AP Bar Row
				if not team_b_box.has_node("ExpWrapB"):
					var exp_wrap_b = HBoxContainer.new()
					exp_wrap_b.name = "ExpWrapB"
					exp_wrap_b.add_theme_constant_override("separation", 6)
					
					exp_label_b = Label.new()
					exp_label_b.text = "100%"
					exp_label_b.add_theme_color_override("font_color", Color(0.25, 0.38, 0.52))
					exp_label_b.add_theme_font_size_override("font_size", 8)
					exp_wrap_b.add_child(exp_label_b)
					
					exp_bar_b = TextureProgressBar.new()
					exp_bar_b.name = "ExpBarB"
					exp_bar_b.nine_patch_stretch = true
					exp_bar_b.stretch_margin_left = 6
					exp_bar_b.stretch_margin_top = 3
					exp_bar_b.stretch_margin_right = 6
					exp_bar_b.stretch_margin_bottom = 3
					exp_bar_b.custom_minimum_size = Vector2(130, 8)
					exp_bar_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					exp_bar_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					exp_bar_b.texture_under = tex_bar_groove
					exp_bar_b.texture_progress = tex_bar_orange
					exp_bar_b.value = 100.0
					exp_wrap_b.add_child(exp_bar_b)
					
					var ap_lbl = Label.new()
					ap_lbl.text = "AP"
					ap_lbl.add_theme_color_override("font_color", Color(0.2, 0.35, 0.5))
					ap_lbl.add_theme_font_size_override("font_size", 8)
					exp_wrap_b.add_child(ap_lbl)
					
					team_b_box.add_child(exp_wrap_b)

			# Avatar Team B Box (Right)
			if not hbox.has_node("AvatarB_Box"):
				var av_box_b = PanelContainer.new()
				av_box_b.name = "AvatarB_Box"
				av_box_b.add_theme_stylebox_override("panel", sbox_avatar_box)
				av_box_b.custom_minimum_size = Vector2(52, 52)
				avatar_b_rect = TextureRect.new()
				avatar_b_rect.name = "AvatarB"
				avatar_b_rect.texture = tex_avatar_b
				avatar_b_rect.custom_minimum_size = Vector2(46, 46)
				avatar_b_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				avatar_b_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				av_box_b.add_child(avatar_b_rect)
				hbox.add_child(av_box_b)

	# 3. Middle Action Pedestals Row (Matching the 5 carved pedestals in reference image!)
	var top_hdr = get_node_or_null("TopHeader")
	if top_hdr and not top_hdr.has_node("PedestalBar"):
		var ped_bar = HBoxContainer.new()
		ped_bar.name = "PedestalBar"
		ped_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
		ped_bar.offset_left = -200.0
		ped_bar.offset_right = 200.0
		ped_bar.offset_top = 108.0
		ped_bar.offset_bottom = 176.0
		ped_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		ped_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		ped_bar.add_theme_constant_override("separation", 14)
		
		# Helper to build a pedestal unit
		var add_ped_btn = func(icon_tex: Texture2D, tip: String, on_click: Callable):
			var v = VBoxContainer.new()
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 0)
			
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(44, 44)
			btn.tooltip_text = tip
			style_pixel_button(btn, false)
			
			var ic = TextureRect.new()
			ic.texture = icon_tex
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic.offset_left = 6.0
			ic.offset_top = 6.0
			ic.offset_right = -6.0
			ic.offset_bottom = -6.0
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(ic)
			btn.pressed.connect(on_click)
			
			var plinth = TextureRect.new()
			plinth.texture = tex_plinth
			plinth.custom_minimum_size = Vector2(48, 14)
			plinth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plinth.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			v.add_child(btn)
			v.add_child(plinth)
			ped_bar.add_child(v)
			
		add_ped_btn.call(tex_bag, "🎒 Formasi Pasukan (Buka/Tutup Buku Formasi)", _on_toggle_sidebar_pressed)
		add_ped_btn.call(tex_swords, "⚔️ Mulai / Lanjutkan Tempur", _on_start_pressed)
		add_ped_btn.call(tex_scroll, "📜 Preset Misi Tempur (Ganti Skenario Cepat)", cycle_next_preset)
		add_ped_btn.call(tex_map, "🗺️ Kamera Taktis (Reels / Drone / Action / Top)", cycle_next_camera)
		add_ped_btn.call(tex_shop, "🎪 Grafik & Audio (Toggle Crowd 60FPS vs Ultra)", _on_toggle_perf_mode)
		
		top_hdr.add_child(ped_bar)

	# 4. Bottom Bar
	var bottom_bar = get_node_or_null("BottomBar")
	if bottom_bar:
		bottom_bar.add_theme_stylebox_override("panel", sbox_parchment)
		bottom_bar.offset_top = -80.0
		bottom_bar.offset_bottom = -14.0
		
		# Camera buttons
		for b in [reels_btn, drone_btn, action_btn, topdown_btn]:
			style_pixel_button(b, false)
			b.custom_minimum_size = Vector2(68, 36)
			
		# Action buttons
		style_pixel_button(start_btn, true)
		start_btn.custom_minimum_size = Vector2(170, 38)
		style_pixel_button(pause_btn, false)
		pause_btn.custom_minimum_size = Vector2(44, 38)
		style_pixel_button(reset_btn, false)
		reset_btn.custom_minimum_size = Vector2(80, 38)
		
		# Speed buttons
		for b in [slow_btn, normal_btn, fast_btn]:
			style_pixel_button(b, false)
			b.custom_minimum_size = Vector2(52, 36)
			
		# Ultimate buttons with Crystal Capsules
		apply_regular_ult_style(ult_a_btn, "A")
		apply_regular_ult_style(ult_b_btn, "B")
		apply_super_ult_charging_style(super_mana_val)

		# Add 3 Stacked Resource Pill Badges on the right of BottomBar
		var b_hbox = bottom_bar.find_child("HBox")
		if b_hbox and not b_hbox.has_node("ResourcePills"):
			var pills_vbox = VBoxContainer.new()
			pills_vbox.name = "ResourcePills"
			pills_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			pills_vbox.add_theme_constant_override("separation", 2)
			
			# 1. Coin Pill (KORBAN / CASUALTY)
			var coin_pill = PanelContainer.new()
			coin_pill.add_theme_stylebox_override("panel", sbox_pill)
			var coin_h = HBoxContainer.new()
			coin_h.add_theme_constant_override("separation", 4)
			var coin_ic = TextureRect.new()
			coin_ic.texture = tex_coin
			coin_ic.custom_minimum_size = Vector2(16, 16)
			coin_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			coin_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			coin_h.add_child(coin_ic)
			kill_counter_label = Label.new()
			kill_counter_label.text = "KORBAN: 0"
			kill_counter_label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
			kill_counter_label.add_theme_font_size_override("font_size", 9)
			coin_h.add_child(kill_counter_label)
			coin_pill.add_child(coin_h)
			pills_vbox.add_child(coin_pill)
			
			# 2. Gem Pill (FPS COUNTER)
			var fps_pill = PanelContainer.new()
			fps_pill.add_theme_stylebox_override("panel", sbox_pill)
			var fps_h = HBoxContainer.new()
			fps_h.add_theme_constant_override("separation", 4)
			var fps_ic = TextureRect.new()
			fps_ic.texture = tex_gem
			fps_ic.custom_minimum_size = Vector2(16, 16)
			fps_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fps_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			fps_h.add_child(fps_ic)
			fps_label = Label.new()
			fps_label.name = "FPSLabel"
			fps_label.text = "60 FPS"
			fps_label.add_theme_color_override("font_color", Color(0.15, 0.38, 0.65))
			fps_label.add_theme_font_size_override("font_size", 9)
			fps_h.add_child(fps_label)
			fps_pill.add_child(fps_h)
			pills_vbox.add_child(fps_pill)
			
			# 3. Clock Pill (TEMPO / SPEED)
			var tempo_pill = PanelContainer.new()
			tempo_pill.add_theme_stylebox_override("panel", sbox_pill)
			var tempo_h = HBoxContainer.new()
			tempo_h.add_theme_constant_override("separation", 4)
			var tempo_ic = TextureRect.new()
			tempo_ic.texture = tex_clock
			tempo_ic.custom_minimum_size = Vector2(16, 16)
			tempo_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tempo_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tempo_h.add_child(tempo_ic)
			tempo_counter_label = Label.new()
			tempo_counter_label.text = "TEMPO: 1.0x"
			tempo_counter_label.add_theme_color_override("font_color", Color(0.65, 0.22, 0.15))
			tempo_counter_label.add_theme_font_size_override("font_size", 9)
			tempo_h.add_child(tempo_counter_label)
			tempo_pill.add_child(tempo_h)
			pills_vbox.add_child(tempo_pill)
			
			b_hbox.add_child(pills_vbox)

	# 5. Sidebar (Buku Strategi Formasi)
	if sidebar:
		sidebar.add_theme_stylebox_override("panel", sbox_parchment)
		var sb_title = sidebar.find_child("Title")
		if sb_title:
			sb_title.text = "📜 BUKU STRATEGI FORMASI"
			sb_title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08))
			sb_title.add_theme_font_size_override("font_size", 13)
			
		var lbl_a = sidebar.find_child("LabelA")
		if lbl_a:
			lbl_a.text = "◆ KUBU A (TIM EMAS) ◆"
			lbl_a.add_theme_color_override("font_color", Color(0.58, 0.35, 0.18))
			
		var lbl_b = sidebar.find_child("LabelB")
		if lbl_b:
			lbl_b.text = "◆ KUBU B (TIM BIRU) ◆"
			lbl_b.add_theme_color_override("font_color", Color(0.18, 0.35, 0.55))
			
		for opt in [option_a, model_option_a, option_b, model_option_b]:
			style_pixel_button(opt, false)
			
		for btn in [load_custom_a_btn, load_custom_b_btn]:
			style_pixel_button(btn, false)
			
		for inp in [val_a_input, val_b_input]:
			style_pixel_input(inp)
			
		for sld in [slider_a, slider_b]:
			style_pixel_slider(sld)
			
		for q in [q60_a, q150_a, q300_a, q500_a, q1000_a, q60_b, q150_b, q300_b, q500_b, q1000_b]:
			style_pixel_button(q, false)
			
		var pres_title = sidebar.find_child("PresetsTitle")
		if pres_title:
			pres_title.text = "⚔️ PRESET PERANG:"
			pres_title.add_theme_color_override("font_color", Color(0.58, 0.35, 0.18))
			
		for p in [preset_btn1, preset_btn2, preset_btn3, preset_btn4, preset_btn5, preset_btn6]:
			style_pixel_button(p, false)
			
		style_pixel_button(apply_army_btn, true)
		apply_army_btn.text = "🚀 TERAPKAN FORMASI"

	# 6. Victory Modal
	if victory_modal:
		var card = victory_modal.find_child("Card")
		if card:
			card.add_theme_stylebox_override("panel", sbox_parchment)
		if winner_lbl:
			winner_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.12))
			winner_lbl.add_theme_font_size_override("font_size", 16)
		if stats_lbl:
			stats_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.14))
			stats_lbl.add_theme_font_size_override("font_size", 11)
		style_pixel_button(rematch_btn, true)
		style_pixel_button(victory_close_btn, false)

	# 7. Top Right Controls
	if toggle_sidebar_btn:
		style_pixel_button(toggle_sidebar_btn, false)
		toggle_sidebar_btn.text = "🎒 Formasi Pasukan"
	if sound_btn:
		style_pixel_button(sound_btn, false)
		sound_btn.text = "🔊 Suara"


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
	title_lbl.text = "🚨 PROTOKOL SUPER ULTIMATE: WHOOSH & GARUDA API! 🚨"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	top_vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "🔥 KERETA CEPAT WHOOSH 350 KM/H & MAHADAHYSAT BURUNG GARUDA API 🔥"
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
	skip_btn.text = "⏩ LUNCURKAN WHOOSH & GARUDA SEKARANG [ESC]"
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

func setup_fps_and_performance_ui() -> void:
	var top_right = get_node_or_null("TopHeader/TopRight")
	if not top_right:
		return
		
	# Crowd 60FPS / Ultra Graphic Toggle Button
	if not top_right.has_node("PerfModeBtn"):
		perf_mode_btn = Button.new()
		perf_mode_btn.name = "PerfModeBtn"
		perf_mode_btn.custom_minimum_size = Vector2(120, 36)
		perf_mode_btn.add_theme_font_size_override("font_size", 10)
		perf_mode_btn.tooltip_text = "Mode Grafik: CROWD 60FPS vs ULTRA CINEMATIC"
		style_pixel_button(perf_mode_btn, false)
		
		var is_crowd = false
		if arena and "is_performance_mode" in arena:
			is_crowd = arena.is_performance_mode
		update_perf_mode_btn_text(is_crowd)
		
		perf_mode_btn.pressed.connect(_on_toggle_perf_mode)
		top_right.add_child(perf_mode_btn)
		top_right.move_child(perf_mode_btn, 0)
		
	# Dedicated Top Bar Custom Model & Element Button!
	if not top_right.has_node("CustomModelTopBtn"):
		var custom_top_btn := Button.new()
		custom_top_btn.name = "CustomModelTopBtn"
		custom_top_btn.text = "🧙‍♂️ Model & Elemen 3D"
		custom_top_btn.custom_minimum_size = Vector2(175, 36)
		custom_top_btn.add_theme_font_size_override("font_size", 11)
		custom_top_btn.tooltip_text = "Pilih / Import Model 3D Sendiri (.glb) & Tentukan Elemen (Mage Api, Es, Petir, dll.)"
		style_pixel_button(custom_top_btn, true)
		custom_top_btn.pressed.connect(open_custom_model_modal)
		top_right.add_child(custom_top_btn)
		top_right.move_child(custom_top_btn, 0)

func update_perf_mode_btn_text(is_crowd: bool) -> void:
	if not perf_mode_btn:
		return
	if is_crowd:
		perf_mode_btn.text = "⚡ CROWD 60FPS"
		style_pixel_button(perf_mode_btn, true)
	else:
		perf_mode_btn.text = "🌟 ULTRA GRAFIK"
		style_pixel_button(perf_mode_btn, false)

func _on_toggle_perf_mode() -> void:
	if arena and arena.has_method("set_performance_mode"):
		var new_mode = not arena.is_performance_mode
		arena.set_performance_mode(new_mode)
		update_perf_mode_btn_text(new_mode)

func play_super_ult_cutscene(team_idx: int = 0) -> void:
	cutscene_team = team_idx
	is_cutscene_playing = true
	
	if video_modal:
		video_modal.visible = true
		
	if video_player and video_player.stream:
		video_player.stop()
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

func setup_custom_model_modal() -> void:
	custom_model_modal = Control.new()
	custom_model_modal.name = "CustomModelModal"
	custom_model_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_model_modal.visible = false
	custom_model_modal.z_index = 95
	add_child(custom_model_modal)
	
	# Dimmed backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.01, 0.03, 0.88)
	custom_model_modal.add_child(bg)
	
	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_model_modal.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(740, 520)
	if sbox_parchment:
		panel.add_theme_stylebox_override("panel", sbox_parchment)
	center.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Title
	var title_lbl := Label.new()
	title_lbl.text = "🧙‍♂️ PUSAT MODEL 3D & ELEMEN TEMPUR"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.12))
	vbox.add_child(title_lbl)
	
	var sub_lbl := Label.new()
	sub_lbl.text = "Import model 3D .glb sendiri & pilih elemen sihir (Mage Api, Es, Petir, Cahaya, Gelap, dll.)"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.14))
	vbox.add_child(sub_lbl)
	
	# Import Buttons
	var imp_box := HBoxContainer.new()
	imp_box.add_theme_constant_override("separation", 12)
	
	var imp_a := Button.new()
	imp_a.text = "📂 Import File .GLB untuk Tim A"
	imp_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	imp_a.custom_minimum_size = Vector2(0, 36)
	style_pixel_button(imp_a, true)
	imp_a.pressed.connect(func(): open_custom_file_dialog("A"))
	imp_box.add_child(imp_a)
	
	var imp_b := Button.new()
	imp_b.text = "📂 Import File .GLB untuk Tim B"
	imp_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	imp_b.custom_minimum_size = Vector2(0, 36)
	style_pixel_button(imp_b, true)
	imp_b.pressed.connect(func(): open_custom_file_dialog("B"))
	imp_box.add_child(imp_b)
	vbox.add_child(imp_box)
	
	var hint := Label.new()
	hint.text = "📁 Model di folder 'custom_models/' otomatis terbaca (Jokowi, Prabowo, Bung Karno, Elon Musk, dll.)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25))
	vbox.add_child(hint)
	
	vbox.add_child(HSeparator.new())
	
	# Side-by-side Columns
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	
	# Column Team A
	var col_a := VBoxContainer.new()
	col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a.add_theme_constant_override("separation", 5)
	
	var lbl_col_a := Label.new()
	lbl_col_a.text = "👑 KUBU A (TIM EMAS)"
	lbl_col_a.add_theme_color_override("font_color", Color(0.75, 0.45, 0.12))
	lbl_col_a.add_theme_font_size_override("font_size", 12)
	col_a.add_child(lbl_col_a)
	
	col_a.add_child(make_modal_field_label("Pilih Model 3D:"))
	modal_model_opt_a = OptionButton.new()
	modal_model_opt_a.custom_minimum_size = Vector2(0, 34)
	style_pixel_button(modal_model_opt_a, false)
	col_a.add_child(modal_model_opt_a)
	
	col_a.add_child(make_modal_field_label("Pilih Elemen / Kelas Tempur:"))
	modal_elem_opt_a = OptionButton.new()
	modal_elem_opt_a.custom_minimum_size = Vector2(0, 34)
	style_pixel_button(modal_elem_opt_a, false)
	col_a.add_child(modal_elem_opt_a)
	cols.add_child(col_a)
	
	# Column Team B
	var col_b := VBoxContainer.new()
	col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b.add_theme_constant_override("separation", 5)
	
	var lbl_col_b := Label.new()
	lbl_col_b.text = "🛡️ KUBU B (TIM BIRU)"
	lbl_col_b.add_theme_color_override("font_color", Color(0.18, 0.45, 0.75))
	lbl_col_b.add_theme_font_size_override("font_size", 12)
	col_b.add_child(lbl_col_b)
	
	col_b.add_child(make_modal_field_label("Pilih Model 3D:"))
	modal_model_opt_b = OptionButton.new()
	modal_model_opt_b.custom_minimum_size = Vector2(0, 34)
	style_pixel_button(modal_model_opt_b, false)
	col_b.add_child(modal_model_opt_b)
	
	col_b.add_child(make_modal_field_label("Pilih Elemen / Kelas Tempur:"))
	modal_elem_opt_b = OptionButton.new()
	modal_elem_opt_b.custom_minimum_size = Vector2(0, 34)
	style_pixel_button(modal_elem_opt_b, false)
	col_b.add_child(modal_elem_opt_b)
	cols.add_child(col_b)
	
	vbox.add_child(cols)
	vbox.add_child(HSeparator.new())
	
	# Action buttons
	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_CENTER
	acts.add_theme_constant_override("separation", 16)
	
	modal_apply_btn = Button.new()
	modal_apply_btn.text = "⚔️ TERAPKAN KE PERANG SEKARANG!"
	modal_apply_btn.custom_minimum_size = Vector2(280, 42)
	modal_apply_btn.add_theme_font_size_override("font_size", 12)
	style_pixel_button(modal_apply_btn, true)
	modal_apply_btn.pressed.connect(_on_modal_apply_pressed)
	acts.add_child(modal_apply_btn)
	
	modal_close_btn = Button.new()
	modal_close_btn.text = "✖ Tutup"
	modal_close_btn.custom_minimum_size = Vector2(100, 42)
	modal_close_btn.add_theme_font_size_override("font_size", 11)
	style_pixel_button(modal_close_btn, false)
	modal_close_btn.pressed.connect(func(): custom_model_modal.visible = false)
	acts.add_child(modal_close_btn)
	
	vbox.add_child(acts)

func make_modal_field_label(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25))
	return l

func open_custom_model_modal() -> void:
	if not custom_model_modal:
		return
	sync_modal_dropdowns()
	custom_model_modal.visible = true

func sync_modal_dropdowns() -> void:
	if not modal_model_opt_a or not modal_elem_opt_a:
		return
	modal_model_opt_a.clear()
	modal_elem_opt_a.clear()
	modal_model_opt_b.clear()
	modal_elem_opt_b.clear()
	
	for i in range(model_option_a.item_count):
		var txt = model_option_a.get_item_text(i)
		modal_model_opt_a.add_item(txt, i)
		modal_model_opt_b.add_item(txt, i)
	if model_option_a.selected >= 0:
		modal_model_opt_a.select(model_option_a.selected)
	if model_option_b.selected >= 0:
		modal_model_opt_b.select(model_option_b.selected)
		
	for i in range(option_a.item_count):
		var txt = option_a.get_item_text(i)
		modal_elem_opt_a.add_item(txt, i)
		modal_elem_opt_b.add_item(txt, i)
	if option_a.selected >= 0:
		modal_elem_opt_a.select(option_a.selected)
	if option_b.selected >= 0:
		modal_elem_opt_b.select(option_b.selected)

func _on_modal_apply_pressed() -> void:
	if modal_model_opt_a and modal_model_opt_a.selected >= 0:
		model_option_a.select(modal_model_opt_a.selected)
	if modal_elem_opt_a and modal_elem_opt_a.selected >= 0:
		option_a.select(modal_elem_opt_a.selected)
	if modal_model_opt_b and modal_model_opt_b.selected >= 0:
		model_option_b.select(modal_model_opt_b.selected)
	if modal_elem_opt_b and modal_elem_opt_b.selected >= 0:
		option_b.select(modal_elem_opt_b.selected)
		
	_on_apply_army_pressed()
	if custom_model_modal:
		custom_model_modal.visible = false

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
	if is_cutscene_playing:
		return
	if not manager or not manager.is_running:
		if super_ult_btn:
			play_ult_locked_shake(super_ult_btn)
		return
	if not super_ult_ready or super_mana_val < 100.0:
		if super_ult_btn:
			play_ult_locked_shake(super_ult_btn)
		return
		
	if super_ult_pulse_tween and super_ult_pulse_tween.is_valid():
		super_ult_pulse_tween.kill()
	super_ult_ready = false
	if super_ult_btn:
		super_ult_btn.scale = Vector2.ONE
	if manager:
		manager.reset_super_mana()
	super_mana_val = 0.0
	apply_super_ult_charging_style(0.0)
	play_super_ult_cutscene(0)

func apply_regular_ult_style(btn: Button, team_key: String) -> void:
	if not btn:
		return
	if team_key == "A":
		if sbox_capsule_gold:
			btn.add_theme_stylebox_override("normal", sbox_capsule_gold)
			btn.add_theme_stylebox_override("hover", sbox_capsule_gold)
			btn.add_theme_stylebox_override("pressed", sbox_capsule_gold)
			btn.add_theme_stylebox_override("focus", sbox_capsule_gold)
		btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		btn.text = "⚡ ULT A [1]"
	else:
		if sbox_capsule_blue:
			btn.add_theme_stylebox_override("normal", sbox_capsule_blue)
			btn.add_theme_stylebox_override("hover", sbox_capsule_blue)
			btn.add_theme_stylebox_override("pressed", sbox_capsule_blue)
			btn.add_theme_stylebox_override("focus", sbox_capsule_blue)
		btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
		btn.text = "⚡ ULT B [2]"

func apply_super_ult_charging_style(percent: float) -> void:
	if not super_ult_btn:
		return
	if percent >= 100.0:
		if sbox_capsule_red:
			super_ult_btn.add_theme_stylebox_override("normal", sbox_capsule_red)
			super_ult_btn.add_theme_stylebox_override("hover", sbox_capsule_red)
			super_ult_btn.add_theme_stylebox_override("pressed", sbox_capsule_red)
			super_ult_btn.add_theme_stylebox_override("focus", sbox_capsule_red)
		super_ult_btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.85))
		super_ult_btn.text = "🔥 SUPER ULT WHOOSH SIAP! [3]"
	else:
		if sbox_capsule_bg:
			super_ult_btn.add_theme_stylebox_override("normal", sbox_capsule_bg)
			super_ult_btn.add_theme_stylebox_override("hover", sbox_capsule_bg)
			super_ult_btn.add_theme_stylebox_override("pressed", sbox_capsule_bg)
			super_ult_btn.add_theme_stylebox_override("focus", sbox_capsule_bg)
		super_ult_btn.add_theme_color_override("font_color", Color(0.9, 0.65, 0.65))
		super_ult_btn.text = "🔮 MANA SUPER: %d%% [3]" % int(percent)

func play_super_ult_unlocked_animation() -> void:
	if not super_ult_btn:
		return
	if sbox_capsule_red:
		super_ult_btn.add_theme_stylebox_override("normal", sbox_capsule_red)
		super_ult_btn.add_theme_stylebox_override("hover", sbox_capsule_red)
		super_ult_btn.add_theme_stylebox_override("pressed", sbox_capsule_red)
		super_ult_btn.add_theme_stylebox_override("focus", sbox_capsule_red)
	super_ult_btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.85))
	super_ult_btn.text = "🔥 WHOOSH & GARUDA API! [3]"
	super_ult_btn.tooltip_text = "💥 MANA SUPER 100%! Tekan [3] untuk Meluncurkan Kereta Cepat Whoosh & Burung Garuda Api!"

	# Dramatic Scale Pop & Bounce Animation
	super_ult_btn.pivot_offset = super_ult_btn.size * 0.5
	super_ult_btn.scale = Vector2(0.85, 0.85)
	var pop_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tw.tween_property(super_ult_btn, "scale", Vector2(1.2, 1.2), 0.18)
	pop_tw.tween_property(super_ult_btn, "scale", Vector2(1.0, 1.0), 0.14)
	
	if audio_mgr and audio_mgr.has_method("play_horn"):
		audio_mgr.play_horn()

	if super_ult_pulse_tween and super_ult_pulse_tween.is_valid():
		super_ult_pulse_tween.kill()
	var pulse_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tw.tween_property(super_ult_btn, "scale", Vector2(1.06, 1.06), 0.45)
	pulse_tw.tween_property(super_ult_btn, "scale", Vector2(1.0, 1.0), 0.45)
	super_ult_pulse_tween = pulse_tw

func play_ult_locked_shake(btn: Button) -> void:
	if not btn:
		return
	btn.pivot_offset = btn.size * 0.5
	var orig_pos_x = btn.position.x
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(btn, "position:x", orig_pos_x - 7.0, 0.04)
	tw.tween_property(btn, "position:x", orig_pos_x + 7.0, 0.04)
	tw.tween_property(btn, "position:x", orig_pos_x - 4.0, 0.04)
	tw.tween_property(btn, "position:x", orig_pos_x + 4.0, 0.04)
	tw.tween_property(btn, "position:x", orig_pos_x, 0.04)
	btn.modulate = Color(1.0, 0.4, 0.4)
	var tw_col = create_tween()
	tw_col.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.25)

func _on_trigger_ult_a() -> void:
	if not manager or not manager.is_running:
		if ult_a_btn:
			play_ult_locked_shake(ult_a_btn)
		return
	if ult_a_btn:
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ult_a_btn, "scale", Vector2(0.9, 0.9), 0.08)
		tw.tween_property(ult_a_btn, "scale", Vector2(1.0, 1.0), 0.12)
	manager.trigger_team_ultimate(BattleUnit.Team.A)

func _on_trigger_ult_b() -> void:
	if not manager or not manager.is_running:
		if ult_b_btn:
			play_ult_locked_shake(ult_b_btn)
		return
	if ult_b_btn:
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ult_b_btn, "scale", Vector2(0.9, 0.9), 0.08)
		tw.tween_property(ult_b_btn, "scale", Vector2(1.0, 1.0), 0.12)
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
	if model_option_a.selected >= 0 and model_option_a.selected < model_keys.size():
		var current_mk = model_keys[model_option_a.selected]
		if current_mk.begins_with("custom_"):
			return # Preserve custom model!
	var pk = preset_keys[idx]
	var pconf = CharacterData.PRESETS[pk]
	var def_model = pconf.get("model_id", "soldier")
	var midx = model_keys.find(def_model)
	if midx >= 0:
		model_option_a.select(midx)

func _on_preset_b_selected(idx: int) -> void:
	if model_option_b.selected >= 0 and model_option_b.selected < model_keys.size():
		var current_mk = model_keys[model_option_b.selected]
		if current_mk.begins_with("custom_"):
			return # Preserve custom model!
	var pk = preset_keys[idx]
	var pconf = CharacterData.PRESETS[pk]
	var def_model = pconf.get("model_id", "xbot")
	var midx = model_keys.find(def_model)
	if midx >= 0:
		model_option_b.select(midx)

func set_slider_a(val: int) -> void:
	slider_a.value = val
	val_a_input.text = str(val)

func set_slider_b(val: int) -> void:
	slider_b.value = val
	val_b_input.text = str(val)

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

func get_clean_preset_titles(full_name: String) -> Dictionary:
	var title = full_name
	var sub = "DIVISI TAKTIS"
	if "(" in full_name and ")" in full_name:
		var p1 = full_name.find("(")
		var p2 = full_name.find(")")
		title = full_name.substr(0, p1).strip_edges()
		sub = full_name.substr(p1 + 1, p2 - p1 - 1).strip_edges()
	return {"title": title, "sub": sub}

func cycle_next_preset() -> void:
	current_preset_idx = (current_preset_idx + 1) % 6
	match current_preset_idx:
		0: apply_preset_matchup("archer", "soldier", 60, "swordsman", "soldier", 60)
		1: apply_preset_matchup("archer", "soldier", 150, "cyborg", "xbot", 150)
		2: apply_preset_matchup("titan", "soldier", 1, "archer", "soldier", 300)
		3: apply_preset_matchup("tyson", "robot_expressive", 200, "swordsman", "soldier", 200)
		4: apply_preset_matchup("archer", "soldier", 500, "swordsman", "soldier", 500)
		5: apply_preset_matchup("commando", "soldier", 1000, "cyborg", "xbot", 1000)

func cycle_next_camera() -> void:
	current_cam_idx = (current_cam_idx + 1) % 4
	set_camera(current_cam_idx)

func update_header_names() -> void:
	if preset_keys.size() > option_a.selected:
		var pdata_a = CharacterData.PRESETS[preset_keys[option_a.selected]]
		var pname_a = pdata_a.get("name", "Kubu A")
		var clean_a = get_clean_preset_titles(pname_a)
		name_a_label.text = "• " + clean_a["title"].to_upper() + " • 32"
		if sub_a_label:
			sub_a_label.text = clean_a["sub"].to_upper()
	if preset_keys.size() > option_b.selected:
		var pdata_b = CharacterData.PRESETS[preset_keys[option_b.selected]]
		var pname_b = pdata_b.get("name", "Kubu B")
		var clean_b = get_clean_preset_titles(pname_b)
		name_b_label.text = "32 • " + clean_b["title"].to_upper() + " •"
		if sub_b_label:
			sub_b_label.text = clean_b["sub"].to_upper()

func set_camera(mode_idx: int) -> void:
	if camera and camera.has_method("set_mode"):
		camera.set_mode(mode_idx)

func _on_start_pressed() -> void:
	if manager:
		if manager.battle_finished:
			_on_rematch_pressed()
			return
		manager.start_battle()
		start_btn.text = "🔥 PERANG SEDANG BERLANGSUNG"

func _on_pause_pressed() -> void:
	if manager:
		var is_running = manager.toggle_pause()
		pause_btn.text = "▶️" if not is_running else "⏸️"

func _on_reset_pressed() -> void:
	victory_modal.visible = false
	super_ult_ready = false
	if super_ult_pulse_tween and super_ult_pulse_tween.is_valid():
		super_ult_pulse_tween.kill()
	if super_ult_btn:
		super_ult_btn.scale = Vector2.ONE
		apply_super_ult_charging_style(0.0)
	if ult_a_btn:
		ult_a_btn.scale = Vector2.ONE
		apply_regular_ult_style(ult_a_btn, "A")
	if ult_b_btn:
		ult_b_btn.scale = Vector2.ONE
		apply_regular_ult_style(ult_b_btn, "B")
	if manager:
		manager.setup_battle()
		start_btn.text = "⚔️ MULAI PERANG!"
		pause_btn.text = "⏸️"

func set_speed(speed: float, _active_btn: Button) -> void:
	if manager:
		manager.set_speed(speed)
	if tempo_counter_label:
		tempo_counter_label.text = "TEMPO: %.1fx" % speed

func show_victory(winner: String, survivors: int, time_sec: float) -> void:
	victory_modal.visible = true
	winner_lbl.text = "🏆 " + winner + " MENANG!"
	var mins = int(time_sec / 60.0)
	var secs = int(time_sec) % 60
	stats_lbl.text = "Sisa Pasukan: %d | Durasi Perang: %02d:%02d" % [survivors, mins, secs]
	start_btn.text = "🏆 " + winner + " MENANG! (Klik Tanding Ulang)"
	
	# Smooth subtle entrance
	victory_modal.modulate.a = 0.0
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(victory_modal, "modulate:a", 1.0, 0.25)

func _on_rematch_pressed() -> void:
	victory_modal.visible = false
	_on_reset_pressed()

func update_stats(alive_a: int, total_a: int, alive_b: int, total_b: int, time_sec: float, running: bool, super_mana: float = 0.0) -> void:
	if count_a_label:
		count_a_label.text = "%d / %d" % [alive_a, total_a]
	if count_b_label:
		count_b_label.text = "%d / %d" % [alive_b, total_b]
		
	if hp_bar_a:
		hp_bar_a.max_value = max(total_a, 1)
		hp_bar_a.value = alive_a
	if hp_bar_b:
		hp_bar_b.max_value = max(total_b, 1)
		hp_bar_b.value = alive_b

	if exp_bar_a:
		var pct_a = int((float(alive_a) / max(total_a, 1)) * 100.0)
		exp_bar_a.value = pct_a
		if exp_label_a:
			exp_label_a.text = "%d%%" % pct_a
	if exp_bar_b:
		var pct_b = int((float(alive_b) / max(total_b, 1)) * 100.0)
		exp_bar_b.value = pct_b
		if exp_label_b:
			exp_label_b.text = "%d%%" % pct_b

	var dead_total = (total_a - alive_a) + (total_b - alive_b)
	if kill_counter_label:
		kill_counter_label.text = "KORBAN: %d" % dead_total
		
	if timer_label:
		var mins = int(time_sec / 60.0)
		var secs = int(time_sec) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		
	super_mana_val = super_mana
	if super_ult_btn:
		if super_mana >= 100.0:
			if not super_ult_ready:
				super_ult_ready = true
				play_super_ult_unlocked_animation()
		else:
			if super_ult_ready:
				if super_ult_pulse_tween and super_ult_pulse_tween.is_valid():
					super_ult_pulse_tween.kill()
				super_ult_btn.scale = Vector2.ONE
				super_ult_ready = false
			apply_super_ult_charging_style(super_mana)
		
	if not running and start_btn and not victory_modal.visible:
		if alive_a == 0 or alive_b == 0:
			var winner = name_a_label.text if alive_a > 0 else name_b_label.text
			start_btn.text = "🏆 " + winner + " MENANG!"
		else:
			start_btn.text = "⚔️ MULAI PERANG!"
			
	if arena and "is_performance_mode" in arena and perf_mode_btn:
		var btn_is_crowd = perf_mode_btn.text.begins_with("⚡")
		if btn_is_crowd != arena.is_performance_mode:
			update_perf_mode_btn_text(arena.is_performance_mode)

