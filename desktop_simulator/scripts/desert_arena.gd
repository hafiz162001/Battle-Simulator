extends Node3D

# ==============================================================================
# ULTRA-DETAILED MODERN METROPOLIS & URBAN WARFARE ARENA (PERKOTAAN)
# Features:
# - High-Density Modern City with Skyscrapers, Office Towers & High-Rises
# - Heavy Perimeter Reinforced Concrete Blast Walls & Security Fencing on All Sides
# - PBR Asphalt Multi-Lane Boulevard with Crosswalks, Lane Markings & Sidewalks
# - Realistic Street Lighting, Traffic Gantries, Planters & Urban Infrastructure
# - Forward+ Real-Time SDFGI, SSAO, SSR & ACES Filmic Atmospheric Lighting
# - Fully Enclosed Combat Perimeter with Corner Spotlight Watchtowers
# ==============================================================================

# Arena boundary limits (meters)
const ARENA_BOUND_X := 42.0
const ARENA_BOUND_Z := 23.5

var world_env_node: WorldEnvironment = null
var sun_light: DirectionalLight3D = null
var is_performance_mode: bool = false

func _ready() -> void:
	setup_lighting_and_environment()
	setup_city_streets_and_ground()
	setup_perimeter_boundary_walls()
	setup_skyscrapers_and_buildings()
	setup_street_props()
	setup_urban_particles()

# ==============================================================================
# 1. GROUND ELEVATION (Paved Urban Flat Surface)
# ==============================================================================
func get_ground_height(x: float, z: float) -> float:
	# Inside the central combat avenue it is flat asphalt (y = 0.0)
	# Sidewalk curbs outside road width (abs(z) > 13.5) raise slightly by 0.15m
	if abs(x) <= ARENA_BOUND_X and abs(z) > 13.5 and abs(z) <= ARENA_BOUND_Z:
		return 0.15
	return 0.0

func get_ground_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP

# ==============================================================================
# 2. LIGHTING, URBAN SKY, SDFGI, SSAO, SSR & CINEMATIC TONE MAPPING
# ==============================================================================
func setup_lighting_and_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	
	# Crisp City Sky with Horizon Atmospheric Gradient
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#1e3a8a")
	sky_mat.sky_horizon_color = Color("#93c5fd")
	sky_mat.sky_curve = 0.12
	sky_mat.sky_energy_multiplier = 1.2
	
	sky_mat.ground_bottom_color = Color("#0f172a")
	sky_mat.ground_horizon_color = Color("#475569")
	sky_mat.ground_curve = 0.08
	sky_mat.ground_energy_multiplier = 0.95
	
	sky_mat.sun_angle_max = 2.4
	sky_mat.sun_curve = 0.12
	
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	
	# Ambient Sky Fill
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.70
	env.ambient_light_color = Color("#cbd5e1")
	env.ambient_light_energy = 1.05
	
	# Atmospheric City Haze & Volumetric Fog
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0055
	env.volumetric_fog_albedo = Color(0.88, 0.94, 1.0)
	env.volumetric_fog_emission = Color(0.12, 0.18, 0.28) * 0.12
	env.volumetric_fog_emission_energy = 0.6
	env.volumetric_fog_anisotropy = 0.65
	env.volumetric_fog_length = 240.0
	
	# Real-Time SDFGI for Realistic Building Light Bounce & Canyon Shading
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.65
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.3
	env.sdfgi_energy = 1.15
	
	# SSAO for Deep Contact Shadows around Curbs, Buildings & Soldiers
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 3.6
	env.ssao_power = 1.6
	env.ssao_detail = 0.85
	
	# Screen Space Reflections (SSR) for Wet Asphalt & Glass Towers
	env.ssr_enabled = true
	env.ssr_max_steps = 36
	env.ssr_fade_in = 0.12
	env.ssr_fade_out = 2.2
	env.ssr_depth_tolerance = 0.2
	
	# ACES Filmic Tone Mapping & High Dynamic Contrast
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.14
	env.tonemap_white = 5.4
	
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.03
	env.adjustment_contrast = 1.16
	env.adjustment_saturation = 1.18
	
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.50
	env.glow_bloom = 0.18
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 1.02
	env.glow_hdr_scale = 1.8
	
	world_env_node = WorldEnvironment.new()
	world_env_node.environment = env
	add_child(world_env_node)
	
	# Primary Sunlight Casting Crisp Soft Shadows & Volumetric Rays
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.98, 0.94)
	sun_light.light_energy = 4.2
	sun_light.light_indirect_energy = 1.5
	sun_light.light_volumetric_fog_energy = 2.4
	
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_blend_splits = true
	sun_light.directional_shadow_max_distance = 110.0
	sun_light.shadow_bias = 0.002
	sun_light.shadow_normal_bias = 1.1
	sun_light.shadow_blur = 1.2
	sun_light.rotation_degrees = Vector3(-38, 48, 0)
	add_child(sun_light)

