extends Node3D

# ==============================================================================
# REALISTIC COUNTRYSIDE & HISTORIC RUSTIC VILLAGE ARENA (PEDESAAN REALISTIS)
# Realism Enhancements:
# - Authentic PBR Materials: High-resolution procedural Normal & Roughness maps
# - Organic Earthy Color Palette: Natural fescue grass, packed gravel loam, weathered timber
# - Architectural Depth: Fieldstone masonry foundations, half-timbered framing (Fachwerk),
#   recessed panel windows, dark wooden plank doors, and overhanging clay/slate eaves
# - Cinematic Balanced Lighting: Deep atmospheric Rayleigh sky, balanced natural sun,
#   deep SSAO contact shadowing, SSIL indirect light bounce, and natural filmic ACES tone mapping
# ==============================================================================

const ARENA_BOUND_X := 42.0
const ARENA_BOUND_Z := 23.5

var world_env_node: WorldEnvironment = null
var sun_light: DirectionalLight3D = null
var is_performance_mode: bool = false

# Animated nodes
var rotating_windmill_blades: Array[Node3D] = []
var stream_mesh_inst: MeshInstance3D = null
var anim_timer: float = 0.0

# Shared Procedural PBR Noise Textures (Generated once for ultra-fast performance)
var tex_grass_normal: NoiseTexture2D = null
var tex_dirt_normal: NoiseTexture2D = null
var tex_stone_normal: NoiseTexture2D = null
var tex_wood_normal: NoiseTexture2D = null
var tex_roof_normal: NoiseTexture2D = null
var tex_stucco_normal: NoiseTexture2D = null

func _ready() -> void:
	init_procedural_textures()
	setup_lighting_and_environment()
	setup_countryside_terrain()
	setup_rustic_boundaries()
	setup_village_and_hills()
	setup_nature_and_farm_props()
	setup_pastoral_particles()

func _process(delta: float) -> void:
	anim_timer += delta
	# Rotate windmill sails gently in the natural mountain breeze
	for blades in rotating_windmill_blades:
		if is_instance_valid(blades):
			blades.rotation.z += delta * 0.40

# ==============================================================================
# PROCEDURAL PBR NOISE MAP GENERATORS
# ==============================================================================
func init_procedural_textures() -> void:
	# 1. Fine Grass Micro-Bump Normal Map
	var n_grass := FastNoiseLite.new()
	n_grass.noise_type = FastNoiseLite.TYPE_PERLIN
	n_grass.frequency = 0.09
	n_grass.fractal_octaves = 4
	tex_grass_normal = NoiseTexture2D.new()
	tex_grass_normal.seamless = true
	tex_grass_normal.as_normal_map = true
	tex_grass_normal.bump_strength = 2.4
	tex_grass_normal.noise = n_grass

	# 2. Packed Dirt & Compacted Gravel Normal Map
	var n_dirt := FastNoiseLite.new()
	n_dirt.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_dirt.frequency = 0.06
	n_dirt.fractal_octaves = 3
	tex_dirt_normal = NoiseTexture2D.new()
	tex_dirt_normal.seamless = true
	tex_dirt_normal.as_normal_map = true
	tex_dirt_normal.bump_strength = 2.2
	tex_dirt_normal.noise = n_dirt

	# 3. Rugged Fieldstone & Mortar Masonry Normal Map
	var n_stone := FastNoiseLite.new()
	n_stone.noise_type = FastNoiseLite.TYPE_CELLULAR
	n_stone.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	n_stone.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2
	n_stone.frequency = 0.12
	tex_stone_normal = NoiseTexture2D.new()
	tex_stone_normal.seamless = true
	tex_stone_normal.as_normal_map = true
	tex_stone_normal.bump_strength = 3.2
	tex_stone_normal.noise = n_stone

	# 4. Aged Timber & Wood Grain Normal Map (Directional linear noise)
	var n_wood := FastNoiseLite.new()
	n_wood.noise_type = FastNoiseLite.TYPE_PERLIN
	n_wood.frequency = 0.08
	n_wood.fractal_octaves = 3
	tex_wood_normal = NoiseTexture2D.new()
	tex_wood_normal.seamless = true
	tex_wood_normal.as_normal_map = true
	tex_wood_normal.bump_strength = 2.5
	tex_wood_normal.noise = n_wood

	# 5. Overlapping Clay Tile / Slate Ridge Normal Map
	var n_roof := FastNoiseLite.new()
	n_roof.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_roof.frequency = 0.14
	tex_roof_normal = NoiseTexture2D.new()
	tex_roof_normal.seamless = true
	tex_roof_normal.as_normal_map = true
	tex_roof_normal.bump_strength = 2.8
	tex_roof_normal.noise = n_roof

	# 6. Weathered Lime Plaster / Stucco Normal Map
	var n_stucco := FastNoiseLite.new()
	n_stucco.noise_type = FastNoiseLite.TYPE_PERLIN
	n_stucco.frequency = 0.16
	tex_stucco_normal = NoiseTexture2D.new()
	tex_stucco_normal.seamless = true
	tex_stucco_normal.as_normal_map = true
	tex_stucco_normal.bump_strength = 1.4
	tex_stucco_normal.noise = n_stucco

# ==============================================================================
# 1. GROUND ELEVATION & NAVIGATION HEIGHT
# ==============================================================================
func get_ground_height(x: float, z: float) -> float:
	if abs(x) <= ARENA_BOUND_X and abs(z) > 14.5 and abs(z) <= ARENA_BOUND_Z:
		return 0.10
	return 0.0

func get_ground_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP

