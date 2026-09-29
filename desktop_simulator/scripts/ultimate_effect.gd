class_name UltimateEffect
extends Node3D

enum EffectType { SHOCKWAVE, EMP, WHIRLWIND, STOMP, AIRSTRIKE }

var effect_type: EffectType = EffectType.SHOCKWAVE
var lifetime: float = 1.0
var timer: float = 0.0
var max_radius: float = 5.0
var ring_mesh: MeshInstance3D = null
var sphere_mesh: MeshInstance3D = null
var dust_particles: Array = []
var primary_color: Color = Color(1.0, 0.7, 0.1)

func setup(p_type: EffectType, p_pos: Vector3, p_color: Color, p_radius: float = 5.0, p_duration: float = 0.8) -> void:
	effect_type = p_type
	global_position = p_pos
	primary_color = p_color
	max_radius = p_radius
	lifetime = p_duration
	build_visuals()

func build_visuals() -> void:
	match effect_type:
		EffectType.SHOCKWAVE, EffectType.STOMP:
			# Expanding glowing ground ring
			var torus := TorusMesh.new()
			torus.inner_radius = 0.85
			torus.outer_radius = 1.0
			torus.rings = 24
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
			
		EffectType.EMP:
			# Expanding electric hemisphere / sphere
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			sphere.radial_segments = 24
			sphere.rings = 16
			
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(0.2, 0.7, 1.0, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			
			sphere_mesh = MeshInstance3D.new()
			sphere_mesh.mesh = sphere
			sphere_mesh.material_override = mat
			sphere_mesh.position.y = 0.8
			add_child(sphere_mesh)
			
			# Also an outer ring
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
			
		EffectType.WHIRLWIND:
			# Glowing rotating blade rings
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
			
		EffectType.AIRSTRIKE:
			# Explosion fireball sphere & ground shockwave
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1.0, 0.45, 0.05, 0.85)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			
			sphere_mesh = MeshInstance3D.new()
			sphere_mesh.mesh = sphere
			sphere_mesh.material_override = mat
			sphere_mesh.position.y = 0.5
			add_child(sphere_mesh)

func _process(delta: float) -> void:
	timer += delta
	var progress = clamp(timer / lifetime, 0.0, 1.0)
	var ease_out = 1.0 - pow(1.0 - progress, 3.0)
	
	match effect_type:
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
					smat.albedo_color = Color(0.2, 0.7, 1.0, (1.0 - progress) * 0.45)
			if ring_mesh:
				var cur_r = lerp(0.5, max_radius * 1.15, ease_out)
				ring_mesh.scale = Vector3(cur_r, 1.0, cur_r)
				var rmat: StandardMaterial3D = ring_mesh.material_override
				if rmat:
					rmat.albedo_color = Color(0.5, 0.9, 1.0, (1.0 - progress) * 0.9)
					
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
					
		EffectType.AIRSTRIKE:
			if sphere_mesh:
				var cur_r = lerp(0.2, max_radius, ease_out)
				sphere_mesh.scale = Vector3(cur_r, cur_r * 1.4, cur_r)
				var mat: StandardMaterial3D = sphere_mesh.material_override
				if mat:
					var c = Color(1.0, 0.4 - progress * 0.3, 0.05, (1.0 - progress) * 0.9)
					mat.albedo_color = c
					
	if timer >= lifetime:
		queue_free()
