class_name UltimateEffect
extends Node3D

enum EffectType { SHOCKWAVE, EMP, WHIRLWIND, STOMP, AIRSTRIKE }

var effect_type: EffectType = EffectType.SHOCKWAVE
var lifetime: float = 1.0
var timer: float = 0.0
var max_radius: float = 5.0
var primary_color: Color = Color(1.0, 0.7, 0.1)

# Visual nodes
var ring_mesh: MeshInstance3D = null
var sphere_mesh: MeshInstance3D = null
var fireball_lobes: Array[MeshInstance3D] = []
var fireball_offsets: Array[Vector3] = []
var fireball_scales: Array[float] = []
var core_flash_mesh: MeshInstance3D = null
var blast_light: OmniLight3D = null
var scorch_mark: MeshInstance3D = null

# Particle nodes
var sparks_particles: CPUParticles3D = null
var smoke_particles: CPUParticles3D = null
var debris_particles: CPUParticles3D = null
var ground_dust_particles: CPUParticles3D = null

func setup(p_type: EffectType, p_pos: Vector3, p_color: Color, p_radius: float = 5.0, p_duration: float = 0.8) -> void:
	effect_type = p_type
	global_position = p_pos
	primary_color = p_color
	max_radius = p_radius
	lifetime = p_duration
	
	# Trigger cinematic camera shake based on blast severity
	trigger_camera_shake()
	build_visuals()

func trigger_camera_shake() -> void:
	var viewport = get_viewport()
	if not viewport:
		return
	var cam = viewport.get_camera_3d()
	if not cam:
		var tree = get_tree()
		if tree and tree.root:
			cam = tree.root.find_child("Camera3D", true, false)
			
	if cam and cam.has_method("add_shake"):
		match effect_type:
			EffectType.AIRSTRIKE:
				cam.add_shake(1.35)
			EffectType.STOMP:
				cam.add_shake(1.8)
			EffectType.SHOCKWAVE:
				cam.add_shake(0.85)
			EffectType.EMP:
				cam.add_shake(0.7)
			_:
				cam.add_shake(0.4)

func build_visuals() -> void:
	match effect_type:
		EffectType.AIRSTRIKE:
			build_realistic_explosion()
			
		EffectType.SHOCKWAVE, EffectType.STOMP:
			build_shockwave_or_stomp()
			
		EffectType.EMP:
			build_emp_explosion()
			
		EffectType.WHIRLWIND:
			build_whirlwind()

