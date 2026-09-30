class_name T2QTable
extends RefCounted

const SCHEMA_VERSION := "t2_q_table_v1"
const ACTION_COUNT := 8

var alpha := 0.20
var config_fingerprint := ""
var episode_count := 0
var training_rng_state := 0
var _values: Dictionary = {}
var _counts: Dictionary = {}
var _applied := false

func configure(fingerprint: String, rng_state: int) -> void:
	config_fingerprint = fingerprint
	training_rng_state = rng_state

func begin_episode() -> void:
	_applied = false

func state_key(observation: Dictionary) -> String:
	if not bool(observation.get("decision_started", false)) or not observation.get("visible_targets", []).is_empty():
		return ""
	var remembered := int(observation.get("last_seen_sector", -1))
	if remembered == -1:
		return "current_empty"
	return "memory:%d" % remembered if remembered >= 0 and remembered < ACTION_COUNT else ""

func select_greedy(state: String) -> int:
	var values: Array = _values.get(state, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var best := 0
	for action in range(1, ACTION_COUNT):
		if float(values[action]) > float(values[best]):
			best = action
	return best

func select_training(state: String) -> int:
	var counts: Array = _counts.get(state, [0, 0, 0, 0, 0, 0, 0, 0])
	var selected := 0
	for action in range(1, ACTION_COUNT):
		if int(counts[action]) < int(counts[selected]):
			selected = action
	return selected

func apply_transition(state: String, action: int, reward: float, training: bool) -> bool:
	if not training or _applied or state.is_empty() or action < 0 or action >= ACTION_COUNT:
		return false
	_applied = true
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
	return JSON.stringify({"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": _canonical(_values), "counts": _canonical(_counts)})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "alpha": alpha, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values)), "counts_binary": Marshalls.raw_to_base64(var_to_bytes(_counts))}
	file.store_string(JSON.stringify(payload))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T2QTable:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != SCHEMA_VERSION or parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed.get("values_binary", "")))
	var counts = bytes_to_var(Marshalls.base64_to_raw(parsed.get("counts_binary", "")))
	if not values is Dictionary or not counts is Dictionary or not parsed.get("training_rng_state", "") is String:
		return null
	var table = load("res://scripts/t2_q_table.gd").new()
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
