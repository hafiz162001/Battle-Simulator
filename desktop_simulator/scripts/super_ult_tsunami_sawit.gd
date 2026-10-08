class_name SuperUltTsunamiSawit
extends Node3D

const HitSparksClass = preload("res://scripts/hit_sparks.gd")
const DamageNumberClass = preload("res://scripts/damage_number.gd")

var team: int = 1
var charge_dir: Vector3 = Vector3.LEFT
var speed: float = 46.0
var travel_dist: float = 0.0
var max_travel: float = 140.0
var damage: float = 380.0
var camera: Camera3D = null
var audio_mgr: Node = null
var arena: Node3D = null

var hit_units: Dictionary = {}
var anim_time: float = 0.0

# Visual nodes
var body_root: Node3D = null
var wave_root: Node3D = null
var sawit_root: Node3D = null
var crest_lip: Node3D = null
var wave_light: OmniLight3D = null

var sawit_bunches: Array[Node3D] = []
var bunch_velocities: Array[Vector3] = []
var loose_fruits: Array[Node3D] = []
var palm_fronds: Array[Node3D] = []
var oil_ribbons: Array[MeshInstance3D] = []
var wave_mesh_instances: Array[MeshInstance3D] = []

var spray_particles: CPUParticles3D = null
var oil_particles: CPUParticles3D = null
var foam_particles: CPUParticles3D = null
var mist_particles: CPUParticles3D = null

# Materials
var mat_water_deep: StandardMaterial3D
var mat_water_trans: StandardMaterial3D
var mat_oil_gold: StandardMaterial3D
var mat_oil_dark: StandardMaterial3D
var mat_foam_white: StandardMaterial3D
var mat_sawit_skin_ripe: StandardMaterial3D
var mat_sawit_skin_mid: StandardMaterial3D
var mat_sawit_base_dark: StandardMaterial3D
var mat_stalk_fibrous: StandardMaterial3D
var mat_frond_green: StandardMaterial3D
var mat_wet_sand: StandardMaterial3D

func _ready() -> void:
	build_materials()
	build_tsunami_and_sawit()

func launch(p_team: int, p_camera: Camera3D, p_audio: Node, p_arena: Node3D = null) -> void:
	team = p_team
	camera = p_camera
	audio_mgr = p_audio
	arena = p_arena
	
	# Team 1 (Kubu B / East) attacks Westward; Team 0 (Kubu A / West) attacks Eastward
	if team == 1:
		charge_dir = Vector3.LEFT
		global_position = Vector3(58.0, 0.0, (randf() - 0.5) * 3.0)
		rotation.y = -PI / 2.0
	else:
		charge_dir = Vector3.RIGHT
		global_position = Vector3(-58.0, 0.0, (randf() - 0.5) * 3.0)
		rotation.y = PI / 2.0
		
	if camera and camera.has_method("add_shake"):
		camera.add_shake(2.4)
		
	if audio_mgr:
		if audio_mgr.has_method("play_whirlwind"):
			audio_mgr.play_whirlwind()
		if audio_mgr.has_method("play_explosion"):
			audio_mgr.play_explosion(true)

