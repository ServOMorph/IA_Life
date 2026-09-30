extends Node

const T1QTable = preload("res://scripts/t1_q_table.gd")
const T1V3Table = preload("res://scripts/t1_v3_table.gd")
const T1V4Table = preload("res://scripts/t1_v4_table.gd")
const T1V5Table = preload("res://scripts/t1_v5_table.gd")
const T1Scenario = preload("res://scripts/t1_scenario.gd")
const FINGERPRINT := "t1_choice_v2|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|state=available_sector_distance_previous"
const FINGERPRINT_V3 := "t1_choice_v3|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_bandit=sector|first_epsilon=0.50"
const FINGERPRINT_V4 := "t1_choice_v4|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_explore=min_count|first_tie=lowest"
const FINGERPRINT_V5 := "t1_choice_v5|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|first_explore=min_count|first_tie=lowest|execution=hold_first"
const CHECKPOINTS := [0, 10, 50, 200, 1000]

var _output_path := ""
var _records: Array = []
var _training_cards: Array[int] = []
var _validation_cards: Array[int] = []
var _fingerprint := FINGERPRINT
var _experiment_id := "t1_choice_v2"
var _seed_base := 320000000
var _initialization_base := 320001000
var _random_base := 320002000
var _table_script = T1QTable
var _contract := "v2"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var contract := args[args.size() - 1] if args.size() >= 2 and args[args.size() - 2] == "--contract" else "v2"
	_contract = contract
	if contract == "v3":
		_fingerprint = FINGERPRINT_V3
		_experiment_id = "t1_choice_v3"
		_seed_base = 350000000
		_initialization_base = 350001000
		_random_base = 350002000
		_table_script = T1V3Table
	elif contract == "v4":
		_fingerprint = FINGERPRINT_V4
		_experiment_id = "t1_choice_v4"
		_seed_base = 360000000
		_initialization_base = 360001000
		_random_base = 360002000
		_table_script = T1V4Table
	elif contract == "v5":
		_fingerprint = FINGERPRINT_V5
		_experiment_id = "t1_choice_v5"
		_seed_base = 370000000
		_initialization_base = 370001000
		_random_base = 370002000
		_table_script = T1V5Table
	elif contract != "v2":
		push_error("Contrat T1 inconnu")
		get_tree().quit(2)
		return
	for seed_value in range(_seed_base + 1, _seed_base + 33):
		_training_cards.append(seed_value)
	for seed_value in range(_seed_base + 101, _seed_base + 133):
		_validation_cards.append(seed_value)
	if (args.size() == 1 or args.size() == 3) and args[0] == "--probe":
		await _run_probe()
		get_tree().quit(0)
		return
	if args.size() != (6 if contract == "v2" else 8) or args[0] != "--output" or args[2] != "--kind" or args[4] != "--initialization-seed":
		push_error("Usage : --output chemin --kind baseline|trained|reset --initialization-seed seed")
		get_tree().quit(2)
		return
	_output_path = args[1]
	var initialization_seed := int(args[5])
	if initialization_seed not in [_initialization_base + 1, _initialization_base + 2, _initialization_base + 3]:
		push_error("Seed d'initialisation T1 invalide.")
		get_tree().quit(2)
		return
	match args[3]:
		"baseline":
			await _evaluate_scripted(initialization_seed)
			await _evaluate_initial(initialization_seed)
			await _evaluate_random(initialization_seed)
		"trained":
			await _train_and_evaluate(initialization_seed, false)
		"reset":
			await _train_and_evaluate(initialization_seed, true)
		_:
			push_error("Type de lignée T1 invalide.")
			get_tree().quit(2)
			return
	if not _write_records():
		push_error("Écriture des résultats T1 impossible.")
		get_tree().quit(1)
		return
	print("SUCCÈS : campagne T1 terminée (%d résultats)." % _records.size())
	get_tree().quit(0)

func _run_probe() -> void:
	var started_ms := Time.get_ticks_msec()
	var scenario = await _new_scenario(_seed_base + 1)
	var result: Dictionary = {}
	var action := _available_action(scenario)
	if _contract == "v5":
		result = await scenario.execute_held_action(action)
	else:
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			result = await scenario.execute_action(action)
	result["elapsed_seconds"] = float(Time.get_ticks_msec() - started_ms) / 1000.0
	result["static_memory_bytes"] = OS.get_static_memory_usage()
	print(JSON.stringify(result))
	await _free_scenario(scenario)

func _evaluate_scripted(initialization_seed: int) -> void:
	for card_seed in _validation_cards:
		var scenario = await _new_scenario(card_seed)
		var result: Dictionary = {}
		var action := _available_action(scenario)
		if _contract == "v5":
			result = await scenario.execute_held_action(action)
		else:
			while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
				result = await scenario.execute_action(action)
		_add_record("scripted_observed", initialization_seed, card_seed, 0, result, "scripted")
		await _free_scenario(scenario)

func _evaluate_initial(initialization_seed: int) -> void:
	var table = _new_table(initialization_seed)
	for card_seed in _validation_cards:
		var result := await _run_episode(table, card_seed, false, false)
		_add_record("initial_frozen", initialization_seed, card_seed, 0, result, table.checksum())