func set_performance_mode(enabled: bool) -> void:
	is_performance_mode = enabled
	if world_env_node and world_env_node.environment:
		var env = world_env_node.environment
		if enabled:
			env.sdfgi_enabled = false
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				sun_light.directional_shadow_blend_splits = false
				sun_light.directional_shadow_max_distance = 60.0
		else:
			env.sdfgi_enabled = true
			env.ssao_enabled = true
			env.ssr_enabled = true
			env.volumetric_fog_enabled = true
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun_light.directional_shadow_blend_splits = true
				sun_light.directional_shadow_max_distance = 110.0
	
	# Skylight Fill to illuminate shaded sides of skyscrapers
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#94a3b8")
	fill.light_energy = 0.70
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(25, -132, 0)
	add_child(fill)

# ==============================================================================
# 3. ASPHALT BOULEVARD, ROAD MARKINGS, CROSSWALKS & CONCRETE SIDEWALKS
# ==============================================================================
func setup_city_streets_and_ground() -> void:
	# A. Main Asphalt Highway Ground with Normal Map Bumpiness
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(260.0, 180.0)
	
	# Procedural Asphalt Noise Normal Map
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.06
	noise.fractal_octaves = 4
	
	var noise_tex := NoiseTexture2D.new()
	noise_tex.seamless = true
	noise_tex.as_normal_map = true
	noise_tex.bump_strength = 1.8
	noise_tex.noise = noise
	
	var asphalt_mat := StandardMaterial3D.new()
	asphalt_mat.albedo_color = Color("#181b20") # Deep realistic asphalt
	asphalt_mat.roughness = 0.38 # Glossy damp asphalt with puddle specular glints
	asphalt_mat.metallic = 0.12
	asphalt_mat.normal_enabled = true
	asphalt_mat.normal_texture = noise_tex
	asphalt_mat.uv1_scale = Vector3(32.0, 22.0, 1.0)
	
	var asphalt_inst := MeshInstance3D.new()
	asphalt_inst.mesh = ground_mesh
	asphalt_inst.material_override = asphalt_mat
	asphalt_inst.position.y = 0.0
	add_child(asphalt_inst)
	
	# B. Concrete Sidewalks (North and South)
	var sidewalk_mat := StandardMaterial3D.new()
	sidewalk_mat.albedo_color = Color("#94a3b8")
	sidewalk_mat.roughness = 0.82
	
	# North Sidewalk
	var sw_north := MeshInstance3D.new()
	var sw_box := BoxMesh.new()
	sw_box.size = Vector3(ARENA_BOUND_X * 2.0, 0.15, (ARENA_BOUND_Z - 13.5))
	sw_north.mesh = sw_box
	sw_north.material_override = sidewalk_mat
	sw_north.position = Vector3(0.0, 0.075, -(13.5 + (ARENA_BOUND_Z - 13.5) * 0.5))
	add_child(sw_north)
	
	# South Sidewalk
	var sw_south := MeshInstance3D.new()
	sw_south.mesh = sw_box
	sw_south.material_override = sidewalk_mat
	sw_south.position = Vector3(0.0, 0.075, (13.5 + (ARENA_BOUND_Z - 13.5) * 0.5))
	add_child(sw_south)
	
	# C. Yellow Center Road Divider Lines (Double Yellow Lines)
	var yellow_mat := StandardMaterial3D.new()
	yellow_mat.albedo_color = Color("#eab308")
	yellow_mat.roughness = 0.45
	
	for offset_z in [-0.18, 0.18]:
		var yellow_line := MeshInstance3D.new()
		var y_mesh := BoxMesh.new()
		y_mesh.size = Vector3(ARENA_BOUND_X * 2.0 - 4.0, 0.02, 0.14)
		yellow_line.mesh = y_mesh
		yellow_line.material_override = yellow_mat
		yellow_line.position = Vector3(0.0, 0.015, offset_z)
		add_child(yellow_line)
		
	# Reflective Road Studs (Mata Kucing) along center lines
	var stud_mat := StandardMaterial3D.new()
	stud_mat.albedo_color = Color("#fbbf24")
	stud_mat.metallic = 0.9
	stud_mat.roughness = 0.2
	stud_mat.emission_enabled = true
	stud_mat.emission = Color("#d97706")
	stud_mat.emission_energy_multiplier = 0.8
	
	for sx in range(int(-ARENA_BOUND_X + 4.0), int(ARENA_BOUND_X - 4.0), 3):
		var stud := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.12, 0.03, 0.12)
		stud.mesh = sm
		stud.material_override = stud_mat
		stud.position = Vector3(sx, 0.02, 0.0)
		add_child(stud)
		
	# D. White Dashed Lane Dividers (North & South Lanes)
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color("#f8fafc")
	white_mat.roughness = 0.45
	
	for lane_z in [-6.5, 6.5]:
		for dash_x in range(int(-ARENA_BOUND_X + 4.0), int(ARENA_BOUND_X - 4.0), 6):
			var dash := MeshInstance3D.new()
			var d_mesh := BoxMesh.new()
			d_mesh.size = Vector3(3.2, 0.02, 0.16)
			dash.mesh = d_mesh
			dash.material_override = white_mat
			dash.position = Vector3(dash_x, 0.015, lane_z)
			add_child(dash)
			
	# E. Pedestrian Zebra Crosswalks (Left, Center, Right)
	var crosswalk_x_positions = [-28.0, 0.0, 28.0]
	for cx in crosswalk_x_positions:
		for stripe_z in range(-12, 13, 2):
			var stripe := MeshInstance3D.new()
			var s_mesh := BoxMesh.new()
			s_mesh.size = Vector3(1.2, 0.02, 1.2)
			stripe.mesh = s_mesh
			stripe.material_override = white_mat
			stripe.position = Vector3(cx, 0.016, float(stripe_z))
			add_child(stripe)

	# F. Storm Sewer Grates along Curbs
	var grate_mat := StandardMaterial3D.new()
	grate_mat.albedo_color = Color("#1e293b")
	grate_mat.metallic = 0.95
	grate_mat.roughness = 0.35
	
	for side_z in [-13.4, 13.4]:
		for gx in range(int(-ARENA_BOUND_X + 8.0), int(ARENA_BOUND_X - 6.0), 14):
			var grate := MeshInstance3D.new()
			var gm := BoxMesh.new()
			gm.size = Vector3(0.9, 0.02, 0.6)
			grate.mesh = gm
			grate.material_override = grate_mat
			grate.position = Vector3(gx, 0.012, side_z)
			add_child(grate)
			
	# G. Cast Iron Manhole Covers
	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color("#292524")
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.5
	
	var manhole_positions = [Vector2(-14.0, -3.2), Vector2(16.0, 3.2), Vector2(-36.0, 2.5), Vector2(35.0, -2.8)]
	for mp in manhole_positions:
		var mh := MeshInstance3D.new()
		var mm := CylinderMesh.new()
		mm.top_radius = 0.65
		mm.bottom_radius = 0.65
		mm.height = 0.02
		mh.mesh = mm
		mh.material_override = iron_mat
		mh.position = Vector3(mp.x, 0.012, mp.y)
		add_child(mh)

