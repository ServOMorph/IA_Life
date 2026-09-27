class_name T1V3Table
extends "res://scripts/t1_q_table.gd"

const V3_SCHEMA := "t1_q_table_v3"

var _first_values: Dictionary = {}

func select_epsilon_greedy(state: String, epsilon: float, rng: RandomNumberGenerator) -> int:
	if not state.ends_with(":8"):
		return super.select_epsilon_greedy(state, epsilon, rng)
	if epsilon > 0.0:
		if rng.randf() < 0.50:
			var action := rng.randi_range(0, ACTION_COUNT - 1)
			training_rng_state = rng.state
			return action
		training_rng_state = rng.state
	return _first_greedy(state.get_slice(":", 0))

func apply_transition(step_index: int, state: String, action: int, reward: float, next_state: String, terminated: bool, training: bool) -> bool:
	var applied := super.apply_transition(step_index, state, action, reward, next_state, terminated, training)
	if applied and step_index == 0:
		var sector := state.get_slice(":", 0)
		if not _first_values.has(sector):
			_first_values[sector] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		var values: Array = _first_values[sector]
		values[action] = float(values[action]) + alpha * (reward - float(values[action]))
		_first_values[sector] = values
	return applied

func checksum() -> String:
	var first_keys := _first_values.keys()
	first_keys.sort()
	var first: Array = []
	for key in first_keys:
		first.append([key, _first_values[key]])
	return JSON.stringify({"schema_version": V3_SCHEMA, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": _canonical_values(), "first_values": first})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {"schema_version": V3_SCHEMA, "config_fingerprint": config_fingerprint, "alpha": alpha, "gamma": gamma, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values)), "first_values_binary": Marshalls.raw_to_base64(var_to_bytes(_first_values))}
	file.store_string(JSON.stringify(payload))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T1V3Table:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != V3_SCHEMA or parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	if not parsed.get("values_binary", "") is String or not parsed.get("first_values_binary", "") is String or not parsed.get("training_rng_state", "") is String:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed["values_binary"]))
	var first_values = bytes_to_var(Marshalls.base64_to_raw(parsed["first_values_binary"]))
	if not values is Dictionary or not first_values is Dictionary:
		return null
	var table = load("res://scripts/t1_v3_table.gd").new()
	table.configure(expected_fingerprint, int(parsed["training_rng_state"]))
	table.alpha = float(parsed.get("alpha", -1.0))
	table.gamma = float(parsed.get("gamma", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if table.alpha < 0.0 or table.gamma < 0.0 or table.episode_count < 0:
		return null
	table._values = values
	table._first_values = first_values
	return table

func _first_greedy(sector: String) -> int:
	if not _first_values.has(sector):
		return 0
	var values: Array = _first_values[sector]
	var best := 0
	for action in range(1, ACTION_COUNT):
		if float(values[action]) > float(values[best]):
			best = action
	return best

func _canonical_values() -> Array:
	var keys := _values.keys()
	keys.sort()
	var canonical: Array = []
	for key in keys:
		canonical.append([key, _values[key]])
	return canonical