# ==============================================================================
# 1. PBR MATERIALS WITH PROCEDURAL FLUID NOISE RIPPLES
# ==============================================================================
func build_materials() -> void:
	# 1.1 Procedural Noise for Water & Oil Ripples
	var water_noise := FastNoiseLite.new()
	water_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	water_noise.frequency = 0.06
	water_noise.fractal_octaves = 3
	
	var tex_water_norm := NoiseTexture2D.new()
	tex_water_norm.seamless = true
	tex_water_norm.as_normal_map = true
	tex_water_norm.bump_strength = 2.8
	tex_water_norm.noise = water_noise
	
	# 1.2 Deep Caribbean Ocean Wave Water
	mat_water_deep = StandardMaterial3D.new()
	mat_water_deep.albedo_color = Color(0.04, 0.36, 0.58, 0.93)
	mat_water_deep.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water_deep.metallic = 0.25
	mat_water_deep.roughness = 0.05
	mat_water_deep.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_water_deep.normal_enabled = true
	mat_water_deep.normal_texture = tex_water_norm
	mat_water_deep.normal_scale = 1.6
	mat_water_deep.rim_enabled = true
	mat_water_deep.rim = 0.4
	mat_water_deep.rim_tint = 0.6
	
	# 1.3 Translucent Breaking Wave Crest & Barrel Surface
	mat_water_trans = StandardMaterial3D.new()
	mat_water_trans.albedo_color = Color(0.16, 0.64, 0.82, 0.82)
	mat_water_trans.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water_trans.metallic = 0.15
	mat_water_trans.roughness = 0.04
	mat_water_trans.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_water_trans.normal_enabled = true
	mat_water_trans.normal_texture = tex_water_norm
	mat_water_trans.normal_scale = 2.0
	
	# 1.4 Crude Palm Oil (CPO - Minyak Sawit Mentah) - Golden Amber Viscous Liquid
	mat_oil_gold = StandardMaterial3D.new()
	mat_oil_gold.albedo_color = Color(0.94, 0.54, 0.04, 0.90)
	mat_oil_gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_oil_gold.metallic = 0.35
	mat_oil_gold.roughness = 0.06
	mat_oil_gold.clearcoat_enabled = true
	mat_oil_gold.clearcoat = 1.0
	mat_oil_gold.clearcoat_roughness = 0.05
	mat_oil_gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_oil_gold.normal_enabled = true
	mat_oil_gold.normal_texture = tex_water_norm
	mat_oil_gold.normal_scale = 1.2
	mat_oil_gold.emission_enabled = true
	mat_oil_gold.emission = Color(0.35, 0.18, 0.02)
	
	# 1.5 Deep Concentrated Palm Oil Sludge (Dark Amber Brown)
	mat_oil_dark = StandardMaterial3D.new()
	mat_oil_dark.albedo_color = Color(0.55, 0.22, 0.03, 0.92)
	mat_oil_dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_oil_dark.metallic = 0.3
	mat_oil_dark.roughness = 0.09
	mat_oil_dark.clearcoat_enabled = true
	mat_oil_dark.clearcoat = 0.8
	mat_oil_dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 1.6 Churning Heavy White Hydraulic Foam
	mat_foam_white = StandardMaterial3D.new()
	mat_foam_white.albedo_color = Color(0.97, 0.98, 1.0, 0.97)
	mat_foam_white.roughness = 0.45
	mat_foam_white.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_foam_white.emission_enabled = true
	mat_foam_white.emission = Color(0.15, 0.2, 0.25)
	
	# 1.7 Ripe Sawit Fruit Crown (Fiery Vivid Red-Orange)
	mat_sawit_skin_ripe = StandardMaterial3D.new()
	mat_sawit_skin_ripe.albedo_color = Color(0.95, 0.22, 0.02)
	mat_sawit_skin_ripe.metallic = 0.2
	mat_sawit_skin_ripe.roughness = 0.18
	mat_sawit_skin_ripe.clearcoat_enabled = true
	mat_sawit_skin_ripe.clearcoat = 0.85
	mat_sawit_skin_ripe.clearcoat_roughness = 0.1
	
	# 1.8 Mid-Ripe Sawit Fruit Center (Golden Orange)
	mat_sawit_skin_mid = StandardMaterial3D.new()
	mat_sawit_skin_mid.albedo_color = Color(0.98, 0.52, 0.06)
	mat_sawit_skin_mid.metallic = 0.2
	mat_sawit_skin_mid.roughness = 0.22
	mat_sawit_skin_mid.clearcoat_enabled = true
	mat_sawit_skin_mid.clearcoat = 0.7
	
	# 1.9 Dark Unripe Base / Drupe Attachment (Purple-Black Crimson)
	mat_sawit_base_dark = StandardMaterial3D.new()
	mat_sawit_base_dark.albedo_color = Color(0.20, 0.06, 0.09)
	mat_sawit_base_dark.roughness = 0.5
	mat_sawit_base_dark.clearcoat_enabled = true
	mat_sawit_base_dark.clearcoat = 0.4
	
	# 1.10 Heavy Palm Fruit Bunch Stalk (Fibrous Brown-Grey)
	mat_stalk_fibrous = StandardMaterial3D.new()
	mat_stalk_fibrous.albedo_color = Color(0.32, 0.22, 0.14)
	mat_stalk_fibrous.roughness = 0.75
	
	# 1.11 Pelepah Sawit (Tropical Lush Palm Frond Green)
	mat_frond_green = StandardMaterial3D.new()
	mat_frond_green.albedo_color = Color(0.12, 0.48, 0.15)
	mat_frond_green.roughness = 0.4
	mat_frond_green.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 1.12 Wet Desert Sand Aftermath Decals
	mat_wet_sand = StandardMaterial3D.new()
	mat_wet_sand.albedo_color = Color(0.38, 0.25, 0.12, 0.75)
	mat_wet_sand.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_wet_sand.roughness = 0.15
	mat_wet_sand.metallic = 0.1