# ==============================================================================
# 4. REINFORCED PERIMETER BOUNDARY WALLS (BATASAN SISI-SISI ARENA)
# ==============================================================================
func setup_perimeter_boundary_walls() -> void:
	var wall_root := Node3D.new()
	wall_root.name = "PerimeterBoundaryWalls"
	add_child(wall_root)
	
	# Concrete Base Material
	var barrier_mat := StandardMaterial3D.new()
	barrier_mat.albedo_color = Color("#475569") # Dark reinforced concrete
	barrier_mat.roughness = 0.8
	
	# Yellow & Black Hazard Stripes Material for Lower Trim
	var hazard_mat := StandardMaterial3D.new()
	hazard_mat.albedo_color = Color("#eab308") # Industrial warning yellow
	hazard_mat.roughness = 0.6
	
	# Industrial Heavy Steel Fence Material
	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color("#0f172a") # Dark coated steel
	fence_mat.metallic = 0.9
	fence_mat.roughness = 0.35
	
	# Razor Wire Coil Material
	var wire_mat := StandardMaterial3D.new()
	wire_mat.albedo_color = Color("#94a3b8")
	wire_mat.metallic = 0.95
	wire_mat.roughness = 0.2
	
	# 1. North Wall (Z = -ARENA_BOUND_Z)
	build_wall_segment(wall_root, Vector3(0, 0, -ARENA_BOUND_Z), Vector3(ARENA_BOUND_X * 2.0 + 3.0, 0, 0), barrier_mat, hazard_mat, fence_mat, wire_mat, false)
	
	# 2. South Wall (Z = +ARENA_BOUND_Z)
	build_wall_segment(wall_root, Vector3(0, 0, ARENA_BOUND_Z), Vector3(ARENA_BOUND_X * 2.0 + 3.0, 0, 0), barrier_mat, hazard_mat, fence_mat, wire_mat, false)
	
	# 3. West Wall (X = -ARENA_BOUND_X)
	build_wall_segment(wall_root, Vector3(-ARENA_BOUND_X, 0, 0), Vector3(0, 0, ARENA_BOUND_Z * 2.0 + 3.0), barrier_mat, hazard_mat, fence_mat, wire_mat, true)
	
	# 4. East Wall (X = +ARENA_BOUND_X)
	build_wall_segment(wall_root, Vector3(ARENA_BOUND_X, 0, 0), Vector3(0, 0, ARENA_BOUND_Z * 2.0 + 3.0), barrier_mat, hazard_mat, fence_mat, wire_mat, true)
	
	# Corner Security Watchtowers with Stadium Spotlights
	var corner_coords = [
		Vector3(-ARENA_BOUND_X, 0, -ARENA_BOUND_Z),
		Vector3(ARENA_BOUND_X, 0, -ARENA_BOUND_Z),
		Vector3(-ARENA_BOUND_X, 0, ARENA_BOUND_Z),
		Vector3(ARENA_BOUND_X, 0, ARENA_BOUND_Z)
	]
	
	for corner in corner_coords:
		build_corner_watchtower(wall_root, corner, barrier_mat, fence_mat)

