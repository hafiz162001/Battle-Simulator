class_name SuperUltWhooshGaruda
extends Node3D

const HitSparksClass = preload("res://scripts/hit_sparks.gd")
const DamageNumberClass = preload("res://scripts/damage_number.gd")

var team: int = 0
var charge_dir: Vector3 = Vector3.RIGHT
var speed: float = 48.0
var travel_dist: float = 0.0
var max_travel: float = 130.0
var damage: float = 350.0
var camera: Camera3D = null
var audio_mgr: Node = null
var arena: Node3D = null

var hit_units: Dictionary = {}
var horn_played: bool = false
var anim_time: float = 0.0

# Visual nodes
var body_root: Node3D = null
var train_root: Node3D = null
var garuda_root: Node3D = null
var garuda_wing_l: Node3D = null
var garuda_wing_r: Node3D = null
var garuda_tail_plumes: Array[Node3D] = []

func _ready() -> void:
	build_whoosh_and_garuda()

func launch(p_team: int, p_camera: Camera3D, p_audio: Node, p_arena: Node3D = null) -> void:
	team = p_team
	camera = p_camera
	audio_mgr = p_audio
	arena = p_arena
	
	# Team 0 (Team A) charges from West to East (Left to Right)
	# Team 1 (Team B) charges from East to West (Right to Left)
	if team == 0:
		charge_dir = Vector3.RIGHT
		global_position = Vector3(-55.0, 0.2, (randf() - 0.5) * 6.0)
		rotation.y = PI / 2.0
	else:
		charge_dir = Vector3.LEFT
		global_position = Vector3(55.0, 0.2, (randf() - 0.5) * 6.0)
		rotation.y = -PI / 2.0
		
	if camera and camera.has_method("add_shake"):
		camera.add_shake(1.8)
		
	if audio_mgr and audio_mgr.has_method("set_super_ult_active"):
		audio_mgr.set_super_ult_active(true)
		
	if audio_mgr:
		if audio_mgr.has_method("play_super_ult_a"):
			audio_mgr.play_super_ult_a()
		else:
			if audio_mgr.has_method("play_horn"):
				audio_mgr.play_horn()
			if audio_mgr.has_method("play_explosion"):
				audio_mgr.play_explosion(true)

func build_whoosh_and_garuda() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	
	# 1. BUILD AUTHENTIC WHOOSH CR400AF BULLET TRAIN
	build_whoosh_bullet_train()
	
	# 2. BUILD MAJESTIC FLAMING GARUDA PHOENIX SOARING ABOVE
	build_flaming_garuda()

