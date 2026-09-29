class_name SuperUltWhooshGaruda
extends Node3D

const HitSparksClass = preload("res://scripts/hit_sparks.gd")
const DamageNumberClass = preload("res://scripts/damage_number.gd")

var team: int = 0
var charge_dir: Vector3 = Vector3.RIGHT
var speed: float = 44.0
var travel_dist: float = 0.0
var max_travel: float = 120.0
var damage: float = 320.0
var camera: Camera3D = null
var audio_mgr: Node = null
var arena: Node3D = null

var hit_units: Dictionary = {} # Prevent re-hitting same unit within split second
var horn_played: bool = false

# Visual nodes
var body_root: Node3D = null

func _ready() -> void:
	build_super_megastructure()

func launch(p_team: int, p_camera: Camera3D, p_audio: Node, p_arena: Node3D = null) -> void:
	team = p_team
	camera = p_camera
	audio_mgr = p_audio
	arena = p_arena
	
	# Team 0 (Team A) charges from West to East (Left to Right)
	# Team 1 (Team B) charges from East to West (Right to Left)
	if team == 0:
		charge_dir = Vector3.RIGHT
		global_position = Vector3(-52.0, 0.2, (randf() - 0.5) * 6.0)
		rotation.y = PI / 2.0
	else:
		charge_dir = Vector3.LEFT
		global_position = Vector3(52.0, 0.2, (randf() - 0.5) * 6.0)
		rotation.y = -PI / 2.0
		
	if camera and camera.has_method("add_shake"):
		camera.add_shake(1.5)
		
	if audio_mgr:
		if audio_mgr.has_method("play_horn"):
			audio_mgr.play_horn()
		if audio_mgr.has_method("play_explosion"):
			audio_mgr.play_explosion(true)

