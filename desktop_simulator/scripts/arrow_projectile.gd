class_name ArrowProjectile
extends Node3D

const HitSparksClass = preload("res://scripts/hit_sparks.gd")
const DamageNumberClass = preload("res://scripts/damage_number.gd")

var velocity: Vector3 = Vector3.ZERO
var damage: float = 45.0
var shooter_team: int = 0
var is_stuck: bool = false
var lifetime: float = 7.0
var age: float = 0.0

var shaft_mesh: MeshInstance3D
var fletch_mesh: MeshInstance3D
var head_mesh: MeshInstance3D

func _ready() -> void:
	build_arrow_mesh()

func build_arrow_mesh() -> void:
	# Wooden shaft
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.02
	shaft.bottom_radius = 0.02
	shaft.height = 0.85
	
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#78350f")
	wood_mat.roughness = 0.7
	
	shaft_mesh = MeshInstance3D.new()
	shaft_mesh.mesh = shaft
	shaft_mesh.material_override = wood_mat
	shaft_mesh.rotation_degrees.x = 90
	add_child(shaft_mesh)
	
	# Metal arrowhead
	var head := CylinderMesh.new()
	head.top_radius = 0.0
	head.bottom_radius = 0.05
	head.height = 0.15
	
	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color("#e2e8f0")
	metal_mat.metallic = 0.95
	metal_mat.roughness = 0.2
	
	head_mesh = MeshInstance3D.new()
	head_mesh.mesh = head
	head_mesh.material_override = metal_mat
	head_mesh.position.z = -0.45
	head_mesh.rotation_degrees.x = -90
	add_child(head_mesh)
	
	# Feather fletching (colored by team)
	var fletch := BoxMesh.new()
	fletch.size = Vector3(0.12, 0.01, 0.18)
	
	var fletch_mat := StandardMaterial3D.new()
	fletch_mat.albedo_color = Color("#f59e0b") if shooter_team == 0 else Color("#38bdf8")
	
	fletch_mesh = MeshInstance3D.new()
	fletch_mesh.mesh = fletch
	fletch_mesh.material_override = fletch_mat
	fletch_mesh.position.z = 0.35
	add_child(fletch_mesh)

func launch(start_pos: Vector3, target_pos: Vector3, p_team: int, p_damage: float) -> void:
	global_position = start_pos
	shooter_team = p_team
	damage = p_damage
	
	var to_target = target_pos - start_pos
	var dist_xz = Vector2(to_target.x, to_target.z).length()
	var travel_time = clamp(dist_xz / 32.0, 0.4, 1.4)
	
	# Calculate parabolic arc velocity
	var vy = (to_target.y + 0.5 * 11.0 * travel_time * travel_time) / travel_time
	var v_xz = Vector2(to_target.x, to_target.z) / travel_time
	velocity = Vector3(v_xz.x, vy, v_xz.y)
	
	if velocity.length_squared() > 0.01:
		look_at(global_position + velocity, Vector3.UP)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
		
	if is_stuck:
		return
		
	# Apply ballistic gravity
	velocity.y -= 11.0 * delta
	var prev_pos = global_position
	global_position += velocity * delta
	
	if velocity.length_squared() > 0.1:
		look_at(global_position + velocity, Vector3.UP)
		
	# Check collision with ground
	if global_position.y <= 0.05:
		global_position.y = 0.05
		is_stuck = true
		velocity = Vector3.ZERO
		return
		
	# Check collision with opposing units only when close to soldier height level
	if global_position.y > 3.5:
		return
		
	var tree = get_tree()
	if not tree:
		return
	var opp_team = 1 if shooter_team == 0 else 0
	var units = tree.get_nodes_in_group("units")
	
	for u in units:
		if is_instance_valid(u) and not u.is_dead and u.team == opp_team:
			var u_center = u.global_position + Vector3(0, 1.0 * u.unit_scale, 0)
			var hit_radius = 0.85 * u.unit_scale
			if global_position.distance_squared_to(u_center) <= hit_radius * hit_radius:
				hit_unit(u)
				break

func hit_unit(target: Node) -> void:
	is_stuck = true
	target.take_damage(damage, global_position - velocity.normalized())
	
	# Attach arrow to target
	var old_pos = global_position
	var old_rot = global_rotation
	if get_parent():
		get_parent().remove_child(self)
	target.add_child(self)
	global_position = old_pos
	global_rotation = old_rot
	
	# Spawn impact sparks
	var sparks := HitSparksClass.new()
	target.get_parent().add_child(sparks)
	sparks.trigger(global_position, false)