# ==============================================================================
# 2. CINEMATIC REALISTIC LIGHTING, ATMOSPHERIC SKY & ACES POST-PROCESSING
# ==============================================================================
func setup_lighting_and_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	# Realistic Atmospheric Sky with Natural Rayleigh/Mie Blue Gradient
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#142c4b") # Deep natural atmospheric blue zenith
	sky_mat.sky_horizon_color = Color("#9db5c9") # Natural atmospheric horizon haze
	sky_mat.sky_curve = 0.14
	sky_mat.sky_energy_multiplier = 1.05

	sky_mat.ground_bottom_color = Color("#181512") # Deep dark moist soil
	sky_mat.ground_horizon_color = Color("#4a4642") # Distant muted haze
	sky_mat.ground_curve = 0.09
	sky_mat.ground_energy_multiplier = 0.85

	sky_mat.sun_angle_max = 2.0
	sky_mat.sun_curve = 0.15

	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky

	# Natural Diffuse Sky Fill Light (Soft cool skylight bounce)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.58
	env.ambient_light_color = Color(0.70, 0.78, 0.88)
	env.ambient_light_energy = 0.58

	# Subtle Morning Atmospheric Mist (Natural grey-blue valley haze, not neon)
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0012
	env.volumetric_fog_albedo = Color(0.86, 0.90, 0.95)
	env.volumetric_fog_emission = Color(0.10, 0.15, 0.20) * 0.02
	env.volumetric_fog_emission_energy = 0.4
	env.volumetric_fog_anisotropy = 0.65
	env.volumetric_fog_length = 260.0

	# Real-Time Screen Space Ambient Occlusion (SSAO) for deep contact shadows
	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 3.2
	env.ssao_power = 1.4
	env.ssao_detail = 1.0

	# Screen Space Indirect Lighting (SSIL) for realistic global light bounce
	env.ssil_enabled = true
	env.ssil_radius = 2.0
	env.ssil_intensity = 1.2

	# Screen Space Reflections (SSR) for the river stream and damp mud tracks
	env.ssr_enabled = true
	env.ssr_max_steps = 32
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.25

	# ACES Filmic Tone Mapping tuned for authentic realistic colors
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.02
	env.tonemap_white = 4.8

	# Filmic adjustments: Natural saturation (0.98) avoids cartoon candy colors!
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.10
	env.adjustment_saturation = 0.98

	# Soft Cinematic Bloom
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 1.15
	env.glow_hdr_scale = 1.5

	world_env_node = WorldEnvironment.new()
	world_env_node.environment = env
	add_child(world_env_node)

	# Realistic Directional Sunlight casting crisp, natural shadows
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.97, 0.92) # Natural crisp sunlight
	sun_light.light_energy = 2.4 # Balanced, prevents harsh blown-out whites
	sun_light.light_indirect_energy = 1.1
	sun_light.light_volumetric_fog_energy = 1.8

	sun_light.shadow_enabled = true
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_blend_splits = true
	sun_light.directional_shadow_max_distance = 110.0
	sun_light.shadow_bias = 0.001
	sun_light.shadow_normal_bias = 1.2
	sun_light.shadow_blur = 1.6
	sun_light.rotation_degrees = Vector3(-44, 46, 0)
	add_child(sun_light)

	# Subtle Skylight Ambient Fill
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.68, 0.78, 0.90)
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(35, -130, 0)
	add_child(fill)

func set_performance_mode(enabled: bool) -> void:
	is_performance_mode = enabled
	if world_env_node and world_env_node.environment:
		var env = world_env_node.environment
		if enabled:
			env.ssao_enabled = false
			env.ssil_enabled = false
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				sun_light.directional_shadow_blend_splits = false
				sun_light.directional_shadow_max_distance = 60.0
		else:
			env.ssao_enabled = true
			env.ssil_enabled = true
			env.ssr_enabled = true
			env.volumetric_fog_enabled = true
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				sun_light.directional_shadow_blend_splits = true
				sun_light.directional_shadow_max_distance = 110.0

# ==============================================================================
# 3. REALISTIC TERRAIN: NATURAL GRASS, PACKED ROAD, MUD RUTS & STREAM
# ==============================================================================
func setup_countryside_terrain() -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "RealisticTerrain"
	add_child(terrain_root)

	# A. Vast Natural Meadow Ground Plane (Muted Natural Meadow Fescue Green)
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(280.0, 200.0)

	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color("#344621") # Natural earthy dark meadow green
	grass_mat.roughness = 0.92
	grass_mat.normal_enabled = true
	grass_mat.normal_texture = tex_grass_normal
	grass_mat.uv1_scale = Vector3(32.0, 24.0, 1.0)

	var grass_inst := MeshInstance3D.new()
	grass_inst.mesh = ground_mesh
	grass_inst.material_override = grass_mat
	grass_inst.position.y = 0.0
	terrain_root.add_child(grass_inst)

	# B. Terraced Earth Plots along Margins
	var terrace_mat := StandardMaterial3D.new()
	terrace_mat.albedo_color = Color("#2a381b") # Deep natural loam & clover
	terrace_mat.roughness = 0.94
	terrace_mat.normal_enabled = true
	terrace_mat.normal_texture = tex_grass_normal
	terrace_mat.uv1_scale = Vector3(18.0, 4.0, 1.0)

	var terrace_mesh := BoxMesh.new()
	terrace_mesh.size = Vector3(ARENA_BOUND_X * 2.0, 0.12, (ARENA_BOUND_Z - 14.5))

	var f_north := MeshInstance3D.new()
	f_north.mesh = terrace_mesh
	f_north.material_override = terrace_mat
	f_north.position = Vector3(0.0, 0.06, -(14.5 + (ARENA_BOUND_Z - 14.5) * 0.5))
	terrain_root.add_child(f_north)

	var f_south := MeshInstance3D.new()
	f_south.mesh = terrace_mesh
	f_south.material_override = terrace_mat
	f_south.position = Vector3(0.0, 0.06, (14.5 + (ARENA_BOUND_Z - 14.5) * 0.5))
	terrain_root.add_child(f_south)

	# C. Realistic Packed Loam & Compacted Gravel Village Road
	var road_mesh := PlaneMesh.new()
	road_mesh.size = Vector2(ARENA_BOUND_X * 2.0 + 8.0, 11.0)

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color("#4d3f31") # Weathered packed dirt road
	road_mat.roughness = 0.94
	road_mat.normal_enabled = true
	road_mat.normal_texture = tex_dirt_normal
	road_mat.uv1_scale = Vector3(20.0, 4.0, 1.0)

	var road_inst := MeshInstance3D.new()
	road_inst.mesh = road_mesh
	road_inst.material_override = road_mat
	road_inst.position = Vector3(0.0, 0.012, 0.0)
	terrain_root.add_child(road_inst)

	# D. Damp Cart Wheel Ruts (Darker moist soil with subtle specular sheen)
	var rut_mat := StandardMaterial3D.new()
	rut_mat.albedo_color = Color("#362b20") # Damp dark soil in ruts
	rut_mat.roughness = 0.65 # Moisture shine
	rut_mat.normal_enabled = true
	rut_mat.normal_texture = tex_dirt_normal
	rut_mat.uv1_scale = Vector3(24.0, 1.5, 1.0)

	for rz in [-2.4, 2.4]:
		var rut_track := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(ARENA_BOUND_X * 2.0 + 6.0, 0.01, 0.55)
		rut_track.mesh = r_box
		rut_track.material_override = rut_mat
		rut_track.position = Vector3(0.0, 0.016, rz)
		terrain_root.add_child(rut_track)

	# E. Natural Granite Cobblestone Stepping Stones Across Road
	var cobble_mat := StandardMaterial3D.new()
	cobble_mat.albedo_color = Color("#595856") # Real weathered river granite
	cobble_mat.roughness = 0.78
	cobble_mat.normal_enabled = true
	cobble_mat.normal_texture = tex_stone_normal
	cobble_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)

	var cobble_crossings = [-26.0, 0.0, 26.0]
	for cx in cobble_crossings:
		for cz in range(-5, 6):
			var stone := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = randf_range(0.35, 0.52)
			sm.bottom_radius = sm.top_radius * 1.1
			sm.height = 0.04
			stone.mesh = sm
			stone.material_override = cobble_mat
			stone.position = Vector3(cx + randf_range(-0.35, 0.35), 0.022, float(cz) * 0.95 + randf_range(-0.12, 0.12))
			stone.rotation_degrees.y = randf_range(0, 360)
			terrain_root.add_child(stone)

	# Scattered Granite Roadside Stones
	for i in range(32):
		var stone_dot := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		var s_rad = randf_range(0.18, 0.38)
		s_mesh.radius = s_rad
		s_mesh.height = s_rad * 1.1
		stone_dot.mesh = s_mesh
		stone_dot.material_override = cobble_mat
		var sx = randf_range(-ARENA_BOUND_X + 2.0, ARENA_BOUND_X - 2.0)
		var sz = randf_range(-5.5, 5.5)
		if abs(sz) < 1.0:
			sz = (1.0 if sz >= 0 else -1.0) * randf_range(3.2, 5.2)
		stone_dot.position = Vector3(sx, 0.03, sz)
		terrain_root.add_child(stone_dot)

	# F. Natural Flowing Stream with Gravel Riverbed
	setup_pastoral_stream(terrain_root)

	# G. Agricultural Crop Plots (Mature Golden Wheat & Rustic Furrows)
	setup_crop_plots(terrain_root)

