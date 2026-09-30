extends Node3D

const BattleUnit = preload("res://scripts/unit.gd")
const CharacterData = preload("res://scripts/character_data.gd")
const SuperUltWhooshGarudaClass = preload("res://scripts/super_ult_whoosh_garuda.gd")

@onready var arena: Node3D = $"../DesertArena"
@onready var camera: Camera3D = $"../Camera3D"
@onready var ui: CanvasLayer = $"../UI"
@onready var audio_mgr: Node = $"../AudioManager"

var loaded_models: Dictionary = {}
var custom_models: Dictionary = {}

var units: Array = []
var is_running: bool = false
var battle_time: float = 0.0

var count_a: int = 60
var count_b: int = 60
var preset_a: String = "commando"
var preset_b: String = "cyborg"
var model_a_id: String = "soldier"
var model_b_id: String = "xbot"

var team_a_alive: int = 0
var team_b_alive: int = 0
var battle_finished: bool = false

var alive_units_a: Array = []
var alive_units_b: Array = []
var spatial_grid_a: Dictionary = {}
var spatial_grid_b: Dictionary = {}
const CELL_SIZE: float = 3.2

func _ready() -> void:
	load_builtin_models()
	scan_custom_models()
	setup_battle()

func load_builtin_models() -> void:
	if ResourceLoader.exists("res://models/Soldier.glb"):
		loaded_models["soldier"] = load("res://models/Soldier.glb")
	if ResourceLoader.exists("res://models/Xbot.glb"):
		loaded_models["xbot"] = load("res://models/Xbot.glb")
	if ResourceLoader.exists("res://models/RobotExpressive.glb"):
		loaded_models["robot_expressive"] = load("res://models/RobotExpressive.glb")

func scan_custom_models() -> void:
	var dir_path = "res://../custom_models"
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".glb") or file_name.ends_with(".gltf")):
				var full_path = ProjectSettings.globalize_path(dir_path) + "/" + file_name
				load_custom_model_from_file(full_path, file_name)
			file_name = dir.get_next()

func load_custom_model_from_file(file_path: String, model_name: String) -> String:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	var err = doc.append_from_file(file_path, state)
	if err == OK:
		var scene = doc.generate_scene(state)
		var packed = PackedScene.new()
		packed.pack(scene)
		var custom_id = "custom_" + model_name.get_basename()
		loaded_models[custom_id] = packed
		custom_models[custom_id] = "📁 " + model_name
		return custom_id
	return ""

func set_army_config(p_count_a: int, p_preset_a: String, p_model_a: String, p_count_b: int, p_preset_b: String, p_model_b: String) -> void:
	count_a = p_count_a
	preset_a = p_preset_a
	model_a_id = p_model_a
	count_b = p_count_b
	preset_b = p_preset_b
	model_b_id = p_model_b
	setup_battle()

func setup_battle() -> void:
	clear_battle()
	is_running = false
	battle_finished = false
	battle_time = 0.0
	Engine.time_scale = 1.0
	
	team_a_alive = count_a
	team_b_alive = count_b
	
	var conf_a = CharacterData.get_preset(preset_a).duplicate()
	var conf_b = CharacterData.get_preset(preset_b).duplicate()
	
	var scene_a = loaded_models.get(model_a_id, loaded_models.get("soldier"))
	var scene_b = loaded_models.get(model_b_id, loaded_models.get("xbot"))
	
	# Spawn Team A at x = -20.0
	spawn_army(BattleUnit.Team.A, count_a, scene_a, conf_a, -20.0, 1.0)
	
	# Spawn Team B at x = 20.0
	spawn_army(BattleUnit.Team.B, count_b, scene_b, conf_b, 20.0, -1.0)
	
	update_hud()

func update_hud() -> void:
	if ui and ui.has_method("update_stats"):
		ui.update_stats(team_a_alive, count_a, team_b_alive, count_b, battle_time, is_running, 0.0, 0.0)

