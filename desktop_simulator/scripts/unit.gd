extends Node3D
class_name BattleUnit

enum Team { A, B }

const DamageNumberClass = preload("res://scripts/damage_number.gd")
const HitSparksClass = preload("res://scripts/hit_sparks.gd")
const ArrowProjectileClass = preload("res://scripts/arrow_projectile.gd")
const WeaponBuilderClass = preload("res://scripts/weapon_builder.gd")
const UltimateEffectClass = preload("res://scripts/ultimate_effect.gd")
const BulletTracerClass = preload("res://scripts/bullet_tracer.gd")

@export var team: Team = Team.A
var preset_id: String = "swordsman"
var max_hp: float = 140.0
var hp: float = 140.0
var damage: float = 38.0
var move_speed: float = 8.0
var attack_range: float = 2.4
var attack_speed: float = 1.4
var knockback: float = 5.0
var unit_scale: float = 1.0

var weapon_type: String = "fists"
var is_ranged: bool = false
var element: String = "physical"

var is_dead: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0

# Ultimate Skill & Energy System
var energy: float = 0.0
var max_energy: float = 100.0
var is_ulting: bool = false
var ult_timer: float = 0.0
var ult_duration: float = 1.0
var ult_cooldown: float = 0.0
var ult_hits_dealt: int = 0

# Martial Combat & Realistic Dynamics
var combo_step: int = 0
var is_blocking: bool = false
var block_timer: float = 0.0
var block_chance: float = 0.15
var strafe_offset: float = 0.0
var flinch_pitch: float = 0.0
var flinch_yaw: float = 0.0
var burst_shots_fired: int = 0
var stain_spawned: bool = false

# Dynamic Strike, Aiming, and Hit Feedback
var strike_timer: float = 0.0
var is_striking: bool = false
var hit_dealt: bool = false
var stagger_timer: float = 0.0
var stagger_intensity: float = 0.0

var velocity: Vector3 = Vector3.ZERO
var target_unit: BattleUnit = null
var retarget_timer: float = 0.0

# Animation & Procedural Kinematics
var anim_player: AnimationPlayer = null
var run_anim_name: String = ""
var attack_anim_name: String = ""
var idle_anim_name: String = ""
var death_anim_name: String = ""
var is_using_procedural_anim: bool = false
var walk_cycle_timer: float = 0.0

# Skeleton3D Bone Indices for Custom 3D Models
var skeleton: Skeleton3D = null
var bone_left_thigh: int = -1
var bone_right_thigh: int = -1
var bone_left_calf: int = -1
var bone_right_calf: int = -1
var bone_left_arm: int = -1
var bone_right_arm: int = -1

var rest_left_thigh: Quaternion = Quaternion.IDENTITY
var rest_right_thigh: Quaternion = Quaternion.IDENTITY
var rest_left_calf: Quaternion = Quaternion.IDENTITY
var rest_right_calf: Quaternion = Quaternion.IDENTITY
var rest_left_arm: Quaternion = Quaternion.IDENTITY
var rest_right_arm: Quaternion = Quaternion.IDENTITY

var audio_manager: Node = null
var arena: Node3D = null
var battle_manager: Node3D = null
var model_root: Node3D = null
var weapon_rig: Node3D = null
var death_timer: float = 0.0
var fall_pitch: float = -88.0

func _ready() -> void:
	add_to_group("units")

func _process(delta: float) -> void:
	# Independent death processing: NEVER freezes even if manager skips dead units!
	if is_dead:
		update_death_process(delta)

func setup(p_team: Team, p_model_scene: PackedScene, preset_config: Dictionary, p_audio_manager: Node, p_arena: Node3D = null, p_battle_manager: Node3D = null) -> void:
	team = p_team
	audio_manager = p_audio_manager
	arena = p_arena
	battle_manager = p_battle_manager
	
	max_hp = preset_config.get("max_hp", 500.0)
	hp = max_hp
	damage = preset_config.get("damage", 38.0)
	move_speed = preset_config.get("speed", 8.0)
	attack_range = preset_config.get("attack_range", 2.4)
	attack_speed = preset_config.get("attack_speed", 1.4)
	knockback = preset_config.get("knockback", 5.0)
	unit_scale = preset_config.get("scale", 1.0)
	preset_id = preset_config.get("id", "swordsman")
	weapon_type = preset_config.get("weapon_type", "fists")
	is_ranged = preset_config.get("is_ranged", false)
	element = preset_config.get("element", "physical")
	energy = 0.0 # Mana starts at 0, charges to 100% during combat!
	
	scale = Vector3(unit_scale, unit_scale, unit_scale)
	attack_cooldown = randf() * 0.4
	walk_cycle_timer = randf() * 6.28 # Stagger strides so army doesn't march like clones
	strafe_offset = randf() * TAU
	
	match weapon_type:
		"sword_shield":
			block_chance = 0.44
		"spear":
			block_chance = 0.32
		"fists":
			block_chance = 0.28 if preset_id == "tyson" else 0.14
		"rifle":
			block_chance = 0.18
		_:
			block_chance = 0.12
	
	if p_model_scene:
		model_root = Node3D.new()
		model_root.name = "ModelRoot"
		add_child(model_root)
		
		var model_instance = p_model_scene.instantiate()
		model_instance.name = "ModelInstance"
		model_root.add_child(model_instance)
		
		normalize_model(model_instance)
		find_and_setup_animations_and_skeleton(model_instance)
		
	# Attach weapon to model_root so it animates, strikes, and falls WITH the body!
	if weapon_type != "fists":
		var attach_parent = model_root if model_root else self
		weapon_rig = WeaponBuilderClass.attach_weapon(attach_parent, weapon_type, team, 1.0)

func normalize_model(model_inst: Node3D) -> void:
	if not model_inst:
		return
	var aabb = calculate_combined_mesh_aabb(model_inst)
	if aabb.size == Vector3.ZERO:
		return
	
	# If model has Z-up from Blender / Sketchfab (e.g. flat on ground)
	if aabb.size.z > aabb.size.y * 1.5 and aabb.size.y < 1.0:
		model_inst.rotation_degrees.x = -90.0
		aabb = calculate_combined_mesh_aabb(model_inst)
		
	# Rotate model 180 degrees around Y so imported humanoid models face +Z (project forward axis)
	model_inst.rotation_degrees.y = 180.0
		
	var current_height = aabb.size.y
	# If height is non-standard (<1.3m or >2.8m), scale to 1.85m standard humanoid height
	if current_height > 0.05 and (current_height < 1.3 or current_height > 2.8):
		var target_height = 1.85
		var s = target_height / current_height
		model_inst.scale = Vector3(s, s, s)
		aabb = calculate_combined_mesh_aabb(model_inst)
		
	# Adjust ground offset so bottom of the model touches y = 0
	if abs(aabb.position.y) > 0.08:
		model_inst.position.y = -aabb.position.y

func calculate_combined_mesh_aabb(root_node: Node3D) -> AABB:
	var total_aabb := AABB()
	var has_first := false
	var stack = [root_node]
	while stack.size() > 0:
		var curr = stack.pop_back()
		if curr is MeshInstance3D and curr.mesh and curr.mesh.get_surface_count() > 0:
			var mesh_aabb = curr.mesh.get_aabb()
			var xform = root_node.global_transform.affine_inverse() * curr.global_transform if curr.is_inside_tree() else Transform3D()
			var transformed_aabb = xform * mesh_aabb
			if not has_first:
				total_aabb = transformed_aabb
				has_first = true
			else:
				total_aabb = total_aabb.merge(transformed_aabb)
		for ch in curr.get_children():
			if ch is Node3D:
				stack.push_back(ch)
	return total_aabb