# Realistic Irrigation River Stream
func setup_pastoral_stream(parent: Node3D) -> void:
	# Water Surface with subtle physical reflections
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.14, 0.28, 0.35, 0.82) # Natural cool river water
	water_mat.roughness = 0.06
	water_mat.metallic = 0.12
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var stream_mesh := BoxMesh.new()
	stream_mesh.size = Vector3(ARENA_BOUND_X * 2.0 + 30.0, 0.18, 5.5)

	stream_mesh_inst = MeshInstance3D.new()
	stream_mesh_inst.mesh = stream_mesh
	stream_mesh_inst.material_override = water_mat
	stream_mesh_inst.position = Vector3(0.0, -0.05, -17.2)
	parent.add_child(stream_mesh_inst)

	# Riverbed Gravel & Mossy Boulders
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#3d4248") # Dark wet river stone
	rock_mat.roughness = 0.65
	rock_mat.normal_enabled = true
	rock_mat.normal_texture = tex_stone_normal

	for bx in range(int(-ARENA_BOUND_X - 5.0), int(ARENA_BOUND_X + 5.0), 4):
		for bz_offset in [-2.8, 2.8]:
			var boulder := MeshInstance3D.new()
			var b_mesh := SphereMesh.new()
			var brad = randf_range(0.32, 0.65)
			b_mesh.radius = brad
			b_mesh.height = brad * 1.2
			boulder.mesh = b_mesh
			boulder.material_override = rock_mat
			boulder.position = Vector3(float(bx) + randf_range(-1.0, 1.0), 0.08, -17.2 + bz_offset + randf_range(-0.25, 0.25))
			parent.add_child(boulder)

	# Timber Footbridges crossing the stream
	var bridge_x_positions = [-20.0, 20.0]
	for brx in bridge_x_positions:
		build_wooden_footbridge(parent, Vector3(brx, 0.0, -17.2))

func build_wooden_footbridge(parent: Node3D, pos: Vector3) -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#4a3624") # Weathered rustic oak
	wood_mat.roughness = 0.88
	wood_mat.normal_enabled = true
	wood_mat.normal_texture = tex_wood_normal
	wood_mat.uv1_scale = Vector3(1.0, 4.0, 1.0)

	var bridge_root := Node3D.new()
	bridge_root.position = pos
	parent.add_child(bridge_root)

	# Bridge Planks Platform
	var deck_mesh := BoxMesh.new()
	deck_mesh.size = Vector3(3.2, 0.22, 6.2)
	var deck := MeshInstance3D.new()
	deck.mesh = deck_mesh
	deck.material_override = wood_mat
	deck.position.y = 0.20
	bridge_root.add_child(deck)

	# Handrail posts and rails
	for side_x in [-1.5, 1.5]:
		for pz in [-2.5, 0.0, 2.5]:
			var post := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.07
			pm.bottom_radius = 0.07
			pm.height = 1.15
			post.mesh = pm
			post.material_override = wood_mat
			post.position = Vector3(side_x, 0.70, pz)
			bridge_root.add_child(post)

		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.12, 0.12, 6.2)
		rail.mesh = rm
		rail.material_override = wood_mat
		rail.position = Vector3(side_x, 1.25, 0.0)
		bridge_root.add_child(rail)

# Agricultural Crop Plots (Realistic Golden Wheat Furrows)
func setup_crop_plots(parent: Node3D) -> void:
	var wheat_mat := StandardMaterial3D.new()
	wheat_mat.albedo_color = Color("#8c7340") # Natural mature golden wheat stalks
	wheat_mat.roughness = 0.88
	wheat_mat.normal_enabled = true
	wheat_mat.normal_texture = tex_grass_normal

	var rye_mat := StandardMaterial3D.new()
	rye_mat.albedo_color = Color("#4e5f2b") # Natural green-gold autumn crop
	rye_mat.roughness = 0.86
	rye_mat.normal_enabled = true
	rye_mat.normal_texture = tex_grass_normal

	for px in range(-36, 37, 18):
		var is_wheat = (abs(px) % 36 == 0)
		var plot_mat = wheat_mat if is_wheat else rye_mat

		for row_z in range(16, 22, 2):
			var crop_row := MeshInstance3D.new()
			var c_box := BoxMesh.new()
			c_box.size = Vector3(14.0, 0.55, 0.75)
			crop_row.mesh = c_box
			crop_row.material_override = plot_mat
			crop_row.position = Vector3(float(px), 0.30, float(row_z))
			parent.add_child(crop_row)

	build_scarecrow(parent, Vector3(-18.0, 0.1, 18.5))
	build_scarecrow(parent, Vector3(18.0, 0.1, 18.5))

