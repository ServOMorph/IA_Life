class_name VariableRegistry
extends RefCounted

## Source de vérité des variables expérimentales disponibles dans le prototype.
const GAME_CONFIG: Dictionary = {
	"max_berries_carried": {"type": "int", "min": 1, "max": 20},
	"pickup_hunger_threshold": {"type": "float", "min": 0.0, "max": 100.0},
	"eat_hunger_threshold": {"type": "float", "min": 0.0, "max": 100.0},
	"full_life_berries": {"type": "float", "min": 0.1, "max": 100.0},
	"ronce_count": {"type": "int", "min": 0, "max": 500},
	"berries_per_ronce": {"type": "int", "min": 0, "max": 100},
	"light_energy": {"type": "float", "min": 0.0, "max": 20.0},
}

const CHARACTER: Dictionary = {
	"move_speed": {"type": "float", "min": 0.0, "max": 20.0},
	"hunger": {"type": "float", "min": 0.0, "max": 100.0},
	"hunger_depletion_rate": {"type": "float", "min": 0.0, "max": 20.0},
	"aging_factor": {"type": "float", "min": 0.0, "max": 10.0},
	"feeding_capacity": {"type": "float", "min": 0.0, "max": 10.0},
	"memory_capacity": {"type": "int", "min": 0, "max": 100},
	"memory_decay_rate": {"type": "float", "min": 0.0, "max": 10.0},
	"exploration_tendency": {"type": "float", "min": 0.0, "max": 1.0},
	"social_radius": {"type": "float", "min": 0.0, "max": 250.0},
	"follow_probability": {"type": "float", "min": 0.0, "max": 1.0},
	"avoid_probability": {"type": "float", "min": 0.0, "max": 1.0},
}

static func validate_values(values: Dictionary, definitions: Dictionary, scope: String) -> PackedStringArray:
	var errors := PackedStringArray()
	for key_variant in values:
		var key := String(key_variant)
		if not definitions.has(key):
			errors.append("%s : variable inconnue '%s'" % [scope, key])
			continue
		var value = values[key_variant]
		var definition: Dictionary = definitions[key]
		var expected_type: String = definition["type"]
		var is_number := typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		var valid_type := (expected_type == "int" and is_number and is_equal_approx(float(value), roundf(float(value)))) or (expected_type == "float" and is_number)
		if not valid_type:
			errors.append("%s.%s : type %s attendu" % [scope, key, expected_type])
			continue
		var numeric_value := float(value)
		if numeric_value < float(definition["min"]) or numeric_value > float(definition["max"]):
			errors.append("%s.%s : valeur %s hors bornes [%s, %s]" % [scope, key, value, definition["min"], definition["max"]])
	return errors