func build_wall_segment(parent: Node3D, center_pos: Vector3, extent_vector: Vector3, barrier_mat: Material, hazard_mat: Material, fence_mat: Material, wire_mat: Material, is_side_wall: bool) -> void:
	var seg_length = extent_vector.x if not is_side_wall else extent_vector.z
	
	# A. Reinforced Concrete Base Barrier (Jersey Blast Barrier)
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(seg_length, 2.0, 1.2) if not is_side_wall else Vector3(1.2, 2.0, seg_length)
	
	var base_inst := MeshInstance3D.new()
	base_inst.mesh = base_mesh
	base_inst.material_override = barrier_mat
	base_inst.position = center_pos + Vector3(0, 1.0, 0)
	parent.add_child(base_inst)
	
	# B. Yellow Hazard Strip along base
	var hazard_mesh := BoxMesh.new()
	hazard_mesh.size = Vector3(seg_length, 0.35, 1.24) if not is_side_wall else Vector3(1.24, 0.35, seg_length)
	var hazard_inst := MeshInstance3D.new()
	hazard_inst.mesh = hazard_mesh
	hazard_inst.material_override = hazard_mat
	hazard_inst.position = center_pos + Vector3(0, 0.6, 0)
	parent.add_child(hazard_inst)
	
	# C. Industrial Steel Fence Panel above Concrete
	var fence_mesh := BoxMesh.new()
	fence_mesh.size = Vector3(seg_length, 2.5, 0.15) if not is_side_wall else Vector3(0.15, 2.5, seg_length)
	var fence_inst := MeshInstance3D.new()
	fence_inst.mesh = fence_mesh
	fence_inst.material_override = fence_mat
	fence_inst.position = center_pos + Vector3(0, 3.25, 0)
	parent.add_child(fence_inst)
	
	# D. Fence Support Steel Pillars every 6 meters
	var post_count = int(seg_length / 6.0)
	for p in range(post_count + 1):
		var offset = -seg_length * 0.5 + float(p) * (seg_length / float(post_count))
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.15
		post_mesh.bottom_radius = 0.18
		post_mesh.height = 4.8
		
		var post_inst := MeshInstance3D.new()
		post_inst.mesh = post_mesh
		post_inst.material_override = fence_mat
		if not is_side_wall:
			post_inst.position = center_pos + Vector3(offset, 2.4, 0)
		else:
			post_inst.position = center_pos + Vector3(0, 2.4, offset)
		parent.add_child(post_inst)
		
	# E. Coiled Razor Wire on top (Cylindrical coil)
	var wire_mesh := CylinderMesh.new()
	wire_mesh.top_radius = 0.35
	wire_mesh.bottom_radius = 0.35
	wire_mesh.height = seg_length
	
	var wire_inst := MeshInstance3D.new()
	wire_inst.mesh = wire_mesh
	wire_inst.material_override = wire_mat
	wire_inst.position = center_pos + Vector3(0, 4.7, 0)
	if not is_side_wall:
		wire_inst.rotation_degrees.z = 90
	else:
		wire_inst.rotation_degrees.x = 90
	parent.add_child(wire_inst)