func build_scarecrow(parent: Node3D, pos: Vector3) -> void:
	var straw_mat := StandardMaterial3D.new()
	straw_mat.albedo_color = Color("#8a7242") # Natural dry straw
	straw_mat.roughness = 0.90

	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = Color("#5a3028") # Weathered earthy faded coat
	cloth_mat.roughness = 0.85

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#3b2b1d")
	wood_mat.roughness = 0.90

	var crow := Node3D.new()
	crow.position = pos
	parent.add_child(crow)

	# Main post
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.08
	pm.height = 2.8
	post.mesh = pm
	post.material_override = wood_mat
	post.position.y = 1.4
	crow.add_child(post)

	# Horizontal cross arms
	var arms := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.05
	am.bottom_radius = 0.05
	am.height = 2.0
	arms.mesh = am
	arms.material_override = cloth_mat
	arms.position.y = 2.1
	arms.rotation_degrees.z = 90
	crow.add_child(arms)

	# Straw head
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.30
	hm.height = 0.55
	head.mesh = hm
	head.material_override = straw_mat
	head.position.y = 2.7
	crow.add_child(head)

# ==============================================================================
# 4. BOUNDARY WALLS, WEATHERED TIMBER FENCES & WATCHTOWERS
# ==============================================================================
func setup_rustic_boundaries() -> void:
	var bounds_root := Node3D.new()
	bounds_root.name = "RusticPerimeter"
	add_child(bounds_root)

	var timber_mat := StandardMaterial3D.new()
	timber_mat.albedo_color = Color("#4a3726") # Weathered cedar split-rail
	timber_mat.roughness = 0.90
	timber_mat.normal_enabled = true
	timber_mat.normal_texture = tex_wood_normal

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color("#4a4744") # Dry-stacked fieldstone wall
	stone_mat.roughness = 0.88
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = tex_stone_normal

	var hedge_mat := StandardMaterial3D.new()
	hedge_mat.albedo_color = Color("#22381b") # Deep natural foliage green
	hedge_mat.roughness = 0.85
	hedge_mat.normal_enabled = true
	hedge_mat.normal_texture = tex_grass_normal

	# 1. North & South Fences
	build_pastoral_fence_segment(bounds_root, Vector3(0, 0, -ARENA_BOUND_Z), ARENA_BOUND_X * 2.0 + 3.0, false, timber_mat, stone_mat, hedge_mat)
	build_pastoral_fence_segment(bounds_root, Vector3(0, 0, ARENA_BOUND_Z), ARENA_BOUND_X * 2.0 + 3.0, false, timber_mat, stone_mat, hedge_mat)

	# 2. West & East Fences
	build_pastoral_fence_segment(bounds_root, Vector3(-ARENA_BOUND_X, 0, 0), ARENA_BOUND_Z * 2.0 + 3.0, true, timber_mat, stone_mat, hedge_mat)
	build_pastoral_fence_segment(bounds_root, Vector3(ARENA_BOUND_X, 0, 0), ARENA_BOUND_Z * 2.0 + 3.0, true, timber_mat, stone_mat, hedge_mat)

	# 3. Corner Watchtowers
	var corner_coords = [
		Vector3(-ARENA_BOUND_X, 0, -ARENA_BOUND_Z),
		Vector3(ARENA_BOUND_X, 0, -ARENA_BOUND_Z),
		Vector3(-ARENA_BOUND_X, 0, ARENA_BOUND_Z),
		Vector3(ARENA_BOUND_X, 0, ARENA_BOUND_Z)
	]
	for corner in corner_coords:
		build_village_watchtower(bounds_root, corner, timber_mat, stone_mat)

	# 4. Entrance Timber Arches
	build_village_gate_arch(bounds_root, Vector3(-ARENA_BOUND_X, 0, 0), true, timber_mat)
	build_village_gate_arch(bounds_root, Vector3(ARENA_BOUND_X, 0, 0), true, timber_mat)

func build_pastoral_fence_segment(parent: Node3D, center_pos: Vector3, seg_len: float, is_side: bool, timber_mat: Material, stone_mat: Material, hedge_mat: Material) -> void:
	# Low Fieldstone Base
	var wall_base := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(seg_len, 0.65, 0.8) if not is_side else Vector3(0.8, 0.65, seg_len)
	wall_base.mesh = wm
	wall_base.material_override = stone_mat
	wall_base.position = center_pos + Vector3(0, 0.325, 0)
	parent.add_child(wall_base)

	# Timber Posts
	var post_count = int(seg_len / 4.0)
	for p in range(post_count + 1):
		var offset = -seg_len * 0.5 + float(p) * (seg_len / float(post_count))
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.12
		pm.bottom_radius = 0.14
		pm.height = 2.2
		post.mesh = pm
		post.material_override = timber_mat
		if not is_side:
			post.position = center_pos + Vector3(offset, 1.1, 0)
		else:
			post.position = center_pos + Vector3(0, 1.1, offset)
		parent.add_child(post)

	# Horizontal Split-Rail Beams
	for beam_y in [1.2, 1.85]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(seg_len, 0.14, 0.14) if not is_side else Vector3(0.14, 0.14, seg_len)
		beam.mesh = bm
		beam.material_override = timber_mat
		beam.position = center_pos + Vector3(0, beam_y, 0)
		parent.add_child(beam)

	# Natural Hedges along outside
	for h in range(int(seg_len / 7.0)):
		var h_offset = -seg_len * 0.5 + float(h) * 7.0 + 3.5
		var hedge := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = randf_range(0.8, 1.2)
		hm.height = hm.radius * 1.6
		hedge.mesh = hm
		hedge.material_override = hedge_mat
		var h_pos = center_pos + (Vector3(h_offset, 0.65, -0.9 if center_pos.z < 0 else 0.9) if not is_side else Vector3(-0.9 if center_pos.x < 0 else 0.9, 0.65, h_offset))
		hedge.position = h_pos
		parent.add_child(hedge)

func build_village_watchtower(parent: Node3D, pos: Vector3, timber_mat: Material, stone_mat: Material) -> void:
	var tower_root := Node3D.new()
	tower_root.position = pos
	parent.add_child(tower_root)

	# Heavy Stone Base
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.2, 1.8, 4.2)
	base.mesh = bm
	base.material_override = stone_mat
	base.position.y = 0.9
	tower_root.add_child(base)

	# 4 Heavy Timber Uprights
	var offsets = [-1.5, 1.5]
	for ox in offsets:
		for oz in offsets:
			var leg := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.16
			lm.bottom_radius = 0.20
			lm.height = 7.0
			leg.mesh = lm
			leg.material_override = timber_mat
			leg.position = Vector3(ox, 4.4, oz)
			tower_root.add_child(leg)

	# Sentry Platform
	var plat := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(4.5, 0.3, 4.5)
	plat.mesh = pm
	plat.material_override = timber_mat
	plat.position.y = 7.0
	tower_root.add_child(plat)

	# Wood Shingle Roof
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color("#5c2e26") # Weathered terracotta shingle
	roof_mat.roughness = 0.75
	roof_mat.normal_enabled = true
	roof_mat.normal_texture = tex_roof_normal

	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(5.2, 2.0, 5.2)
	roof.mesh = roof_mesh
	roof.material_override = roof_mat
	roof.position.y = 9.8
	tower_root.add_child(roof)