func _evaluate_random(initialization_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _random_base + 1 + (initialization_seed - _initialization_base - 1)
	for card_seed in _validation_cards:
		var result := await _run_random_episode(card_seed, rng)
		_add_record("random_valid", initialization_seed, card_seed, 0, result, "random:%d" % rng.state)

func _train_and_evaluate(initialization_seed: int, reset_each_episode: bool) -> void:
	var table = _new_table(initialization_seed)
	var completed := 0
	for checkpoint in CHECKPOINTS:
		while completed < checkpoint:
			if reset_each_episode:
				table = _new_table(initialization_seed)
			await _run_episode(table, _training_cards[completed % _training_cards.size()], true, true)
			table.finish_training_episode()
			completed += 1
		var arm := "reset_each_episode" if reset_each_episode else "trained"
		var evaluation_table = table
		if not reset_each_episode:
			var checkpoint_path := "%s.%d.%d.checkpoint.json" % [_output_path, initialization_seed, checkpoint]
			if table.save_checkpoint(checkpoint_path) != OK:
				push_error("Sauvegarde T1 impossible.")
				get_tree().quit(1)
				return
			evaluation_table = _table_script.load_checkpoint(checkpoint_path, _fingerprint)
			if evaluation_table == null or evaluation_table.checksum() != table.checksum():
				push_error("Recharge T1 divergente.")
				get_tree().quit(1)
				return
		for card_seed in _validation_cards:
			var checksum: String = evaluation_table.checksum()
			var result := await _run_episode(evaluation_table, card_seed, false, false)
			if evaluation_table.checksum() != checksum:
				push_error("L'évaluation T1 a modifié la table.")
				return
			_add_record(arm, initialization_seed, card_seed, checkpoint, result, checksum)

func _new_table(initialization_seed: int):
	var table = _table_script.new()
	table.configure(_fingerprint, initialization_seed)
	return table

func _run_episode(table, card_seed: int, training: bool, epsilon_enabled: bool) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	table.begin_episode()
	var previous_action := T1QTable.START_ACTION
	var result: Dictionary = {}
	var step_index := 0
	var rng := RandomNumberGenerator.new()
	rng.state = table.training_rng_state
	if _contract == "v5":
		var observation: Dictionary = scenario.observation(previous_action)
		var state: String = table.state_key(observation["targets"], observation["previous_action"])
		var action: int = table.select_epsilon_greedy(state, 0.20 if epsilon_enabled else 0.0, rng)
		result = await scenario.execute_held_action(action)
		var training_reward := float(result["first_reward"]) + 0.50 * float(result["first_distance_progress"]) if training else float(result["first_reward"])
		table.apply_transition(0, state, action, training_reward, "", true, training)
		if training:
			table.training_rng_state = rng.state
		await _free_scenario(scenario)
		return result
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var observation: Dictionary = scenario.observation(previous_action)
		var state: String = table.state_key(observation["targets"], observation["previous_action"])
		var action: int = table.select_epsilon_greedy(state, 0.20 if epsilon_enabled else 0.0, rng)
		result = await scenario.execute_action(action)
		var next_observation: Dictionary = scenario.observation(action)
		var next_state: String = table.state_key(next_observation["targets"], action)
		var training_reward: float = float(result["reward"]) + 0.50 * float(result["distance_progress"]) if training else float(result["reward"])
		table.apply_transition(step_index, state, action, training_reward, next_state, bool(result["terminated"]), training)
		previous_action = action
		step_index += 1
	if training:
		table.training_rng_state = rng.state
	await _free_scenario(scenario)
	return result

func _run_random_episode(card_seed: int, rng: RandomNumberGenerator) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	var result: Dictionary = {}
	if _contract == "v5":
		result = await scenario.execute_held_action(rng.randi_range(0, 7))
	else:
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			result = await scenario.execute_action(rng.randi_range(0, 7))
	await _free_scenario(scenario)
	return result

func _new_scenario(card_seed: int):
	var scenario := T1Scenario.new()
	scenario.configure(card_seed)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _available_action(scenario) -> int:
	for slot in scenario.observation(T1QTable.START_ACTION)["targets"]:
		if bool(slot["available"]):
			return int(slot["resource_sector"])
	return -1

func _add_record(arm: String, initialization_seed: int, card_seed: int, checkpoint: int, result: Dictionary, checksum: String) -> void:
	_records.append({"experiment_id": _experiment_id, "arm": arm, "initialization_seed": initialization_seed, "card_seed": card_seed, "checkpoint": checkpoint, "consumed": bool(result.get("consumed", false)), "first_selected_available": bool(result.get("first_selected_available", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "terminated": bool(result.get("terminated", false)), "truncated": bool(result.get("truncated", false)), "actions": int(result.get("actions", 0)), "table_checksum": checksum, "config_fingerprint": _fingerprint})

func _write_records() -> bool:
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		return false
	for record in _records:
		file.store_line(JSON.stringify(record))
	file.close()
	return true