func find_and_setup_animations_and_skeleton(node: Node) -> void:
	find_nodes_recursive(node)
	
	if anim_player:
		var anim_list = anim_player.get_animation_list()
		for anim in anim_list:
			var a_obj = anim_player.get_animation(anim)
			var anim_lower = anim.to_lower()
			
			# Enable continuous linear looping for locomotion & idle
			if a_obj and ("death" not in anim_lower and "die" not in anim_lower and "punch" not in anim_lower and "attack" not in anim_lower and "slash" not in anim_lower):
				a_obj.loop_mode = Animation.LOOP_LINEAR
				
			if "punch" in anim_lower or "attack" in anim_lower or "slash" in anim_lower or "hit" in anim_lower or "strike" in anim_lower or "swing" in anim_lower:
				attack_anim_name = anim
			elif "run" in anim_lower or "sprint" in anim_lower or "walk" in anim_lower or "jog" in anim_lower or "stride" in anim_lower:
				run_anim_name = anim
			elif "idle" in anim_lower or "stand" in anim_lower or "breath" in anim_lower:
				idle_anim_name = anim
			elif "death" in anim_lower or "die" in anim_lower:
				death_anim_name = anim
				
		# Fallback detection for Mixamo & generic glTF models (e.g. "mixamo.com", "Action", "Take 001")
		if run_anim_name == "" and anim_list.size() > 0:
			for anim in anim_list:
				var anim_lower = anim.to_lower()
				if "tpose" not in anim_lower and "agree" not in anim_lower and "shake" not in anim_lower and "sad" not in anim_lower:
					run_anim_name = anim
					var a_obj = anim_player.get_animation(anim)
					if a_obj:
						a_obj.loop_mode = Animation.LOOP_LINEAR
					break
			if run_anim_name == "":
				run_anim_name = anim_list[0]
				var a_obj = anim_player.get_animation(run_anim_name)
				if a_obj:
					a_obj.loop_mode = Animation.LOOP_LINEAR

	# Auto-retarget natural motion-captured animations to custom humanoid models
	if skeleton and (anim_player == null or run_anim_name == ""):
		auto_retarget_natural_animations()
		
	# If model still has no anim player or no run anim, activate procedural kinematics
	if anim_player == null or run_anim_name == "":
		is_using_procedural_anim = true
	else:
		is_using_procedural_anim = false
		play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)

func auto_retarget_natural_animations() -> void:
	if not skeleton or not model_root:
		return
		
	# Check if this skeleton has humanoid bones
	var has_humanoid_rig = false
	var bone_prefix = ""
	for b in range(skeleton.get_bone_count()):
		var bname = skeleton.get_bone_name(b)
		if "Hips" in bname or "hips" in bname:
			has_humanoid_rig = true
			if "mixamorig" in bname:
				bone_prefix = "mixamorig_"
			break
			
	if not has_humanoid_rig:
		return
		
	if not ResourceLoader.exists("res://models/Soldier.glb"):
		return
	var soldier_scene = load("res://models/Soldier.glb")
	if not soldier_scene:
		return
	var s_inst = soldier_scene.instantiate()
	var s_ap: AnimationPlayer = s_inst.find_child("AnimationPlayer", true, false)
	if not s_ap:
		s_inst.queue_free()
		return
		
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AutoAnimPlayer"
		model_root.add_child(anim_player)
		
	var target_skel_path = model_root.get_path_to(skeleton)
	var anim_lib: AnimationLibrary = null
	if anim_player.has_animation_library(""):
		anim_lib = anim_player.get_animation_library("")
	else:
		anim_lib = AnimationLibrary.new()
		anim_player.add_animation_library("", anim_lib)
		
	# Retarget Run, Walk, Idle
	var retarget_targets = ["Run", "Walk", "Idle"]
	for anim_name in retarget_targets:
		if s_ap.has_animation(anim_name):
			var orig = s_ap.get_animation(anim_name)
			var cloned = orig.duplicate()
			cloned.loop_mode = Animation.LOOP_LINEAR
			
			for t in range(cloned.get_track_count()):
				var p = str(cloned.track_get_path(t))
				var parts = p.split(":")
				if parts.size() == 2:
					var bone_name = parts[1]
					if skeleton.find_bone(bone_name) != -1:
						var new_path = str(target_skel_path) + ":" + bone_name
						cloned.track_set_path(t, NodePath(new_path))
					elif bone_prefix != "" and skeleton.find_bone(bone_prefix + bone_name) != -1:
						var new_path = str(target_skel_path) + ":" + (bone_prefix + bone_name)
						cloned.track_set_path(t, NodePath(new_path))
						
			var new_anim_name = "Natural" + anim_name
			if anim_lib.has_animation(new_anim_name):
				anim_lib.remove_animation(new_anim_name)
			anim_lib.add_animation(new_anim_name, cloned)
			
			if anim_name == "Run":
				run_anim_name = new_anim_name
			elif anim_name == "Idle":
				idle_anim_name = new_anim_name
				
	s_inst.queue_free()

func find_nodes_recursive(node: Node) -> void:
	if not anim_player and node is AnimationPlayer:
		anim_player = node
	if not skeleton and node is Skeleton3D:
		skeleton = node
		setup_skeleton_bones()
	for child in node.get_children():
		find_nodes_recursive(child)

func setup_skeleton_bones() -> void:
	if not skeleton:
		return
	for b in range(skeleton.get_bone_count()):
		var bname = skeleton.get_bone_name(b).to_lower()
		var rest_q = skeleton.get_bone_rest(b).basis.get_rotation_quaternion()
		
		# Left leg / thigh
		if bone_left_thigh == -1 and ("left" in bname or "_l" in bname or ".l" in bname) and ("leg" in bname or "thigh" in bname or "upleg" in bname):
			bone_left_thigh = b
			rest_left_thigh = rest_q
		# Right leg / thigh
		elif bone_right_thigh == -1 and ("right" in bname or "_r" in bname or ".r" in bname) and ("leg" in bname or "thigh" in bname or "upleg" in bname):
			bone_right_thigh = b
			rest_right_thigh = rest_q
		# Left calf / knee
		elif bone_left_calf == -1 and ("left" in bname or "_l" in bname or ".l" in bname) and ("knee" in bname or "shin" in bname or "calf" in bname or "lowerleg" in bname):
			bone_left_calf = b
			rest_left_calf = rest_q
		# Right calf / knee
		elif bone_right_calf == -1 and ("right" in bname or "_r" in bname or ".r" in bname) and ("knee" in bname or "shin" in bname or "calf" in bname or "lowerleg" in bname):
			bone_right_calf = b
			rest_right_calf = rest_q
		# Left arm
		elif bone_left_arm == -1 and ("left" in bname or "_l" in bname or ".l" in bname) and ("arm" in bname or "shoulder" in bname):
			bone_left_arm = b
			rest_left_arm = rest_q
		# Right arm
		elif bone_right_arm == -1 and ("right" in bname or "_r" in bname or ".r" in bname) and ("arm" in bname or "shoulder" in bname):
			bone_right_arm = b
			rest_right_arm = rest_q

func play_anim(anim_name: String) -> void:
	if anim_player and anim_name != "" and anim_player.has_animation(anim_name):
		var a_obj = anim_player.get_animation(anim_name)
		if a_obj and ("death" not in anim_name.to_lower() and "die" not in anim_name.to_lower()):
			a_obj.loop_mode = Animation.LOOP_LINEAR
		if anim_player.current_animation != anim_name or not anim_player.is_playing():
			anim_player.play(anim_name, 0.2)
			
		# Synchronize footstep tempo with movement speed so boots grip the sand without sliding
		if "run" in anim_name.to_lower() or "walk" in anim_name.to_lower():
			anim_player.speed_scale = clamp(move_speed / 6.2, 0.85, 1.75)
		else:
			anim_player.speed_scale = 1.0

