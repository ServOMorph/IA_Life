class_name T3QTable
extends RefCounted

const SCHEMA_VERSION := "t3_q_table_v1"
const ACTION_COUNT := 8

var alpha := 0.20
var gamma := 0.90
var config_fingerprint := ""
var episode_count := 0
var training_rng_state := 0
var schema_version := SCHEMA_VERSION
var _values: Dictionary = {}

func configure(fingerprint: String, rng_state: int, checkpoint_schema: String = SCHEMA_VERSION) -> void:
	config_fingerprint = fingerprint
	training_rng_state = rng_state
	schema_version = checkpoint_schema

func state_key(observation: Dictionary) -> String:
	var source := "none"
	var sector := 8
	var distance_bin := 3
	for target in observation.get("targets", []):
		if float(target[0]) > 0.5 and float(target[4]) > 0.5:
			source = "visible"
			sector = _sector(float(target[1]), float(target[2]))
			distance_bin = _distance_bin(float(target[3]))
			break
	if source == "none":
		for memory in observation.get("memories", []):
			if float(memory[0]) > 0.5:
				source = "memory"
				sector = _sector(float(memory[1]), float(memory[2]))
				distance_bin = _distance_bin(float(memory[3]))
				break
	var hunger_values: Array = observation.get("hunger", [])
	var hunger := float(hunger_values[0]) if hunger_values.size() == 1 else -1.0
	var inventory_values: Array = observation.get("inventory", [])
	var inventory := float(inventory_values[0]) if inventory_values.size() == 1 else -1.0
	var previous := int(observation.get("previous_action", -1))
	if hunger < 0.0 or hunger > 1.0 or inventory < 0.0 or inventory > 1.0 or previous < 0 or previous > 8:
		return ""
	return "%s:%d:%d:%d:%d:%d" % [source, sector, distance_bin, mini(3, int(hunger * 4.0)), 1 if inventory > 0.0 else 0, previous]

func select_greedy(state: String) -> int:
	var values: Array = _values.get(state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var best := 0
	for action in range(1, ACTION_COUNT):
		if float(values[action]) > float(values[best]):
			best = action
	return best

func select_epsilon_greedy(state: String, epsilon: float, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(0, ACTION_COUNT - 1) if rng.randf() < epsilon else select_greedy(state)

func apply_transition(state: String, action: int, reward: float, next_state: String, terminated: bool, training: bool) -> bool:
	if not training or state.is_empty() or next_state.is_empty() or action < 0 or action >= ACTION_COUNT:
		return false
	var values: Array = _values.get(state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var target := reward
	if not terminated:
		var next_values: Array = _values.get(next_state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
		target += gamma * float(next_values.max())
	values[action] = float(values[action]) + alpha * (target - float(values[action]))
	_values[state] = values
	return true

func finish_training_episode() -> void:
	episode_count += 1

func checksum() -> String:
	return JSON.stringify({"schema_version": schema_version, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": _canonical(_values)})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema_version": schema_version, "config_fingerprint": config_fingerprint, "alpha": alpha, "gamma": gamma, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values))}))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String, expected_schema: String = SCHEMA_VERSION) -> T3QTable:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != expected_schema or parsed.get("config_fingerprint", "") != expected_fingerprint or not parsed.get("training_rng_state", "") is String:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed.get("values_binary", "")))
	if not values is Dictionary:
		return null
	var table = load("res://scripts/t3_q_table.gd").new()
	table.configure(expected_fingerprint, int(parsed["training_rng_state"]), expected_schema)
	table.alpha = float(parsed.get("alpha", -1.0))
	table.gamma = float(parsed.get("gamma", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if table.alpha < 0.0 or table.gamma < 0.0 or table.episode_count < 0:
		return null
	table._values = values
	return table

func _sector(x: float, z: float) -> int:
	var direction := Vector3(x, 0.0, z).normalized()
	var directions := [Vector3.FORWARD, Vector3(1, 0, -1).normalized(), Vector3.RIGHT, Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3(-1, 0, 1).normalized(), Vector3.LEFT, Vector3(-1, 0, -1).normalized()]
	var best := 0
	for index in range(1, directions.size()):
		if direction.dot(directions[index]) > direction.dot(directions[best]):
			best = index
	return best

func _distance_bin(normalized_distance: float) -> int:
	if normalized_distance <= 0.05:
		return 0
	if normalized_distance <= 0.12:
		return 1
	return 2

func _canonical(source: Dictionary) -> Array:
	var keys: Array = source.keys()
	keys.sort()
	var result: Array = []
	for key in keys:
		result.append([key, source[key]])
	return result
