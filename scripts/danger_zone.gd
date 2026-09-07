class_name DangerZone
extends Area3D

## Zone statique v3. Le coût est calculé par Character afin que les zones qui se
## chevauchent appliquent une seule fois leur taux maximal.

var zone_id: String = ""
var radius: float = 1.0
var hunger_cost_rate: float = 0.0

func is_character_exposed(world_position: Vector3) -> bool:
	var offset := world_position - global_position
	offset.y = 0.0
	return offset.length_squared() <= radius * radius

func get_perception_type() -> String:
	return "danger"

func get_perception_state() -> Dictionary:
	return {"zone_id": zone_id}