# ==============================================================================
# 2. WAVE GEOMETRY & OIL SWIRLS
# ==============================================================================
func build_tsunami_and_sawit() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	
	# Internal Caustic Sunlight Glow
	wave_light = OmniLight3D.new()
	wave_light.name = "TsunamiCausticLight"
	wave_light.light_color = Color(0.95, 0.75, 0.35) # Warm golden amber water caustics
	wave_light.light_energy = 3.5
	wave_light.omni_range = 28.0
	wave_light.omni_attenuation = 1.2
	wave_light.position = Vector3(0.0, 4.5, 2.0)
	body_root.add_child(wave_light)
	
	build_water_tsunami_mesh()
	build_palm_oil_swirls()
	build_tandan_buah_sawit_clusters()
	build_loose_sawit_fruits()
	build_palm_fronds()
	build_spray_and_foam_particles()

func build_water_tsunami_mesh() -> void:
	wave_root = Node3D.new()
	wave_root.name = "WaterTsunamiRoot"
	body_root.add_child(wave_root)
	
	# 2.1 Giant Curved Breaker Wall (28m Wide, 8.5m High)
	var main_wall := CylinderMesh.new()
	main_wall.top_radius = 7.5
	main_wall.bottom_radius = 8.8
	main_wall.height = 28.0
	main_wall.radial_segments = 32
	main_wall.rings = 6
	
	var mi_wall := MeshInstance3D.new()
	mi_wall.mesh = main_wall
	mi_wall.material_override = mat_water_deep
	mi_wall.rotation.z = PI / 2.0
	mi_wall.position = Vector3(0.0, 4.2, -2.0)
	mi_wall.scale = Vector3(0.68, 1.0, 1.15)
	wave_root.add_child(mi_wall)
	wave_mesh_instances.append(mi_wall)
	
	# 2.2 Secondary Supporting Water Ridge (Back Surge)
	var back_wall := CylinderMesh.new()
	back_wall.top_radius = 5.5
	back_wall.bottom_radius = 6.8
	back_wall.height = 27.5
	back_wall.radial_segments = 24
	var mi_back := MeshInstance3D.new()
	mi_back.mesh = back_wall
	mi_back.material_override = mat_water_deep
	mi_back.rotation.z = PI / 2.0
	mi_back.position = Vector3(0.0, 3.2, -6.5)
	mi_back.scale = Vector3(0.75, 1.0, 1.0)
	wave_root.add_child(mi_back)
	wave_mesh_instances.append(mi_back)
	
	# 2.3 Overhanging Crashing Wave Barrel Lip (The Curling Breaker)
	crest_lip = Node3D.new()
	crest_lip.position = Vector3(0.0, 7.8, 1.6)
	wave_root.add_child(crest_lip)
	
	var lip_mesh := CylinderMesh.new()
	lip_mesh.top_radius = 3.0
	lip_mesh.bottom_radius = 3.5
	lip_mesh.height = 28.0
	lip_mesh.radial_segments = 24
	
	var mi_lip := MeshInstance3D.new()
	mi_lip.mesh = lip_mesh
	mi_lip.material_override = mat_water_trans
	mi_lip.rotation.z = PI / 2.0
	mi_lip.scale = Vector3(0.55, 1.0, 0.85)
	crest_lip.add_child(mi_lip)
	wave_mesh_instances.append(mi_lip)
	
	# 2.4 Heavy Frothing Wave Lip Crest (White Churning Foam Roller)
	var foam_crest := BoxMesh.new()
	foam_crest.size = Vector3(28.2, 1.8, 2.6)
	var mi_foam := MeshInstance3D.new()
	mi_foam.mesh = foam_crest
	mi_foam.material_override = mat_foam_white
	mi_foam.position = Vector3(0.0, 8.4, 2.4)
	wave_root.add_child(mi_foam)
	
	# 2.5 Sweeping Torrential Rapids / Hydraulic Wash Across Arena Sand (30m wide, 18m forward reach)
	var flood_plane := BoxMesh.new()
	flood_plane.size = Vector3(30.0, 0.45, 18.0)
	var mi_flood := MeshInstance3D.new()
	mi_flood.mesh = flood_plane
	mi_flood.material_override = mat_water_trans
	mi_flood.position = Vector3(0.0, 0.22, 6.5)
	wave_root.add_child(mi_flood)
	wave_mesh_instances.append(mi_flood)
	
	# 2.6 Forward Foam Surge Line (Tidal Bore Head)
	var surge_lip := BoxMesh.new()
	surge_lip.size = Vector3(30.5, 0.65, 2.8)
	var mi_surge := MeshInstance3D.new()
	mi_surge.mesh = surge_lip
	mi_surge.material_override = mat_foam_white
	mi_surge.position = Vector3(0.0, 0.32, 15.0)
	wave_root.add_child(mi_surge)