func build_village_gate_arch(parent: Node3D, pos: Vector3, is_side: bool, timber_mat: Material) -> void:
	var arch_root := Node3D.new()
	arch_root.position = pos
	parent.add_child(arch_root)

	var gap = 7.5
	for side in [-gap * 0.5, gap * 0.5]:
		var pillar := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.28
		pm.bottom_radius = 0.35
		pm.height = 6.2
		pillar.mesh = pm
		pillar.material_override = timber_mat
		if is_side:
			pillar.position = Vector3(0, 3.1, side)
		else:
			pillar.position = Vector3(side, 3.1, 0)
		arch_root.add_child(pillar)

	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, 0.65, gap + 2.0) if is_side else Vector3(gap + 2.0, 0.65, 0.55)
	beam.mesh = bm
	beam.material_override = timber_mat
	beam.position = Vector3(0, 5.9, 0)
	arch_root.add_child(beam)

# ==============================================================================
# 5. AUTHENTIC VILLAGE ARCHITECTURE: HALF-TIMBERED COTTAGES, BARNS & WINDMILL
# ==============================================================================
func setup_village_and_hills() -> void:
	var village_root := Node3D.new()
	village_root.name = "RealisticVillage"
	add_child(village_root)

	# Shared Realistic PBR Materials
	var wall_plaster := StandardMaterial3D.new()
	wall_plaster.albedo_color = Color("#b8afa2") # Aged lime plaster / weathered stucco
	wall_plaster.roughness = 0.82
	wall_plaster.normal_enabled = true
	wall_plaster.normal_texture = tex_stucco_normal
	wall_plaster.uv1_scale = Vector3(4.0, 4.0, 1.0)

	var wall_timber := StandardMaterial3D.new()
	wall_timber.albedo_color = Color("#38271a") # Dark aged oak timber beams
	wall_timber.roughness = 0.90
	wall_timber.normal_enabled = true
	wall_timber.normal_texture = tex_wood_normal
	wall_timber.uv1_scale = Vector3(1.0, 6.0, 1.0)

	var foundation_stone := StandardMaterial3D.new()
	foundation_stone.albedo_color = Color("#4a4742") # Fieldstone masonry foundation
	foundation_stone.roughness = 0.88
	foundation_stone.normal_enabled = true
	foundation_stone.normal_texture = tex_stone_normal
	foundation_stone.uv1_scale = Vector3(3.0, 1.5, 1.0)

	var roof_terracotta := StandardMaterial3D.new()
	roof_terracotta.albedo_color = Color("#5c2e26") # Weathered burnt terracotta clay
	roof_terracotta.roughness = 0.72
	roof_terracotta.normal_enabled = true
	roof_terracotta.normal_texture = tex_roof_normal
	roof_terracotta.uv1_scale = Vector3(6.0, 4.0, 1.0)

	var roof_slate := StandardMaterial3D.new()
	roof_slate.albedo_color = Color("#2d3744") # Dark Welsh/Alpine mountain slate
	roof_slate.roughness = 0.65
	roof_slate.normal_enabled = true
	roof_slate.normal_texture = tex_roof_normal
	roof_slate.uv1_scale = Vector3(6.0, 4.0, 1.0)

	var roof_thatch := StandardMaterial3D.new()
	roof_thatch.albedo_color = Color("#6e5b38") # Weathered grey-gold reed thatch
	roof_thatch.roughness = 0.92
	roof_thatch.normal_enabled = true
	roof_thatch.normal_texture = tex_grass_normal
	roof_thatch.uv1_scale = Vector3(4.0, 4.0, 1.0)

	var stone_chimney := StandardMaterial3D.new()
	stone_chimney.albedo_color = Color("#42403d")
	stone_chimney.roughness = 0.88
	stone_chimney.normal_enabled = true
	stone_chimney.normal_texture = tex_stone_normal

	# A. North Village Settlement (Framing the Vista)
	for i in range(-5, 6):
		var hx: float = float(i) * 16.5 + randf_range(-1.8, 1.8)
		var hz: float = -46.0 - abs(float(i)) * 3.5 + randf_range(-1.8, 1.8)
		var hw: float = randf_range(9.0, 12.5)
		var hd: float = randf_range(7.5, 9.8)
		var hh: float = randf_range(4.6, 6.0)
		var r_mat = roof_terracotta if (abs(i) % 2 == 0) else roof_slate
		build_realistic_cottage(village_root, Vector3(hx, 0, hz), Vector3(hw, hh, hd), wall_plaster, wall_timber, foundation_stone, r_mat, stone_chimney)

	# B. South Village Farmsteads & Homesteads
	for i in range(-5, 6):
		if abs(i) <= 1:
			continue # Center spectator camera clearance
		var hx: float = float(i) * 17.5 + randf_range(-1.8, 1.8)
		var hz: float = 54.0 + abs(float(i)) * 4.0 + randf_range(-1.8, 1.8)
		var hw: float = randf_range(9.5, 13.0)
		var hd: float = randf_range(8.0, 10.2)
		var hh: float = randf_range(4.8, 6.5)
		var r_mat = roof_thatch if (abs(i) % 2 == 0) else roof_terracotta
		build_realistic_cottage(village_root, Vector3(hx, 0, hz), Vector3(hw, hh, hd), wall_plaster, wall_timber, foundation_stone, r_mat, stone_chimney)

	# C. Weathered Dark Barns on Flanks
	build_realistic_barn(village_root, Vector3(-58.0, 0, -22.0), roof_terracotta, foundation_stone)
	build_realistic_barn(village_root, Vector3(58.0, 0, 22.0), roof_slate, foundation_stone)

	# D. Animated Traditional Stone Windmills
	build_realistic_windmill(village_root, Vector3(42.0, 0, -48.0), foundation_stone, roof_slate)
	build_realistic_windmill(village_root, Vector3(-44.0, 0, -52.0), foundation_stone, roof_slate)

	# E. Distant Rolling Green Valleys & Mountain Ridges
	setup_rolling_hills(village_root)

