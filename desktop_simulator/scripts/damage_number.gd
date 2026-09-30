class_name DamageNumber
extends Label3D

var lifetime: float = 0.75
var timer: float = 0.0
var rise_speed: float = 2.5
var start_scale: Vector3 = Vector3(1.2, 1.2, 1.2)

static var active_count: int = 0
const MAX_ACTIVE: int = 35

static func can_spawn(is_critical: bool = false) -> bool:
	if is_critical:
		return active_count < (MAX_ACTIVE + 15)
	return active_count < MAX_ACTIVE

func _ready() -> void:
	active_count += 1
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	font_size = 32
	outline_size = 8
	outline_modulate = Color(0, 0, 0, 0.9)
	scale = start_scale

func _exit_tree() -> void:
	active_count = max(0, active_count - 1)

func setup(amount: float, is_critical: bool, team_color: Color) -> void:
	if is_critical:
		text = "💥 -" + str(int(amount)) + "!"
		modulate = Color(1.0, 0.3, 0.2)
		start_scale = Vector3(1.8, 1.8, 1.8)
	else:
		text = "-" + str(int(amount))
		modulate = team_color
		start_scale = Vector3(1.2, 1.2, 1.2)
	scale = start_scale

func setup_banner(banner_text: String, banner_color: Color) -> void:
	text = banner_text
	modulate = banner_color
	font_size = 40
	outline_size = 12
	outline_modulate = Color(0.05, 0.05, 0.05, 0.95)
	start_scale = Vector3(2.2, 2.2, 2.2)
	scale = start_scale
	lifetime = 1.3
	rise_speed = 3.2

func _process(delta: float) -> void:
	timer += delta
	var progress = timer / lifetime
	
	global_position.y += rise_speed * delta
	scale = start_scale.lerp(Vector3(0.5, 0.5, 0.5), progress)
	modulate.a = 1.0 - progress
	
	if timer >= lifetime:
		queue_free()
