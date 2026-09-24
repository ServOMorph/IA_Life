extends Node

const T0QTable = preload("res://scripts/t0_q_table.gd")
const T0Scenario = preload("res://scripts/t0_scenario.gd")

const CHECKPOINTS := [0, 10, 50, 200, 1000]

var _output_path := ""
var _records: Array = []
var _training_cards: Array[int] = []
var _validation_cards: Array[int] = []
var _experiment_id := "t0_contract_v2"
var _fingerprint := "t0_contract_v2|resource_distance=2.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90"
var _resource_distance := 2.0
var _initialization_seeds: Array[int] = [310001001, 310001002, 310001003]
var _random_seed_base := 310002001
var _training_seed_start := 310000001
var _validation_seed_start := 310000101

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 3 and args[0] == "--probe" and args[1] == "--contract":
		if args[2] != "t0_contract_v3":
			push_error("Contrat T0 inconnu.")
			get_tree().quit(2)
			return
		_configure_v3()
		await _run_probe()
		get_tree().quit(0)
		return
	if args.size() == 1 and args[0] == "--probe":
		await _run_probe()
		get_tree().quit(0)
		return
	if args.size() == 3 and args[0] == "--calibrate-random":
		await _run_calibration(args[1], args[2])
		get_tree().quit(0)
		return
	if args.size() == 8 and args[6] == "--contract":
		if args[7] != "t0_contract_v3":
			push_error("Contrat T0 inconnu.")
			get_tree().quit(2)
			return
		_configure_v3()
		args = args.slice(0, 6)
	if args.size() != 6 or args[0] != "--output" or args[2] != "--kind" or args[4] != "--initialization-seed":
		push_error("Usage : --probe ou --output chemin --kind baseline|trained|reset --initialization-seed seed [--contract t0_contract_v3]")
		get_tree().quit(2)
		return
	_configure_cards()
	_output_path = args[1]
	var kind := args[3]
	var succeeded := true
	var initialization_seed := int(args[5])
	if initialization_seed not in _initialization_seeds:
		push_error("Seed d'initialisation T0 invalide.")
		get_tree().quit(2)
		return
	match kind:
		"baseline":
			await _evaluate_scripted(initialization_seed)
			await _evaluate_initial(initialization_seed)
			await _evaluate_random(initialization_seed)
		"trained":
			succeeded = await _train_and_evaluate(initialization_seed, false)
		"reset":
			succeeded = await _train_and_evaluate(initialization_seed, true)
		_:
			push_error("Type de lignée T0 invalide.")
			get_tree().quit(2)
			return
	if not succeeded:
		get_tree().quit(1)
		return
	if not _write_records():
		push_error("Écriture des résultats T0 impossible.")
		get_tree().quit(1)
		return
	print("SUCCÈS : campagne T0 terminée (%d résultats)." % _records.size())
	get_tree().quit(0)

func _run_probe() -> void:
	var started_ms := Time.get_ticks_msec()
	var table = _new_table(_initialization_seeds[0])
	var result := await _run_episode(table, _validation_seed_start, false, false)
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	print(JSON.stringify({
		"probe": _experiment_id,
		"elapsed_seconds": float(elapsed_ms) / 1000.0,
		"actions": result["actions"],
		"success": result["success"],
		"static_memory_bytes": OS.get_static_memory_usage(),
	}))

func _evaluate_scripted(initialization_seed: int) -> void:
	for card_seed in _validation_cards:
		var scenario = await _new_scenario(card_seed)
		var result: Dictionary = {}
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			result = await scenario.execute_action(scenario.resource_sector)
		_add_record("scripted", initialization_seed, card_seed, 0, result, "scripted")
		await _free_scenario(scenario)

func _evaluate_initial(initialization_seed: int) -> void:
	var table = _new_table(initialization_seed)
	for card_seed in _validation_cards:
		var result := await _run_episode(table, card_seed, false, false)
		_add_record("initial_frozen", initialization_seed, card_seed, 0, result, table.checksum())