func build_palm_oil_swirls() -> void:
	# 7 Viscous Golden Palm Oil Ribbons streaming inside the wave
	for i in range(7):
		var oil_mesh := CylinderMesh.new()
		oil_mesh.top_radius = 1.8 + i * 0.25
		oil_mesh.bottom_radius = 2.2 + i * 0.25
		oil_mesh.height = 27.0 - i * 1.2
		oil_mesh.radial_segments = 20
		
		var mi := MeshInstance3D.new()
		mi.mesh = oil_mesh
		mi.material_override = mat_oil_gold if (i % 2 == 0) else mat_oil_dark
		mi.rotation.z = PI / 2.0
		mi.position = Vector3(
			sin(float(i) * 1.5) * 2.5,
			2.8 + i * 0.75,
			-1.0 + i * 0.85
		)
		mi.scale = Vector3(0.42, 1.0, 0.75)
		wave_root.add_child(mi)
		oil_ribbons.append(mi)
		
	# Surface Golden Palm Oil Slick (Oily film floating on the torrential ground rapids)
	var oil_slick := BoxMesh.new()
	oil_slick.size = Vector3(27.0, 0.12, 13.0)
	var mi_slick := MeshInstance3D.new()
	mi_slick.mesh = oil_slick
	mi_slick.material_override = mat_oil_gold
	mi_slick.position = Vector3(0.0, 0.35, 5.5)
	wave_root.add_child(mi_slick)
	oil_ribbons.append(mi_slick)

# ==============================================================================
# 3. ANATOMICALLY ACCURATE TANDAN BUAH SEGAR (TBS) KELAPA SAWIT
# ==============================================================================
func build_tandan_buah_sawit_clusters() -> void:
	sawit_root = Node3D.new()
	sawit_root.name = "SawitClustersRoot"
	body_root.add_child(sawit_root)
	
	# 9 Colossal Bunches of Palm Oil Fruit surfing and tumbling
	var bunch_positions = [
		Vector3(-10.5, 5.8, 1.2),
		Vector3(-6.5, 7.2, 1.8),
		Vector3(-2.2, 6.4, 2.5),
		Vector3(2.5, 7.5, 1.6),
		Vector3(6.8, 6.8, 2.0),
		Vector3(10.5, 5.2, 1.0),
		Vector3(-7.5, 1.8, 8.5),  # Rolling on ground rapids
		Vector3(0.0, 1.9, 10.5),  # Centered ground ram bunch
		Vector3(7.5, 1.8, 9.2)    # Rolling on ground rapids
	]
	
	for pos in bunch_positions:
		var bunch_node := create_realistic_tbs_bunch()
		bunch_node.position = pos
		sawit_root.add_child(bunch_node)
		sawit_bunches.append(bunch_node)
		bunch_velocities.append(Vector3(
			randf_range(-1.2, 1.2),
			randf_range(-2.0, 2.0),
			randf_range(-1.5, 1.5)
		))

