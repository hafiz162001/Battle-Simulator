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
		"staff_fire":
			build_magic_staff(weapon_container, "fire", team, unit_scale)
		"staff_ice":
			build_magic_staff(weapon_container, "ice", team, unit_scale)
		"staff_lightning":
			build_magic_staff(weapon_container, "lightning", team, unit_scale)
		"staff_holy":
			build_magic_staff(weapon_container, "holy", team, unit_scale)
		"staff_dark":
			build_magic_staff(weapon_container, "dark", team, unit_scale)
			
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
	# 1. Realistic Forged Steel Blade
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color("#71717a") # Authentic tempered forged steel
	steel_mat.metallic = 0.98
	steel_mat.roughness = 0.22
	
	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color("#27272a") # Dark wrought iron
	iron_mat.metallic = 0.90
	iron_mat.roughness = 0.35
	
	var hilt_wood := StandardMaterial3D.new()
	hilt_wood.albedo_color = Color("#291b12") # Dark leather-wrapped hilt
	hilt_wood.roughness = 0.85
	
	var sword_group := Node3D.new()
	sword_group.position = Vector3(0.38 * s, 1.0 * s, 0.3 * s)
	sword_group.rotation_degrees = Vector3(55, 10, -25)
	parent.add_child(sword_group)
	
	# Sword blade
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.055 * s, 0.95 * s, 0.012 * s)
	var sword := MeshInstance3D.new()
	sword.mesh = blade_mesh
	sword.material_override = steel_mat
	sword.position.y = 0.45 * s
	sword_group.add_child(sword)
	
	# Steel Crossguard
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.24 * s, 0.035 * s, 0.045 * s)
	var guard := MeshInstance3D.new()
	guard.mesh = guard_mesh
	guard.material_override = iron_mat
	sword_group.add_child(guard)
	
	# Leather Grip
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.022 * s
	grip_mesh.bottom_radius = 0.022 * s
	grip_mesh.height = 0.22 * s
	var grip := MeshInstance3D.new()
	grip.mesh = grip_mesh
	grip.material_override = hilt_wood
	grip.position.y = -0.11 * s
	sword_group.add_child(grip)
	
	# 2. Battle-Worn Round Shield with Steel Boss & Rim
	var shield_group := Node3D.new()
	shield_group.position = Vector3(-0.35 * s, 1.1 * s, 0.15 * s)
	shield_group.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(shield_group)
	
	var shield_wood := StandardMaterial3D.new()
	# Muted realistic heraldry colors (faded dark maroon or deep weathered navy)
	shield_wood.albedo_color = Color("#3e1f1a") if team == 0 else Color("#182b3d")
	shield_wood.roughness = 0.78
	
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.38 * s
	shield_mesh.bottom_radius = 0.38 * s
	shield_mesh.height = 0.035 * s
	var shield := MeshInstance3D.new()
	shield.mesh = shield_mesh
	shield.material_override = shield_wood
	shield_group.add_child(shield)
	
	# Central Steel Shield Boss (Umbo)
	var boss_mesh := SphereMesh.new()
	boss_mesh.radius = 0.11 * s
	boss_mesh.height = 0.14 * s
	var boss := MeshInstance3D.new()
	boss.mesh = boss_mesh
	boss.material_override = iron_mat
	boss.position.y = 0.02 * s
	shield_group.add_child(boss)

static func build_spear(parent: Node3D, _team: int, s: float) -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#3e2c1d") # Dark aged ash shaft
	wood_mat.roughness = 0.88
	
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color("#71717a") # Forged steel spearhead
	steel_mat.metallic = 0.98
	steel_mat.roughness = 0.22
	
	var spear_group := Node3D.new()
	spear_group.position = Vector3(0.3 * s, 1.2 * s, 0.2 * s)
	spear_group.rotation_degrees = Vector3(45, 0, 0)
	parent.add_child(spear_group)
	
	# Ash Shaft
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.028 * s
	shaft.bottom_radius = 0.032 * s
	shaft.height = 2.4 * s
	var spear := MeshInstance3D.new()
	spear.mesh = shaft
	spear.material_override = wood_mat
	spear_group.add_child(spear)
	
	# Forged Leaf Spearhead
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.06 * s, 0.35 * s, 0.015 * s)
	var spearhead := MeshInstance3D.new()
	spearhead.mesh = head_mesh
	spearhead.material_override = steel_mat
	spearhead.position.y = 1.35 * s
	spear_group.add_child(spearhead)

