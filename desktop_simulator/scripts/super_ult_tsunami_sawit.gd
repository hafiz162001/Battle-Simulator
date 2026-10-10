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
var crest_lip: Node3D = null
var wave_light: OmniLight3D = null

var wave_mesh_instances: Array[MeshInstance3D] = []

var spray_particles: CPUParticles3D = null
var foam_particles: CPUParticles3D = null
var mist_particles: CPUParticles3D = null

# Materials
var mat_water_deep: StandardMaterial3D
var mat_water_trans: StandardMaterial3D
var mat_water_crest: StandardMaterial3D
var mat_foam_white: StandardMaterial3D

func _ready() -> void:
	build_materials()
	build_pure_tsunami()

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
		
	if audio_mgr and audio_mgr.has_method("set_super_ult_active"):
		audio_mgr.set_super_ult_active(true)
		
	if audio_mgr:
		if audio_mgr.has_method("play_super_ult_b"):
			audio_mgr.play_super_ult_b()
		else:
			if audio_mgr.has_method("play_whirlwind"):
				audio_mgr.play_whirlwind()
			if audio_mgr.has_method("play_explosion"):
				audio_mgr.play_explosion(true)

# ==============================================================================
# 1. PBR MATERIALS WITH NOISE RIPPLES (MURNI AIR TSUNAMI, TANPA BULATAN)
# ==============================================================================
func build_materials() -> void:
	var water_noise := FastNoiseLite.new()
	water_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	water_noise.frequency = 0.06
	water_noise.fractal_octaves = 3
	
	var tex_water_norm := NoiseTexture2D.new()
	tex_water_norm.seamless = true
	tex_water_norm.as_normal_map = true
	tex_water_norm.bump_strength = 2.8
	tex_water_norm.noise = water_noise
	
	# Deep Ocean Water (Badai Tsunami)
	mat_water_deep = StandardMaterial3D.new()
	mat_water_deep.albedo_color = Color(0.03, 0.32, 0.55, 0.94)
	mat_water_deep.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water_deep.metallic = 0.2
	mat_water_deep.roughness = 0.06
	mat_water_deep.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_water_deep.normal_enabled = true
	mat_water_deep.normal_texture = tex_water_norm
	mat_water_deep.normal_scale = 1.8
	mat_water_deep.rim_enabled = true
	mat_water_deep.rim = 0.4
	mat_water_deep.rim_tint = 0.5
	
	# Translucent Breaking Wave Crest
	mat_water_trans = StandardMaterial3D.new()
	mat_water_trans.albedo_color = Color(0.15, 0.62, 0.82, 0.82)
	mat_water_trans.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water_trans.metallic = 0.12
	mat_water_trans.roughness = 0.04
	mat_water_trans.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_water_trans.normal_enabled = true
	mat_water_trans.normal_texture = tex_water_norm
	mat_water_trans.normal_scale = 2.2
	
	# High Velocity Crest Water
	mat_water_crest = StandardMaterial3D.new()
	mat_water_crest.albedo_color = Color(0.35, 0.78, 0.92, 0.88)
	mat_water_crest.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_water_crest.roughness = 0.08
	mat_water_crest.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_water_crest.normal_enabled = true
	mat_water_crest.normal_texture = tex_water_norm
	mat_water_crest.normal_scale = 1.5
	
	# Heavy Frothing White Hydraulic Foam
	mat_foam_white = StandardMaterial3D.new()
	mat_foam_white.albedo_color = Color(0.96, 0.98, 1.0, 0.96)
	mat_foam_white.roughness = 0.45
	mat_foam_white.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_foam_white.emission_enabled = true
	mat_foam_white.emission = Color(0.18, 0.24, 0.30)

# ==============================================================================
# 2. PURE TSUNAMI WAVE GEOMETRY (TANPA BUAH / TANPA BOLA SAWIT)
# ==============================================================================
func build_pure_tsunami() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	
	# Internal Caustic Water Sunlight Glow (Cyan-Aquamarine)
	wave_light = OmniLight3D.new()
	wave_light.name = "TsunamiCausticLight"
	wave_light.light_color = Color(0.3, 0.8, 1.0)
	wave_light.light_energy = 4.0
	wave_light.omni_range = 30.0
	wave_light.omni_attenuation = 1.1
	wave_light.position = Vector3(0.0, 5.0, 2.0)
	body_root.add_child(wave_light)
	
	build_water_tsunami_mesh()
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
	
	# 2.3 Overhanging Crashing Wave Barrel Lip (Curling Breaker)
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
	
	# 2.5 Sweeping Torrential Rapids / Hydraulic Wash Across Arena Ground (30m wide, 18m reach)
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