func spawn_army(team: BattleUnit.Team, count: int, model_scene: PackedScene, config: Dictionary, _start_x: float, forward_dir: float) -> void:
	var max_cols: int = 30 if count > 200 else (20 if count > 80 else 10)
	var cols: int = clamp(int(ceil(sqrt(float(count) * 1.6))), 4, max_cols)
	var rows: int = int(ceil(float(count) / float(cols)))
	
	var usable_width_z: float = 36.0
	var spacing_z: float = clamp(usable_width_z / float(cols), 0.75, 1.4)
	
	var usable_depth_x: float = 28.0
	var spacing_x: float = clamp(usable_depth_x / float(max(rows, 1)), 0.65, 1.3)
	
	var actual_start_x: float = -6.5 if forward_dir > 0 else 6.5
	
	for i in range(count):
		var row = int(i / cols)
		var col = i % cols
		
		var px = actual_start_x + (-row * spacing_x if forward_dir > 0 else row * spacing_x) + (randf() - 0.5) * 0.15
		var pz = (col - (float(cols) - 1.0) * 0.5) * spacing_z + (randf() - 0.5) * 0.15
		var py = arena.get_ground_height(px, pz) if arena else 0.0
		
		var unit := BattleUnit.new()
		add_child(unit)
		unit.position = Vector3(px, py, pz)
		unit.rotation.y = PI / 2.0 if forward_dir > 0 else -PI / 2.0
		
		unit.setup(team, model_scene, config, audio_mgr, arena)
		units.append(unit)

func clear_battle() -> void:
	for u in units:
		if is_instance_valid(u):
			u.queue_free()
	units.clear()

func _process(delta: float) -> void:
	if is_running:
		battle_time += delta
		
	alive_units_a.clear()
	alive_units_b.clear()
	spatial_grid_a.clear()
	spatial_grid_b.clear()
	
	var energy_sum_a: float = 0.0
	var energy_sum_b: float = 0.0
	var center_sum: Vector3 = Vector3.ZERO
	var lead_unit: BattleUnit = null
	
	# Pass 1: Filter alive units and populate spatial hash grid
	for u in units:
		if is_instance_valid(u) and not u.is_dead:
			var cx = int(floor(u.global_position.x / CELL_SIZE))
			var cz = int(floor(u.global_position.z / CELL_SIZE))
			var ckey = Vector2i(cx, cz)
			
			if u.team == BattleUnit.Team.A:
				alive_units_a.append(u)
				energy_sum_a += u.energy
				if not spatial_grid_a.has(ckey):
					spatial_grid_a[ckey] = []
				spatial_grid_a[ckey].append(u)
				if lead_unit == null:
					lead_unit = u
			else:
				alive_units_b.append(u)
				energy_sum_b += u.energy
				if not spatial_grid_b.has(ckey):
					spatial_grid_b[ckey] = []
				spatial_grid_b[ckey].append(u)
				
			center_sum += u.global_position
			
	team_a_alive = alive_units_a.size()
	team_b_alive = alive_units_b.size()
	var total_alive = team_a_alive + team_b_alive
	
	if total_alive > 0 and camera:
		camera.set_target_center(center_sum / float(total_alive), lead_unit)
		
	# Pass 2: Update units with ultra-fast spatial separation and cached target acquisition
	for team_idx in [0, 1]:
		var current_team_list = alive_units_a if team_idx == 0 else alive_units_b
		var enemy_team_list = alive_units_b if team_idx == 0 else alive_units_a
		var grid = spatial_grid_a if team_idx == 0 else spatial_grid_b
		var march_x = 50.0 if team_idx == 0 else -50.0
		
		for u in current_team_list:
			var sep_force = Vector3.ZERO
			var sep_radius: float = 1.25 * float(u.unit_scale)
			var sep_radius_sq: float = sep_radius * sep_radius
			
			# Query only the 9 neighboring spatial cells instead of all units!
			var cx = int(floor(u.global_position.x / CELL_SIZE))
			var cz = int(floor(u.global_position.z / CELL_SIZE))
			
			for nx in range(cx - 1, cx + 2):
				for nz in range(cz - 1, cz + 2):
					var nkey = Vector2i(nx, nz)
					if grid.has(nkey):
						var neighbors = grid[nkey]
						for other in neighbors:
							if other == u:
								continue
							var diff = u.global_position - other.global_position
							diff.y = 0.0
							var d_sq = diff.length_squared()
							if d_sq < sep_radius_sq and d_sq > 0.001:
								var dist = sqrt(d_sq)
								sep_force += (diff / dist) * (1.0 - dist / sep_radius)
								
			if sep_force.length_squared() > 0.64:
				sep_force = sep_force.normalized() * 0.8
				
			# Fast smart enemy target selection
			var target: BattleUnit = null
			if is_instance_valid(u.target_unit) and not u.target_unit.is_dead and u.retarget_timer > 0.0:
				target = u.target_unit
			else:
				target = find_nearest_in_list(u, enemy_team_list)
				
			var forward_target = Vector3(march_x, 0.0, u.global_position.z)
			u.update_unit(delta, is_running, target, forward_target, sep_force)

	# Update HUD with pre-accumulated energy percentages (0 extra loops!)
	var avg_energy_a = (energy_sum_a / float(team_a_alive)) if team_a_alive > 0 else 0.0
	var avg_energy_b = (energy_sum_b / float(team_b_alive)) if team_b_alive > 0 else 0.0
	if ui and ui.has_method("update_stats"):
		ui.update_stats(team_a_alive, count_a, team_b_alive, count_b, battle_time, is_running, avg_energy_a, avg_energy_b)
		
	# Check battle conclusion
	if is_running and not battle_finished:
		if team_a_alive == 0 or team_b_alive == 0:
			is_running = false
			battle_finished = true
			if audio_mgr:
				audio_mgr.play_victory()
			if ui and ui.has_method("show_victory"):
				var winner_name = "KUBU A (" + CharacterData.get_preset(preset_a).get("name") + ")" if team_a_alive > 0 else "KUBU B (" + CharacterData.get_preset(preset_b).get("name") + ")"
				var survivors = team_a_alive if team_a_alive > 0 else team_b_alive
				ui.show_victory(winner_name, survivors, battle_time)

