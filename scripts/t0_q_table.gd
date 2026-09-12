class_name T0QTable
extends RefCounted

const SCHEMA_VERSION := "t0_q_table_v1"
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

func state_key(resource_sector: int, resource_visible: bool, previous_action: int) -> String:
	if resource_sector < 0 or resource_sector >= ACTION_COUNT:
		push_error("Secteur T0 invalide")
		return ""
	if previous_action < 0 or previous_action > START_ACTION:
		push_error("Action précédente T0 invalide")
		return ""
	return "%d:%d:%d" % [resource_sector, 1 if resource_visible else 0, previous_action]

func select_greedy(state: String) -> int:
	if not _values.has(state):
		return 0
	var values: Array = _values[state]
	var best_action := 0
	var best_value := float(values[0])
	for action in range(1, ACTION_COUNT):
		var value := float(values[action])
		if value > best_value:
			best_value = value
			best_action = action
	return best_action

func select_epsilon_greedy(state: String, epsilon: float, rng: RandomNumberGenerator) -> int:
	if epsilon > 0.0:
		if rng.randf() < epsilon:
			var random_action := rng.randi_range(0, ACTION_COUNT - 1)
			training_rng_state = rng.state
			return random_action
		var greedy_action := select_greedy(state)
		training_rng_state = rng.state
		return greedy_action
	return select_greedy(state)

func apply_transition(step_index: int, state: String, action: int, reward: float, next_state: String, terminated: bool, truncated: bool, training: bool = true) -> bool:
	if not training:
		return false
	if step_index < 0 or _applied_steps.has(step_index):
		return false
	if action < 0 or action >= ACTION_COUNT or state.is_empty():
		return false
	if terminated and truncated:
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
	var canonical: Array = []
	var keys := _values.keys()
	keys.sort()
	for key in keys:
		canonical.append([key, _values[key]])
	return JSON.stringify({"schema_version": SCHEMA_VERSION, "config_fingerprint": config_fingerprint, "episode_count": episode_count, "training_rng_state": training_rng_state, "values": canonical})

func save_checkpoint(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"schema_version": SCHEMA_VERSION,
		"config_fingerprint": config_fingerprint,
		"alpha": alpha,
		"gamma": gamma,
		"episode_count": episode_count,
		"training_rng_state": str(training_rng_state),
		"values": _values,
	}))
	file.close()
	return OK

static func load_checkpoint(path: String, expected_fingerprint: String) -> T0QTable:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return null
	if parsed.get("schema_version", "") != SCHEMA_VERSION:
		return null
	if parsed.get("config_fingerprint", "") != expected_fingerprint:
		return null
	if not parsed.get("values", {}) is Dictionary:
		return null
	var table = load("res://scripts/t0_q_table.gd").new()
	table.config_fingerprint = expected_fingerprint
	table.alpha = float(parsed.get("alpha", -1.0))
	table.gamma = float(parsed.get("gamma", -1.0))
	table.episode_count = int(parsed.get("episode_count", -1))
	if not parsed.has("training_rng_state") or not parsed["training_rng_state"] is String:
		return null
	table.training_rng_state = int(parsed["training_rng_state"])
	if table.alpha < 0.0 or table.gamma < 0.0 or table.episode_count < 0:
		return null
	table._values = parsed["values"]
	return table

func _state_values(state: String) -> Array:
	if not _values.has(state):
		_values[state] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	return _values[state]

func _max_value(state: String) -> float:
	var values := _state_values(state)
	var best := float(values[0])
	for action in range(1, ACTION_COUNT):
		best = maxf(best, float(values[action]))
	return best