# Detailed Realistic European Half-Timbered Cottage (Fachwerk Architecture)
func build_realistic_cottage(parent: Node3D, pos: Vector3, dims: Vector3, wall_mat: Material, timber_mat: Material, stone_mat: Material, roof_mat: Material, chimney_mat: Material) -> void:
	var house := Node3D.new()
	house.position = pos
	parent.add_child(house)

	# 1. Sturdy Fieldstone Foundation Skirting (Base Plinth)
	var base_h = 0.75
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(dims.x + 0.25, base_h, dims.z + 0.25)
	foundation.mesh = fm
	foundation.material_override = stone_mat
	foundation.position.y = base_h * 0.5
	house.add_child(foundation)

	# 2. Main Wall Body (Aged Plaster)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = dims
	body.mesh = bm
	body.material_override = wall_mat
	body.position.y = base_h + dims.y * 0.5
	house.add_child(body)

	# 3. Half-Timbered Dark Oak Corner Posts (Fachwerk Eckbalken)
	var post_w = 0.32
	var corner_xs = [-dims.x * 0.5, dims.x * 0.5]
	var corner_zs = [-dims.z * 0.5, dims.z * 0.5]
	for cx in corner_xs:
		for cz in corner_zs:
			var post := MeshInstance3D.new()
			var c_box := BoxMesh.new()
			c_box.size = Vector3(post_w, dims.y, post_w)
			post.mesh = c_box
			post.material_override = timber_mat
			post.position = Vector3(cx, base_h + dims.y * 0.5, cz)
			house.add_child(post)

	# 4. Horizontal Timber Tie-Beams (Horizontal Riegel)
	var tie := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(dims.x + 0.08, 0.26, dims.z + 0.08)
	tie.mesh = tm
	tie.material_override = timber_mat
	tie.position.y = base_h + dims.y * 0.55
	house.add_child(tie)

	# 5. Overhanging Eaves Roof (PrismMesh with overhang & dark fascia trim)
	var roof_h = dims.y * 0.72
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(dims.x + 1.4, roof_h, dims.z + 1.2)
	roof.mesh = rm
	roof.material_override = roof_mat
	roof.position.y = base_h + dims.y + roof_h * 0.5
	house.add_child(roof)

	# Dark Wooden Fascia Boards along Eaves
	var fascia := MeshInstance3D.new()
	var f_box := BoxMesh.new()
	f_box.size = Vector3(dims.x + 1.45, 0.18, dims.z + 1.25)
	fascia.mesh = f_box
	fascia.material_override = timber_mat
	fascia.position.y = base_h + dims.y + 0.09
	house.add_child(fascia)

	# 6. Recessed Wooden Plank Door on Front
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.3, 2.2, 0.15)
	door.mesh = dm
	door.material_override = timber_mat
	door.position = Vector3(0.0, base_h + 1.1, dims.z * 0.5 + 0.04)
	house.add_child(door)

	# 7. Multi-Pane Wooden Windows with Reflective Glass Panes
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.12, 0.16, 0.20)
	glass_mat.roughness = 0.15
	glass_mat.metallic = 0.85

	for wx in [-dims.x * 0.28, dims.x * 0.28]:
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(1.1, 1.2, 0.12)
		win.mesh = wm
		win.material_override = glass_mat
		win.position = Vector3(wx, base_h + dims.y * 0.55, dims.z * 0.5 + 0.04)
		house.add_child(win)

	# 8. Masonry Stone Chimney with Clay Pot
	var chimney := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.0, dims.y * 1.4, 1.0)
	chimney.mesh = cm
	chimney.material_override = chimney_mat
	chimney.position = Vector3(dims.x * 0.28, base_h + dims.y * 0.75 + 0.5, dims.z * 0.2)
	house.add_child(chimney)

	# Subtle Warm Interior Window Glow
	var window_light := OmniLight3D.new()
	window_light.light_color = Color(1.0, 0.82, 0.55)
	window_light.light_energy = 1.6
	window_light.omni_range = 8.0
	window_light.position = Vector3(0, base_h + 1.2, dims.z * 0.5 + 0.5)
	house.add_child(window_light)

# Weathered Rustic Rural Barn / Timber Storehouse
func build_realistic_barn(parent: Node3D, pos: Vector3, roof_mat: Material, stone_mat: Material) -> void:
	var barn := Node3D.new()
	barn.position = pos
	parent.add_child(barn)

	var barn_wood := StandardMaterial3D.new()
	barn_wood.albedo_color = Color("#3e271c") # Weathered dark barnwood
	barn_wood.roughness = 0.90
	barn_wood.normal_enabled = true
	barn_wood.normal_texture = tex_wood_normal
	barn_wood.uv1_scale = Vector3(1.0, 8.0, 1.0)

	var base_h = 0.8
	var b_base := MeshInstance3D.new()
	var b_bm := BoxMesh.new()
	b_bm.size = Vector3(16.4, base_h, 12.4)
	b_base.mesh = b_bm
	b_base.material_override = stone_mat
	b_base.position.y = base_h * 0.5
	barn.add_child(b_base)

	var b_body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(16.0, 7.2, 12.0)
	b_body.mesh = bm
	b_body.material_override = barn_wood
	b_body.position.y = base_h + 3.6
	barn.add_child(b_body)

	var b_roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(17.8, 4.8, 13.4)
	b_roof.mesh = rm
	b_roof.material_override = roof_mat
	b_roof.position.y = base_h + 7.2 + 2.4
	barn.add_child(b_roof)

	# Large Double Sliding Barn Doors with Cross 'X' Bracing
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color("#2a1a12") # Darker inner timber
	door_mat.roughness = 0.88

	var b_door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(4.5, 4.5, 0.2)
	b_door.mesh = dm
	b_door.material_override = door_mat
	b_door.position = Vector3(0, base_h + 2.25, 6.08)
	barn.add_child(b_door)

# Realistic Stone & Timber Windmill
func build_realistic_windmill(parent: Node3D, pos: Vector3, stone_mat: Material, roof_mat: Material) -> void:
	var mill_root := Node3D.new()
	mill_root.position = pos
	parent.add_child(mill_root)

	var timber_mat := StandardMaterial3D.new()
	timber_mat.albedo_color = Color("#38271a")
	timber_mat.roughness = 0.90
	timber_mat.normal_enabled = true
	timber_mat.normal_texture = tex_wood_normal

	var sail_mat := StandardMaterial3D.new()
	sail_mat.albedo_color = Color("#c5bbae") # Authentic unbleached natural flax linen canvas
	sail_mat.roughness = 0.85
	sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Tapered Masonry Stone Tower Base
	var tower := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 3.2
	tm.bottom_radius = 4.8
	tm.height = 14.0
	tower.mesh = tm
	tower.material_override = stone_mat
	tower.position.y = 7.0
	mill_root.add_child(tower)

	# Timber Cap
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.2
	cm.bottom_radius = 3.6
	cm.height = 4.5
	cap.mesh = cm
	cap.material_override = roof_mat
	cap.position.y = 16.25
	mill_root.add_child(cap)

	# Rotating Rotor Assembly
	var blades_hub := Node3D.new()
	blades_hub.position = Vector3(0, 15.5, 3.4)
	mill_root.add_child(blades_hub)
	rotating_windmill_blades.append(blades_hub)

	var hub := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.45
	hm.bottom_radius = 0.55
	hm.height = 0.8
	hub.mesh = hm
	hub.material_override = timber_mat
	hub.rotation_degrees.x = 90
	blades_hub.add_child(hub)

	# 4 Cross Sails
	for blade_idx in range(4):
		var blade_arm := Node3D.new()
		blade_arm.rotation_degrees.z = float(blade_idx) * 90.0
		blades_hub.add_child(blade_arm)

		var spar := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.18, 8.5, 0.18)
		spar.mesh = sm
		spar.material_override = timber_mat
		spar.position.y = 4.25
		blade_arm.add_child(spar)

		var sail := MeshInstance3D.new()
		var canvas := BoxMesh.new()
		canvas.size = Vector3(1.3, 6.5, 0.04)
		sail.mesh = canvas
		sail.material_override = sail_mat
		sail.position = Vector3(0.65, 5.0, 0.04)
		blade_arm.add_child(sail)

