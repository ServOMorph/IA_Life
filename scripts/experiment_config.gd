class_name ExperimentConfig
extends RefCounted

const FORMAT_VERSION := 1

var normalized: Dictionary = {}
var errors := PackedStringArray()

static func from_raw(raw: Dictionary) -> ExperimentConfig:
	var config := ExperimentConfig.new()
	config._normalize(raw)
	return config

func is_valid() -> bool:
	return errors.is_empty()

func _normalize(raw: Dictionary) -> void:
	var environment: Dictionary = raw.get("environment", {})
	var agents: Dictionary = raw.get("agents", {})
	var simulation: Dictionary = raw.get("simulation", {})
	var raw_events = raw.get("events", [])
	if not environment is Dictionary:
		errors.append("environment doit être un objet JSON")
		environment = {}
	if not agents is Dictionary:
		errors.append("agents doit être un objet JSON")
		agents = {}
	if not simulation is Dictionary:
		errors.append("simulation doit être un objet JSON")
		simulation = {}
	if not raw_events is Array:
		errors.append("events doit être une liste JSON")
		raw_events = []

	var seed_value = raw.get("seed", environment.get("seed", 1337))
	var seed_is_number := typeof(seed_value) == TYPE_INT or typeof(seed_value) == TYPE_FLOAT
	if not seed_is_number or seed_value < 0 or not is_equal_approx(float(seed_value), roundf(float(seed_value))):
		errors.append("seed doit être un entier positif ou nul")
		seed_value = 1337
	else:
		seed_value = int(seed_value)
	var game_config: Dictionary = raw.get("game_config", environment.get("game_config", environment.get("variables", {})))
	var character_defaults: Dictionary = raw.get("character_defaults", agents.get("defaults", {}))
	var character_overrides: Dictionary = agents.get("individual", agents.get("overrides", {}))
	if not game_config is Dictionary:
		errors.append("environment.game_config doit être un objet JSON")
		game_config = {}
	if not character_defaults is Dictionary:
		errors.append("agents.defaults doit être un objet JSON")
		character_defaults = {}
	if not character_overrides is Dictionary:
		errors.append("agents.individual doit être un objet JSON")
		character_overrides = {}

	errors.append_array(VariableRegistry.validate_values(game_config, VariableRegistry.GAME_CONFIG, "environment.game_config"))
	errors.append_array(VariableRegistry.validate_values(character_defaults, VariableRegistry.CHARACTER, "agents.defaults"))
	errors.append_array(_validate_social_probabilities(character_defaults, "agents.defaults"))
	for agent_name_variant in character_overrides:
		var agent_name := String(agent_name_variant)
		var values = character_overrides[agent_name_variant]
		if not values is Dictionary:
			errors.append("agents.individual.%s doit être un objet JSON" % agent_name)
			continue
		errors.append_array(VariableRegistry.validate_values(values, VariableRegistry.CHARACTER, "agents.individual.%s" % agent_name))
		var effective_values := character_defaults.duplicate()
		effective_values.merge(values, true)
		errors.append_array(_validate_social_probabilities(effective_values, "agents.individual.%s" % agent_name))

	var game_speed = simulation.get("game_speed", raw.get("game_speed", 1.0))
	if not (typeof(game_speed) == TYPE_INT or typeof(game_speed) == TYPE_FLOAT) or game_speed < 0.0 or game_speed > 80.0:
		errors.append("simulation.game_speed doit être compris entre 0 et 80")
		game_speed = 1.0
	var max_wall_seconds = simulation.get("max_wall_seconds", raw.get("max_wall_seconds", 120.0))
	if not (typeof(max_wall_seconds) == TYPE_INT or typeof(max_wall_seconds) == TYPE_FLOAT) or max_wall_seconds <= 0.0:
		errors.append("simulation.max_wall_seconds doit être positif")
		max_wall_seconds = 120.0
	var events := _normalize_events(raw_events)

	normalized = {
		"format_version": FORMAT_VERSION,
		"experiment_id": String(raw.get("experiment_id", "unnamed")),
		"seed": seed_value,
		"environment": {"game_config": game_config},
		"agents": {"defaults": character_defaults, "individual": character_overrides},
		"simulation": {"game_speed": float(game_speed), "quit_on_all_dead": bool(simulation.get("quit_on_all_dead", raw.get("quit_on_all_dead", true))), "max_wall_seconds": float(max_wall_seconds)},
		"events": events,
		"metadata": raw.get("metadata", {}),
	}
	if raw.has("screenshot"):
		normalized["screenshot"] = raw["screenshot"]
	normalized["config_sha256"] = JSON.stringify(normalized).sha256_text()

func _validate_social_probabilities(values: Dictionary, scope: String) -> PackedStringArray:
	var errors := PackedStringArray()
	var follow = values.get("follow_probability", 0.0)
	var avoid = values.get("avoid_probability", 0.0)
	if not (typeof(follow) == TYPE_INT or typeof(follow) == TYPE_FLOAT):
		return errors
	if not (typeof(avoid) == TYPE_INT or typeof(avoid) == TYPE_FLOAT):
		return errors
	if float(follow) + float(avoid) > 1.0:
		errors.append("%s : follow_probability + avoid_probability ne doit pas dépasser 1" % scope)
	return errors

func _normalize_events(raw_events: Array) -> Array:
	var events: Array = []
	for index in raw_events.size():
		var raw_event = raw_events[index]
		if not raw_event is Dictionary:
			errors.append("events[%d] doit être un objet JSON" % index)
			continue
		var event_type := String(raw_event.get("type", ""))
		var at_seconds = raw_event.get("at_seconds", -1.0)
		if not (typeof(at_seconds) == TYPE_INT or typeof(at_seconds) == TYPE_FLOAT) or at_seconds < 0.0:
			errors.append("events[%d].at_seconds doit être positif ou nul" % index)
			continue
		match event_type:
			"remove_ronces_fraction":
				var fraction = raw_event.get("fraction", -1.0)
				if not (typeof(fraction) == TYPE_INT or typeof(fraction) == TYPE_FLOAT) or fraction < 0.0 or fraction > 1.0:
					errors.append("events[%d].fraction doit être compris entre 0 et 1" % index)
					continue
				events.append({"type": event_type, "at_seconds": float(at_seconds), "fraction": float(fraction)})
			"spawn_ronces":
				var count = raw_event.get("count", 0)
				var valid_count: bool = (typeof(count) == TYPE_INT or typeof(count) == TYPE_FLOAT) and is_equal_approx(float(count), roundf(float(count))) and count >= 1 and count <= 500
				if not valid_count:
					errors.append("events[%d].count doit être un entier compris entre 1 et 500" % index)
					continue
				events.append({"type": event_type, "at_seconds": float(at_seconds), "count": int(count)})
			_:
				errors.append("events[%d].type inconnu : %s" % [index, event_type])
	events.sort_custom(func(a, b): return a["at_seconds"] < b["at_seconds"])
	return events
