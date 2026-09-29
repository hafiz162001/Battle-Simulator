extends Camera3D

enum CamMode { REELS, DRONE, ACTION, TOPDOWN }

var current_mode: CamMode = CamMode.DRONE
var target_pos := Vector3.ZERO
var lead_unit: Node3D = null

# Orbit parameters for Drone mode
var yaw := 0.0
var pitch := -18.0
var distance := 38.0

var move_speed := 35.0
var mouse_sensitivity := 0.22
var is_dragging := false
var auto_follow := true
var shake_amount := 0.0

var cam_attr: CameraAttributesPractical = null

func add_shake(intensity: float) -> void:
	shake_amount = clamp(shake_amount + intensity, 0.0, 3.0)

func _ready() -> void:
	current = true
	setup_cinematic_camera_attributes()
	update_camera_transform()

func setup_cinematic_camera_attributes() -> void:
	cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 65.0
	cam_attr.dof_blur_far_transition = 45.0
	cam_attr.dof_blur_near_enabled = false
	cam_attr.auto_exposure_enabled = false
	attributes = cam_attr

func set_mode(mode: CamMode) -> void:
	current_mode = mode
	auto_follow = true
	match current_mode:
		CamMode.REELS:
			pitch = -12.0
			distance = 22.0
			if cam_attr:
				cam_attr.dof_blur_far_enabled = true
				cam_attr.dof_blur_far_distance = 32.0
				cam_attr.dof_blur_far_transition = 25.0
		CamMode.DRONE:
			pitch = -22.0
			distance = 42.0
			if cam_attr:
				cam_attr.dof_blur_far_enabled = true
				cam_attr.dof_blur_far_distance = 75.0
				cam_attr.dof_blur_far_transition = 50.0
		CamMode.ACTION:
			pitch = -8.0
			distance = 8.0
			if cam_attr:
				cam_attr.dof_blur_far_enabled = true
				cam_attr.dof_blur_far_distance = 18.0
				cam_attr.dof_blur_far_transition = 14.0
		CamMode.TOPDOWN:
			pitch = -88.0
			distance = 55.0
			if cam_attr:
				cam_attr.dof_blur_far_enabled = false
	update_camera_transform()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if event.pressed and current_mode == CamMode.DRONE:
				auto_follow = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 3.5, 4.0, 180.0)
			update_camera_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 3.5, 4.0, 180.0)
			update_camera_transform()
			
	elif event is InputEventMouseMotion and is_dragging:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -89.0, 5.0)
		update_camera_transform()

func _process(delta: float) -> void:
	# WASD free flight in DRONE mode
	var move_vec := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move_vec -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		move_vec += global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		move_vec -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		move_vec += global_transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):
		auto_follow = true
		
	if move_vec.length_squared() > 0:
		auto_follow = false
		move_vec.y = 0
		target_pos += move_vec.normalized() * move_speed * delta
		update_camera_transform()
		
	if current_mode == CamMode.REELS:
		# Slight cinematic slow oscillation
		yaw += delta * 1.5
		update_camera_transform()
	elif current_mode == CamMode.ACTION and is_instance_valid(lead_unit):
		target_pos = target_pos.lerp(lead_unit.global_position + Vector3(0, 1.5, 0), delta * 8.0)
		yaw = lerp_angle(deg_to_rad(yaw), lead_unit.rotation.y + PI, delta * 5.0)
		yaw = rad_to_deg(yaw)
		update_camera_transform()
		
	if shake_amount > 0.0:
		shake_amount = max(0.0, shake_amount - delta * 2.5)
		update_camera_transform()

func set_target_center(center: Vector3, p_lead_unit: Node3D = null) -> void:
	lead_unit = p_lead_unit
	if auto_follow:
		if current_mode == CamMode.ACTION and is_instance_valid(lead_unit):
			target_pos = target_pos.lerp(lead_unit.global_position + Vector3(0, 1.5, 0), 0.1)
		else:
			target_pos = target_pos.lerp(center, 0.08)
		update_camera_transform()

func update_camera_transform() -> void:
	var rot_yaw := deg_to_rad(yaw)
	var rot_pitch := deg_to_rad(pitch)
	
	var offset := Vector3(
		sin(rot_yaw) * cos(rot_pitch),
		-sin(rot_pitch),
		cos(rot_yaw) * cos(rot_pitch)
	) * distance
	
	var shake_offset := Vector3.ZERO
	if shake_amount > 0.0:
		var s = shake_amount * 0.8
		shake_offset = Vector3((randf() - 0.5) * s, (randf() - 0.5) * s, (randf() - 0.5) * s)
		
	global_position = target_pos + offset + shake_offset
	look_at(target_pos, Vector3.UP)
