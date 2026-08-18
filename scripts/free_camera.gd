extends Camera3D

enum Mode { FREE, FOLLOW, FPS, ORBIT }

const INITIAL_POSITION := Vector3(0, 60, 80)
const INITIAL_ROTATION_DEGREES := Vector3(-30, 0, 0)
const FOLLOW_OFFSET := Vector3(0, 12, 8)
const FOLLOW_ZOOM_MIN := 0.3
const FOLLOW_ZOOM_MAX := 3.0
const FOLLOW_ZOOM_STEP := 0.1
const FPS_EYE_HEIGHT := 1.2
const FPS_FORWARD_OFFSET := 0.25
const FPS_YAW_LIMIT := 1.5708
const FPS_PITCH_LIMIT := 1.1
const ORBIT_HEIGHT := 1.5
const ORBIT_DISTANCE_DEFAULT := 6.0
const ORBIT_DISTANCE_MIN := 3.0
const ORBIT_DISTANCE_MAX := 15.0
const ORBIT_DISTANCE_STEP := 0.5
const ORBIT_PITCH_LIMIT := 1.2

@export var move_speed: float = 10.0
@export var boost_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.003

var _rotation_y := 0.0
var _rotation_x := 0.0
var _mode: Mode = Mode.FREE
var _follow_target: Node3D = null
var _follow_zoom := 1.0
var _previous_snapshot: Dictionary = {}
var _fps_yaw_offset := 0.0
var _fps_pitch := 0.0
var _orbit_target: Node3D = null
var _orbit_yaw := 0.0
var _orbit_pitch := -0.3
var _orbit_distance := ORBIT_DISTANCE_DEFAULT

func _ready() -> void:
	reset_view()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if _mode == Mode.FPS:
			_fps_yaw_offset = clamp(_fps_yaw_offset - event.relative.x * mouse_sensitivity, -FPS_YAW_LIMIT, FPS_YAW_LIMIT)
			_fps_pitch = clamp(_fps_pitch - event.relative.y * mouse_sensitivity, -FPS_PITCH_LIMIT, FPS_PITCH_LIMIT)
		elif _mode == Mode.ORBIT:
			_orbit_yaw -= event.relative.x * mouse_sensitivity
			_orbit_pitch = clamp(_orbit_pitch - event.relative.y * mouse_sensitivity, -ORBIT_PITCH_LIMIT, ORBIT_PITCH_LIMIT)
		else:
			_rotation_y -= event.relative.x * mouse_sensitivity
			_rotation_x -= event.relative.y * mouse_sensitivity
			_rotation_x = clamp(_rotation_x, -1.5, 1.5)
			rotation = Vector3(_rotation_x, _rotation_y, 0.0)
	elif event is InputEventMouseButton and event.pressed and _mode == Mode.FOLLOW:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_follow_zoom = clamp(_follow_zoom - FOLLOW_ZOOM_STEP, FOLLOW_ZOOM_MIN, FOLLOW_ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_follow_zoom = clamp(_follow_zoom + FOLLOW_ZOOM_STEP, FOLLOW_ZOOM_MIN, FOLLOW_ZOOM_MAX)
	elif event is InputEventMouseButton and event.pressed and _mode == Mode.ORBIT:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_distance = clamp(_orbit_distance - ORBIT_DISTANCE_STEP, ORBIT_DISTANCE_MIN, ORBIT_DISTANCE_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_distance = clamp(_orbit_distance + ORBIT_DISTANCE_STEP, ORBIT_DISTANCE_MIN, ORBIT_DISTANCE_MAX)

func start_orbit(target: Node3D) -> void:
	_save_snapshot()
	_mode = Mode.ORBIT
	_orbit_target = target
	_orbit_yaw = 0.0
	_orbit_pitch = -0.3
	_orbit_distance = ORBIT_DISTANCE_DEFAULT

func stop_orbit() -> void:
	_orbit_target = null
	_restore_previous()

func follow(target: Node3D) -> void:
	_mode = Mode.FOLLOW
	_follow_target = target
	_follow_zoom = 1.0

func toggle_character(target: Node3D) -> String:
	if _mode == Mode.FOLLOW and _follow_target == target:
		_mode = Mode.FPS
		_fps_yaw_offset = 0.0
		_fps_pitch = 0.0
		return "fps"
	elif _mode == Mode.FPS and _follow_target == target:
		_restore_previous()
		return "restored"
	else:
		_save_snapshot()
		follow(target)
		return "follow"

func _save_snapshot() -> void:
	_previous_snapshot = {
		"mode": _mode,
		"target": _follow_target,
		"position": position,
		"rotation_degrees": rotation_degrees,
		"follow_zoom": _follow_zoom,
	}

func _restore_previous() -> void:
	if _previous_snapshot.is_empty():
		reset_view()
		return
	_mode = _previous_snapshot.mode
	_follow_target = _previous_snapshot.target
	_follow_zoom = _previous_snapshot.follow_zoom
	if _mode == Mode.FREE:
		position = _previous_snapshot.position
		rotation_degrees = _previous_snapshot.rotation_degrees
		_rotation_x = rotation.x
		_rotation_y = rotation.y
	_previous_snapshot = {}

func reset_view() -> void:
	_mode = Mode.FREE
	_follow_target = null
	_follow_zoom = 1.0
	_previous_snapshot = {}
	position = INITIAL_POSITION
	rotation_degrees = INITIAL_ROTATION_DEGREES
	_rotation_x = rotation.x
	_rotation_y = rotation.y

func _process(delta: float) -> void:
	if _mode == Mode.FOLLOW and _follow_target != null:
		position = _follow_target.position + FOLLOW_OFFSET * _follow_zoom
		look_at(_follow_target.position, Vector3.UP)
		_rotation_x = rotation.x
		_rotation_y = rotation.y
		return

	if _mode == Mode.FPS and _follow_target != null:
		var target_forward: Vector3 = -_follow_target.global_transform.basis.z
		position = _follow_target.position + Vector3(0, FPS_EYE_HEIGHT, 0) + target_forward * FPS_FORWARD_OFFSET
		var target_yaw: float = _follow_target.rotation.y
		rotation = Vector3(_fps_pitch, target_yaw + _fps_yaw_offset, 0.0)
		return

	if _mode == Mode.ORBIT and _orbit_target != null:
		var pivot: Vector3 = _orbit_target.position + Vector3(0, ORBIT_HEIGHT, 0)
		var offset := Vector3(
			sin(_orbit_yaw) * cos(_orbit_pitch),
			sin(_orbit_pitch),
			cos(_orbit_yaw) * cos(_orbit_pitch)
		) * _orbit_distance
		position = pivot + offset
		look_at(pivot, Vector3.UP)
		return

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