func build_super_megastructure() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	
	# === MATERIALS ===
	# Indonesian Red
	var red_mat := StandardMaterial3D.new()
	red_mat.albedo_color = Color("#dc2626")
	red_mat.metallic = 0.85
	red_mat.roughness = 0.2
	
	# Futuristic White / Silver Ceramic
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color("#f8fafc")
	white_mat.metallic = 0.9
	white_mat.roughness = 0.15
	
	# Dark Tinted Glass Windshield
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color("#0f172a")
	glass_mat.metallic = 0.95
	glass_mat.roughness = 0.05
	
	# Golden Bronze Garuda Wing Material
	var garuda_gold := StandardMaterial3D.new()
	garuda_gold.albedo_color = Color("#f59e0b")
	garuda_gold.metallic = 0.95
	garuda_gold.roughness = 0.25
	garuda_gold.emission_enabled = true
	garuda_gold.emission = Color("#d97706")
	garuda_gold.emission_energy_multiplier = 1.2
	
	# Glowing Cyan Headlight / Energy Material
	var cyan_glow := StandardMaterial3D.new()
	cyan_glow.albedo_color = Color("#38bdf8")
	cyan_glow.emission_enabled = true
	cyan_glow.emission = Color("#0ea5e9")
	cyan_glow.emission_energy_multiplier = 4.0
	cyan_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# === 1. LOCOMOTIVE BULLET TRAIN CABIN (WHOOSH NOSE) ===
	var nose_mesh := CylinderMesh.new()
	nose_mesh.top_radius = 0.0
	nose_mesh.bottom_radius = 2.2
	nose_mesh.height = 6.5
	
	var nose := MeshInstance3D.new()
	nose.mesh = nose_mesh
	nose.material_override = red_mat
	nose.rotation_degrees = Vector3(90, 0, 0)
	nose.position = Vector3(0, 1.8, 5.0)
	body_root.add_child(nose)
	
	# Main Locomotive Body
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(4.2, 3.4, 18.0)
	
	var main_car := MeshInstance3D.new()
	main_car.mesh = body_mesh
	main_car.material_override = white_mat
	main_car.position = Vector3(0, 2.0, -4.0)
	body_root.add_child(main_car)
	
	# Red Stripe along carriage
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(4.28, 0.6, 18.2)
	var stripe := MeshInstance3D.new()
	stripe.mesh = stripe_mesh
	stripe.material_override = red_mat
	stripe.position = Vector3(0, 2.0, -4.0)
	body_root.add_child(stripe)
	
	# Aerodynamic Glass Windshield Cockpit
	var wind_mesh := BoxMesh.new()
	wind_mesh.size = Vector3(3.2, 1.2, 3.2)
	var windshield := MeshInstance3D.new()
	windshield.mesh = wind_mesh
	windshield.material_override = glass_mat
	windshield.position = Vector3(0, 2.7, 3.5)
	windshield.rotation_degrees.x = -25.0
	body_root.add_child(windshield)
	
	# Powerful Dual Headlights
	for side in [-1.4, 1.4]:
		var light_mesh := BoxMesh.new()
		light_mesh.size = Vector3(0.65, 0.45, 0.2)
		var h_light := MeshInstance3D.new()
		h_light.mesh = light_mesh
		h_light.material_override = cyan_glow
		h_light.position = Vector3(side, 1.4, 7.8)
		body_root.add_child(h_light)
		
		var spot := SpotLight3D.new()
		spot.light_color = Color(1.0, 0.95, 0.7)
		spot.light_energy = 8.0
		spot.spot_range = 35.0
		spot.spot_angle = 35.0
		spot.position = Vector3(side, 1.4, 8.0)
		body_root.add_child(spot)

	# Heavy Steel Cowcatcher Wedge Plow in Front
	var plow_mesh := PrismMesh.new()
	plow_mesh.size = Vector3(4.6, 1.6, 2.5)
	var plow := MeshInstance3D.new()
	plow.mesh = plow_mesh
	plow.material_override = red_mat
	plow.position = Vector3(0, 0.8, 7.6)
	plow.rotation_degrees = Vector3(0, 180, 0)
	body_root.add_child(plow)

	# === 2. SAYAP GARUDA NUSANTARA (ISTANA GARUDA IKN WINGS) ===
	for side_mult in [-1.0, 1.0]:
		# Layered Golden Wing Blades
		for layer in range(5):
			var wing_blade := BoxMesh.new()
			var span = 8.5 - layer * 0.9
			wing_blade.size = Vector3(span, 0.28, 2.2 - layer * 0.25)
			
			var blade_inst := MeshInstance3D.new()
			blade_inst.mesh = wing_blade
			blade_inst.material_override = garuda_gold
			blade_inst.position = Vector3(side_mult * (2.1 + span * 0.48), 3.4 + layer * 0.55, 1.0 - layer * 2.8)
			blade_inst.rotation_degrees = Vector3(side_mult * 12.0, side_mult * -18.0, side_mult * 15.0)
			body_root.add_child(blade_inst)

	# Majestic Golden Garuda Emblem Crest on Front Roof
	var crest_mesh := PrismMesh.new()
	crest_mesh.size = Vector3(2.8, 2.2, 1.2)
	var crest := MeshInstance3D.new()
	crest.mesh = crest_mesh
	crest.material_override = garuda_gold
	crest.position = Vector3(0, 4.4, 2.6)
	crest.rotation_degrees.x = 25.0
	body_root.add_child(crest)

	# === 3. GEDUNG IKN / NUSANTARA ARCHITECTURAL MEGASTRUCTURE SPIRE ===
	var spire_mesh := CylinderMesh.new()
	spire_mesh.top_radius = 0.2
	spire_mesh.bottom_radius = 1.6
	spire_mesh.height = 7.5
	
	var spire := MeshInstance3D.new()
	spire.mesh = spire_mesh
	spire.material_override = white_mat
	spire.position = Vector3(0, 7.0, -4.0)
	body_root.add_child(spire)
	
	# Glowing Spire Core Beacon
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.8
	core_mesh.height = 1.6
	var core := MeshInstance3D.new()
	core.mesh = core_mesh
	core.material_override = cyan_glow
	core.position = Vector3(0, 10.8, -4.0)
	body_root.add_child(core)

	# Roof Pantographs & Energy Arcs
	var panto_mesh := BoxMesh.new()
	panto_mesh.size = Vector3(2.2, 1.4, 0.2)
	var panto := MeshInstance3D.new()
	panto.mesh = panto_mesh
	panto.material_override = red_mat
	panto.position = Vector3(0, 4.4, -10.0)
	body_root.add_child(panto)

