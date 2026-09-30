extends Node

const T1Scenario = preload("res://scripts/t1_scenario.gd")
const T1V4Table = preload("res://scripts/t1_v4_table.gd")
const FINGERPRINT_V4 := "t1_choice_v4|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_explore=min_count|first_tie=lowest"
const MODES := ["learned", "hold_first", "retarget"]

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--checkpoint" or args[2] != "--output":
		push_error("Usage : --checkpoint chemin --output chemin")
		get_tree().quit(2)
		return
	var table = T1V4Table.load_checkpoint(args[1], FINGERPRINT_V4)
	if table == null or table.episode_count != 1000:
		push_error("Checkpoint T1 v4 invalide")
		get_tree().quit(1)
		return
	var initial_checksum: String = table.checksum()
	var file := FileAccess.open(args[3], FileAccess.WRITE)
	if file == null:
		push_error("Fichier de diagnostic inaccessible")
		get_tree().quit(1)
		return
	for card_seed in range(360000001, 360000033):
		for mode in MODES:
			var result: Dictionary = await _run_episode(table, card_seed, mode)
			result["card_seed"] = card_seed
			result["mode"] = mode
			file.store_line(JSON.stringify(result))
	file.close()
	if table.checksum() != initial_checksum:
		push_error("Le diagnostic a modifié le checkpoint")
		get_tree().quit(1)
		return
	print("SUCCÈS : 96 diagnostics T1 v4 sur cartes d'entraînement.")
	get_tree().quit(0)

func _run_episode(table, card_seed: int, mode: String) -> Dictionary:
	var scenario := T1Scenario.new()
	scenario.configure(card_seed)
	add_child(scenario)
	await get_tree().physics_frame
	table.begin_episode()
	var available_index := _available_index(scenario)
	var available_sector := int(scenario.targets[available_index]["sector"])
	var available_distance := float(scenario.targets[available_index]["distance"])
	var target = scenario.ronces[available_index]
	var previous_action := 8
	var first_action := -1
	var actions: Array[int] = []
	var distances: Array[float] = [_horizontal_distance(scenario.character.global_position, target.global_position)]
	var positions: Array = [_position_array(scenario.character.global_position)]
	var result: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.state = table.training_rng_state
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var action := -1
		if mode == "retarget" and not actions.is_empty():
			action = _nearest_action(target.global_position - scenario.character.global_position)
		elif mode == "hold_first" and not actions.is_empty():
			action = first_action
		else:
			var observation: Dictionary = scenario.observation(previous_action)
			var state: String = table.state_key(observation["targets"], observation["previous_action"])
			action = table.select_epsilon_greedy(state, 0.0, rng)
		if actions.is_empty():
			first_action = action
		result = await scenario.execute_action(action)
		actions.append(action)
		previous_action = action
		distances.append(_horizontal_distance(scenario.character.global_position, target.global_position))
		positions.append(_position_array(scenario.character.global_position))
	var summary := {
		"available_sector": available_sector,
		"available_distance": available_distance,
		"first_action": first_action,
		"first_selected_available": first_action == available_sector,
		"consumed": bool(result["consumed"]),
		"actions": actions,
		"distances": distances,
		"positions": positions,
	}
	scenario.queue_free()
	await get_tree().physics_frame
	return summary

func _available_index(scenario) -> int:
	for index in range(scenario.targets.size()):
		if bool(scenario.targets[index]["available"]):
			return index
	return -1

func _nearest_action(delta: Vector3) -> int:
	var direction := Vector3(delta.x, 0.0, delta.z).normalized()
	var candidates := [Vector3.FORWARD, Vector3(1, 0, -1).normalized(), Vector3.RIGHT, Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3(-1, 0, 1).normalized(), Vector3.LEFT, Vector3(-1, 0, -1).normalized()]
	var best_action := 0
	var best_dot := -INF
	for action in range(8):
		var score := direction.dot(candidates[action])
		if score > best_dot:
			best_dot = score
			best_action = action
	return best_action

func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()

func _position_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
