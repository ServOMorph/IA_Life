extends RefCounted

const AGENT_RADIUS := 0.35
const MARGIN := 0.25
const LOOKAHEAD := 3.0
const SIDE_HOLD_SECONDS := 0.6
const STALL_SECONDS := 2.0
const STALL_DISTANCE := 0.2

var active := false
var side := 1.0
var detours_total := 0
var detour_seconds_total := 0.0
var failed_total := 0
var blocked_seconds := 0.0
var blocked_seconds_max := 0.0

var _side_timer := 0.0
var _progress_position := Vector3.ZERO
var _stalled_seconds := 0.0
var _flipped := false

static func flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)

func reset() -> void:
	active = false
	_side_timer = 0.0
	_stalled_seconds = 0.0
	_flipped = false

func steer(position: Vector3, direction: Vector3, obstacles: Array, delta: float) -> Vector3:
	var heading := flat(direction)
	if heading.is_zero_approx() or obstacles.is_empty():
		_leave()
		return direction
	heading = heading.normalized()
	var blocker: Dictionary = {}
	var nearest_ahead := INF
	var lateral_signed := 0.0
	for obstacle in obstacles:
		var relative := flat(Vector3(obstacle["position"]) - position)
		var ahead := relative.dot(heading)
		if ahead <= 0.0 or ahead > LOOKAHEAD:
			continue
		var lateral := heading.cross(relative).y
		if absf(lateral) >= float(obstacle["radius"]) + AGENT_RADIUS + MARGIN:
			continue
		if ahead < nearest_ahead:
			nearest_ahead = ahead
			blocker = obstacle
			lateral_signed = lateral
	if blocker.is_empty():
		_side_timer -= delta
		if _side_timer <= 0.0:
			_leave()
		return direction
	if not active:
		active = true
		detours_total += 1
		_progress_position = position
		_stalled_seconds = 0.0
		_flipped = false
		if _side_timer <= 0.0:
			side = 1.0 if lateral_signed > 0.0 else -1.0
	_side_timer = SIDE_HOLD_SECONDS
	detour_seconds_total += delta
	if flat(position - _progress_position).length() >= STALL_DISTANCE:
		_progress_position = position
		_stalled_seconds = 0.0
		blocked_seconds = 0.0
	else:
		_stalled_seconds += delta
		blocked_seconds += delta
		blocked_seconds_max = maxf(blocked_seconds_max, blocked_seconds)
	if _stalled_seconds >= STALL_SECONDS:
		_stalled_seconds = 0.0
		if not _flipped:
			side = -side
			_flipped = true
		else:
			failed_total += 1
	var tangent := Vector3(-heading.z, 0.0, heading.x) * side
	var urgency := clampf(2.0 - nearest_ahead / LOOKAHEAD, 1.0, 2.0)
	return (heading + tangent * urgency).normalized()

func _leave() -> void:
	active = false
	blocked_seconds = 0.0