func build_corner_watchtower(parent: Node3D, pos: Vector3, concrete_mat: Material, steel_mat: Material) -> void:
	# Heavy Column Pillar Tower
	var tower_mesh := BoxMesh.new()
	tower_mesh.size = Vector3(3.2, 8.5, 3.2)
	
	var tower := MeshInstance3D.new()
	tower.mesh = tower_mesh
	tower.material_override = concrete_mat
	tower.position = pos + Vector3(0, 4.25, 0)
	parent.add_child(tower)
	
	# Observation Platform Cap
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(4.2, 1.2, 4.2)
	var cap := MeshInstance3D.new()
	cap.mesh = cap_mesh
	cap.material_override = steel_mat
	cap.position = pos + Vector3(0, 8.8, 0)
	parent.add_child(cap)
	
	# Spotlight on Tower pointing towards the arena center
	var light := SpotLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 5.0
	light.spot_range = 65.0
	light.spot_angle = 50.0
	light.position = pos + Vector3(0, 9.0, 0)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)
	parent.add_child(light)

# ==============================================================================
# 5. METROPOLIS SKYSCRAPERS & URBAN SKYLINE (PERKOTAAN)
# ==============================================================================
func setup_skyscrapers_and_buildings() -> void:
	var city_root := Node3D.new()
	city_root.name = "MetropolisCitySkyline"
	add_child(city_root)
	
	# Diverse PBR Building Materials
	var glass_cyan := StandardMaterial3D.new()
	glass_cyan.albedo_color = Color("#0f3d61") # Reflective tinted cyan glass
	glass_cyan.metallic = 0.92
	glass_cyan.roughness = 0.12
	
	var glass_dark := StandardMaterial3D.new()
	glass_dark.albedo_color = Color("#090d16") # Sleek black mirror glass
	glass_dark.metallic = 0.95
	glass_dark.roughness = 0.15
	
	var concrete_facade := StandardMaterial3D.new()
	concrete_facade.albedo_color = Color("#334155") # Modern charcoal architectural concrete
	concrete_facade.roughness = 0.75
	
	var white_facade := StandardMaterial3D.new()
	white_facade.albedo_color = Color("#e2e8f0") # Sleek white panels
	white_facade.roughness = 0.55
	
	var materials = [glass_cyan, glass_dark, concrete_facade, white_facade]
	
	# A. Inner Ring of High-Rise Buildings Framing North & South Perimeters
	# North building row (Z between -44 and -85, backdrop city skyline)
	for i in range(-5, 6):
		var bx: float = float(i) * 16.0
		var bz: float = -44.0 - abs(float(i)) * 3.5
		var bw: float = randf_range(12.0, 15.0)
		var bd: float = randf_range(14.0, 18.0)
		var bh: float = randf_range(28.0, 68.0)
		var mat_idx: int = abs(i) % materials.size()
		build_skyscraper(city_root, Vector3(bx, 0, bz), Vector3(bw, bh, bd), materials[mat_idx])
		
	# South building row (Z between +54 and +95, framing the arena without blocking spectator camera)
	for i in range(-5, 6):
		if abs(i) <= 1:
			continue # Center spectator opening so the camera has a pristine view of both armies!
		var bx: float = float(i) * 18.0
		var bz: float = 54.0 + abs(float(i)) * 4.0
		var bw: float = randf_range(13.0, 16.0)
		var bd: float = randf_range(14.0, 18.0)
		var bh: float = randf_range(28.0, 68.0)
		var mat_idx: int = (abs(i) + 1) % materials.size()
		build_skyscraper(city_root, Vector3(bx, 0, bz), Vector3(bw, bh, bd), materials[mat_idx])
		
	# West building row (X between -55 and -110)
	for j in range(-3, 4):
		var bz: float = float(j) * 15.0
		var bx: float = -58.0 - abs(float(j)) * 4.0
		var bw: float = randf_range(14.0, 18.0)
		var bd: float = randf_range(12.0, 15.0)
		var bh: float = randf_range(35.0, 75.0)
		var mat_idx: int = (abs(j) + 2) % materials.size()
		build_skyscraper(city_root, Vector3(bx, 0, bz), Vector3(bw, bh, bd), materials[mat_idx])
		
	# East building row (X between +55 and +110)
	for j in range(-3, 4):
		var bz: float = float(j) * 15.0
		var bx: float = 58.0 + abs(float(j)) * 4.0
		var bw: float = randf_range(14.0, 18.0)
		var bd: float = randf_range(12.0, 15.0)
		var bh: float = randf_range(35.0, 75.0)
		var mat_idx: int = (abs(j) + 3) % materials.size()
		build_skyscraper(city_root, Vector3(bx, 0, bz), Vector3(bw, bh, bd), materials[mat_idx])
		
	# B. Outer Skyline Megatowers (Distant Metropolis Horizon, heights 80m to 140m)
	var outer_coords = [
		Vector2(-95, -85), Vector2(-45, -100), Vector2(0, -115), Vector2(50, -105), Vector2(100, -90),
		Vector2(-100, 85), Vector2(-50, 105), Vector2(0, 115), Vector2(55, 100), Vector2(95, 88),
		Vector2(-115, -45), Vector2(-120, 0), Vector2(-115, 45),
		Vector2(115, -45), Vector2(120, 0), Vector2(115, 45)
	]
	
	for oc in outer_coords:
		var mega_h = randf_range(80.0, 140.0)
		var mega_w = randf_range(20.0, 30.0)
		build_skyscraper(city_root, Vector3(oc.x, 0, oc.y), Vector3(mega_w, mega_h, mega_w), glass_dark)