# ==============================================================================
# 1. AUTHENTIC WHOOSH CR400AF BULLET TRAIN (KCIC RED KOMODO)
# ==============================================================================
func build_whoosh_bullet_train() -> void:
	train_root = Node3D.new()
	train_root.name = "WhooshBulletTrain"
	body_root.add_child(train_root)
	
	# --- Materials ---
	# Metallic Silver / Pearl White Body
	var mat_silver := StandardMaterial3D.new()
	mat_silver.albedo_color = Color("#f1f5f9")
	mat_silver.metallic = 0.9
	mat_silver.roughness = 0.15
	
	# Signature KCIC Whoosh Crimson Red
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color("#c8102e") # Authentic Whoosh Red
	mat_red.metallic = 0.85
	mat_red.roughness = 0.2
	
	# Magenta / Maroon Speed Ribbon Accent
	var mat_maroon := StandardMaterial3D.new()
	mat_maroon.albedo_color = Color("#831843")
	mat_maroon.metallic = 0.8
	mat_maroon.roughness = 0.25
	
	# Aerodynamic Tinted Cockpit Glass
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color("#090d16")
	mat_glass.metallic = 0.95
	mat_glass.roughness = 0.04
	
	# Dark Undercarriage & Wheels
	var mat_dark_steel := StandardMaterial3D.new()
	mat_dark_steel.albedo_color = Color("#1e293b")
	mat_dark_steel.metallic = 0.8
	mat_dark_steel.roughness = 0.5
	
	# Xenon Headlights
	var mat_headlight := StandardMaterial3D.new()
	mat_headlight.albedo_color = Color("#ffffff")
	mat_headlight.emission_enabled = true
	mat_headlight.emission = Color("#e0f2fe")
	mat_headlight.emission_energy_multiplier = 5.0
	mat_headlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# --- A. NOSE SECTION (Lead Locomotive) ---
	# 1. Aerodynamic Tapered Bullet Nose (Lower Snout)
	var snout_mesh := CylinderMesh.new()
	snout_mesh.top_radius = 0.2
	snout_mesh.bottom_radius = 1.75
	snout_mesh.height = 5.5
	
	var snout := MeshInstance3D.new()
	snout.mesh = snout_mesh
	snout.material_override = mat_silver
	snout.rotation_degrees = Vector3(90, 0, 0)
	snout.position = Vector3(0, 1.45, 8.5)
	train_root.add_child(snout)
	
	# 2. Nose Cone Rounded Tip
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius = 0.75
	tip_mesh.height = 1.5
	var tip := MeshInstance3D.new()
	tip.mesh = tip_mesh
	tip.material_override = mat_silver
	tip.position = Vector3(0, 1.45, 11.2)
	train_root.add_child(tip)
	
	# 3. Signature Whoosh Red Mask Canopy (Nose Red Hood)
	var hood_mesh := CylinderMesh.new()
	hood_mesh.top_radius = 0.1
	hood_mesh.bottom_radius = 1.78
	hood_mesh.height = 4.8
	var hood := MeshInstance3D.new()
	hood.mesh = hood_mesh
	hood.material_override = mat_red
	hood.rotation_degrees = Vector3(88, 0, 0)
	hood.position = Vector3(0, 1.75, 8.2)
	hood.scale = Vector3(0.96, 0.45, 0.96) # Flattened upper hood wrap
	train_root.add_child(hood)
	
	# 4. Aerodynamic Cockpit Windshield (Curved Dark Visor)
	var wind_mesh := BoxMesh.new()
	wind_mesh.size = Vector3(2.6, 0.85, 2.2)
	var windshield := MeshInstance3D.new()
	windshield.mesh = wind_mesh
	windshield.material_override = mat_glass
	windshield.position = Vector3(0, 2.35, 6.6)
	windshield.rotation_degrees.x = -32.0
	train_root.add_child(windshield)
	
	# 5. Dual Sleek Angular LED Headlights
	for side in [-1.05, 1.05]:
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.55, 0.28, 0.25)
		var hl := MeshInstance3D.new()
		hl.mesh = hl_mesh
		hl.material_override = mat_headlight
		hl.position = Vector3(side, 1.4, 10.4)
		hl.rotation_degrees.y = -15.0 if side > 0 else 15.0
		train_root.add_child(hl)
		
		# High-Intensity Forward Headlight Beams
		var spot := SpotLight3D.new()
		spot.light_color = Color(1.0, 0.96, 0.88)
		spot.light_energy = 9.0
		spot.spot_range = 45.0
		spot.spot_angle = 32.0
		spot.position = Vector3(side, 1.4, 10.8)
		train_root.add_child(spot)
		
	# 6. Aerodynamic Chin Deflector
	var chin_mesh := PrismMesh.new()
	chin_mesh.size = Vector3(3.2, 0.75, 2.0)
	var chin := MeshInstance3D.new()
	chin.mesh = chin_mesh
	chin.material_override = mat_dark_steel
	chin.position = Vector3(0, 0.65, 9.8)
	chin.rotation_degrees = Vector3(0, 180, 0)
	train_root.add_child(chin)

	# --- B. LEAD LOCOMOTIVE CAR BODY ---
	var car1_mesh := BoxMesh.new()
	car1_mesh.size = Vector3(3.4, 2.7, 13.0)
	var car1 := MeshInstance3D.new()
	car1.mesh = car1_mesh
	car1.material_override = mat_silver
	car1.position = Vector3(0, 1.85, 0.0)
	train_root.add_child(car1)
	
	# Curved Upper Roof Fairing
	var roof1_mesh := CylinderMesh.new()
	roof1_mesh.top_radius = 1.7
	roof1_mesh.bottom_radius = 1.7
	roof1_mesh.height = 13.0
	var roof1 := MeshInstance3D.new()
	roof1.mesh = roof1_mesh
	roof1.material_override = mat_silver
	roof1.rotation_degrees = Vector3(90, 0, 0)
	roof1.position = Vector3(0, 2.85, 0.0)
	roof1.scale = Vector3(1.0, 0.35, 1.0)
	train_root.add_child(roof1)
	
	# Signature Red & Maroon Speed Ribbon (Lateral Stripes)
	var stripe_red := BoxMesh.new()
	stripe_red.size = Vector3(3.46, 0.45, 13.1)
	var s_red_inst := MeshInstance3D.new()
	s_red_inst.mesh = stripe_red
	s_red_inst.material_override = mat_red
	s_red_inst.position = Vector3(0, 1.95, 0.0)
	train_root.add_child(s_red_inst)
	
	var stripe_maroon := BoxMesh.new()
	stripe_maroon.size = Vector3(3.48, 0.16, 13.1)
	var s_mar_inst := MeshInstance3D.new()
	s_mar_inst.mesh = stripe_maroon
	s_mar_inst.material_override = mat_maroon
	s_mar_inst.position = Vector3(0, 1.6, 0.0)
	train_root.add_child(s_mar_inst)
	
	# Dark Passenger Window Ribbon
	for side in [-1.72, 1.72]:
		var win_strip := BoxMesh.new()
		win_strip.size = Vector3(0.08, 0.65, 11.5)
		var w_inst := MeshInstance3D.new()
		w_inst.mesh = win_strip
		w_inst.material_override = mat_glass
		w_inst.position = Vector3(side, 2.2, 0.0)
		train_root.add_child(w_inst)
		
	# Aerodynamic Side Skirts
	for side in [-1.68, 1.68]:
		var skirt_mesh := BoxMesh.new()
		skirt_mesh.size = Vector3(0.12, 0.7, 13.0)
		var skirt := MeshInstance3D.new()
		skirt.mesh = skirt_mesh
		skirt.material_override = mat_dark_steel
		skirt.position = Vector3(side, 0.65, 0.0)
		train_root.add_child(skirt)

	# --- C. ARTICULATED GANGWAY (Connection) ---
	var gangway_mesh := BoxMesh.new()
	gangway_mesh.size = Vector3(3.0, 2.5, 1.2)
	var gangway := MeshInstance3D.new()
	gangway.mesh = gangway_mesh
	gangway.material_override = mat_dark_steel
	gangway.position = Vector3(0, 1.8, -7.0)
	train_root.add_child(gangway)

	# --- D. SECOND PASSENGER COACH ---
	var car2_mesh := BoxMesh.new()
	car2_mesh.size = Vector3(3.4, 2.7, 12.0)
	var car2 := MeshInstance3D.new()
	car2.mesh = car2_mesh
	car2.material_override = mat_silver
	car2.position = Vector3(0, 1.85, -13.5)
	train_root.add_child(car2)
	
	# Car 2 Stripes & Windows
	var s2_red := MeshInstance3D.new()
	s2_red.mesh = stripe_red
	s2_red.material_override = mat_red
	s2_red.position = Vector3(0, 1.95, -13.5)
	train_root.add_child(s2_red)
	
	for side in [-1.72, 1.72]:
		var w2 := MeshInstance3D.new()
		var win_strip2 := BoxMesh.new()
		win_strip2.size = Vector3(0.08, 0.65, 11.0)
		w2.mesh = win_strip2
		w2.material_override = mat_glass
		w2.position = Vector3(side, 2.2, -13.5)
		train_root.add_child(w2)
		
	# --- E. HIGH-SPEED AERODYNAMIC PANTOGRAPH ---
	var panto_base := BoxMesh.new()
	panto_base.size = Vector3(1.4, 0.2, 1.8)
	var p_base := MeshInstance3D.new()
	p_base.mesh = panto_base
	p_base.material_override = mat_dark_steel
	p_base.position = Vector3(0, 3.25, -12.0)
	train_root.add_child(p_base)
	
	# Pantograph Angled Arm
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.12, 1.5, 0.12)
	var arm := MeshInstance3D.new()
	arm.mesh = arm_mesh
	arm.material_override = mat_red
	arm.position = Vector3(0, 3.9, -12.0)
	arm.rotation_degrees.x = 35.0
	train_root.add_child(arm)
	
	# Pantograph Collector Shoe
	var shoe_mesh := BoxMesh.new()
	shoe_mesh.size = Vector3(2.4, 0.1, 0.35)
	var shoe := MeshInstance3D.new()
	shoe.mesh = shoe_mesh
	shoe.material_override = mat_dark_steel
	shoe.position = Vector3(0, 4.45, -11.5)
	train_root.add_child(shoe)

