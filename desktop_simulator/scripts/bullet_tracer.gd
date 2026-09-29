class_name BulletTracer
extends Node3D

const HitSparksClass = preload("res://scripts/hit_sparks.gd")

var start_pos: Vector3
var target_pos: Vector3
var speed: float = 110.0
var damage: float = 18.0
var team: int = 0
var target_unit: Node = null
var current_pos: Vector3
var direction: Vector3
var total_dist: float = 0.0
var traveled: float = 0.0

var mesh_inst: MeshInstance3D

func _ready() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.75)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.88, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.2)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	add_child(mesh_inst)

func fire(from: Vector3, to: Vector3, p_team: int, p_damage: float, p_target: Node = null) -> void:
	start_pos = from
	target_pos = to
	current_pos = from
	global_position = from
	team = p_team
	damage = p_damage
	target_unit = p_target
	
	direction = (to - from)
	total_dist = direction.length()
	if total_dist > 0.01:
		direction = direction.normalized()
		look_at(global_position + direction, Vector3.UP)

func _process(delta: float) -> void:
	var step = speed * delta
	traveled += step
	current_pos += direction * step
	global_position = current_pos
	
	if traveled >= total_dist:
		if is_instance_valid(target_unit) and not target_unit.is_dead:
			target_unit.take_damage(damage, start_pos)
		
		var parent = get_parent()
		if parent:
			var sparks := HitSparksClass.new()
			parent.add_child(sparks)
			sparks.trigger(target_pos, false)
		
		queue_free()
