class_name T1V5Table
extends RefCounted

const SCHEMA_VERSION := "t1_q_table_v5"
const ACTION_COUNT := 8

var alpha := 0.20
var config_fingerprint := ""
var episode_count := 0
var training_rng_state := 0
var _values: Dictionary = {}
var _counts: Dictionary = {}
var _first_applied := false

func configure(fingerprint: String, rng_state: int) -> void:
	config_fingerprint = fingerprint
	training_rng_state = rng_state

func begin_episode() -> void:
	_first_applied = false

func state_key(targets: Array, previous_action: int) -> String:
	if targets.size() != 3 or previous_action != 8:
		return ""
	var available_count := 0
	var available_sector := -1
	for target in targets:
		var sector := int(target.get("resource_sector", -1))
		var distance_bin := int(target.get("distance_bin", -1))
		if sector < 0 or sector >= ACTION_COUNT or distance_bin < 0 or distance_bin > 2 or not target.has("available"):
			return ""
		if bool(target["available"]):
			available_count += 1
			available_sector = sector
	return str(available_sector) if available_count == 1 else ""

func select_greedy(state: String) -> int:
	var values: Array = _values.get(state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var best := 0
	for action in range(1, ACTION_COUNT):
		if float(values[action]) > float(values[best]):
			best = action
	return best

func select_epsilon_greedy(state: String, epsilon: float, _rng: RandomNumberGenerator) -> int:
	if epsilon <= 0.0:
		return select_greedy(state)
	var counts: Array = _counts.get(state, [0, 0, 0, 0, 0, 0, 0, 0])
	var selected := 0
	for action in range(1, ACTION_COUNT):
		if int(counts[action]) < int(counts[selected]):
			selected = action
	return selected

func apply_transition(step_index: int, state: String, action: int, reward: float, _next_state: String, _terminated: bool, training: bool) -> bool:
	if not training or step_index != 0 or _first_applied or state.is_empty() or action < 0 or action >= ACTION_COUNT:
		return false
	_first_applied = true
	var values: Array = _values.get(state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	values[action] = float(values[action]) + alpha * (reward - float(values[action]))
	_values[state] = values
	var counts: Array = _counts.get(state, [0, 0, 0, 0, 0, 0, 0, 0])
	counts[action] = int(counts[action]) + 1
	_counts[state] = counts
	return true

func finish_training_episode() -> void:
	episode_count += 1

func checksum() -> String:
	return JSON.stringify({"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": _canonical(_values), "first_counts": _canonical(_counts)})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "alpha": alpha, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values)), "counts_binary": Marshalls.raw_to_base64(var_to_bytes(_counts))}
	file.store_string(JSON.stringify(payload))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T1V5Table:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != SCHEMA_VERSION or parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	if not parsed.get("values_binary", "") is String or not parsed.get("counts_binary", "") is String or not parsed.get("training_rng_state", "") is String:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed["values_binary"]))
	var counts = bytes_to_var(Marshalls.base64_to_raw(parsed["counts_binary"]))
	if not values is Dictionary or not counts is Dictionary:
		return null
	var table = load("res://scripts/t1_v5_table.gd").new()
	table.configure(expected_fingerprint, int(parsed["training_rng_state"]))
	table.alpha = float(parsed.get("alpha", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if table.alpha < 0.0 or table.episode_count < 0:
		return null
	table._values = values
	table._counts = counts
	return table

func _canonical(source: Dictionary) -> Array:
	var keys: Array = source.keys()
	keys.sort()
	var canonical: Array = []
	for key in keys:
		canonical.append([key, source[key]])
	return canonical
