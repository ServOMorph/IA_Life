extends RefCounted

const RONCE_CLEARANCE := 3.0
const SPAWN_CLEARANCE := 5.0
const DECOR_CLEARANCE := 1.5
const WALL_MARGIN := 3.0
const MAX_ATTEMPTS := 50

static func pick(rng: RandomNumberGenerator, half: float, ronces: Array, spawns: Array, placed: Array) -> Dictionary:
	for attempt in MAX_ATTEMPTS:
		var candidate := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if is_valid(candidate, ronces, spawns, placed):
			return {"position": candidate, "attempts": attempt + 1}
	return {}

static func is_valid(candidate: Vector2, ronces: Array, spawns: Array, placed: Array) -> bool:
	if not _clear_of(candidate, ronces, RONCE_CLEARANCE):
		return false
	if not _clear_of(candidate, spawns, SPAWN_CLEARANCE):
		return false
	return _clear_of(candidate, placed, DECOR_CLEARANCE)

static func _clear_of(candidate: Vector2, others: Array, minimum: float) -> bool:
	var minimum_squared := minimum * minimum
	for other in others:
		if candidate.distance_squared_to(other) < minimum_squared:
			return false
	return true