# ==============================================================================
# 2. MAJESTIC FLAMING BURUNG GARUDA (FIERY PHOENIX EAGLE)
# ==============================================================================
func build_flaming_garuda() -> void:
	garuda_root = Node3D.new()
	garuda_root.name = "FlamingGarudaPhoenix"
	garuda_root.position = Vector3(0, 8.5, 1.5) # Soaring directly above the Whoosh train!
	body_root.add_child(garuda_root)
	
	# --- Flaming Materials ---
	# Intense Golden Fire Feather Material
	var mat_fire_gold := StandardMaterial3D.new()
	mat_fire_gold.albedo_color = Color("#f59e0b")
	mat_fire_gold.emission_enabled = true
	mat_fire_gold.emission = Color("#fbbf24")
	mat_fire_gold.emission_energy_multiplier = 3.2
	mat_fire_gold.roughness = 0.3
	
	# Blazing Red/Orange Flame Material
	var mat_fire_orange := StandardMaterial3D.new()
	mat_fire_orange.albedo_color = Color("#ea580c")
	mat_fire_orange.emission_enabled = true
	mat_fire_orange.emission = Color("#f97316")
	mat_fire_orange.emission_energy_multiplier = 4.0
	mat_fire_orange.roughness = 0.2
	
	# Deep Crimson Fire Plume Material
	var mat_fire_crimson := StandardMaterial3D.new()
	mat_fire_crimson.albedo_color = Color("#b91c1c")
	mat_fire_crimson.emission_enabled = true
	mat_fire_crimson.emission = Color("#ef4444")
	mat_fire_crimson.emission_energy_multiplier = 2.8
	
	# Golden Predatory Beak & Talons
	var mat_beak := StandardMaterial3D.new()
	mat_beak.albedo_color = Color("#eab308")
	mat_beak.metallic = 0.8
	mat_beak.roughness = 0.25
	mat_beak.emission_enabled = true
	mat_beak.emission = Color("#f59e0b")
	mat_beak.emission_energy_multiplier = 1.5
	
	# White-Hot Piercing Fire Eyes
	var mat_eye := StandardMaterial3D.new()
	mat_eye.albedo_color = Color("#ffffff")
	mat_eye.emission_enabled = true
	mat_eye.emission = Color("#fef08a")
	mat_eye.emission_energy_multiplier = 7.0
	mat_eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Radiating Warm Fire Light
	var fire_light := OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.65, 0.2)
	fire_light.light_energy = 8.0
	fire_light.omni_range = 35.0
	garuda_root.add_child(fire_light)

	# --- A. GARUDA EAGLE TORSO & CHEST ---
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 1.4
	body_mesh.height = 3.8
	var torso := MeshInstance3D.new()
	torso.mesh = body_mesh
	torso.material_override = mat_fire_orange
	torso.scale = Vector3(1.1, 0.9, 1.4)
	torso.position = Vector3(0, 0, 0)
	garuda_root.add_child(torso)
	
	# Blazing Fiery Chest Crest
	var chest_mesh := PrismMesh.new()
	chest_mesh.size = Vector3(1.8, 2.2, 1.2)
	var chest := MeshInstance3D.new()
	chest.mesh = chest_mesh
	chest.material_override = mat_fire_gold
	chest.position = Vector3(0, -0.4, 1.2)
	chest.rotation_degrees.x = -25.0
	garuda_root.add_child(chest)

	# --- B. FIERCE EAGLE HEAD & HOOKED BEAK ---
	var head_node := Node3D.new()
	head_node.position = Vector3(0, 0.7, 2.4)
	garuda_root.add_child(head_node)
	
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.85
	head_mesh.height = 1.7
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = mat_fire_gold
	head.scale = Vector3(0.9, 1.0, 1.1)
	head_node.add_child(head)
	
	# Hooked Golden Predatory Eagle Beak (Open Screaming Cry)
	var beak_top_mesh := PrismMesh.new()
	beak_top_mesh.size = Vector3(0.65, 1.4, 0.7)
	var beak_top := MeshInstance3D.new()
	beak_top.mesh = beak_top_mesh
	beak_top.material_override = mat_beak
	beak_top.position = Vector3(0, 0.1, 1.2)
	beak_top.rotation_degrees = Vector3(82, 0, 0)
	head_node.add_child(beak_top)
	
	var beak_bot_mesh := PrismMesh.new()
	beak_bot_mesh.size = Vector3(0.45, 0.9, 0.5)
	var beak_bot := MeshInstance3D.new()
	beak_bot.mesh = beak_bot_mesh
	beak_bot.material_override = mat_beak
	beak_bot.position = Vector3(0, -0.35, 1.0)
	beak_bot.rotation_degrees = Vector3(105, 0, 0)
	head_node.add_child(beak_bot)
	
	# Piercing White-Hot Eyes
	for side in [-0.52, 0.52]:
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.18
		eye_mesh.height = 0.36
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = mat_eye
		eye.position = Vector3(side, 0.25, 0.65)
		head_node.add_child(eye)
		
	# Fiery Feathered Crown Crest Trailing Back
	for i in range(4):
		var crest_blade := PrismMesh.new()
		crest_blade.size = Vector3(0.4, 1.8 - i * 0.25, 0.35)
		var c_inst := MeshInstance3D.new()
		c_inst.mesh = crest_blade
		c_inst.material_override = mat_fire_orange if i % 2 == 0 else mat_fire_gold
		c_inst.position = Vector3((i - 1.5) * 0.25, 0.8 + i * 0.12, -0.4 - i * 0.4)
		c_inst.rotation_degrees = Vector3(-45.0, 0, (i - 1.5) * 12.0)
		head_node.add_child(c_inst)

	# --- C. MASSIVE FLAPPING WINGS (LEFT & RIGHT) ---
	garuda_wing_l = Node3D.new()
	garuda_wing_l.name = "WingLeft"
	garuda_wing_l.position = Vector3(-1.2, 0.4, 0.2)
	garuda_root.add_child(garuda_wing_l)
	
	garuda_wing_r = Node3D.new()
	garuda_wing_r.name = "WingRight"
	garuda_wing_r.position = Vector3(1.2, 0.4, 0.2)
	garuda_root.add_child(garuda_wing_r)
	
	# Build multi-tiered flaming wing plumes on both wings
	build_wing_feathers(garuda_wing_l, -1.0, mat_fire_gold, mat_fire_orange, mat_fire_crimson)
	build_wing_feathers(garuda_wing_r, 1.0, mat_fire_gold, mat_fire_orange, mat_fire_crimson)

	# --- D. MAJESTIC WAVING FLAMING TAIL ---
	for i in range(5):
		var tail_node := Node3D.new()
		tail_node.position = Vector3((i - 2) * 0.5, -0.2, -1.8)
		garuda_root.add_child(tail_node)
		garuda_tail_plumes.append(tail_node)
		
		var plume_mesh := PrismMesh.new()
		var length = 4.5 - abs(i - 2) * 0.6
		plume_mesh.size = Vector3(0.7, length, 0.18)
		var p_inst := MeshInstance3D.new()
		p_inst.mesh = plume_mesh
		p_inst.material_override = mat_fire_gold if i == 2 else (mat_fire_orange if i % 2 == 1 else mat_fire_crimson)
		p_inst.position = Vector3(0, -0.3, -length * 0.45)
		p_inst.rotation_degrees = Vector3(-75.0, (i - 2) * 12.0, 0)
		tail_node.add_child(p_inst)

	# --- E. PREDATORY TALONS OF FIRE ---
	for side in [-0.85, 0.85]:
		var talon_node := Node3D.new()
		talon_node.position = Vector3(side, -1.1, 0.6)
		garuda_root.add_child(talon_node)
		
		# 3 Curved Front Claws
		for claw_i in range(3):
			var claw_mesh := CylinderMesh.new()
			claw_mesh.top_radius = 0.04
			claw_mesh.bottom_radius = 0.16
			claw_mesh.height = 1.1
			var claw := MeshInstance3D.new()
			claw.mesh = claw_mesh
			claw.material_override = mat_beak
			claw.position = Vector3((claw_i - 1) * 0.28, -0.3, 0.4)
			claw.rotation_degrees = Vector3(45.0, (claw_i - 1) * 20.0, 0)
			talon_node.add_child(claw)