# Rolling Green Hills on Horizon with Atmospheric Depth
func setup_rolling_hills(parent: Node3D) -> void:
	var hill_mat := StandardMaterial3D.new()
	hill_mat.albedo_color = Color("#22361a") # Natural forest valley ridge
	hill_mat.roughness = 0.94
	hill_mat.normal_enabled = true
	hill_mat.normal_texture = tex_grass_normal

	var distant_hill_mat := StandardMaterial3D.new()
	distant_hill_mat.albedo_color = Color("#1d2c18")
	distant_hill_mat.roughness = 0.95

	var hill_positions = [
		Vector3(-95, 0, -85), Vector3(-45, 0, -100), Vector3(0, 0, -115), Vector3(50, 0, -105), Vector3(100, 0, -90),
		Vector3(-100, 0, 85), Vector3(-50, 0, 105), Vector3(0, 0, 115), Vector3(55, 0, 100), Vector3(95, 0, 88),
		Vector3(-115, 0, -45), Vector3(-120, 0, 0), Vector3(-115, 0, 45),
		Vector3(115, 0, -45), Vector3(120, 0, 0), Vector3(115, 0, 45)
	]
	for hp in hill_positions:
		var hill := MeshInstance3D.new()
		var hm := SphereMesh.new()
		var h_rad = randf_range(35.0, 55.0)
		hm.radius = h_rad
		hm.height = h_rad * 0.9
		hill.mesh = hm
		hill.material_override = hill_mat if randf() > 0.5 else distant_hill_mat
		hill.position = hp + Vector3(0, -h_rad * 0.45, 0)
		parent.add_child(hill)

# ==============================================================================
# 6. AUTHENTIC COUNTRYSIDE FLORA & FARM PROPS
# ==============================================================================
func setup_nature_and_farm_props() -> void:
	var props_root := Node3D.new()
	props_root.name = "RealisticProps"
	add_child(props_root)

	# Realistic Foliage Materials (Deep forest & olive greens, no neon!)
	var leaf_lush := StandardMaterial3D.new()
	leaf_lush.albedo_color = Color("#1e381b") # Deep European oak canopy
	leaf_lush.roughness = 0.85
	leaf_lush.normal_enabled = true
	leaf_lush.normal_texture = tex_grass_normal

	var leaf_deep := StandardMaterial3D.new()
	leaf_deep.albedo_color = Color("#26431f") # Rich woodland olive canopy
	leaf_deep.roughness = 0.88
	leaf_deep.normal_enabled = true
	leaf_deep.normal_texture = tex_grass_normal

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("#342316") # Natural rugged tree bark
	trunk_mat.roughness = 0.92
	trunk_mat.normal_enabled = true
	trunk_mat.normal_texture = tex_wood_normal
	trunk_mat.uv1_scale = Vector3(1.0, 5.0, 1.0)

	# A. Natural Layered Canopy Shade Trees
	for x in range(int(-ARENA_BOUND_X + 6.0), int(ARENA_BOUND_X - 4.0), 11):
		var tree_pos = Vector3(float(x) + randf_range(-1.4, 1.4), 0.1, -14.2 + randf_range(-0.5, 0.5))
		var canopy_mat = leaf_lush if randf() > 0.5 else leaf_deep
		build_realistic_tree(props_root, tree_pos, trunk_mat, canopy_mat)

	for x in range(int(-ARENA_BOUND_X + 8.0), int(ARENA_BOUND_X - 6.0), 12):
		var tree_pos = Vector3(float(x) + randf_range(-1.4, 1.4), 0.1, 14.5 + randf_range(-0.5, 0.5))
		var canopy_mat = leaf_deep if randf() > 0.5 else leaf_lush
		build_realistic_tree(props_root, tree_pos, trunk_mat, canopy_mat)

	# B. Wooden Farm Wagons
	build_farm_cart(props_root, Vector3(-24.0, 0.05, 8.5), 25.0)
	build_farm_cart(props_root, Vector3(25.0, 0.05, -8.5), -35.0)

	# C. Natural Weathered Straw Hay Bales
	var hay_mat := StandardMaterial3D.new()
	hay_mat.albedo_color = Color("#8d7442") # Natural dry amber straw
	hay_mat.roughness = 0.92

	var hay_coords = [
		Vector3(-28.0, 0.6, 9.5), Vector3(-26.5, 0.6, 10.2), Vector3(-27.2, 1.6, 9.8),
		Vector3(22.0, 0.6, -9.5), Vector3(23.5, 0.6, -10.2), Vector3(22.8, 1.6, -9.8),
		Vector3(-12.0, 0.6, -9.5), Vector3(14.0, 0.6, 9.5)
	]
	for hc in hay_coords:
		var bale := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.62
		bm.bottom_radius = 0.62
		bm.height = 1.35
		bale.mesh = bm
		bale.material_override = hay_mat
		bale.position = hc
		bale.rotation_degrees.z = 90
		bale.rotation_degrees.y = randf_range(0, 45)
		props_root.add_child(bale)

	# D. Traditional Stone Water Wells
	build_village_stone_well(props_root, Vector3(-12.0, 0.0, 8.5))
	build_village_stone_well(props_root, Vector3(12.0, 0.0, -8.5))

	# E. Scattered Firewood & Iron-Hooped Barrels
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#4a3523")
	wood_mat.roughness = 0.90
	wood_mat.normal_enabled = true
	wood_mat.normal_texture = tex_wood_normal

	var barrel_coords = [
		Vector3(-32.0, 0.5, 7.5), Vector3(-31.2, 0.5, 8.2),
		Vector3(32.0, 0.5, -7.5), Vector3(31.2, 0.5, -8.2),
		Vector3(-5.0, 0.5, 8.2), Vector3(5.0, 0.5, -8.2)
	]
	for bc in barrel_coords:
		var barrel := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.38
		bm.bottom_radius = 0.40
		bm.height = 0.95
		barrel.mesh = bm
		barrel.material_override = wood_mat
		barrel.position = bc
		props_root.add_child(barrel)

	# F. Subtle Wildflower Patches
	setup_wildflower_patches(props_root)