func create_realistic_tbs_bunch() -> Node3D:
	var bunch := Node3D.new()
	
	# 3.1 Main Fibrous Stalk (Gagang Tandan Kelapa Sawit)
	var stalk_mesh := CylinderMesh.new()
	stalk_mesh.top_radius = 0.45
	stalk_mesh.bottom_radius = 0.72
	stalk_mesh.height = 3.0
	stalk_mesh.radial_segments = 10
	var mi_stalk := MeshInstance3D.new()
	mi_stalk.mesh = stalk_mesh
	mi_stalk.material_override = mat_stalk_fibrous
	bunch.add_child(mi_stalk)
	
	# Cut Base Crown of Stalk
	var cut_base := CylinderMesh.new()
	cut_base.top_radius = 0.75
	cut_base.bottom_radius = 0.78
	cut_base.height = 0.35
	var mi_base := MeshInstance3D.new()
	mi_base.mesh = cut_base
	mi_base.material_override = mat_sawit_base_dark
	mi_base.position = Vector3(0, -1.5, 0)
	bunch.add_child(mi_base)
	
	# 3.2 Dense Phyllotaxis Cluster of Palm Drupes (48 fruits per bunch)
	var fruit_count = 48
	for i in range(fruit_count):
		var phi = i * 2.39996 # Golden angle in radians
		var y = lerp(-1.1, 1.1, float(i) / float(fruit_count))
		# Ovoid bunch taper shape (fatter in middle, tapering at stalk and tip)
		var taper = sqrt(max(0.01, 1.0 - (y / 1.25) * (y / 1.25)))
		var r = (0.75 + taper * 0.95)
		var fx = cos(phi) * r
		var fz = sin(phi) * r
		
		# Ovoid fruit drupe (Elongated droplet/egg shape)
		var f_mesh := SphereMesh.new()
		f_mesh.radius = randf_range(0.32, 0.44)
		f_mesh.height = f_mesh.radius * 2.2
		f_mesh.radial_segments = 8
		f_mesh.rings = 5
		
		var mi_f := MeshInstance3D.new()
		mi_f.mesh = f_mesh
		
		# Realistic Ripening Gradient: Dark at inner base, fiery orange-red in middle, bright yellow at crown
		var height_ratio = float(i) / float(fruit_count)
		if height_ratio < 0.25:
			mi_f.material_override = mat_sawit_base_dark
		elif height_ratio < 0.75:
			mi_f.material_override = mat_sawit_skin_ripe if (i % 2 == 0) else mat_sawit_skin_mid
		else:
			mi_f.material_override = mat_sawit_skin_ripe
			
		mi_f.position = Vector3(fx, y, fz)
		# Point outwards from center stalk
		var look_target = mi_f.position + Vector3(fx, y * 0.4, fz).normalized()
		mi_f.look_at(look_target, Vector3.UP)
		bunch.add_child(mi_f)
		
	# 3.3 Protective Spined Bracts (Duri Tandan Sawit) protruding between fruits
	for k in range(12):
		var thorn_angle = k * (PI * 2.0 / 12.0)
		var ty = lerp(-0.8, 0.8, float(k) / 12.0)
		var thorn_mesh := CylinderMesh.new()
		thorn_mesh.top_radius = 0.04
		thorn_mesh.bottom_radius = 0.16
		thorn_mesh.height = 1.1
		thorn_mesh.radial_segments = 5
		
		var mi_thorn := MeshInstance3D.new()
		mi_thorn.mesh = thorn_mesh
		mi_thorn.material_override = mat_stalk_fibrous
		mi_thorn.position = Vector3(cos(thorn_angle) * 1.5, ty, sin(thorn_angle) * 1.5)
		mi_thorn.look_at(mi_thorn.position * 2.0, Vector3.UP)
		bunch.add_child(mi_thorn)
		
	# Size of the colossal bunch (equivalent to 30-40 kg prize bunch)
	bunch.scale = Vector3.ONE * randf_range(1.9, 2.6)
	return bunch

# ==============================================================================
# 4. LOOSE SAWIT FRUITS (BRONDOLAN SAWIT LEPAS)
# ==============================================================================
func build_loose_sawit_fruits() -> void:
	# 45 loose sawit fruits shooting like cannonballs through the water
	for i in range(45):
		var f_node := Node3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.3, 0.5)
		mesh.height = mesh.radius * 2.1
		mesh.radial_segments = 7
		mesh.rings = 5
		
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat_sawit_skin_ripe if (i % 3 != 0) else mat_sawit_skin_mid
		f_node.add_child(mi)
		
		f_node.position = Vector3(
			randf_range(-13.0, 13.0),
			randf_range(0.6, 7.8),
			randf_range(-1.0, 12.0)
		)
		sawit_root.add_child(f_node)
		loose_fruits.append(f_node)

