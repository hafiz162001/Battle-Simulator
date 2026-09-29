class_name HitSparks
extends CPUParticles3D

func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 0.95
	lifetime = 0.4
	amount = 14
	lifetime_randomness = 0.3
	
	# Direction and spread
	direction = Vector3(0, 1, 0)
	spread = 75.0
	initial_velocity_min = 3.0
	initial_velocity_max = 6.5
	gravity = Vector3(0, -9.8, 0)
	damping_min = 2.0
	damping_max = 5.0
	
	# Mesh and glowing spark material
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.08, 0.08, 0.08)
	mesh = p_mesh
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	material_override = mat

func trigger(pos: Vector3, is_crit: bool = false) -> void:
	global_position = pos
	if is_crit:
		amount = 24
		initial_velocity_max = 9.0
		if material_override:
			material_override.albedo_color = Color(1.0, 0.25, 0.1)
	emitting = true
	await get_tree().create_timer(0.6).timeout
	queue_free()
