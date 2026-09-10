extends RefCounted

const CLEARANCE := 0.8
const ARRIVAL := 0.8
const MAX_SECONDS := 30.0

var target: Dictionary = {}
var obstacle: Dictionary = {}
var side := 0.0
var elapsed := 0.0
var phase := ""
var reason := ""
var _progress_position := Vector3.ZERO
var _stalled_seconds := 0.0
var _reversed := false

func reset(why: String = "") -> void:
	target = {}
	obstacle = {}
	side = 0.0
	elapsed = 0.0
	phase = ""
	reason = why
	_stalled_seconds = 0.0
	_reversed = false

static func flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0.0, value.z)

static func blocks(start: Vector3, finish: Vector3, zone: Dictionary) -> bool:
	var segment := flat(finish - start)
	if segment.is_zero_approx():
		return false
	var center := flat(Vector3(zone["position"]) - start)
	var projection := clampf(center.dot(segment) / segment.length_squared(), 0.0, 1.0)
	return (center - segment * projection).length() < float(zone["radius"]) + CLEARANCE

func steer(position: Vector3, candidate: Dictionary, zones: Array, delta: float, invalid_ids: Array = []) -> Vector3:
	reason = ""
	if not target.is_empty():
		elapsed += delta
		if invalid_ids.has(target["id"]) or elapsed >= MAX_SECONDS:
			reset("target_invalid" if invalid_ids.has(target["id"]) else "timeout")
			return Vector3.ZERO
		if flat(Vector3(target["position"]) - position).length() <= ARRIVAL:
			reset("arrived")
			return Vector3.ZERO
	var destination: Dictionary = candidate if target.is_empty() else target
	if destination.is_empty():
		return Vector3.ZERO
	var finish := Vector3(destination["position"])
	if not obstacle.is_empty() and not blocks(position, finish, obstacle):
		obstacle = {}
		phase = "resume"
	if obstacle.is_empty():
		var nearest := INF
		for zone in zones:
			var distance := flat(Vector3(zone["position"]) - position).length_squared()
			if blocks(position, finish, zone) and distance < nearest:
				obstacle = zone.duplicate()
				nearest = distance
		if not obstacle.is_empty():
			if target.is_empty():
				target = destination.duplicate()
				elapsed = 0.0
			var radial := flat(position - Vector3(obstacle["position"])).normalized()
			if radial.is_zero_approx():
				radial = -flat(finish - position).normalized()
			var tangent := Vector3(-radial.z, 0.0, radial.x)
			side = 1.0 if tangent.dot(flat(finish - position)) >= 0.0 else -1.0
			phase = "detour"
			_progress_position = position
			_stalled_seconds = 0.0
			_reversed = false
	if target.is_empty():
		return Vector3.ZERO
	if obstacle.is_empty():
		return flat(finish - position).normalized()
	if flat(position - _progress_position).length() >= 0.2:
		_progress_position = position
		_stalled_seconds = 0.0
	else:
		_stalled_seconds += delta
	if _stalled_seconds >= 2.0 and not _reversed:
		side = -side
		_reversed = true
		reason = "blocked_reverse"
		_stalled_seconds = 0.0
	var offset := flat(position - Vector3(obstacle["position"]))
	var distance := offset.length()
	var outward := offset.normalized() if distance > 0.001 else -flat(finish - position).normalized()
	var radius := float(obstacle["radius"]) + CLEARANCE
	var tangent := Vector3(-outward.z, 0.0, outward.x) * side
	# Un champ tangent avec rappel radial garde le côté choisi jusqu'à visibilité directe.
	return (tangent + outward * clampf((radius - distance) * 2.0, -1.0, 2.0)).normalized()