static func build_rifle(parent: Node3D, _team: int, s: float) -> void:
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color("#18181b") # Blued gunmetal steel
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.25
	
	var stock_mat := StandardMaterial3D.new()
	stock_mat.albedo_color = Color("#382315") # Walnut rifle stock
	stock_mat.roughness = 0.75
	
	var rifle_group := Node3D.new()
	rifle_group.position = Vector3(0.2 * s, 1.1 * s, 0.35 * s)
	rifle_group.rotation_degrees = Vector3(-15, 0, 0)
	parent.add_child(rifle_group)
	
	# Walnut Stock
	var stock_mesh := BoxMesh.new()
	stock_mesh.size = Vector3(0.06 * s, 0.16 * s, 0.45 * s)
	var stock := MeshInstance3D.new()
	stock.mesh = stock_mesh
	stock.material_override = stock_mat
	stock.position.z = -0.15 * s
	rifle_group.add_child(stock)
	
	# Steel Barrel & Receiver
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.065 * s, 0.12 * s, 0.75 * s)
	var rifle := MeshInstance3D.new()
	rifle.mesh = body_mesh
	rifle.material_override = steel_mat
	rifle.position.z = 0.18 * s
	rifle_group.add_child(rifle)

static func build_magic_staff(parent: Node3D, element: String, _team: int, s: float) -> void:
	# 1. Staff Shaft (Dark Polished Wood)
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#27272a") # Sleek obsidian/ebony
	wood_mat.roughness = 0.5
	
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.025 * s
	shaft.bottom_radius = 0.03 * s
	shaft.height = 2.1 * s
	
	var staff_mesh := MeshInstance3D.new()
	staff_mesh.mesh = shaft
	staff_mesh.material_override = wood_mat
	staff_mesh.position = Vector3(0.32 * s, 1.15 * s, 0.25 * s)
	staff_mesh.rotation_degrees = Vector3(15, 0, -10)
	parent.add_child(staff_mesh)
	
	# 2. Ornate Golden Crystal Crown / Prongs
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color("#fbbf24")
	gold_mat.metallic = 0.95
	gold_mat.roughness = 0.2
	
	var crown_mesh := TorusMesh.new()
	crown_mesh.inner_radius = 0.12 * s
	crown_mesh.outer_radius = 0.18 * s
	var crown := MeshInstance3D.new()
	crown.mesh = crown_mesh
	crown.material_override = gold_mat
	crown.position = Vector3(0.32 * s, 2.15 * s, 0.25 * s)
	crown.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(crown)
	
	# 3. Glowing Elemental Magic Core Orb
	var orb_mat := StandardMaterial3D.new()
	var orb_color := Color("#ef4444")
	var emission_col := Color("#ff5500")
	
	match element:
		"fire":
			orb_color = Color("#ef4444")
			emission_col = Color("#ff6600")
		"ice":
			orb_color = Color("#06b6d4")
			emission_col = Color("#38bdf8")
		"lightning":
			orb_color = Color("#a855f7")
			emission_col = Color("#c084fc")
		"holy":
			orb_color = Color("#fef08a")
			emission_col = Color("#eab308")
		"dark":
			orb_color = Color("#7c3aed")
			emission_col = Color("#9333ea")
			
	orb_mat.albedo_color = orb_color
	orb_mat.emission_enabled = true
	orb_mat.emission = emission_col
	orb_mat.emission_energy_multiplier = 5.0
	orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.15 * s
	orb_mesh.height = 0.3 * s
	
	var orb := MeshInstance3D.new()
	orb.mesh = orb_mesh
	orb.material_override = orb_mat
	orb.position = Vector3(0.32 * s, 2.15 * s, 0.25 * s)
	parent.add_child(orb)
	
	# Elemental Glow Light
	var light := OmniLight3D.new()
	light.light_color = emission_col
	light.light_energy = 2.5
	light.omni_range = 6.0 * s
	orb.add_child(light)