func _process(delta: float) -> void:
	var move_step = speed * delta
	travel_dist += move_step
	global_position += charge_dir * move_step
	
	# Stick to ground height
	if arena and arena.has_method("get_ground_height"):
		var target_y = arena.get_ground_height(global_position.x, global_position.z) + 0.2
		global_position.y = lerp(global_position.y, target_y, delta * 12.0)
		
	# Ground vibration and camera shake
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.28)
		
	# Check collision with opposing units ("menabrak lawan lawan")
	ram_opponents()
	
	# Spawn pavement spark trails
	if randf() < 0.65:
		spawn_wheel_sparks()
		
	# Self clean up when reaching arena perimeter
	if travel_dist >= max_travel or abs(global_position.x) > 55.0:
		on_charge_complete()

func ram_opponents() -> void:
	var tree = get_tree()
	if not tree:
		return
		
	var opp_team = 1 if team == 0 else 0
	var units = tree.get_nodes_in_group("units")
	var front_center = global_position + charge_dir * 5.0
	
	for u in units:
		if is_instance_valid(u) and not u.is_dead and u.team == opp_team:
			var uid = u.get_instance_id()
			if hit_units.has(uid):
				continue
				
			var u_pos = u.global_position
			var to_unit = u_pos - global_position
			
			# Check distance along charge axis and lateral width
			var dist_forward = to_unit.dot(charge_dir)
			var lateral_vec = to_unit - charge_dir * dist_forward
			var lateral_dist = lateral_vec.length()
			
			# Ram Hitbox: 10m forward, 6.5m sideways (matching wide Garuda wings)
			if dist_forward >= -8.0 and dist_forward <= 9.0 and lateral_dist <= 6.8:
				hit_units[uid] = true
				ram_unit(u)

func ram_unit(target: Node) -> void:
	# Enormous upward and forward catapulting launch
	var launch_velocity = charge_dir * randf_range(48.0, 65.0) + Vector3(
		(randf() - 0.5) * 14.0,
		randf_range(18.0, 28.0), # Launch high into sky!
		(randf() - 0.5) * 14.0
	)
	
	if "velocity" in target:
		target.velocity = launch_velocity
		
	var is_fatal = (target.hp <= damage)
	var banner_title = "🚄 DITABRAK WHOOSH IKN!"
	if randf() < 0.35:
		banner_title = "🦅 SAYAP GARUDA NUSANTARA!"
	elif is_fatal:
		banner_title = "💥 OBLITERATED!"
		
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = target.global_position + Vector3(0, 2.5 * target.unit_scale, 0)
	dmg_label.setup_banner(banner_title, Color(1.0, 0.25, 0.25))
	
	target.take_damage(damage, global_position)
	
	# Massive hit sparks and explosions
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(target.global_position, true)
	
	if camera and camera.has_method("add_shake"):
		camera.add_shake(0.85)
		
	if audio_mgr and audio_mgr.has_method("play_hit"):
		audio_mgr.play_hit(true)

func spawn_wheel_sparks() -> void:
	var spark_pos = global_position + Vector3(
		(randf() - 0.5) * 3.5,
		0.1,
		(randf() - 0.5) * 10.0
	)
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(spark_pos, false)

func on_charge_complete() -> void:
	if audio_mgr and audio_mgr.has_method("play_explosion"):
		audio_mgr.play_explosion(true)
	queue_free()