func build_skyscraper(parent: Node3D, pos: Vector3, dims: Vector3, mat: Material) -> void:
	# Main Building Mass
	var tower := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dims
	tower.mesh = box
	tower.material_override = mat
	tower.position = pos + Vector3(0, dims.y * 0.5, 0)
	parent.add_child(tower)
	
	# Rooftop Structures (HVAC Units & Elevator Housing)
	var roof_box := BoxMesh.new()
	roof_box.size = Vector3(dims.x * 0.5, 3.5, dims.z * 0.5)
	var roof_unit := MeshInstance3D.new()
	roof_unit.mesh = roof_box
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color("#334155")
	roof_unit.material_override = roof_mat
	roof_unit.position = pos + Vector3(0, dims.y + 1.75, 0)
	parent.add_child(roof_unit)
	
	# Communication Antenna Mast
	if dims.y > 45.0:
		var ant := MeshInstance3D.new()
		var ant_mesh := CylinderMesh.new()
		ant_mesh.top_radius = 0.08
		ant_mesh.bottom_radius = 0.25
		ant_mesh.height = 12.0
		ant.mesh = ant_mesh
		ant.material_override = roof_mat
		ant.position = pos + Vector3(0, dims.y + 9.5, 0)
		parent.add_child(ant)
		
		# Red Aviation Warning Light on Spire Tip
		var beacon := OmniLight3D.new()
		beacon.light_color = Color(1.0, 0.1, 0.1)
		beacon.light_energy = 2.5
		beacon.omni_range = 15.0
		beacon.position = pos + Vector3(0, dims.y + 15.5, 0)
		parent.add_child(beacon)