func update_procedural_movement(delta: float, is_moving: bool) -> void:
	if not model_root or is_dead:
		return
		
	if is_moving:
		walk_cycle_timer += delta * (move_speed * 1.25)
		var cycle = walk_cycle_timer
		
		# 1. Natural body bobbing and sprint lean for ANY model
		var bob = abs(sin(cycle)) * 0.12 * unit_scale
		model_root.position.y = bob
		model_root.rotation.x = deg_to_rad(6.0) # Forward sprint lean
		model_root.rotation.z = sin(cycle) * deg_to_rad(3.5) # Dynamic torso sway
		
		# 2. Procedural leg and arm bone swinging for Skeleton3D (interleaved on massive battles for 2x performance)
		var skip_bone_frame = (battle_manager and battle_manager.is_massive_battle and (Engine.get_process_frames() + get_instance_id()) % 2 != 0)
		if skeleton and is_using_procedural_anim and not skip_bone_frame:
			var swing = sin(cycle) * 0.65
			var knee_flex_left = clamp(-sin(cycle) * 0.85, 0.0, 1.2)
			var knee_flex_right = clamp(sin(cycle) * 0.85, 0.0, 1.2)
			
			if bone_left_thigh != -1:
				var q = Quaternion(Vector3(1, 0, 0), swing)
				skeleton.set_bone_pose_rotation(bone_left_thigh, rest_left_thigh * q)
			if bone_right_thigh != -1:
				var q = Quaternion(Vector3(1, 0, 0), -swing)
				skeleton.set_bone_pose_rotation(bone_right_thigh, rest_right_thigh * q)
				
			if bone_left_calf != -1:
				var q = Quaternion(Vector3(1, 0, 0), knee_flex_left)
				skeleton.set_bone_pose_rotation(bone_left_calf, rest_left_calf * q)
			if bone_right_calf != -1:
				var q = Quaternion(Vector3(1, 0, 0), knee_flex_right)
				skeleton.set_bone_pose_rotation(bone_right_calf, rest_right_calf * q)
				
			if bone_left_arm != -1:
				var q = Quaternion(Vector3(1, 0, 0), -swing * 0.6)
				skeleton.set_bone_pose_rotation(bone_left_arm, rest_left_arm * q)
			if bone_right_arm != -1:
				var q = Quaternion(Vector3(1, 0, 0), swing * 0.6)
				skeleton.set_bone_pose_rotation(bone_right_arm, rest_right_arm * q)
	else:
		# Return smoothly to rest pose with subtle combat breathing
		walk_cycle_timer += delta * 3.0
		var combat_breathe = sin(walk_cycle_timer) * 0.03 * unit_scale
		model_root.position.y = lerp(model_root.position.y, combat_breathe, delta * 8.0)
		model_root.rotation.x = lerp(model_root.rotation.x, 0.0, delta * 8.0)
		model_root.rotation.z = lerp(model_root.rotation.z, 0.0, delta * 8.0)
		
		if skeleton and is_using_procedural_anim:
			if bone_left_thigh != -1:
				skeleton.set_bone_pose_rotation(bone_left_thigh, rest_left_thigh)
			if bone_right_thigh != -1:
				skeleton.set_bone_pose_rotation(bone_right_thigh, rest_right_thigh)
			if bone_left_calf != -1:
				skeleton.set_bone_pose_rotation(bone_left_calf, rest_left_calf)
			if bone_right_calf != -1:
				skeleton.set_bone_pose_rotation(bone_right_calf, rest_right_calf)
			if bone_left_arm != -1:
				skeleton.set_bone_pose_rotation(bone_left_arm, rest_left_arm)
			if bone_right_arm != -1:
				skeleton.set_bone_pose_rotation(bone_right_arm, rest_right_arm)

func update_death_process(delta: float) -> void:
	death_timer += delta
	
	# 1. Realistic Ballistic Ragdoll Flight & Ground Bounce
	if velocity.length_squared() > 0.1:
		velocity.y -= 22.0 * delta # Realistic gravity
		global_position += velocity * delta
		
		# Ground elevation check
		var ground_y: float = 0.0
		if arena and arena.has_method("get_ground_height"):
			ground_y = arena.get_ground_height(global_position.x, global_position.z)
			
		if global_position.y <= ground_y:
			global_position.y = ground_y
			if abs(velocity.y) > 3.0:
				velocity.y = -velocity.y * 0.28 # Ground restitution bounce
				spawn_pavement_impact_sparks()
			else:
				velocity.y = 0.0
			velocity.x = lerp(velocity.x, 0.0, delta * 7.5) # Asphalt friction
			velocity.z = lerp(velocity.z, 0.0, delta * 7.5)
			
		enforce_arena_boundaries()
	
	# 2. Smooth gravitational collapse & body settlement
	if death_timer <= 0.85:
		var t = clamp(death_timer / 0.70, 0.0, 1.0)
		var ease_t = 1.0 - (1.0 - t) * (1.0 - t)
		
		if model_root:
			model_root.rotation_degrees.x = lerp(0.0, fall_pitch, ease_t)
			model_root.position.y = lerp(0.0, 0.12 * unit_scale, ease_t)
			var shift_z = (-0.6 * unit_scale if fall_pitch < 0.0 else 0.6 * unit_scale)
			model_root.position.z = lerp(0.0, shift_z, ease_t)
			
		# Limp skeleton limbs
		if skeleton:
			if bone_left_thigh != -1:
				skeleton.set_bone_pose_rotation(bone_left_thigh, rest_left_thigh)
			if bone_right_thigh != -1:
				skeleton.set_bone_pose_rotation(bone_right_thigh, rest_right_thigh)
			if bone_left_calf != -1:
				skeleton.set_bone_pose_rotation(bone_left_calf, rest_left_calf)
			if bone_right_calf != -1:
				skeleton.set_bone_pose_rotation(bone_right_calf, rest_right_calf)
			if bone_left_arm != -1:
				skeleton.set_bone_pose_rotation(bone_left_arm, rest_left_arm)
			if bone_right_arm != -1:
				skeleton.set_bone_pose_rotation(bone_right_arm, rest_right_arm)
				
		# Drop weapon onto pavement
		if weapon_rig:
			weapon_rig.position.y = lerp(weapon_rig.position.y, 0.05, ease_t)
			weapon_rig.rotation_degrees.x = lerp(weapon_rig.rotation_degrees.x, 90.0, ease_t)
			
	# 3. Spawn permanent battle asphalt stain decal once settled
	elif death_timer > 0.85 and not stain_spawned:
		stain_spawned = true
		spawn_battle_decal()
			
	# After lying on ground, sink smoothly into asphalt (faster cleanup on massive battles)
	var max_ground_time = 3.5 if (battle_manager and battle_manager.is_massive_battle) else 12.0
	var max_sink_time = max_ground_time + 2.0
	if death_timer > max_ground_time:
		global_position.y -= delta * 0.25
		if death_timer > max_sink_time:
			queue_free()

func spawn_pavement_impact_sparks() -> void:
	if not HitSparksClass.can_spawn(false):
		return
	var sparks := HitSparksClass.new()
	var p = get_parent()
	if p:
		p.add_child(sparks)
		sparks.trigger(global_position + Vector3(0, 0.1, 0), false)

static var active_decals: int = 0
const MAX_ACTIVE_DECALS: int = 35
static var shared_decal_mesh: PlaneMesh = null
static var shared_decal_mat: StandardMaterial3D = null