# ==============================================================================
# 1. REALISTIC AAA CINEMATIC EXPLOSION (AIRSTRIKE / ARTILLERY)
# ==============================================================================
func build_realistic_explosion() -> void:
	lifetime = max(lifetime, 1.4) # Ample time for smoke dissipation
	
	# 1.1 Blinding Blast Flash Light
	blast_light = OmniLight3D.new()
	blast_light.light_color = Color(1.0, 0.88, 0.55)
	blast_light.light_energy = 16.0
	blast_light.omni_range = max_radius * 4.8
	blast_light.position = Vector3(0, 1.8, 0)
	add_child(blast_light)
	
	# 1.2 White-Hot Core Flash Sphere (First ~0.1s instant incandescence)
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 1.2
	core_sphere.height = 2.4
	core_sphere.radial_segments = 16
	core_sphere.rings = 10
	
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = Color(2.0, 1.9, 1.4, 1.0) # HDR intense white-yellow
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	core_flash_mesh = MeshInstance3D.new()
	core_flash_mesh.mesh = core_sphere
	core_flash_mesh.material_override = core_mat
	core_flash_mesh.position.y = 1.2
	add_child(core_flash_mesh)
	
	# 1.3 Turbulent Multi-Lobe Fireball Cluster (Natural asymmetric billows)
	var lobe_configs = [
		Vector3(0.0, 1.0, 0.0),       # Central main lobe
		Vector3(0.0, 2.2, 0.0),       # High chimney plume
		Vector3(0.9, 1.3, 0.6),       # Front-right burst
		Vector3(-0.8, 1.4, -0.5),     # Back-left burst
		Vector3(-0.6, 1.1, 0.8),      # Front-left burst
		Vector3(0.7, 1.2, -0.7)       # Back-right burst
	]
	var lobe_sizes = [1.2, 0.95, 0.85, 0.85, 0.8, 0.8]
	
	for i in range(lobe_configs.size()):
		var lobe_mesh := SphereMesh.new()
		lobe_mesh.radius = 1.0
		lobe_mesh.height = 2.0
		lobe_mesh.radial_segments = 14
		lobe_mesh.rings = 8
		
		var lobe_mat := StandardMaterial3D.new()
		lobe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lobe_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lobe_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		lobe_mat.albedo_color = Color(1.0, 0.65, 0.1, 0.95)
		
		var mi := MeshInstance3D.new()
		mi.mesh = lobe_mesh
		mi.material_override = lobe_mat
		mi.position = lobe_configs[i]
		add_child(mi)
		
		fireball_lobes.append(mi)
		fireball_offsets.append(lobe_configs[i])
		fireball_scales.append(lobe_sizes[i])
		
	# 1.4 Supersonic Ground Shockwave Ring
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 8
	
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	ring_mesh = MeshInstance3D.new()
	ring_mesh.mesh = torus
	ring_mesh.material_override = rmat
	ring_mesh.position.y = 0.08
	add_child(ring_mesh)
	
	# 1.5 Fiery Shrapnel & Glowing Embers (CPU Particles)
	sparks_particles = CPUParticles3D.new()
	sparks_particles.emitting = true
	sparks_particles.one_shot = true
	sparks_particles.explosiveness = 0.98
	sparks_particles.lifetime = 0.85
	sparks_particles.amount = 45
	sparks_particles.direction = Vector3(0, 1.2, 0)
	sparks_particles.spread = 85.0
	sparks_particles.initial_velocity_min = 15.0
	sparks_particles.initial_velocity_max = 28.0
	sparks_particles.gravity = Vector3(0, -19.6, 0)
	sparks_particles.damping_min = 2.0
	sparks_particles.damping_max = 5.0
	
	var spark_box := BoxMesh.new()
	spark_box.size = Vector3(0.09, 0.09, 0.18)
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(1.0, 0.82, 0.25)
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sparks_particles.mesh = spark_box
	sparks_particles.material_override = spark_mat
	sparks_particles.position.y = 0.5
	add_child(sparks_particles)
	
	# 1.6 Flying Dirt Clods & Rock Fragments (CPU Particles)
	debris_particles = CPUParticles3D.new()
	debris_particles.emitting = true
	debris_particles.one_shot = true
	debris_particles.explosiveness = 0.95
	debris_particles.lifetime = 0.95
	debris_particles.amount = 26
	debris_particles.direction = Vector3(0, 1.4, 0)
	debris_particles.spread = 60.0
	debris_particles.initial_velocity_min = 9.0
	debris_particles.initial_velocity_max = 18.0
	debris_particles.gravity = Vector3(0, -22.0, 0)
	
	var debris_box := BoxMesh.new()
	debris_box.size = Vector3(0.18, 0.16, 0.18)
	var debris_mat := StandardMaterial3D.new()
	debris_mat.roughness = 0.9
	debris_mat.albedo_color = Color("#291d15") # Dark scorched earth
	debris_particles.mesh = debris_box
	debris_particles.material_override = debris_mat
	debris_particles.position.y = 0.3
	add_child(debris_particles)
	
	# 1.7 Thick Billowing Smoke Column (CPU Particles)
	smoke_particles = CPUParticles3D.new()
	smoke_particles.emitting = true
	smoke_particles.one_shot = true
	smoke_particles.explosiveness = 0.85
	smoke_particles.lifetime = 1.35
	smoke_particles.amount = 32
	smoke_particles.direction = Vector3(0, 1.0, 0)
	smoke_particles.spread = 45.0
	smoke_particles.initial_velocity_min = 3.5
	smoke_particles.initial_velocity_max = 7.5
	smoke_particles.gravity = Vector3(0, 2.2, 0) # Buoyant rising hot smoke
	smoke_particles.damping_min = 4.0
	smoke_particles.damping_max = 7.0
	
	var smoke_sphere := SphereMesh.new()
	smoke_sphere.radius = 0.65
	smoke_sphere.height = 1.3
	smoke_sphere.radial_segments = 10
	smoke_sphere.rings = 6
	
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	smoke_mat.albedo_color = Color(0.15, 0.14, 0.13, 0.82)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.roughness = 0.95
	smoke_particles.mesh = smoke_sphere
	smoke_particles.material_override = smoke_mat
	smoke_particles.position.y = 0.6
	add_child(smoke_particles)
	
	# 1.8 Radial Ground Dust Shockwave Skirt
	ground_dust_particles = CPUParticles3D.new()
	ground_dust_particles.emitting = true
	ground_dust_particles.one_shot = true
	ground_dust_particles.explosiveness = 0.94
	ground_dust_particles.lifetime = 0.8
	ground_dust_particles.amount = 28
	ground_dust_particles.direction = Vector3(0, 0.1, 0)
	ground_dust_particles.spread = 90.0
	ground_dust_particles.initial_velocity_min = 7.0
	ground_dust_particles.initial_velocity_max = 14.0
	ground_dust_particles.gravity = Vector3(0, -3.0, 0)
	ground_dust_particles.damping_min = 5.0
	ground_dust_particles.damping_max = 9.0
	
	var dust_sphere := SphereMesh.new()
	dust_sphere.radius = 0.45
	dust_sphere.height = 0.9
	dust_sphere.radial_segments = 8
	dust_sphere.rings = 5
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.68, 0.58, 0.45, 0.6) # Desert sand/dust
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_dust_particles.mesh = dust_sphere
	ground_dust_particles.material_override = dust_mat
	ground_dust_particles.position.y = 0.15
	add_child(ground_dust_particles)
	
	# 1.9 Persistent Charred Crater Decal on Ground
	spawn_ground_scorch_crater()