# ==============================================================================
# 3. VOLUMETRIC SPRAY, FOAM & MIST PARTICLES (TANPA BULATAN / SPHERE)
# Menggunakan QuadMesh billboard dan flat BoxMesh untuk efek percikan air asli
# ==============================================================================
func build_spray_and_foam_particles() -> void:
	# 3.1 Heavy Ocean Mist Cloud (Billboard Quads, kabut halus air laut)
	mist_particles = CPUParticles3D.new()
	mist_particles.amount = 40
	mist_particles.lifetime = 1.2
	mist_particles.direction = Vector3(0, 0.2, 1.0)
	mist_particles.spread = 55.0
	mist_particles.initial_velocity_min = 16.0
	mist_particles.initial_velocity_max = 26.0
	mist_particles.gravity = Vector3(0, -3.5, 0)
	
	var mist_mesh := QuadMesh.new()
	mist_mesh.size = Vector2(2.4, 2.4)
	mist_particles.mesh = mist_mesh
	
	var mat_mist := StandardMaterial3D.new()
	mat_mist.albedo_color = Color(0.85, 0.95, 1.0, 0.22)
	mat_mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_mist.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_mist.roughness = 0.9
	mist_particles.material_override = mat_mist
	mist_particles.position = Vector3(0, 5.0, 5.0)
	body_root.add_child(mist_particles)
	
	# 3.2 Crashing Ocean Wave Spray & Water Droplets (Flat Billboard Quads)
	spray_particles = CPUParticles3D.new()
	spray_particles.amount = 60
	spray_particles.lifetime = 0.8
	spray_particles.explosiveness = 0.25
	spray_particles.direction = Vector3(0, 0.45, 1.0)
	spray_particles.spread = 45.0
	spray_particles.initial_velocity_min = 15.0
	spray_particles.initial_velocity_max = 28.0
	spray_particles.gravity = Vector3(0, -9.8, 0)
	
	var spray_quad := QuadMesh.new()
	spray_quad.size = Vector2(0.65, 0.65)
	spray_particles.mesh = spray_quad
	
	var mat_spray := StandardMaterial3D.new()
	mat_spray.albedo_color = Color(0.7, 0.9, 1.0, 0.5)
	mat_spray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_spray.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat_spray.roughness = 0.2
	spray_particles.material_override = mat_spray
	spray_particles.position = Vector3(0, 6.8, 2.5)
	body_root.add_child(spray_particles)
	
	# 3.3 Ground Hydraulic Frothing Foam Rapids (Flat Box Mesh)
	foam_particles = CPUParticles3D.new()
	foam_particles.amount = 55
	foam_particles.lifetime = 0.75
	foam_particles.direction = Vector3(0, 0.25, 1.0)
	foam_particles.spread = 75.0
	foam_particles.initial_velocity_min = 10.0
	foam_particles.initial_velocity_max = 20.0
	foam_particles.gravity = Vector3(0, -5.0, 0)
	
	var foam_box := BoxMesh.new()
	foam_box.size = Vector3(0.7, 0.2, 0.7)
	foam_particles.mesh = foam_box
	foam_particles.material_override = mat_foam_white
	foam_particles.position = Vector3(0, 0.35, 12.0)
	body_root.add_child(foam_particles)

# ==============================================================================
# 4. REAL-TIME FLUID PROCESS & PHYSICS
# ==============================================================================
var wet_wake_timer: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	var step = speed * delta
	global_position += charge_dir * step
	travel_dist += step
	
	# Real-time Fluid Normal Map UV Scrolling (Turbulent Ocean Waves)
	if mat_water_deep:
		mat_water_deep.uv1_offset += Vector3(0.08, 1.6, 0.0) * delta
	if mat_water_trans:
		mat_water_trans.uv1_offset += Vector3(-0.06, 2.2, 0.0) * delta
	if mat_water_crest:
		mat_water_crest.uv1_offset += Vector3(0.12, 2.0, 0.0) * delta
		
	# Undulate Wave Crest Lip Dynamically (Realistic Breaking Wave Barrel)
	if crest_lip:
		crest_lip.position.y = 7.8 + sin(anim_time * 7.5) * 0.8
		crest_lip.position.z = 1.6 + cos(anim_time * 6.5) * 0.5
		crest_lip.rotation.x = sin(anim_time * 5.0) * 0.12
		
	# Continuous Heavy Camera Screen Rumble
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.25 * delta)
		
	# Check Ram Hits on Enemy Units
	check_ram_hits()
	
	# Water splash effect along arena floor
	wet_wake_timer += delta
	if wet_wake_timer >= 0.08:
		wet_wake_timer = 0.0
		spawn_ground_water_splash()
		
	if travel_dist >= max_travel:
		on_flood_complete()

# ==============================================================================
# 5. ENEMY COLLISION & WATER IMPACT
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
	var banner_title = "🌊 DISAPU TSUNAMI MAHADASYAT!"
	var banner_color = Color(0.2, 0.85, 1.0)
	
	var r = randf()
	if r < 0.4:
		banner_title = "🌊 TERGULUNG OMBAK RAKSASA!"
		banner_color = Color(0.25, 0.9, 1.0)
	elif is_fatal:
		banner_title = "💥 DROWNED IN HIGH-PRESSURE TSUNAMI!"
		banner_color = Color(0.35, 1.0, 0.95)
		
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = target.global_position + Vector3(0, 2.6 * target.unit_scale, 0)
	dmg_label.setup_banner(banner_title, banner_color)
	
	target.take_damage(damage, global_position)
	
	# Massive hit sparks and water splash burst
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
	if audio_mgr and audio_mgr.has_method("set_super_ult_active"):
		audio_mgr.set_super_ult_active(false)
	queue_free()