func spawn_battle_decal() -> void:
	if active_decals >= MAX_ACTIVE_DECALS:
		return
	var p = get_parent()
	if not p:
		return
	active_decals += 1
	var decal := MeshInstance3D.new()
	if not shared_decal_mesh:
		shared_decal_mesh = PlaneMesh.new()
		shared_decal_mesh.size = Vector2(1.5, 1.5)
	if not shared_decal_mat:
		shared_decal_mat = StandardMaterial3D.new()
		shared_decal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shared_decal_mat.albedo_color = Color(0.08, 0.08, 0.1, 0.65)
		shared_decal_mat.roughness = 0.95
	
	decal.mesh = shared_decal_mesh
	decal.material_override = shared_decal_mat
	decal.position = Vector3(global_position.x, 0.012, global_position.z)
	decal.rotation.y = randf() * TAU
	decal.tree_exited.connect(func(): active_decals = max(0, active_decals - 1))
	p.add_child(decal)
	var t = get_tree()
	if t:
		var ttl = 8.0 if (battle_manager and battle_manager.is_massive_battle) else 20.0
		t.create_timer(ttl).timeout.connect(decal.queue_free)

func update_unit(delta: float, is_battle_running: bool, nearest_enemy: BattleUnit, forward_target: Vector3, separation_force: Vector3) -> void:
	if is_dead:
		return
		
	if attack_cooldown > 0:
		attack_cooldown -= delta
		
	if ult_cooldown > 0:
		ult_cooldown -= delta
		
	# Block & Parry Guard Pose
	if block_timer > 0:
		block_timer -= delta
		if model_root:
			model_root.rotation_degrees.x = lerp(model_root.rotation_degrees.x, 8.0, delta * 18.0)
		if weapon_rig:
			if weapon_type == "sword_shield":
				weapon_rig.rotation_degrees = weapon_rig.rotation_degrees.lerp(Vector3(-15, 60, 20), delta * 24.0)
				weapon_rig.position = weapon_rig.position.lerp(Vector3(-0.1, 0.15, 0.25), delta * 24.0)
			elif weapon_type == "spear":
				weapon_rig.rotation_degrees = weapon_rig.rotation_degrees.lerp(Vector3(-25, 45, -15), delta * 24.0)
			elif preset_id == "tyson":
				if model_root:
					model_root.position.z = lerp(model_root.position.z, -0.15, delta * 20.0)
					model_root.rotation_degrees.x = lerp(model_root.rotation_degrees.x, 15.0, delta * 20.0)
	elif stagger_timer > 0:
		stagger_timer -= delta
		var p = stagger_timer / 0.22
		if model_root:
			model_root.rotation_degrees.x = flinch_pitch * stagger_intensity * p
			model_root.rotation_degrees.y = flinch_yaw * stagger_intensity * p
	elif not is_striking and not is_ulting and model_root:
		model_root.rotation_degrees.x = lerp(model_root.rotation_degrees.x, 0.0, delta * 14.0)
		model_root.rotation_degrees.y = lerp(model_root.rotation_degrees.y, 0.0, delta * 14.0)
		model_root.rotation_degrees.z = lerp(model_root.rotation_degrees.z, 0.0, delta * 14.0)
		model_root.position.x = lerp(model_root.position.x, 0.0, delta * 14.0)
		model_root.position.z = lerp(model_root.position.z, 0.0, delta * 14.0)
		if weapon_rig:
			weapon_rig.position = weapon_rig.position.lerp(Vector3.ZERO, delta * 14.0)
			weapon_rig.rotation_degrees = weapon_rig.rotation_degrees.lerp(Vector3.ZERO, delta * 14.0)
		
	if not is_battle_running:
		update_procedural_movement(delta, false)
		play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)
		return
		
	# Passive energy gain during active battle
	energy = min(max_energy, energy + delta * 3.2)
	
	# Execute ongoing Ultimate Skill
	if is_ulting:
		update_ultimate(delta)
		return
		
	if not is_instance_valid(target_unit) or target_unit.is_dead:
		target_unit = nearest_enemy
		retarget_timer = randf_range(0.35, 0.65)
	elif nearest_enemy != null:
		retarget_timer -= delta
		if retarget_timer <= 0.0:
			target_unit = nearest_enemy
			retarget_timer = randf_range(0.35, 0.65)
		
	var target_pos := forward_target
	if is_instance_valid(target_unit) and not target_unit.is_dead:
		target_pos = target_unit.global_position
		
	var dir_to_target = (target_pos - global_position)
	dir_to_target.y = 0.0
	var dist_xz = dir_to_target.length()
	
	# Auto-cast Ultimate when energy is full and within engagement range
	if energy >= max_energy and ult_cooldown <= 0 and is_instance_valid(target_unit) and not target_unit.is_dead:
		var ult_range = 35.0 if is_ranged else max(attack_range * 4.5, 9.0)
		if dist_xz <= ult_range:
			cast_ultimate()
			return
	
	# Face the enemy directly forward (HEAD FIRST)
	if dist_xz > 0.05:
		var move_dir = dir_to_target / dist_xz
		var target_yaw = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 14.0)
		
	var effective_range = attack_range * max(0.9, unit_scale * 0.8)
	
	# Archer Ranged Combat vs Melee Combat
	if is_ranged:
		update_archer_combat(delta, dist_xz, dir_to_target, effective_range, separation_force)
	else:
		update_melee_combat(delta, dist_xz, dir_to_target, effective_range, separation_force)