# ==============================================================================
# 5. PELEPAH KELAPA SAWIT (REALISTIC ARCHED PALM FRONDS)
# ==============================================================================
func build_palm_fronds() -> void:
	# 6 massive arched palm fronds surfing the wave
	var frond_positions = [
		Vector3(-9.0, 7.2, 0.8),
		Vector3(-4.0, 8.0, 1.8),
		Vector3(0.0, 7.6, 2.4),
		Vector3(4.5, 8.1, 1.5),
		Vector3(9.5, 7.0, 1.0),
		Vector3(-2.0, 2.2, 8.5)
	]
	
	for pos in frond_positions:
		var frond := create_realistic_palm_frond()
		frond.position = pos
		frond.rotation.y = randf_range(-0.5, 0.5)
		frond.rotation.x = randf_range(-0.35, 0.35)
		sawit_root.add_child(frond)
		palm_fronds.append(frond)

func create_realistic_palm_frond() -> Node3D:
	var frond := Node3D.new()
	
	# Central Arched Rachis (Batang Pelepah Sawit)
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.25, 0.22, 6.8)
	var mi_spine := MeshInstance3D.new()
	mi_spine.mesh = spine_mesh
	mi_spine.material_override = mat_stalk_fibrous
	frond.add_child(mi_spine)
	
	# 20 pairs of Feathered Leaflets (Anak Daun Sawit)
	for j in range(20):
		var z_pos = lerp(-3.0, 3.0, float(j) / 20.0)
		var leaf_len = 1.9 * (1.0 - abs(z_pos) / 4.5)
		
		# Left Leaflet
		var l_mesh := BoxMesh.new()
		l_mesh.size = Vector3(leaf_len, 0.04, 0.28)
		var mi_l := MeshInstance3D.new()
		mi_l.mesh = l_mesh
		mi_l.material_override = mat_frond_green
		mi_l.position = Vector3(-leaf_len * 0.45, -0.05, z_pos)
		mi_l.rotation.z = -0.25
		mi_l.rotation.y = 0.25
		frond.add_child(mi_l)
		
		# Right Leaflet
		var r_mesh := BoxMesh.new()
		r_mesh.size = Vector3(leaf_len, 0.04, 0.28)
		var mi_r := MeshInstance3D.new()
		mi_r.mesh = r_mesh
		mi_r.material_override = mat_frond_green
		mi_r.position = Vector3(leaf_len * 0.45, -0.05, z_pos)
		mi_r.rotation.z = 0.25
		mi_r.rotation.y = -0.25
		frond.add_child(mi_r)
		
	frond.scale = Vector3.ONE * randf_range(1.2, 1.6)
	return frond