func build_wing_feathers(wing_node: Node3D, side_mult: float, mat_gold: Material, mat_orange: Material, mat_crimson: Material) -> void:
	# Primary, Secondary & Tertiary Fiery Feather Layers spreading 18+ meters!
	for tier in range(4):
		var feather_count = 6
		for f in range(feather_count):
			var feather_mesh := PrismMesh.new()
			var length = 5.8 - tier * 0.8 - f * 0.35
			var width = 0.85 - tier * 0.1
			feather_mesh.size = Vector3(width, length, 0.15)
			
			var feather := MeshInstance3D.new()
			feather.mesh = feather_mesh
			
			if (tier + f) % 3 == 0:
				feather.material_override = mat_gold
			elif (tier + f) % 3 == 1:
				feather.material_override = mat_orange
			else:
				feather.material_override = mat_crimson
				
			var span_offset = side_mult * (1.2 + f * 1.35 + tier * 0.6)
			var backward_offset = -0.4 - f * 0.55 - tier * 0.4
			var height_offset = tier * 0.35 + sin(f * 0.5) * 0.4
			
			feather.position = Vector3(span_offset, height_offset, backward_offset)
			feather.rotation_degrees = Vector3(
				-20.0 - tier * 8.0,
				side_mult * (-35.0 - f * 8.0),
				side_mult * (30.0 + f * 6.0 + tier * 4.0)
			)
			wing_node.add_child(feather)