func update_archer_combat(delta: float, dist_xz: float, dir_to_target: Vector3, effective_range: float, separation_force: Vector3) -> void:
	if is_instance_valid(target_unit) and not target_unit.is_dead and dist_xz <= effective_range:
		is_attacking = true
		
		# Tactical Kiting / Backpedal if enemy gets uncomfortably close
		var min_kite_dist = 6.0 * unit_scale
		if dist_xz < min_kite_dist:
			var retreat_dir = -dir_to_target.normalized()
			velocity = velocity.lerp(retreat_dir * (move_speed * 0.72), delta * 7.0)
			global_position += velocity * delta
			ground_unit(delta)
			update_procedural_movement(delta, true)
		else:
			# Tactical Strafe Footwork
			var tangent = Vector3(-dir_to_target.z, 0, dir_to_target.x).normalized()
			var strafe_speed = sin(Time.get_ticks_msec() * 0.0025 + strafe_offset) * (move_speed * 0.28)
			velocity = velocity.lerp(tangent * strafe_speed, delta * 6.0)
			global_position += velocity * delta
			ground_unit(delta)
			update_procedural_movement(delta, false)
		
		# Draw and shoot arrow / fire burst
		if not is_striking and attack_cooldown <= 0:
			is_striking = true
			strike_timer = 0.0
			hit_dealt = false
			burst_shots_fired = 0
			attack_cooldown = 1.0 / attack_speed
			
		if is_striking:
			strike_timer += delta
			
			if weapon_type == "rifle":
				# Commando 3-Round Burst Fire
				var burst_duration = 0.52 / attack_speed
				var t = clamp(strike_timer / burst_duration, 0.0, 1.0)
				
				# Weapon recoil recovery
				if weapon_rig:
					weapon_rig.position = weapon_rig.position.lerp(Vector3.ZERO, delta * 18.0)
					weapon_rig.rotation_degrees = weapon_rig.rotation_degrees.lerp(Vector3.ZERO, delta * 18.0)
				
				if t >= 0.18 and burst_shots_fired == 0:
					burst_shots_fired = 1
					fire_rifle_burst_shot(damage * 0.36)
				elif t >= 0.44 and burst_shots_fired == 1:
					burst_shots_fired = 2
					fire_rifle_burst_shot(damage * 0.36)
				elif t >= 0.70 and burst_shots_fired == 2:
					burst_shots_fired = 3
					fire_rifle_burst_shot(damage * 0.42)
					
				if t >= 1.0:
					is_striking = false
					if weapon_rig:
						weapon_rig.position = Vector3.ZERO
						weapon_rig.rotation_degrees = Vector3.ZERO
					play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)
			elif weapon_type.begins_with("staff_"):
				# Elemental Mage Spellcast!
				var cast_duration = 0.58 / attack_speed
				var t = clamp(strike_timer / cast_duration, 0.0, 1.0)
				
				# Staff thrust / raise pose
				if weapon_rig:
					weapon_rig.rotation_degrees.x = -sin(t * PI) * 35.0
					weapon_rig.position.z = sin(t * PI) * 0.25 * unit_scale
				if model_root:
					model_root.rotation_degrees.x = -sin(t * PI) * 8.0
					
				# Release magic spell at 45%
				if t >= 0.45 and not hit_dealt:
					hit_dealt = true
					energy = min(max_energy, energy + 20.0)
					shoot_magic(target_unit.global_position + Vector3(0, 1.2 * target_unit.unit_scale, 0))
					if audio_manager and audio_manager.has_method("play_ult_cast"):
						audio_manager.play_ult_cast()
						
				if t >= 1.0:
					is_striking = false
					if weapon_rig:
						weapon_rig.position = Vector3.ZERO
						weapon_rig.rotation_degrees = Vector3.ZERO
					if model_root:
						model_root.position = Vector3.ZERO
						model_root.rotation_degrees = Vector3.ZERO
					play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)
			else:
				# Bow / Urban Sniper
				var shoot_duration = 0.55 / attack_speed
				var t = clamp(strike_timer / shoot_duration, 0.0, 1.0)
				
				# Upper body bow draw pose
				if model_root:
					model_root.rotation_degrees.y = -sin(t * PI) * 20.0
					model_root.position.z = -sin(t * PI) * 0.15
					
				# Release arrow at 50%
				if t >= 0.50 and not hit_dealt:
					hit_dealt = true
					energy = min(max_energy, energy + 18.0)
					shoot_arrow(target_unit.global_position + Vector3(0, 1.2 * target_unit.unit_scale, 0))
					if audio_manager and audio_manager.has_method("play_bow_shoot"):
						audio_manager.play_bow_shoot()
						
				if t >= 1.0:
					is_striking = false
					if model_root:
						model_root.position = Vector3.ZERO
						model_root.rotation_degrees = Vector3.ZERO
					play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)
	else:
		# Advance towards enemy in disciplined formation
		is_attacking = false
		is_striking = false
		var enemy_dir = dir_to_target.normalized() if dist_xz > 0.1 else (Vector3.RIGHT if team == Team.A else Vector3.LEFT)
		
		var backward_push = separation_force.dot(enemy_dir)
		var clean_sep = separation_force
		if backward_push < 0.0:
			clean_sep -= enemy_dir * backward_push
			
		var combined_dir = (enemy_dir * 1.0 + clean_sep * 0.85).normalized()
		velocity = velocity.lerp(combined_dir * move_speed, delta * 8.0)
		global_position += velocity * delta
		ground_unit(delta)
		update_procedural_movement(delta, velocity.length() > 0.5)
		play_anim(run_anim_name)

func fire_rifle_burst_shot(shot_damage: float) -> void:
	if not is_instance_valid(target_unit) or target_unit.is_dead:
		return
	energy = min(max_energy, energy + 8.0)
	
	# Recoil kick!
	if weapon_rig:
		weapon_rig.position.z = -0.16 * unit_scale
		weapon_rig.rotation_degrees.x = 18.0
	if model_root:
		model_root.rotation_degrees.x = 4.0
		
	if audio_manager and audio_manager.has_method("play_gunshot"):
		audio_manager.play_gunshot()
		
	var muzzle_pos = global_position + Vector3(0.2, 1.1, 0.4) * unit_scale + global_transform.basis.z * 0.35
	var target_chest = target_unit.global_position + Vector3(0, 1.15 * target_unit.unit_scale, 0)
	
	# Muzzle flash spark
	var muzzle_spark := HitSparksClass.new()
	get_parent().add_child(muzzle_spark)
	muzzle_spark.trigger(muzzle_pos, false)
	
	# Launch tracer bullet
	var tracer := BulletTracerClass.new()
	get_parent().add_child(tracer)
	tracer.fire(muzzle_pos, target_chest, team, shot_damage, target_unit)

func shoot_arrow(target_pos: Vector3) -> void:
	var arrow = ArrowProjectileClass.new()
	get_parent().add_child(arrow)
	var shoot_origin = global_position + Vector3(0, 1.35 * unit_scale, 0) + global_transform.basis.z * 0.4
	arrow.launch(shoot_origin, target_pos, team, damage, "physical")

func shoot_magic(target_pos: Vector3) -> void:
	var proj = ArrowProjectileClass.new()
	get_parent().add_child(proj)
	var shoot_origin = global_position + Vector3(0.3 * unit_scale, 1.8 * unit_scale, 0.3 * unit_scale) + global_transform.basis.z * 0.4
	proj.launch(shoot_origin, target_pos, team, damage, element)

func update_melee_combat(delta: float, dist_xz: float, dir_to_target: Vector3, effective_range: float, separation_force: Vector3) -> void:
	if is_instance_valid(target_unit) and not target_unit.is_dead and dist_xz <= effective_range:
		is_attacking = true
		
		# Tactical Footwork: Circle-Strafing during melee combat with spacing separation!
		var tangent = Vector3(-dir_to_target.z, 0, dir_to_target.x).normalized()
		var strafe_speed = sin(Time.get_ticks_msec() * 0.0035 + strafe_offset) * (move_speed * 0.42)
		var combat_sep = separation_force * 0.65
		velocity = velocity.lerp(tangent * strafe_speed + combat_sep, delta * 7.0)
		global_position += velocity * delta
		ground_unit(delta)
		update_procedural_movement(delta, false)
		
		if not is_striking and attack_cooldown <= 0:
			is_striking = true
			strike_timer = 0.0
			hit_dealt = false
			attack_cooldown = 1.0 / attack_speed
			if attack_anim_name != "":
				play_anim(attack_anim_name)
				
		if is_striking:
			strike_timer += delta
			var combo_speed_mult = 1.1 if combo_step == 0 else (1.0 if combo_step == 1 else 0.85)
			var strike_duration = (0.45 * combo_speed_mult) / attack_speed
			var t = clamp(strike_timer / strike_duration, 0.0, 1.0)
			
			# Execute 3-hit combo procedural martial kinematics
			animate_melee_combo(t, combo_step)
			
			var impact_t = 0.40 if combo_step == 0 else (0.44 if combo_step == 1 else 0.48)
			if t >= impact_t and not hit_dealt:
				hit_dealt = true
				energy = min(max_energy, energy + 18.0)
				execute_melee_impact(combo_step)
							
			if t >= 1.0:
				is_striking = false
				combo_step = (combo_step + 1) % 3
				if model_root:
					model_root.position = Vector3.ZERO
					model_root.rotation_degrees = Vector3.ZERO
				if weapon_rig:
					weapon_rig.position = Vector3.ZERO
					weapon_rig.rotation_degrees = Vector3.ZERO
				play_anim(idle_anim_name if idle_anim_name != "" else run_anim_name)
	else:
		# Army charge towards enemy
		is_attacking = false
		is_striking = false
		var enemy_dir = dir_to_target.normalized() if dist_xz > 0.1 else (Vector3.RIGHT if team == Team.A else Vector3.LEFT)
		
		var backward_push = separation_force.dot(enemy_dir)
		var clean_sep = separation_force
		if backward_push < 0.0:
			clean_sep -= enemy_dir * backward_push
			
		var combined_dir = (enemy_dir * 1.0 + clean_sep * 0.85).normalized()
		velocity = velocity.lerp(combined_dir * move_speed, delta * 8.0)
		global_position += velocity * delta
		ground_unit(delta)
		update_procedural_movement(delta, velocity.length() > 0.5)
		play_anim(run_anim_name)

