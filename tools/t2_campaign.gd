extends Node

const T2Scenario = preload("res://scripts/t2_scenario.gd")
const T2QTable = preload("res://scripts/t2_q_table.gd")
const FINGERPRINT := "t2_memory_v1|target=1|distances=3,6,9|sectors=8|fov=90|turn=180|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|explore=min_count|execution=hold_first"
const CHECKPOINTS := [0, 10, 50, 200, 1000]
const TRAINING_CARDS := 32

var _output_path := ""
var _records: Array = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] == "--probe":
		await _run_probe()
		get_tree().quit(0)
		return
	if args.size() != 6 or args[0] != "--output" or args[2] != "--kind" or args[4] != "--initialization-seed":
		push_error("Usage : --output chemin --kind baseline|trained_memory|trained_observation|reset --initialization-seed seed")
		get_tree().quit(2)
		return
	_output_path = args[1]
	var initialization_seed := int(args[5])
	if initialization_seed not in [380001001, 380001002, 380001003]:
		push_error("Seed d'initialisation T2 invalide.")
		get_tree().quit(2)
		return
	match args[3]:
		"baseline":
			await _evaluate_scripted(initialization_seed)
			await _evaluate_initial(initialization_seed)
			await _evaluate_random(initialization_seed)
		"trained_memory":
			await _train_and_evaluate(initialization_seed, true, false)
		"trained_observation":
			await _train_and_evaluate(initialization_seed, false, false)
		"reset":
			await _train_and_evaluate(initialization_seed, true, true)
		_:
			push_error("Type de lignée T2 invalide.")
			get_tree().quit(2)
			return
	if not _write_records():
		push_error("Écriture des résultats T2 impossible.")
		get_tree().quit(1)
		return
	print("SUCCÈS : campagne T2 terminée (%d résultats)." % _records.size())
	get_tree().quit(0)

func _run_probe() -> void:
	var started_ms := Time.get_ticks_msec()
	var result := await _run_scripted_episode(380000001, true)
	result["elapsed_seconds"] = float(Time.get_ticks_msec() - started_ms) / 1000.0
	result["static_memory_bytes"] = OS.get_static_memory_usage()
	print(JSON.stringify(result))

func _evaluate_scripted(initialization_seed: int) -> void:
	for card_seed in range(380000101, 380000133):
		var result := await _run_scripted_episode(card_seed, true)
		_add_record("scripted_memory", initialization_seed, card_seed, 0, result, "scripted")

func _evaluate_initial(initialization_seed: int) -> void:
	var table = _new_table(initialization_seed)
	for card_seed in range(380000101, 380000133):
		var result := await _run_episode(table, card_seed, true, false)
		_add_record("initial_memory_frozen", initialization_seed, card_seed, 0, result, table.checksum())

func _evaluate_random(initialization_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 380002001 + (initialization_seed - 380001001)
	for card_seed in range(380000101, 380000133):
		var scenario = await _new_scenario(card_seed)
		scenario.begin_decision(false)
		var result: Dictionary = await scenario.execute_held_action(rng.randi_range(0, 7))
		await _free_scenario(scenario)
		_add_record("random_valid", initialization_seed, card_seed, 0, result, "random:%d" % rng.state)

func _train_and_evaluate(initialization_seed: int, use_memory: bool, reset_each_episode: bool) -> void:
	var table = _new_table(initialization_seed)
	var completed := 0
	for checkpoint in CHECKPOINTS:
		while completed < checkpoint:
			if reset_each_episode:
				table = _new_table(initialization_seed)
			var training_index := (completed * 5) % TRAINING_CARDS
			await _run_episode(table, 380000001 + training_index, use_memory, true)
			table.finish_training_episode()
			completed += 1
		var evaluation_table = table
		if not reset_each_episode:
			var checkpoint_path := "%s.%d.%d.checkpoint.json" % [_output_path, initialization_seed, checkpoint]
			if table.save_checkpoint(checkpoint_path) != OK:
				push_error("Sauvegarde T2 impossible.")
				get_tree().quit(1)
				return
			evaluation_table = T2QTable.load_checkpoint(checkpoint_path, FINGERPRINT)
			if evaluation_table == null or evaluation_table.checksum() != table.checksum():
				push_error("Recharge T2 divergente.")
				get_tree().quit(1)
				return
		var arm := "reset_each_episode" if reset_each_episode else "trained_memory" if use_memory else "trained_observation_only"
		for card_seed in range(380000101, 380000133):
			var checksum: String = evaluation_table.checksum()
			var result := await _run_episode(evaluation_table, card_seed, use_memory, false)
			if evaluation_table.checksum() != checksum:
				push_error("L'évaluation T2 a modifié la table.")
				get_tree().quit(1)
				return
			_add_record(arm, initialization_seed, card_seed, checkpoint, result, checksum)

func _new_table(initialization_seed: int):
	var table := T2QTable.new()
	table.configure(FINGERPRINT, initialization_seed)
	return table

func _run_episode(table, card_seed: int, use_memory: bool, training: bool) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	table.begin_episode()
	if not scenario.begin_decision(use_memory):
		push_error("La perception initiale T2 a échoué.")
	var observation: Dictionary = scenario.observation(use_memory)
	var state: String = table.state_key(observation)
	var action: int = table.select_training(state) if training else table.select_greedy(state)
	var result: Dictionary = await scenario.execute_held_action(action)
	var training_reward := float(result["first_reward"]) + 0.50 * float(result["first_distance_progress"])
	table.apply_transition(state, action, training_reward, training)
	await _free_scenario(scenario)
	return result

func _run_scripted_episode(card_seed: int, use_memory: bool) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	if not scenario.begin_decision(use_memory):
		push_error("La perception initiale T2 a échoué.")
	var action := int(scenario.observation(use_memory)["last_seen_sector"])
	var result: Dictionary = await scenario.execute_held_action(action)
	await _free_scenario(scenario)
	return result

func _new_scenario(card_seed: int):
	var scenario := T2Scenario.new()
	scenario.configure(card_seed)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _add_record(arm: String, initialization_seed: int, card_seed: int, checkpoint: int, result: Dictionary, checksum: String) -> void:
	_records.append({"experiment_id": "t2_memory_v1", "arm": arm, "initialization_seed": initialization_seed, "card_seed": card_seed, "checkpoint": checkpoint, "consumed": bool(result.get("consumed", false)), "selected_remembered_sector": bool(result.get("selected_remembered_sector", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "terminated": bool(result.get("terminated", false)), "truncated": bool(result.get("truncated", false)), "actions": int(result.get("actions", 0)), "policy_decisions": int(result.get("policy_decisions", 0)), "table_checksum": checksum, "config_fingerprint": FINGERPRINT})

func _write_records() -> bool:
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		return false
	for record in _records:
		file.store_line(JSON.stringify(record))
	file.close()
	return true