func find_nearest_in_list(unit: BattleUnit, enemy_list: Array) -> BattleUnit:
	var nearest: BattleUnit = null
	var min_dist_sq := INF
	var u_pos = unit.global_position
	
	var list_size = enemy_list.size()
	var step = 1
	if list_size > 300:
		step = 5
	elif list_size > 120:
		step = 2
		
	for i in range(0, list_size, step):
		var other = enemy_list[i]
		if is_instance_valid(other) and not other.is_dead:
			var d_sq = u_pos.distance_squared_to(other.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = other
				
	return nearest

func start_battle() -> void:
	is_running = true
	battle_finished = false
	if audio_mgr:
		audio_mgr.play_horn()

func toggle_pause() -> bool:
	is_running = not is_running
	return is_running

func set_speed(speed: float) -> void:
	Engine.time_scale = speed

func trigger_team_ultimate(p_team: BattleUnit.Team) -> void:
	var list = alive_units_a if p_team == BattleUnit.Team.A else alive_units_b
	for u in list:
		if is_instance_valid(u) and not u.is_dead:
			u.force_cast_ultimate()

func get_team_energy_percent(p_team: BattleUnit.Team) -> float:
	var list = alive_units_a if p_team == BattleUnit.Team.A else alive_units_b
	if list.size() == 0:
		return 0.0
	var total: float = 0.0
	for u in list:
		if is_instance_valid(u):
			total += u.energy
	return clamp(total / float(list.size()), 0.0, 100.0)

func spawn_super_ult_train(p_team: int = 0) -> void:
	var train := SuperUltWhooshGarudaClass.new()
	add_child(train)
	train.launch(p_team, camera, audio_mgr, arena)

func trigger_super_ultimate(p_team: int = 0) -> void:
	if ui and ui.has_method("play_super_ult_cutscene"):
		ui.play_super_ult_cutscene(p_team)
	else:
		spawn_super_ult_train(p_team)