func animate_melee_combo(t: float, step: int) -> void:
	if not model_root:
		return
		
	var sin_t = sin(t * PI)
	
	if preset_id == "tyson":
		match step:
			0: # Lead Left Jab
				model_root.position.z = sin_t * 0.55 * unit_scale
				model_root.rotation_degrees.y = sin_t * 18.0
				model_root.rotation_degrees.x = -sin_t * 8.0
			1: # Ducking Slip-in Right Hook to Liver/Head
				model_root.position.x = -sin_t * 0.35
				model_root.position.y = -sin_t * 0.15
				model_root.position.z = sin_t * 0.45 * unit_scale
				model_root.rotation_degrees.y = -sin_t * 32.0
				model_root.rotation_degrees.z = sin_t * 12.0
			2: # Explosive Rising Knockout Uppercut
				model_root.position.y = (sin_t - 0.15) * 0.45
				model_root.position.z = sin_t * 0.75 * unit_scale
				model_root.rotation_degrees.x = -sin_t * 32.0
				model_root.rotation_degrees.y = sin_t * 24.0
	elif preset_id == "titan":
		match step:
			0: # Horizontal Backhand Sweep
				model_root.rotation_degrees.y = sin_t * 30.0
				model_root.position.z = sin_t * 0.4 * unit_scale
			1: # Forehand Cleaving Swipe
				model_root.rotation_degrees.y = -sin_t * 35.0
				model_root.position.z = sin_t * 0.5 * unit_scale
			2: # Overhead Earth-Shattering Hammer Slam
				model_root.position.y = -sin_t * 0.45
				model_root.position.z = sin_t * 0.9 * unit_scale
				model_root.rotation_degrees.x = -sin_t * 48.0
	else:
		match step:
			0: # Combo 1: Fast Horizontal Slash / Quick Thrust
				model_root.position.z = sin_t * 0.45 * unit_scale
				model_root.rotation_degrees.y = sin_t * 16.0
				if weapon_rig:
					if weapon_type == "spear":
						weapon_rig.position.z = sin_t * 0.9 * unit_scale
						weapon_rig.rotation_degrees.x = -sin_t * 15.0
					else:
						weapon_rig.rotation_degrees.y = sin_t * 60.0
						weapon_rig.rotation_degrees.x = -sin_t * 25.0
						weapon_rig.position.z = sin_t * 0.35
			1: # Combo 2: Diagonal Cleave / Cross Strike
				model_root.position.z = sin_t * 0.6 * unit_scale
				model_root.rotation_degrees.y = -sin_t * 22.0
				if weapon_rig:
					if weapon_type == "spear":
						weapon_rig.rotation_degrees.y = sin_t * 50.0
						weapon_rig.position.z = sin_t * 0.5
					else:
						weapon_rig.rotation_degrees.x = -sin_t * 50.0
						weapon_rig.rotation_degrees.y = -sin_t * 40.0
						weapon_rig.rotation_degrees.z = sin_t * 25.0
			2: # Combo 3 (Finisher): Deep Lunging Overhead Chop / Shield Bash
				model_root.position.z = sin_t * 0.95 * unit_scale
				model_root.rotation_degrees.x = -sin_t * 24.0
				if weapon_rig:
					if weapon_type == "spear":
						weapon_rig.position.z = sin_t * 1.4 * unit_scale
						weapon_rig.rotation_degrees.x = -sin_t * 25.0
					else:
						weapon_rig.rotation_degrees.x = -sin_t * 80.0
						weapon_rig.position.z = sin_t * 0.6

func execute_melee_impact(step: int) -> void:
	if not is_instance_valid(target_unit) or target_unit.is_dead:
		return
		
	var is_heavy = (unit_scale > 1.8) or (weapon_type == "fists")
	var dmg_mult = 0.85 if step == 0 else (1.05 if step == 1 else 1.45)
	var actual_damage = damage * dmg_mult * (0.95 + randf() * 0.2)
	
	# Titan Colossus AoE Slam on Finisher
	if preset_id == "titan" and step == 2:
		actual_damage *= 1.25
		target_unit.take_damage(actual_damage, global_position)
		if audio_manager:
			audio_manager.play_explosion(true)
		var opp_team_int = 1 if team == Team.A else 0
		var candidates: Array = []
		if battle_manager and battle_manager.has_method("get_units_in_radius"):
			candidates = battle_manager.get_units_in_radius(global_position, 5.0, opp_team_int)
		else:
			var tree = get_tree()
			if tree:
				candidates = tree.get_nodes_in_group("units")
		for u in candidates:
			if is_instance_valid(u) and not u.is_dead and u != target_unit and u.team != team:
				if global_position.distance_squared_to(u.global_position) <= 25.0:
					u.take_damage(actual_damage * 0.45, global_position)
		return
		
	# Mike Tyson Knockout Uppercut on Finisher
	if preset_id == "tyson" and step == 2:
		is_heavy = true
		actual_damage *= 1.3
		if target_unit.hp <= actual_damage:
			spawn_banner("🥊 K.O.!", Color(1.0, 0.2, 0.2))
		target_unit.take_damage(actual_damage, global_position)
		if audio_manager:
			audio_manager.play_hit(true)
		return
		
	target_unit.take_damage(actual_damage, global_position)
	if audio_manager:
		if weapon_type == "sword_shield" or weapon_type == "spear":
			audio_manager.play_sword_slash()
		else:
			audio_manager.play_hit(is_heavy or step == 2)

func ground_unit(delta: float) -> void:
	if arena and arena.has_method("get_ground_height"):
		var target_y: float = arena.get_ground_height(global_position.x, global_position.z)
		global_position.y = lerp(global_position.y, target_y, delta * 14.0)
	enforce_arena_boundaries()

func enforce_arena_boundaries() -> void:
	var bound_x = 40.8
	var bound_z = 22.4
	if global_position.x < -bound_x:
		global_position.x = -bound_x
		velocity.x = abs(velocity.x) * 0.4
	elif global_position.x > bound_x:
		global_position.x = bound_x
		velocity.x = -abs(velocity.x) * 0.4
		
	if global_position.z < -bound_z:
		global_position.z = -bound_z
		velocity.z = abs(velocity.z) * 0.4
	elif global_position.z > bound_z:
		global_position.z = bound_z
		velocity.z = -abs(velocity.z) * 0.4