func _evaluate_random(initialization_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _random_seed_base + _initialization_seeds.find(initialization_seed)
	for card_seed in _validation_cards:
		var result := await _run_random_episode(card_seed, rng)
		_add_record("random_valid", initialization_seed, card_seed, 0, result, "random:%d" % rng.state)

func _train_and_evaluate(initialization_seed: int, reset_each_episode: bool) -> bool:
	var table = _new_table(initialization_seed)
	var completed_episodes := 0
	for checkpoint in CHECKPOINTS:
		while completed_episodes < checkpoint:
			if reset_each_episode:
				table = _new_table(initialization_seed)
			var card_seed: int = _training_cards[completed_episodes % _training_cards.size()]
			await _run_episode(table, card_seed, true, true)
			table.finish_training_episode()
			completed_episodes += 1
		var arm := "reset_each_episode" if reset_each_episode else "trained"
		for card_seed in _validation_cards:
			var before: String = table.checksum()
			var result := await _run_episode(table, card_seed, false, false)
			if table.checksum() != before:
				push_error("L'évaluation T0 a modifié la table.")
				return false
			_add_record(arm, initialization_seed, card_seed, checkpoint, result, before)
	return true

func _new_table(initialization_seed: int):
	var table := T0QTable.new()
	table.configure(_fingerprint, initialization_seed)
	return table

func _run_episode(table, card_seed: int, training: bool, epsilon_enabled: bool) -> Dictionary:
	var scenario = await _new_scenario(card_seed, _resource_distance)
	table.begin_episode()
	var previous_action := T0QTable.START_ACTION
	var result: Dictionary = {}
	var step_index := 0
	var rng := RandomNumberGenerator.new()
	rng.state = table.training_rng_state
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var observation: Dictionary = scenario.observation(previous_action)
		var state: String = table.state_key(observation["resource_sector"], observation["resource_visible"], observation["previous_action"])
		var action: int = table.select_epsilon_greedy(state, 0.20 if epsilon_enabled else 0.0, rng)
		result = await scenario.execute_action(action)
		var next_state: String = table.state_key(scenario.resource_sector, true, action)
		table.apply_transition(step_index, state, action, float(result["reward"]), next_state, bool(result["terminated"]), bool(result["truncated"]), training)
		previous_action = action
		step_index += 1
	if training:
		table.training_rng_state = rng.state
	result["actions"] = scenario.action_count
	await _free_scenario(scenario)
	return result

func _run_random_episode(card_seed: int, rng: RandomNumberGenerator, distance: float = T0Scenario.DEFAULT_RESOURCE_DISTANCE) -> Dictionary:
	var scenario = await _new_scenario(card_seed, distance)
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		result = await scenario.execute_action(rng.randi_range(0, 7))
	result["actions"] = scenario.action_count
	await _free_scenario(scenario)
	return result

func _new_scenario(card_seed: int, distance: float = T0Scenario.DEFAULT_RESOURCE_DISTANCE):
	var scenario = T0Scenario.new()
	scenario.configure(card_seed, distance)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _run_calibration(distance_str: String, rng_seed_str: String) -> void:
	var distance := float(distance_str)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rng_seed_str)
	var successes := 0
	var total := 0
	for card_seed in range(310000301, 310000333):
		var result := await _run_random_episode(card_seed, rng, distance)
		if bool(result.get("success", false)):
			successes += 1
		total += 1
	print(JSON.stringify({
		"distance": distance,
		"rng_seed": int(rng_seed_str),
		"successes": successes,
		"total": total,
		"success_rate": float(successes) / float(total),
	}))

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _add_record(arm: String, initialization_seed: int, card_seed: int, checkpoint: int, result: Dictionary, checksum: String) -> void:
	_records.append({
		"experiment_id": _experiment_id,
		"arm": arm,
		"initialization_seed": initialization_seed,
		"card_seed": card_seed,
		"checkpoint": checkpoint,
		"success": bool(result.get("success", false)),
		"terminated": bool(result.get("terminated", false)),
		"truncated": bool(result.get("truncated", false)),
		"actions": int(result.get("actions", 0)),
		"table_checksum": checksum,
		"config_fingerprint": _fingerprint,
	})

func _configure_v3() -> void:
	_experiment_id = "t0_contract_v3"
	_fingerprint = "t0_contract_v3|resource_distance=3.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90"
	_resource_distance = 3.0
	_initialization_seeds = [330001001, 330001002, 330001003]
	_random_seed_base = 330002001
	_training_seed_start = 330000001
	_validation_seed_start = 330000101

func _configure_cards() -> void:
	_training_cards.clear()
	_validation_cards.clear()
	for card_seed in range(_training_seed_start, _training_seed_start + 16):
		_training_cards.append(card_seed)
	for card_seed in range(_validation_seed_start, _validation_seed_start + 32):
		_validation_cards.append(card_seed)

func _write_records() -> bool:
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		return false
	for record in _records:
		file.store_line(JSON.stringify(record))
	file.close()
	return true