# ==============================================================================
# 6. VOLUMETRIC MULTI-EMITTER SPRAY, FOAM & CRUDE OIL PARTICLES
# ==============================================================================
func build_spray_and_foam_particles() -> void:
	# 6.1 Heavy Ocean Mist Cloud (Drifting forward ahead of the tsunami)
	mist_particles = CPUParticles3D.new()
	mist_particles.amount = 45
	mist_particles.lifetime = 1.2
	mist_particles.direction = Vector3(0, 0.2, 1.0)
	mist_particles.spread = 55.0
	mist_particles.initial_velocity_min = 16.0
	mist_particles.initial_velocity_max = 26.0
	mist_particles.gravity = Vector3(0, -3.5, 0)
	
	var mist_mesh := SphereMesh.new()
	mist_mesh.radius = 0.85
	mist_mesh.height = 1.7
	mist_particles.mesh = mist_mesh
	
	var mat_mist := StandardMaterial3D.new()
	mat_mist.albedo_color = Color(0.85, 0.94, 1.0, 0.35)
	mat_mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_mist.roughness = 0.8
	mist_particles.material_override = mat_mist
	mist_particles.position = Vector3(0, 5.0, 5.0)
	body_root.add_child(mist_particles)
	
	# 6.2 Crashing Ocean Wave Spray & Water Droplets
	spray_particles = CPUParticles3D.new()
	spray_particles.amount = 70
	spray_particles.lifetime = 0.85
	spray_particles.explosiveness = 0.25
	spray_particles.direction = Vector3(0, 0.45, 1.0)
	spray_particles.spread = 45.0
	spray_particles.initial_velocity_min = 15.0
	spray_particles.initial_velocity_max = 28.0
	spray_particles.gravity = Vector3(0, -9.8, 0)
	
	var spray_sphere := SphereMesh.new()
	spray_sphere.radius = 0.38
	spray_sphere.height = 0.76
	spray_particles.mesh = spray_sphere
	spray_particles.material_override = mat_water_trans
	spray_particles.position = Vector3(0, 6.8, 2.5)
	body_root.add_child(spray_particles)
	
	# 6.3 Flying Golden Crude Palm Oil Droplets
	oil_particles = CPUParticles3D.new()
	oil_particles.amount = 55
	oil_particles.lifetime = 0.8
	oil_particles.explosiveness = 0.3
	oil_particles.direction = Vector3(0, 0.5, 1.0)
	oil_particles.spread = 55.0
	oil_particles.initial_velocity_min = 14.0
	oil_particles.initial_velocity_max = 24.0
	oil_particles.gravity = Vector3(0, -11.0, 0)
	
	var oil_sphere := SphereMesh.new()
	oil_sphere.radius = 0.26
	oil_sphere.height = 0.52
	oil_particles.mesh = oil_sphere
	oil_particles.material_override = mat_oil_gold
	oil_particles.position = Vector3(0, 4.5, 3.2)
	body_root.add_child(oil_particles)
	
	# 6.4 Ground Hydraulic Frothing Foam & Mud Rapids
	foam_particles = CPUParticles3D.new()
	foam_particles.amount = 60
	foam_particles.lifetime = 0.75
	foam_particles.direction = Vector3(0, 0.25, 1.0)
	foam_particles.spread = 75.0
	foam_particles.initial_velocity_min = 10.0
	foam_particles.initial_velocity_max = 20.0
	foam_particles.gravity = Vector3(0, -5.0, 0)
	
	var foam_box := BoxMesh.new()
	foam_box.size = Vector3(0.65, 0.35, 0.65)
	foam_particles.mesh = foam_box
	foam_particles.material_override = mat_foam_white
	foam_particles.position = Vector3(0, 0.35, 12.0)
	body_root.add_child(foam_particles)

# ==============================================================================
# 7. REAL-TIME FLUID PROCESS & PHYSICS
# ==============================================================================
var wet_wake_timer: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	var step = speed * delta
	global_position += charge_dir * step
	travel_dist += step
	
	# 7.1 Real-time Fluid Normal Map UV Scrolling (Turbulent Ocean Waves & Oil Shearing)
	if mat_water_deep:
		mat_water_deep.uv1_offset += Vector3(0.08, 1.6, 0.0) * delta
	if mat_water_trans:
		mat_water_trans.uv1_offset += Vector3(-0.06, 2.2, 0.0) * delta
	if mat_oil_gold:
		mat_oil_gold.uv1_offset += Vector3(0.12, 1.2, 0.0) * delta
		
	# 7.2 Undulate Wave Crest Lip Dynamically (Realistic Breaking Wave Barrel)
	if crest_lip:
		crest_lip.position.y = 7.8 + sin(anim_time * 7.5) * 0.8
		crest_lip.position.z = 1.6 + cos(anim_time * 6.5) * 0.5
		crest_lip.rotation.x = sin(anim_time * 5.0) * 0.12
		
	# 7.3 Tumble & Bob Sawit Fruit Bunches (Physics Buoyancy + Angular Rolling)
	for i in range(sawit_bunches.size()):
		var b = sawit_bunches[i]
		if is_instance_valid(b):
			# Heavy roll forward
			b.rotation.x += delta * (5.0 + i * 0.4)
			# Tumbling sideways
			b.rotation.z += delta * (sin(anim_time * 3.0 + i) * 2.2)
			# Vertical water bobbing
			b.position.y += sin(anim_time * 6.0 + i * 1.5) * (0.4 * delta)
			
	# 7.4 Scatter Loose Sawit Fruits
	for j in range(loose_fruits.size()):
		var lf = loose_fruits[j]
		if is_instance_valid(lf):
			lf.rotation.x += delta * 12.0
			lf.rotation.y += delta * 9.0
			lf.position.y += sin(anim_time * 9.0 + j) * (0.6 * delta)
			
	# 7.5 Sway Pelepah Sawit (Fluid Drag in High Speed Water)
	for k in range(palm_fronds.size()):
		var pf = palm_fronds[k]
		if is_instance_valid(pf):
			pf.rotation.z = sin(anim_time * 6.0 + k * 1.2) * 0.35
			pf.rotation.x = cos(anim_time * 5.0 + k) * 0.25
			
	# 7.6 Continuous Heavy Camera Screen Rumble
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.25 * delta)
		
	# 7.7 Check Ram Hits on Enemy Units
	check_ram_hits()
	
	# 7.8 Leave Residual Wet Oily Sand Decals & Splashes along Arena Floor
	wet_wake_timer += delta
	if wet_wake_timer >= 0.07:
		wet_wake_timer = 0.0
		spawn_ground_water_splash()
		
	if travel_dist >= max_travel:
		on_flood_complete()

