class_name DangerZonePlacement
extends RefCounted

const MODE_ALEATOIRE := "aleatoire"
const MODE_APPROCHE_RONCIER := "approche_roncier"

static func approach_position(spawn_position: Vector3, ronce_position: Vector3, radius: float, clearance: float) -> Vector3:
	var from_spawn := ronce_position - spawn_position
	from_spawn.y = 0.0
	if from_spawn.length_squared() <= 0.0001:
		return Vector3.ZERO
	var position := ronce_position - from_spawn.normalized() * (radius + clearance)
	position.y = ronce_position.y
	return position