func spawn_ground_scorch_crater() -> void:
	var crater_disk := CylinderMesh.new()
	crater_disk.top_radius = max_radius * 0.72
	crater_disk.bottom_radius = max_radius * 0.72
	crater_disk.height = 0.012
	
	var scorch_mat := StandardMaterial3D.new()
	scorch_mat.albedo_color = Color(0.08, 0.06, 0.05, 0.85) # Jet black charred crater
	scorch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch_mat.roughness = 0.98
	
	scorch_mark = MeshInstance3D.new()
	scorch_mark.mesh = crater_disk
	scorch_mark.material_override = scorch_mat
	scorch_mark.position.y = 0.015
	add_child(scorch_mark)
	
	# Detach scorch mark when effect finishes so crater stays for 8 seconds
	var tree = get_tree()
	if tree:
		tree.create_timer(lifetime).timeout.connect(detach_scorch_to_world)

func detach_scorch_to_world() -> void:
	if not is_instance_valid(scorch_mark):
		return
	var parent_world = get_parent()
	if parent_world:
		var scorch_global = scorch_mark.global_position
		remove_child(scorch_mark)
		parent_world.add_child(scorch_mark)
		scorch_mark.global_position = scorch_global
		
		# Slowly fade out scorched earth over 7 seconds
		var t = get_tree()
		if t:
			var tween = t.create_tween()
			var smat = scorch_mark.material_override
			if tween and smat:
				tween.tween_property(smat, "albedo_color:a", 0.0, 7.0)
				tween.tween_callback(scorch_mark.queue_free)

# ==============================================================================
# 2. SHOCKWAVE & TITAN STOMP
# ==============================================================================
func build_shockwave_or_stomp() -> void:
	# Expanding glowing ground ring
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 28
	torus.ring_segments = 12
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = primary_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	ring_mesh = MeshInstance3D.new()
	ring_mesh.mesh = torus
	ring_mesh.material_override = mat
	ring_mesh.position.y = 0.08
	add_child(ring_mesh)
	
	# Ground impact dust wave
	ground_dust_particles = CPUParticles3D.new()
	ground_dust_particles.emitting = true
	ground_dust_particles.one_shot = true
	ground_dust_particles.explosiveness = 0.92
	ground_dust_particles.lifetime = 0.65
	ground_dust_particles.amount = 24
	ground_dust_particles.direction = Vector3(0, 0.2, 0)
	ground_dust_particles.spread = 90.0
	ground_dust_particles.initial_velocity_min = 6.0
	ground_dust_particles.initial_velocity_max = 13.0
	ground_dust_particles.damping_min = 4.0
	ground_dust_particles.damping_max = 8.0
	
	var dust_sphere := SphereMesh.new()
	dust_sphere.radius = 0.35
	dust_sphere.height = 0.7
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.72, 0.62, 0.48, 0.5)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_dust_particles.mesh = dust_sphere
	ground_dust_particles.material_override = dust_mat
	ground_dust_particles.position.y = 0.1
	add_child(ground_dust_particles)