# Broad-Canopy Realistic Tree with Multi-Cluster Foliage Volumes
func build_realistic_tree(parent: Node3D, pos: Vector3, trunk_mat: Material, canopy_mat: Material) -> void:
	var tree := Node3D.new()
	tree.position = pos
	parent.add_child(tree)

	# Tree Trunk
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = randf_range(0.24, 0.34)
	tm.bottom_radius = tm.top_radius * 1.5
	tm.height = randf_range(4.8, 6.0)
	trunk.mesh = tm
	trunk.material_override = trunk_mat
	trunk.position.y = tm.height * 0.5
	tree.add_child(trunk)

	# Multi-Cluster Layered Organic Foliage
	var canopy_y = tm.height * 0.78
	var sphere_configs = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(-0.9, 0.8, 0.5),
		Vector3(0.8, 0.9, -0.6),
		Vector3(0.2, 1.8, 0.3)
	]
	for cfg in sphere_configs:
		var foliage := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var srad = randf_range(1.6, 2.1)
		sm.radius = srad
		sm.height = srad * 1.6
		foliage.mesh = sm
		foliage.material_override = canopy_mat
		foliage.position = Vector3(cfg.x, canopy_y + cfg.y, cfg.z)
		tree.add_child(foliage)

func build_farm_cart(parent: Node3D, pos: Vector3, rot_y: float) -> void:
	var cart := Node3D.new()
	cart.position = pos
	cart.rotation_degrees.y = rot_y
	parent.add_child(cart)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#4a3726")
	wood_mat.roughness = 0.90
	wood_mat.normal_enabled = true
	wood_mat.normal_texture = tex_wood_normal

	var hay_mat := StandardMaterial3D.new()
	hay_mat.albedo_color = Color("#8d7442")
	hay_mat.roughness = 0.92

	# Cart Bed
	var bed := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 0.65, 1.8)
	bed.mesh = bm
	bed.material_override = wood_mat
	bed.position.y = 0.90
	cart.add_child(bed)

	# Hay Load
	var hay := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 1.05
	hm.height = 1.3
	hay.mesh = hm
	hay.material_override = hay_mat
	hay.position.y = 1.35
	cart.add_child(hay)

	# Wheels
	for wx in [-1.2, 1.2]:
		for wz in [-1.0, 1.0]:
			var wheel := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.52
			wm.bottom_radius = 0.52
			wm.height = 0.14
			wheel.mesh = wm
			wheel.material_override = wood_mat
			wheel.position = Vector3(wx, 0.52, wz)
			wheel.rotation_degrees.x = 90
			cart.add_child(wheel)

func build_village_stone_well(parent: Node3D, pos: Vector3) -> void:
	var well := Node3D.new()
	well.position = pos
	parent.add_child(well)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color("#4a4744")
	stone_mat.roughness = 0.88
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = tex_stone_normal

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#38271a")
	wood_mat.roughness = 0.90

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color("#5c2e26")
	roof_mat.roughness = 0.75
	roof_mat.normal_enabled = true
	roof_mat.normal_texture = tex_roof_normal

	# Stone Basin
	var basin := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 1.05
	bm.bottom_radius = 1.15
	bm.height = 1.05
	basin.mesh = bm
	basin.material_override = stone_mat
	basin.position.y = 0.52
	well.add_child(basin)

	# Wooden Roof Posts
	for px in [-0.85, 0.85]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.08
		pm.bottom_radius = 0.08
		pm.height = 2.4
		post.mesh = pm
		post.material_override = wood_mat
		post.position = Vector3(px, 1.7, 0)
		well.add_child(post)

	# Canopy
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(2.4, 1.0, 2.1)
	roof.mesh = rm
	roof.material_override = roof_mat
	roof.position.y = 3.1
	well.add_child(roof)

# Subtle Natural Wildflowers (Muted poppies & heather)
func setup_wildflower_patches(parent: Node3D) -> void:
	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color("#8f2d24") # Natural wild poppy

	var yellow_mat := StandardMaterial3D.new()
	yellow_mat.albedo_color = Color("#b8902d") # Field mustard / dandelion

	var lavender_mat := StandardMaterial3D.new()
	lavender_mat.albedo_color = Color("#6d5885") # Wild lavender

	var mats = [red_mat, yellow_mat, lavender_mat]
	for i in range(20):
		var center_x = randf_range(-ARENA_BOUND_X + 4.0, ARENA_BOUND_X - 4.0)
		var center_z = randf_range(6.5, 13.0) if randf() > 0.5 else randf_range(-13.0, -6.5)
		var patch_mat = mats[i % mats.size()]

		for b in range(5):
			var flower := MeshInstance3D.new()
			var fm := SphereMesh.new()
			fm.radius = randf_range(0.10, 0.18)
			fm.height = fm.radius * 1.4
			flower.mesh = fm
			flower.material_override = patch_mat
			flower.position = Vector3(center_x + randf_range(-1.0, 1.0), 0.10, center_z + randf_range(-1.0, 1.0))
			parent.add_child(flower)

# ==============================================================================
# 7. NATURAL FLOATING PARTICLES (POLLEN & SUMMER BREEZE MOTES)
# ==============================================================================
func setup_pastoral_particles() -> void:
	var nature_motes := CPUParticles3D.new()
	nature_motes.amount = 60
	nature_motes.lifetime = 8.0
	nature_motes.preprocess = 5.0
	nature_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	nature_motes.emission_box_extents = Vector3(ARENA_BOUND_X, 8.0, ARENA_BOUND_Z)
	nature_motes.direction = Vector3(0.9, -0.15, 0.35).normalized()
	nature_motes.spread = 25.0
	nature_motes.initial_velocity_min = 0.3
	nature_motes.initial_velocity_max = 1.1
	nature_motes.gravity = Vector3(0, -0.012, 0)
	nature_motes.position = Vector3(0, 4.0, 0)

	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 0.04
	mote_mesh.height = 0.07
	mote_mesh.radial_segments = 6
	mote_mesh.rings = 3
	nature_motes.mesh = mote_mesh

	var mote_mat := StandardMaterial3D.new()
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.albedo_color = Color(0.95, 0.92, 0.82, 0.40) # Subtle natural seed fluff
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nature_motes.material_override = mote_mat
	add_child(nature_motes)
