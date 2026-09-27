class_name T1QTable
extends RefCounted

const SCHEMA_VERSION := "t1_q_table_v2"
const ACTION_COUNT := 8
const START_ACTION := 8

var alpha := 0.20
var gamma := 0.90
var config_fingerprint := ""
var episode_count := 0
var training_rng_state := 0
var _values: Dictionary = {}
var _applied_steps: Dictionary = {}

func configure(fingerprint: String, rng_state: int) -> void:
	config_fingerprint = fingerprint
	training_rng_state = rng_state

func begin_episode() -> void:
	_applied_steps.clear()

func state_key(targets: Array, previous_action: int) -> String:
	if targets.size() != 3 or previous_action < 0 or previous_action > START_ACTION:
		return ""
	var available_count := 0
	var available_sector := -1
	var available_distance := -1
	for target in targets:
		var sector := int(target.get("resource_sector", -1))
		var distance_bin := int(target.get("distance_bin", -1))
		if sector < 0 or sector >= ACTION_COUNT or distance_bin < 0 or distance_bin > 2 or not target.has("available"):
			return ""
		if bool(target["available"]):
			available_count += 1
			available_sector = sector
			available_distance = distance_bin
	if available_count > 1:
		return ""
	return "%d:%d:%d" % [available_sector, available_distance, previous_action]

func select_greedy(state: String) -> int:
	if not _values.has(state):
		return 0
	var values: Array = _values[state]
	var best_action := 0
	for action in range(1, ACTION_COUNT):
		if float(values[action]) > float(values[best_action]):
			best_action = action
	return best_action

func select_epsilon_greedy(state: String, epsilon: float, rng: RandomNumberGenerator) -> int:
	if epsilon > 0.0:
		if rng.randf() < epsilon:
			var random_action := rng.randi_range(0, ACTION_COUNT - 1)
			training_rng_state = rng.state
			return random_action
		training_rng_state = rng.state
	return select_greedy(state)

func apply_transition(step_index: int, state: String, action: int, reward: float, next_state: String, terminated: bool, training: bool) -> bool:
	if not training or step_index < 0 or _applied_steps.has(step_index) or state.is_empty() or action < 0 or action >= ACTION_COUNT:
		return false
	_applied_steps[step_index] = true
	var target := reward
	if not terminated:
		target += gamma * _max_value(next_state)
	var values := _state_values(state)
	values[action] = float(values[action]) + alpha * (target - float(values[action]))
	_values[state] = values
	return true

func finish_training_episode() -> void:
	episode_count += 1

func checksum() -> String:
	var keys: Array = _values.keys()
	keys.sort()
	var canonical: Array = []
	for key in keys:
		canonical.append([key, _values[key]])
	return JSON.stringify({"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": canonical})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "alpha": alpha, "gamma": gamma, "episode_count": episode_count, "training_rng_state": str(training_rng_state), "values_binary": Marshalls.raw_to_base64(var_to_bytes(_values))}
	file.store_string(JSON.stringify(payload))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T1QTable:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or parsed.get("schema_version", "") != SCHEMA_VERSION or parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	if not parsed.get("values_binary", "") is String or not parsed.get("training_rng_state", "") is String:
		return null
	var values = bytes_to_var(Marshalls.base64_to_raw(parsed["values_binary"]))
	if not values is Dictionary:
		return null
	var table = load("res://scripts/t1_q_table.gd").new()
	table.configure(expected_fingerprint, int(parsed["training_rng_state"]))
	table.alpha = float(parsed.get("alpha", -1.0))
	table.gamma = float(parsed.get("gamma", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if table.alpha < 0.0 or table.gamma < 0.0 or table.episode_count < 0:
		return null
	table._values = values
	return table

func _state_values(state: String) -> Array:
	if not _values.has(state):
		_values[state] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	return _values[state]

func _max_value(state: String) -> float:
	var values := _state_values(state)
	var maximum := float(values[0])
	for action in range(1, ACTION_COUNT):
		maximum = maxf(maximum, float(values[action]))
	return maximum