# ==============================================================================
# 3. CYBORG EMP DETONATION
# ==============================================================================
func build_emp_explosion() -> void:
	# Electric shock sphere
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 16
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.75, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	sphere_mesh = MeshInstance3D.new()
	sphere_mesh.mesh = sphere
	sphere_mesh.material_override = mat
	sphere_mesh.position.y = 0.8
	add_child(sphere_mesh)
	
	# Outer cyan ring
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	var rmat := mat.duplicate()
	rmat.albedo_color = Color(0.4, 0.9, 1.0, 0.9)
	ring_mesh = MeshInstance3D.new()
	ring_mesh.mesh = torus
	ring_mesh.material_override = rmat
	ring_mesh.position.y = 0.1
	add_child(ring_mesh)
	
	# Electric spark discharge particles
	sparks_particles = CPUParticles3D.new()
	sparks_particles.emitting = true
	sparks_particles.one_shot = true
	sparks_particles.explosiveness = 0.95
	sparks_particles.lifetime = 0.6
	sparks_particles.amount = 30
	sparks_particles.direction = Vector3(0, 1, 0)
	sparks_particles.spread = 80.0
	sparks_particles.initial_velocity_min = 8.0
	sparks_particles.initial_velocity_max = 18.0
	sparks_particles.gravity = Vector3(0, -6.0, 0)
	
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.08, 0.08, 0.16)
	var emat := StandardMaterial3D.new()
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emat.albedo_color = Color(0.3, 0.95, 1.0)
	emat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sparks_particles.mesh = p_box
	sparks_particles.material_override = emat
	add_child(sparks_particles)

# ==============================================================================
# 4. SWORDSMAN WHIRLWIND
# ==============================================================================
func build_whirlwind() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 1.8
	torus.outer_radius = 2.1
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = primary_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	ring_mesh = MeshInstance3D.new()
	ring_mesh.mesh = torus
	ring_mesh.material_override = mat
	ring_mesh.position.y = 1.2
	add_child(ring_mesh)

# ==============================================================================
# PROCESS UPDATER & DYNAMIC TIMELINE
# ==============================================================================
func _process(delta: float) -> void:
	timer += delta
	var progress = clamp(timer / lifetime, 0.0, 1.0)
	var ease_out = 1.0 - pow(1.0 - progress, 3.0)
	var fast_ease = 1.0 - pow(1.0 - progress, 4.0)
	
	match effect_type:
		EffectType.AIRSTRIKE:
			update_realistic_explosion(progress, ease_out, fast_ease)
			
		EffectType.SHOCKWAVE, EffectType.STOMP:
			if ring_mesh:
				var cur_r = lerp(0.5, max_radius, ease_out)
				ring_mesh.scale = Vector3(cur_r, 1.0, cur_r)
				var mat: StandardMaterial3D = ring_mesh.material_override
				if mat:
					var c = primary_color
					c.a = (1.0 - progress) * 0.95
					mat.albedo_color = c
					
		EffectType.EMP:
			if sphere_mesh:
				var cur_r = lerp(0.5, max_radius, ease_out)
				sphere_mesh.scale = Vector3(cur_r, cur_r * 0.7, cur_r)
				var smat: StandardMaterial3D = sphere_mesh.material_override
				if smat:
					smat.albedo_color = Color(0.2, 0.75, 1.0, (1.0 - progress) * 0.55)
			if ring_mesh:
				var cur_r = lerp(0.5, max_radius * 1.15, ease_out)
				ring_mesh.scale = Vector3(cur_r, 1.0, cur_r)
				var rmat: StandardMaterial3D = ring_mesh.material_override
				if rmat:
					rmat.albedo_color = Color(0.4, 0.9, 1.0, (1.0 - progress) * 0.9)
					
		EffectType.WHIRLWIND:
			if ring_mesh:
				ring_mesh.rotation.y += delta * 18.0
				var scale_factor = sin(progress * PI) * 1.2
				ring_mesh.scale = Vector3(scale_factor, 1.0, scale_factor)
				var mat: StandardMaterial3D = ring_mesh.material_override
				if mat:
					var c = primary_color
					c.a = (1.0 - progress)
					mat.albedo_color = c
					
	if timer >= lifetime:
		queue_free()