# ==============================================================================
# 8. ENEMY COLLISION & TORQUE LAUNCH
# ==============================================================================
func check_ram_hits() -> void:
	var tree = get_tree()
	if not tree:
		return
		
	var opp_team = 0 if team == 1 else 1
	var units = tree.get_nodes_in_group("units")
	
	for u in units:
		if is_instance_valid(u) and not u.is_dead and u.team == opp_team:
			var uid = u.get_instance_id()
			if hit_units.has(uid):
				continue
				
			var u_pos = u.global_position
			var to_unit = u_pos - global_position
			
			var dist_forward = to_unit.dot(charge_dir)
			var lateral_vec = to_unit - charge_dir * dist_forward
			var lateral_dist = lateral_vec.length()
			
			# Tsunami Hitbox: 16m forward reach, 14.5m lateral (covers 29m wide battlefield)
			if dist_forward >= -6.0 and dist_forward <= 15.5 and lateral_dist <= 14.5:
				hit_units[uid] = true
				ram_unit(u)

func ram_unit(target: Node) -> void:
	# Devastating high-arc water launch with chaotic angular torque
	var launch_velocity = charge_dir * randf_range(52.0, 72.0) + Vector3(
		(randf() - 0.5) * 22.0,
		randf_range(20.0, 34.0),
		(randf() - 0.5) * 22.0
	)
	
	if "velocity" in target:
		target.velocity = launch_velocity
		
	# Chaotic cartwheel tumble torque in 3D
	target.rotation_degrees += Vector3(
		randf_range(-180.0, 180.0),
		randf_range(-180.0, 180.0),
		randf_range(-180.0, 180.0)
	)
		
	var is_fatal = (target.hp <= damage)
	var banner_title = "🌊 DISAPU TSUNAMI AIR & SAWIT!"
	var banner_color = Color(0.18, 0.82, 1.0)
	
	var r = randf()
	if r < 0.35:
		banner_title = "🌴 TERHANTAM TANDAN BUAH SAWIT!"
		banner_color = Color(1.0, 0.42, 0.08) # Ripe Sawit Orange
	elif r < 0.70:
		banner_title = "🛢️ BANJIR BANDANG MINYAK SAWIT!"
		banner_color = Color(1.0, 0.82, 0.15) # Golden CPO
	elif is_fatal:
		banner_title = "💥 DROWNED IN HIGH-PRESSURE PALM TSUNAMI!"
		banner_color = Color(0.25, 0.95, 0.95)
		
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = target.global_position + Vector3(0, 2.6 * target.unit_scale, 0)
	dmg_label.setup_banner(banner_title, banner_color)
	
	target.take_damage(damage, global_position)
	
	# Massive hit sparks and golden oil splash burst
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(target.global_position, true)
	
	if camera and camera.has_method("add_shake"):
		camera.add_shake(1.2)
		
	if audio_mgr and audio_mgr.has_method("play_hit"):
		audio_mgr.play_hit(true)

func spawn_ground_water_splash() -> void:
	var splash_pos = global_position + Vector3(
		(randf() - 0.5) * 26.0,
		0.12,
		(randf() - 0.5) * 10.0
	)
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(splash_pos, false)

func on_flood_complete() -> void:
	if audio_mgr and audio_mgr.has_method("play_explosion"):
		audio_mgr.play_explosion(true)
	queue_free()
