extends Camera3D

@export var move_speed: float = 10.0
@export var boost_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.003

var _rotation_y := 0.0
var _rotation_x := 0.0

func _ready() -> void:
	_rotation_y = rotation.y
	_rotation_x = rotation.x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotation_y -= event.relative.x * mouse_sensitivity
		_rotation_x -= event.relative.y * mouse_sensitivity
		_rotation_x = clamp(_rotation_x, -1.5, 1.5)
		rotation = Vector3(_rotation_x, _rotation_y, 0.0)

func focus_on(target: Vector3) -> void:
	position = target + Vector3(0, 12, 8)
	look_at(target, Vector3.UP)
	_rotation_x = rotation.x
	_rotation_y = rotation.y

func _process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_Z):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_Q):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	if Input.is_key_pressed(KEY_E):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_C):
		input_dir += Vector3.DOWN

	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= boost_multiplier
		position += input_dir * speed * delta