func update_realistic_explosion(progress: float, ease_out: float, fast_ease: float) -> void:
	# 1. Decay Blast Flash Light
	if blast_light:
		blast_light.light_energy = max(0.0, 16.0 * exp(-progress * 10.0))
		if progress > 0.35:
			blast_light.visible = false
			
	# 2. Flash Core (Extremely rapid 0.08s flash)
	if core_flash_mesh:
		if progress < 0.12:
			var cp = progress / 0.12
			var core_scale = lerp(0.5, max_radius * 0.8, sin(cp * PI * 0.5))
			core_flash_mesh.scale = Vector3(core_scale, core_scale * 1.1, core_scale)
			var cmat: StandardMaterial3D = core_flash_mesh.material_override
			if cmat:
				cmat.albedo_color.a = 1.0 - cp
		else:
			core_flash_mesh.visible = false
			
	# 3. Expanding & Rising Multi-Lobe Fireball Cluster
	for i in range(fireball_lobes.size()):
		var lobe = fireball_lobes[i]
		if not is_instance_valid(lobe):
			continue
			
		var base_offset = fireball_offsets[i]
		var size_mult = fireball_scales[i]
		
		# Thermal buoyancy: fireball billows upwards into mushroom shape
		var rise_y = base_offset.y + progress * 2.8 * (1.2 if i == 1 else 0.8)
		lobe.position.y = rise_y
		lobe.position.x = base_offset.x * (1.0 + progress * 0.8)
		lobe.position.z = base_offset.z * (1.0 + progress * 0.8)
		
		# Scale expands aggressively then contracts as fuel is consumed
		var cur_r: float
		if progress < 0.28:
			cur_r = lerp(0.3, max_radius * 0.85 * size_mult, progress / 0.28)
		else:
			cur_r = lerp(max_radius * 0.85 * size_mult, max_radius * 1.05 * size_mult, (progress - 0.28) / 0.72)
		lobe.scale = Vector3(cur_r, cur_r * 1.1, cur_r)
		
		# Color transformation: White-Hot -> Fire Flame -> Deep Crimson -> Black Smoke
		var lmat: StandardMaterial3D = lobe.material_override
		if lmat:
			var col: Color
			if progress < 0.22:
				col = Color(1.0, 0.85 - progress * 1.2, 0.15, 0.95)
			elif progress < 0.52:
				var t = (progress - 0.22) / 0.30
				col = Color(lerp(1.0, 0.65, t), lerp(0.58, 0.15, t), 0.05, lerp(0.95, 0.75, t))
			else:
				var t = (progress - 0.52) / 0.48
				# Transition into billowing smoke
				col = Color(lerp(0.65, 0.12, t), lerp(0.15, 0.11, t), lerp(0.05, 0.10, t), (1.0 - t) * 0.75)
				lmat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			lmat.albedo_color = col
			
	# 4. Supersonic Ground Shockwave Ring
	if ring_mesh:
		var cur_r = lerp(0.6, max_radius * 1.75, fast_ease)
		ring_mesh.scale = Vector3(cur_r, 1.0, cur_r)
		var rmat: StandardMaterial3D = ring_mesh.material_override
		if rmat:
			var alpha = max(0.0, (1.0 - progress * 1.8) * 0.9)
			rmat.albedo_color = Color(1.0, 0.65, 0.2, alpha)
			if progress >= 0.55:
				ring_mesh.visible = false