func take_damage(amount: float, attacker_pos: Vector3) -> void:
	if is_dead:
		return
		
	var forward_dir = global_transform.basis.z
	var to_attacker = (attacker_pos - global_position).normalized()
	to_attacker.y = 0.0
	var is_facing_attacker = forward_dir.dot(to_attacker) > 0.12 # Frontal arc
	
	var blocked: bool = false
	if is_facing_attacker and not is_ulting and randf() < block_chance:
		blocked = true
		
	if blocked:
		# Active Block & Parry
		is_blocking = true
		block_timer = 0.30
		var reduced_damage = amount * 0.25 # 75% damage mitigation!
		hp -= reduced_damage
		energy = min(max_energy, energy + 25.0)
		
		var is_parry = (weapon_type == "fists" or randf() < 0.35)
		var banner_txt = "⚡ PARRIED!" if is_parry else "🛡️ BLOCKED!"
		var banner_col = Color(0.35, 0.85, 1.0) if is_parry else Color(0.98, 0.85, 0.25)
		spawn_banner(banner_txt, banner_col)
		
		if audio_manager and audio_manager.has_method("play_block"):
			audio_manager.play_block()
			
		spawn_hit_sparks()
		
		var kb_dir = (global_position - attacker_pos).normalized()
		kb_dir.y = 0.0
		velocity += kb_dir * (knockback * 0.2)
		
		if hp <= 0:
			die(kb_dir)
		return

	# Direct Unblocked Hit
	hp -= amount
	energy = min(max_energy, energy + amount * 0.45 + 10.0)
	if battle_manager and battle_manager.has_method("add_super_mana"):
		battle_manager.add_super_mana(0.35)
	
	stagger_timer = 0.22
	stagger_intensity = clamp(amount / max(1.0, damage), 0.5, 2.0)
	
	var local_hit_dir = global_transform.basis.inverse() * (attacker_pos - global_position).normalized()
	flinch_yaw = -local_hit_dir.x * 22.0
	flinch_pitch = -clamp(local_hit_dir.z, 0.25, 1.0) * 22.0
	
	spawn_damage_number(amount)
	spawn_hit_sparks()
	
	var kb_dir = (global_position - attacker_pos).normalized()
	kb_dir.y = 0.1
	velocity += kb_dir * (knockback / max(0.6, unit_scale * 0.75))
	
	if hp <= 0:
		die(kb_dir)

func spawn_damage_number(amount: float) -> void:
	var is_crit = (amount >= damage * 1.1) or (unit_scale > 2.0)
	if battle_manager and battle_manager.is_massive_battle and not is_crit:
		if randf() > 0.15:
			return # In massive battles, only show 15% of non-crit damage numbers
	if not DamageNumberClass.can_spawn(is_crit):
		return
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = global_position + Vector3((randf() - 0.5) * 0.3, 1.85 * unit_scale, (randf() - 0.5) * 0.3)
	var color = Color(0.96, 0.62, 0.04) if team == Team.A else Color(0.23, 0.51, 0.96)
	dmg_label.setup(amount, is_crit, color)

func spawn_banner(banner_text: String, banner_color: Color) -> void:
	if not DamageNumberClass.can_spawn(true):
		return
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = global_position + Vector3(0, 2.1 * unit_scale, 0)
	dmg_label.setup_banner(banner_text, banner_color)

func spawn_hit_sparks() -> void:
	var is_heavy = unit_scale > 2.0
	if battle_manager and battle_manager.is_massive_battle and not is_heavy:
		if randf() > 0.2:
			return
	if not HitSparksClass.can_spawn(is_heavy):
		return
	var sparks := HitSparksClass.new()
	get_parent().add_child(sparks)
	sparks.trigger(global_position + Vector3(0, 1.2 * unit_scale, 0), is_heavy)

