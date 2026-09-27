class_name T1V4Table
extends "res://scripts/t1_v3_table.gd"

const V4_SCHEMA := "t1_q_table_v4"

var _first_counts: Dictionary = {}

func select_epsilon_greedy(state: String, epsilon: float, rng: RandomNumberGenerator) -> int:
	if not state.ends_with(":8") or epsilon <= 0.0:
		return super.select_epsilon_greedy(state, epsilon, rng)
	var sector := state.get_slice(":", 0)
	var counts: Array = _first_counts.get(sector, [0, 0, 0, 0, 0, 0, 0, 0])
	var selected := 0
	for action in range(1, ACTION_COUNT):
		if int(counts[action]) < int(counts[selected]):
			selected = action
	return selected

func apply_transition(step_index: int, state: String, action: int, reward: float, next_state: String, terminated: bool, training: bool) -> bool:
	var applied := super.apply_transition(step_index, state, action, reward, next_state, terminated, training)
	if applied and step_index == 0:
		var sector := state.get_slice(":", 0)
		var counts: Array = _first_counts.get(sector, [0, 0, 0, 0, 0, 0, 0, 0])
		counts[action] = int(counts[action]) + 1
		_first_counts[sector] = counts
	return applied

func checksum() -> String:
	var first_keys := _first_values.keys()
	first_keys.sort()
	var first: Array = []
	for key in first_keys:
		first.append([key, _first_values[key]])
	var count_keys := _first_counts.keys()
	count_keys.sort()
	var counts: Array = []
	for key in count_keys:
		counts.append([key, _first_counts[key]])
	return JSON.stringify({"schema_version": V4_SCHEMA, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": _canonical_values(), "first_values": first, "first_counts": counts})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {"schema_version": V4_SCHEMA, "config_fingerprint": config_fingerprint, "alpha": alpha, "gamma": gamma, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values)), "first_values_binary": Marshalls.raw_to_base64(var_to_bytes(_first_values)), "first_counts_binary": Marshalls.raw_to_base64(var_to_bytes(_first_counts))}
	file.store_string(JSON.stringify(payload))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T1V4Table:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != V4_SCHEMA or parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	if not parsed.get("values_binary", "") is String or not parsed.get("first_values_binary", "") is String or not parsed.get("first_counts_binary", "") is String or not parsed.get("training_rng_state", "") is String:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed["values_binary"]))
	var first_values = bytes_to_var(Marshalls.base64_to_raw(parsed["first_values_binary"]))
	var first_counts = bytes_to_var(Marshalls.base64_to_raw(parsed["first_counts_binary"]))
	if not values is Dictionary or not first_values is Dictionary or not first_counts is Dictionary:
		return null
	var table = load("res://scripts/t1_v4_table.gd").new()
	table.configure(expected_fingerprint, int(parsed["training_rng_state"]))
	table.alpha = float(parsed.get("alpha", -1.0))
	table.gamma = float(parsed.get("gamma", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if table.alpha < 0.0 or table.gamma < 0.0 or table.episode_count < 0:
		return null
	table._values = values
	table._first_values = first_values
	table._first_counts = first_counts
	return table
