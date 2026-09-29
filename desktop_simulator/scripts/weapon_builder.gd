class_name WeaponBuilder
extends RefCounted

static func attach_weapon(unit_root: Node3D, weapon_type: String, team: int, unit_scale: float) -> Node3D:
	var weapon_container := Node3D.new()
	weapon_container.name = "WeaponRig"
	unit_root.add_child(weapon_container)
	
	match weapon_type:
		"bow":
			build_bow_and_quiver(weapon_container, team, unit_scale)
		"sword_shield":
			build_sword_and_shield(weapon_container, team, unit_scale)
		"spear":
			build_spear(weapon_container, team, unit_scale)
		"rifle":
			build_rifle(weapon_container, team, unit_scale)
			
	return weapon_container

static func build_bow_and_quiver(parent: Node3D, team: int, s: float) -> void:
	var bow_mat := StandardMaterial3D.new()
	bow_mat.albedo_color = Color("#593110")
	bow_mat.roughness = 0.6
	
	# Curved bow body
	var bow_mesh := TorusMesh.new()
	bow_mesh.inner_radius = 0.55 * s
	bow_mesh.outer_radius = 0.60 * s
	
	var bow := MeshInstance3D.new()
	bow.mesh = bow_mesh
	bow.material_override = bow_mat
	bow.position = Vector3(-0.35 * s, 1.1 * s, 0.25 * s)
	bow.rotation_degrees = Vector3(0, 90, 45)
	parent.add_child(bow)
	
	# Leather quiver on back
	var quiver_mat := StandardMaterial3D.new()
	quiver_mat.albedo_color = Color("#78350f") if team == 0 else Color("#1e3a8a")
	
	var q_mesh := CylinderMesh.new()
	q_mesh.top_radius = 0.12 * s
	q_mesh.bottom_radius = 0.08 * s
	q_mesh.height = 0.75 * s
	
	var quiver := MeshInstance3D.new()
	quiver.mesh = q_mesh
	quiver.material_override = quiver_mat
	quiver.position = Vector3(0.0, 1.35 * s, -0.22 * s)
	quiver.rotation_degrees = Vector3(25, 0, 30)
	parent.add_child(quiver)

static func build_sword_and_shield(parent: Node3D, team: int, s: float) -> void:
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color("#cbd5e1")
	steel_mat.metallic = 0.95
	steel_mat.roughness = 0.25
	
	# Sword blade in right hand
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.06 * s, 0.9 * s, 0.015 * s)
	
	var sword := MeshInstance3D.new()
	sword.mesh = blade_mesh
	sword.material_override = steel_mat
	sword.position = Vector3(0.38 * s, 1.0 * s, 0.3 * s)
	sword.rotation_degrees = Vector3(55, 10, -25)
	parent.add_child(sword)
	
	# Round shield on left arm
	var shield_mat := StandardMaterial3D.new()
	shield_mat.albedo_color = Color("#b45309") if team == 0 else Color("#1d4ed8")
	shield_mat.metallic = 0.4
	shield_mat.roughness = 0.5
	
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.38 * s
	shield_mesh.bottom_radius = 0.38 * s
	shield_mesh.height = 0.04 * s
	
	var shield := MeshInstance3D.new()
	shield.mesh = shield_mesh
	shield.material_override = shield_mat
	shield.position = Vector3(-0.35 * s, 1.1 * s, 0.15 * s)
	shield.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(shield)

static func build_spear(parent: Node3D, _team: int, s: float) -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#78350f")
	
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.03 * s
	shaft.bottom_radius = 0.03 * s
	shaft.height = 2.4 * s
	
	var spear := MeshInstance3D.new()
	spear.mesh = shaft
	spear.material_override = wood_mat
	spear.position = Vector3(0.3 * s, 1.2 * s, 0.2 * s)
	spear.rotation_degrees = Vector3(45, 0, 0)
	parent.add_child(spear)

static func build_rifle(parent: Node3D, _team: int, s: float) -> void:
	var rifle_mat := StandardMaterial3D.new()
	rifle_mat.albedo_color = Color("#18181b")
	rifle_mat.metallic = 0.8
	rifle_mat.roughness = 0.3
	
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.08 * s, 0.18 * s, 0.75 * s)
	
	var rifle := MeshInstance3D.new()
	rifle.mesh = body_mesh
	rifle.material_override = rifle_mat
	rifle.position = Vector3(0.2 * s, 1.1 * s, 0.35 * s)
	rifle.rotation_degrees = Vector3(-15, 0, 0)
	parent.add_child(rifle)