# ==============================================================================
# ANIMATION & MOVEMENT PROCESS
# ==============================================================================
func _process(delta: float) -> void:
	anim_time += delta
	var move_step = speed * delta
	travel_dist += move_step
	global_position += charge_dir * move_step
	
	# Stick train to ground height
	if arena and arena.has_method("get_ground_height"):
		var target_y = arena.get_ground_height(global_position.x, global_position.z) + 0.2
		global_position.y = lerp(global_position.y, target_y, delta * 12.0)
		
	# Ground vibration and camera shake
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.35)
		
	# DYNAMIC GARUDA FLAPPING WINGS & FLIGHT MOTION
	if garuda_root and garuda_wing_l and garuda_wing_r:
		# Flapping motion
		var flap = sin(anim_time * 8.5) * 0.48
		garuda_wing_l.rotation.z = -flap
		garuda_wing_r.rotation.z = flap
		
		# Flight bobbing and soaring sway
		garuda_root.position.y = 8.5 + sin(anim_time * 4.2) * 0.9
		garuda_root.position.x = sin(anim_time * 2.5) * 0.6
		garuda_root.rotation.z = sin(anim_time * 2.5) * 0.12
		
		# Tail undulation
		for i in range(garuda_tail_plumes.size()):
			var t_node = garuda_tail_plumes[i]
			t_node.rotation.x = sin(anim_time * 6.0 + i * 0.7) * 0.22
			
	# Check collision with opposing units ("menabrak lawan-lawan")
	ram_opponents()
	
	# Spawn sparks and fiery embers
	if randf() < 0.8:
		spawn_wheel_sparks()
	if randf() < 0.7:
		spawn_garuda_fire_embers()
		
	# Self clean up when reaching arena perimeter
	if travel_dist >= max_travel or abs(global_position.x) > 58.0:
		on_charge_complete()