# ==============================================================================
# 6. STREET FURNITURE, LIGHT POLES & URBAN PLANTERS
# ==============================================================================
func setup_street_props() -> void:
	var props_root := Node3D.new()
	props_root.name = "StreetProps"
	add_child(props_root)
	
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color("#1e293b")
	pole_mat.metallic = 0.8
	pole_mat.roughness = 0.3
	
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp_mat.albedo_color = Color(1.0, 0.95, 0.85)
	
	# A. Modern Curved LED Street Light Poles along Sidewalks
	for z_side in [-13.8, 13.8]:
		for x in range(int(-ARENA_BOUND_X + 6.0), int(ARENA_BOUND_X - 4.0), 12):
			var pole := Node3D.new()
			pole.position = Vector3(x, 0.15, z_side)
			props_root.add_child(pole)
			
			# Vertical Mast
			var mast := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.18
			cyl.height = 7.5
			mast.mesh = cyl
			mast.material_override = pole_mat
			mast.position = Vector3(0, 3.75, 0)
			pole.add_child(mast)
			
			# Horizontal Luminaire Arm
			var arm := MeshInstance3D.new()
			var abox := BoxMesh.new()
			abox.size = Vector3(0.18, 0.15, 2.2)
			arm.mesh = abox
			arm.material_override = pole_mat
			var arm_dir = 1.0 if z_side < 0 else -1.0
			arm.position = Vector3(0, 7.35, arm_dir * 0.9)
			pole.add_child(arm)
			
			# Glowing LED Fixture
			var bulb := MeshInstance3D.new()
			var b_mesh := BoxMesh.new()
			b_mesh.size = Vector3(0.35, 0.08, 0.8)
			bulb.mesh = b_mesh
			bulb.material_override = lamp_mat
			bulb.position = Vector3(0, 7.25, arm_dir * 1.6)
			pole.add_child(bulb)
			
			# Downward Street Spotlight
			var spot := SpotLight3D.new()
			spot.light_color = Color(1.0, 0.92, 0.82)
			spot.light_energy = 3.5
			spot.spot_range = 16.0
			spot.spot_angle = 55.0
			spot.position = Vector3(0, 7.2, arm_dir * 1.6)
			spot.rotation_degrees.x = -90
			pole.add_child(spot)

	# B. Concrete Planters with Urban Green Trees
	var planter_mat := StandardMaterial3D.new()
	planter_mat.albedo_color = Color("#64748b")
	
	var leaves_mat := StandardMaterial3D.new()
	leaves_mat.albedo_color = Color("#15803d") # Deep lush green
	leaves_mat.roughness = 0.7
	
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#451a03")
	
	for z_side in [-15.5, 15.5]:
		for x in range(int(-ARENA_BOUND_X + 12.0), int(ARENA_BOUND_X - 10.0), 16):
			var tree_root := Node3D.new()
			tree_root.position = Vector3(x, 0.15, z_side)
			props_root.add_child(tree_root)
			
			# Planter Box
			var p_box := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = Vector3(2.4, 0.6, 2.4)
			p_box.mesh = pb
			p_box.material_override = planter_mat
			p_box.position.y = 0.3
			tree_root.add_child(p_box)
			
			# Tree Trunk
			var trunk := MeshInstance3D.new()
			var tc := CylinderMesh.new()
			tc.top_radius = 0.15
			tc.bottom_radius = 0.22
			tc.height = 3.2
			trunk.mesh = tc
			trunk.material_override = wood_mat
			trunk.position.y = 2.1
			tree_root.add_child(trunk)
			
			# Foliage Canopy
			var canopy := MeshInstance3D.new()
			var sp := SphereMesh.new()
			sp.radius = 1.4
			sp.height = 2.8
			canopy.mesh = sp
			canopy.material_override = leaves_mat
			canopy.position.y = 4.2
			tree_root.add_child(canopy)

# ==============================================================================
# 7. SUBTLE URBAN ATMOSPHERIC PARTICLES
# ==============================================================================
func setup_urban_particles() -> void:
	var motes := CPUParticles3D.new()
	motes.amount = 80
	motes.lifetime = 6.0
	motes.preprocess = 4.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(ARENA_BOUND_X, 8.0, ARENA_BOUND_Z)
	motes.direction = Vector3(0.8, -0.1, 0.4).normalized()
	motes.spread = 25.0
	motes.initial_velocity_min = 0.5
	motes.initial_velocity_max = 1.8
	motes.gravity = Vector3(0, -0.01, 0)
	motes.position = Vector3(0, 4.0, 0)
	
	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 0.04
	mote_mesh.height = 0.08
	mote_mesh.radial_segments = 6
	mote_mesh.rings = 3
	motes.mesh = mote_mesh
	
	var mote_mat := StandardMaterial3D.new()
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.35)
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	motes.material_override = mote_mat
	add_child(motes)