func die(kb_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	is_dead = true
	death_timer = 0.0
	
	# Determine realistic fall direction and ballistic flight
	if kb_dir.length_squared() > 0.01:
		var dot = kb_dir.dot(global_transform.basis.z)
		fall_pitch = 88.0 if dot > 0.0 else -88.0
		# Preserve and impart ballistic knockback momentum into ragdoll flight!
		velocity += kb_dir * (knockback * 1.6 / max(0.6, unit_scale * 0.75))
		velocity.y = max(velocity.y, randf_range(3.5, 7.5))
	else:
		fall_pitch = -88.0 if randf() > 0.35 else 88.0
		velocity = Vector3((randf() - 0.5) * 1.5, randf_range(1.5, 3.5), (randf() - 0.5) * 1.5)
		
	# Stop looping run or attack animation immediately so unit never runs in place while dying
	if anim_player:
		if death_anim_name != "" and anim_player.has_animation(death_anim_name):
			anim_player.play(death_anim_name, 0.1)
		else:
			anim_player.stop()

func force_cast_ultimate() -> void:
	if is_dead or is_ulting:
		return
	energy = max_energy
	ult_cooldown = 0.0
	cast_ultimate()

func cast_ultimate() -> void:
	if is_dead or is_ulting or ult_cooldown > 0:
		return
		
	is_ulting = true
	ult_timer = 0.0
	ult_hits_dealt = 0
	ult_cooldown = 6.0
	is_attacking = true
	velocity = Vector3.ZERO
	
	var banner_text = "⚡ ULTIMATE!"
	var banner_color = Color(1.0, 0.8, 0.2)
	
	match preset_id:
		"archer":
			banner_text = "🏹 ARROW STORM!"
			banner_color = Color("#10b981")
			ult_duration = 0.95
		"swordsman":
			banner_text = "🌪️ BLADE TEMPEST!"
			banner_color = Color("#f59e0b")
			ult_duration = 1.15
		"spearman":
			banner_text = "⚡ DRAGON PIERCE!"
			banner_color = Color("#f97316")
			ult_duration = 0.85
		"commando":
			banner_text = "💣 TACTICAL AIRSTRIKE!"
			banner_color = Color("#ef4444")
			ult_duration = 1.35
		"cyborg":
			banner_text = "⚡ EMP OVERCLOCK!"
			banner_color = Color("#38bdf8")
			ult_duration = 1.05
		"tyson":
			banner_text = "🥊 THUNDER SLAM!"
			banner_color = Color("#ec4899")
			ult_duration = 1.15
		"titan":
			banner_text = "🧌 CATACLYSM STOMP!"
			banner_color = Color("#eab308")
			ult_duration = 1.6
		_:
			banner_text = "⚡ BERSERK BURST!"
			banner_color = Color("#eab308")
			ult_duration = 1.0
			
	spawn_ult_banner(banner_text, banner_color)
	if audio_manager and audio_manager.has_method("play_ult_cast"):
		audio_manager.play_ult_cast()

func spawn_ult_banner(banner_text: String, banner_color: Color) -> void:
	var dmg_label = DamageNumberClass.new()
	get_parent().add_child(dmg_label)
	dmg_label.global_position = global_position + Vector3(0, 2.3 * unit_scale, 0)
	dmg_label.setup_banner(banner_text, banner_color)

func update_ultimate(delta: float) -> void:
	ult_timer += delta
	var t = clamp(ult_timer / ult_duration, 0.0, 1.0)
	
	match preset_id:
		"mage_fire", "mage_ice", "mage_lightning", "mage_holy", "mage_dark":
			# Ultimate Elemental Storm / Barrage!
			var shot_interval = 0.14
			var target_shots = int(ult_timer / shot_interval)
			while ult_hits_dealt < target_shots and ult_hits_dealt < 6:
				ult_hits_dealt += 1
				var aim_target = global_position + global_transform.basis.z * 18.0
				if is_instance_valid(target_unit) and not target_unit.is_dead:
					aim_target = target_unit.global_position
				var spread = Vector3((randf() - 0.5) * 6.0, 0, (randf() - 0.5) * 6.0)
				var proj = ArrowProjectileClass.new()
				get_parent().add_child(proj)
				var shoot_origin = global_position + Vector3(0, 2.2 * unit_scale, 0)
				proj.launch(shoot_origin, aim_target + spread, team, damage * 1.6, element)
				if audio_manager and audio_manager.has_method("play_ult_cast"):
					audio_manager.play_ult_cast()
					
		"archer":
			# Rapid-fire 7 flaming arrows in a sweeping arc!
			var shot_interval = 0.12
			var target_shots = int(ult_timer / shot_interval)
			while ult_hits_dealt < target_shots and ult_hits_dealt < 7:
				ult_hits_dealt += 1
				var aim_target = global_position + global_transform.basis.z * 16.0
				if is_instance_valid(target_unit) and not target_unit.is_dead:
					aim_target = target_unit.global_position
				var spread = Vector3((randf() - 0.5) * 5.0, 0, (randf() - 0.5) * 5.0)
				var arrow = ArrowProjectileClass.new()
				get_parent().add_child(arrow)
				var shoot_origin = global_position + Vector3(0, 1.35 * unit_scale, 0) + global_transform.basis.z * 0.4
				arrow.launch(shoot_origin, aim_target + spread, team, damage * 1.5)
				if audio_manager and audio_manager.has_method("play_bow_shoot"):
					audio_manager.play_bow_shoot()
					
		"swordsman":
			# 1080 degree spin + forward whirlwind dash
			if ult_hits_dealt == 0:
				ult_hits_dealt = 1
				var fx = UltimateEffectClass.new()
				get_parent().add_child(fx)
				fx.setup(UltimateEffectClass.EffectType.WHIRLWIND, global_position, Color(1.0, 0.75, 0.1), 4.5, ult_duration)
				if audio_manager and audio_manager.has_method("play_whirlwind"):
					audio_manager.play_whirlwind()
			
			rotation.y += delta * 24.0
			var forward_dir = global_transform.basis.z
			if is_instance_valid(target_unit) and not target_unit.is_dead:
				forward_dir = (target_unit.global_position - global_position).normalized()
			global_position += forward_dir * delta * 4.5
			ground_unit(delta)
			
			var hit_cycle = int(ult_timer / 0.3)
			if hit_cycle >= ult_hits_dealt and ult_hits_dealt < 4:
				ult_hits_dealt += 1
				damage_aoe_enemies(global_position, 4.2 * unit_scale, damage * 1.25, 7.0)
				if audio_manager and audio_manager.has_method("play_sword_slash"):
					audio_manager.play_sword_slash()
					
		"spearman":
			# Dragon thrust forward lunge
			if ult_hits_dealt == 0 and t >= 0.22:
				ult_hits_dealt = 1
				var dash_dir = global_transform.basis.z
				if is_instance_valid(target_unit) and not target_unit.is_dead:
					dash_dir = (target_unit.global_position - global_position).normalized()
				global_position += dash_dir * 6.5
				ground_unit(delta)
				damage_aoe_enemies(global_position, 3.8 * unit_scale, damage * 2.6, 12.0)
				
				var fx = UltimateEffectClass.new()
				get_parent().add_child(fx)
				fx.setup(UltimateEffectClass.EffectType.SHOCKWAVE, global_position, Color(1.0, 0.5, 0.1), 5.0, 0.7)
				if audio_manager and audio_manager.has_method("play_explosion"):
					audio_manager.play_explosion()
			elif ult_hits_dealt == 0:
				if model_root:
					model_root.position.z = -0.35
					
		"commando":
			# 3 artillery strikes on enemy positions
			var strike_interval = 0.32
			var target_strikes = int(ult_timer / strike_interval)
			while ult_hits_dealt < target_strikes and ult_hits_dealt < 3:
				ult_hits_dealt += 1
				var target_pos = global_position + global_transform.basis.z * 12.0
				if is_instance_valid(target_unit) and not target_unit.is_dead:
					target_pos = target_unit.global_position
				var blast_pos = target_pos + Vector3((randf() - 0.5) * 6.0, 0, (randf() - 0.5) * 6.0)
				if arena and arena.has_method("get_ground_height"):
					blast_pos.y = arena.get_ground_height(blast_pos.x, blast_pos.z)
					
				var fx = UltimateEffectClass.new()
				get_parent().add_child(fx)
				fx.setup(UltimateEffectClass.EffectType.AIRSTRIKE, blast_pos, Color(1.0, 0.3, 0.05), 4.5, 0.6)
				damage_aoe_enemies(blast_pos, 4.5, damage * 1.8, 10.0)
				if audio_manager and audio_manager.has_method("play_explosion"):
					audio_manager.play_explosion()
					
		"cyborg":
			# EMP Overclock blast
			if ult_hits_dealt == 0 and t >= 0.28:
				ult_hits_dealt = 1
				var fx = UltimateEffectClass.new()
				get_parent().add_child(fx)
				fx.setup(UltimateEffectClass.EffectType.EMP, global_position, Color(0.2, 0.8, 1.0), 6.5, 0.9)
				damage_aoe_enemies(global_position, 6.5 * unit_scale, damage * 2.2, 8.0, true)
				if audio_manager and audio_manager.has_method("play_emp"):
					audio_manager.play_emp()
					
		"tyson":
			# Thunder slam: jump up and crash down
			if t < 0.48:
				var jump_h = sin((t / 0.48) * PI * 0.5) * 2.4
				if model_root:
					model_root.position.y = jump_h
			else:
				if model_root:
					model_root.position.y = 0.0
				if ult_hits_dealt == 0:
					ult_hits_dealt = 1
					var fx = UltimateEffectClass.new()
					get_parent().add_child(fx)
					fx.setup(UltimateEffectClass.EffectType.SHOCKWAVE, global_position, Color(1.0, 0.2, 0.6), 6.5, 0.8)
					damage_aoe_enemies(global_position, 6.0, damage * 2.4, 8.0, false, 12.0)
					if audio_manager and audio_manager.has_method("play_explosion"):
						audio_manager.play_explosion()
						
		"titan":
			# Cataclysm Stomp
			if t < 0.45:
				if model_root:
					model_root.position.y = sin((t / 0.45) * PI) * 0.8
					model_root.rotation_degrees.x = -15.0
			else:
				if model_root:
					model_root.position.y = 0.0
					model_root.rotation_degrees.x = 0.0
				if ult_hits_dealt == 0:
					ult_hits_dealt = 1
					var fx = UltimateEffectClass.new()
					get_parent().add_child(fx)
					fx.setup(UltimateEffectClass.EffectType.STOMP, global_position, Color(1.0, 0.8, 0.1), 14.0, 1.2)
					damage_aoe_enemies(global_position, 13.0, damage * 2.2, 22.0, false, 15.0)
					if audio_manager and audio_manager.has_method("play_explosion"):
						audio_manager.play_explosion(true)
						
		_:
			if ult_hits_dealt == 0 and t >= 0.4:
				ult_hits_dealt = 1
				damage_aoe_enemies(global_position, 5.0, damage * 2.0, 10.0)
				if audio_manager and audio_manager.has_method("play_explosion"):
					audio_manager.play_explosion()

	if ult_timer >= ult_duration:
		is_ulting = false
		is_attacking = false
		if model_root:
			model_root.position = Vector3.ZERO
			model_root.rotation_degrees = Vector3.ZERO

func damage_aoe_enemies(center: Vector3, radius: float, dmg: float, kb: float, stun: bool = false, vertical_kb: float = 0.0) -> void:
	var opp_team = Team.B if team == Team.A else Team.A
	var opp_team_int = 1 if opp_team == Team.B else 0
	var candidates: Array = []
	if battle_manager and battle_manager.has_method("get_units_in_radius"):
		candidates = battle_manager.get_units_in_radius(center, radius, opp_team_int)
	else:
		var tree = get_tree()
		if tree:
			candidates = tree.get_nodes_in_group("units")
	
	var r_sq = radius * radius
	for u in candidates:
		if is_instance_valid(u) and not u.is_dead and u.team == opp_team:
			var d_sq = u.global_position.distance_squared_to(center)
			if d_sq <= r_sq:
				u.take_damage(dmg * (0.9 + randf() * 0.25), center)
				if stun:
					u.stagger_timer = 1.2
					u.stagger_intensity = 2.0
				if vertical_kb > 0.0:
					u.velocity.y += vertical_kb