func ram_opponents() -> void:
	var tree = get_tree()
	if not tree:
		return
		
	var opp_team = 1 if team == 0 else 0
	var units = tree.get_nodes_in_group("units")
	
	for u in units:
		if is_instance_valid(u) and not u.is_dead and u.team == opp_team:
			var uid = u.get_instance_id()
			if hit_units.has(uid):
				continue
				
			var u_pos = u.global_position
			var to_unit = u_pos - global_position
			
			# Check distance along charge axis and lateral width
			var dist_forward = to_unit.dot(charge_dir)
			var lateral_vec = to_unit - charge_dir * dist_forward
			var lateral_dist = lateral_vec.length()
			
			# Ram Hitbox: 14m forward, 7.5m sideways (matching Whoosh & wide Garuda wingspan)
			if dist_forward >= -8.0 and dist_forward <= 12.0 and lateral_dist <= 7.8:
				hit_units[uid] = true
				ram_unit(u)

func ram_unit(target: Node) -> void:
	# Enormous upward and forward catapulting launch
	var launch_velocity = charge_dir * randf_range(52.0, 72.0) + Vector3(
		(randf() - 0.5) * 16.0,
		randf_range(20.0, 32.0), # Launch high into sky!
		(randf() - 0.5) * 16.0
	)
	
	if "velocity" in target:
		target.velocity = launch_velocity
		
	var is_fatal = (target.hp <= damage)
	var banner_title = "🚄 DITABRAK WHOOSH 350 KM/H!"
	var banner_color = Color(1.0, 0.2, 0.2)
	
	if randf() < 0.5:
		banner_title = "🦅 SAMBARAN GARUDA API!"
		banner_color = Color(1.0, 0.65, 0.1)
	elif is_fatal:
		banner_title = "💥 OBLITERATED IN FLAMES!"
		banner_color = Color(1.0, 0.9, 0.2)
		
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = target.global_position + Vector3(0, 2.5 * target.unit_scale, 0)
	dmg_label.setup_banner(banner_title, banner_color)
	
	target.take_damage(damage, global_position)
	
	# Massive hit sparks, fire burst and explosions
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(target.global_position, true)
	
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.95)
		
	if audio_mgr and audio_mgr.has_method("play_hit"):
		audio_mgr.play_hit(true)

func spawn_wheel_sparks() -> void:
	var spark_pos = global_position + Vector3(
		(randf() - 0.5) * 3.2,
		0.1,
		(randf() - 0.5) * 14.0
	)
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(spark_pos, false)

func spawn_garuda_fire_embers() -> void:
	if not garuda_root:
		return
	var ember_pos = garuda_root.global_position + Vector3(
		(randf() - 0.5) * 14.0,
		(randf() - 0.5) * 3.0,
		(randf() - 0.5) * 8.0
	)
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(ember_pos, true)

func on_charge_complete() -> void:
	if audio_mgr and audio_mgr.has_method("play_explosion"):
		audio_mgr.play_explosion(true)
	if audio_mgr and audio_mgr.has_method("set_super_ult_active"):
		audio_mgr.set_super_ult_active(false)
	queue_free()
