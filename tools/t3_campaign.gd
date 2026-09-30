extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTable = preload("res://scripts/t3_q_table.gd")
const FINGERPRINT_V2 := "t3_world_v2|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const FINGERPRINT_V3 := "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const CHECKPOINTS_DEVELOPMENT := [0, 10, 50, 200]
const TRAINING_CARDS := 32

var _output_path := ""
var _records: Array = []
var _experiment_id := "t3_world_v2"
var _fingerprint := FINGERPRINT_V2
var _schema := "t3_q_table_v2"
var _seed_base := 400000000
var _initialization_base := 400001000
var _random_base := 400002000
var _competitors := false
var _checkpoints: Array = CHECKPOINTS_DEVELOPMENT
var _initialization_count := 3
var _card_first := 101
var _card_last := 132

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 6 or args.size() > 10 or args.size() % 2 != 0 or args[0] != "--output" or args[2] != "--kind" or args[4] != "--initialization-seed":
		push_error("Usage : --output chemin --kind baseline|trained|reset --initialization-seed seed [--contract v3|v3c] [--cards validation|final]")
		get_tree().quit(2)
		return
	var contract := ""
	var cards := ""
	for index in range(6, args.size(), 2):
		if args[index] == "--contract":
			contract = args[index + 1]
		elif args[index] == "--cards":
			cards = args[index + 1]
		else:
			get_tree().quit(2)
			return
	if contract not in ["", "v3", "v3c"] or (contract != "v3c" and cards != "") or (contract == "v3c" and cards not in ["validation", "final"]):
		push_error("Combinaison --contract/--cards invalide.")
		get_tree().quit(2)
		return
	if contract in ["v3", "v3c"]:
		_experiment_id = "t3_world_v3"
		_fingerprint = FINGERPRINT_V3
		_schema = "t3_q_table_v3"
		_seed_base = 410000000
		_initialization_base = 410001000
		_random_base = 410002000
		_competitors = true
	if contract == "v3c":
		_experiment_id = "t3_confirmation_v1"
		_initialization_base = 410001100
		_random_base = 410002100
		_initialization_count = 5
		_checkpoints = [200]
		if cards == "final":
			_card_first = 201
			_card_last = 264
	_output_path = args[1]
	var initialization_seed := int(args[5])
	if initialization_seed < _initialization_base + 1 or initialization_seed > _initialization_base + _initialization_count:
		push_error("Seed d'initialisation T3 invalide.")
		get_tree().quit(2)
		return
	match args[3]:
		"baseline":
			await _evaluate_baselines(initialization_seed)
		"trained":
			await _train_and_evaluate(initialization_seed, false)
		"reset":
			await _train_and_evaluate(initialization_seed, true)
		_:
			push_error("Type de lignée T3 invalide.")
			get_tree().quit(2)
			return
	if not _write_records():
		push_error("Écriture des résultats T3 impossible.")
		get_tree().quit(1)
		return
	print("SUCCÈS : campagne %s terminée (%d résultats)." % [_experiment_id, _records.size()])
	get_tree().quit(0)

func _evaluate_baselines(initialization_seed: int) -> void:
	var initial_table = _new_table(initialization_seed)
	var random_rng := RandomNumberGenerator.new()
	random_rng.seed = _random_base + 1 + (initialization_seed - (_initialization_base + 1))
	for card_seed in range(_seed_base + _card_first, _seed_base + _card_last + 1):
		_add_record("scripted_food", initialization_seed, card_seed, 0, await _run_scripted_episode(card_seed), "scripted")
		var checksum: String = initial_table.checksum()
		_add_record("initial_frozen", initialization_seed, card_seed, 0, await _run_table_episode(initial_table, card_seed, false, random_rng), checksum)
		_add_record("random_valid", initialization_seed, card_seed, 0, await _run_random_episode(card_seed, random_rng), "random:%d" % random_rng.state)

func _train_and_evaluate(initialization_seed: int, reset_each_episode: bool) -> void:
	var table = _new_table(initialization_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = initialization_seed
	var completed := 0
	for checkpoint in _checkpoints:
		while completed < checkpoint:
			if reset_each_episode:
				table = _new_table(initialization_seed)
			var training_index := positive_modulo(completed * 5 + initialization_seed, TRAINING_CARDS)
			await _run_table_episode(table, _seed_base + 1 + training_index, true, rng)
			table.finish_training_episode()
			table.training_rng_state = rng.state
			completed += 1
		var evaluation_table = table
		if not reset_each_episode:
			var checkpoint_path := "%s.%d.%d.checkpoint.json" % [_output_path, initialization_seed, checkpoint]
			if table.save_checkpoint(checkpoint_path) != OK:
				push_error("Sauvegarde T3 impossible.")
				get_tree().quit(1)
				return
			evaluation_table = T3QTable.load_checkpoint(checkpoint_path, _fingerprint, _schema)
			if evaluation_table == null or evaluation_table.checksum() != table.checksum():
				push_error("Recharge T3 divergente.")
				get_tree().quit(1)
				return
		var arm := "reset_each_episode" if reset_each_episode else "trained"
		for card_seed in range(_seed_base + _card_first, _seed_base + _card_last + 1):
			var checksum: String = evaluation_table.checksum()
			var result := await _run_table_episode(evaluation_table, card_seed, false, rng)
			if evaluation_table.checksum() != checksum:
				push_error("L'évaluation T3 a modifié la table.")
				get_tree().quit(1)
				return
			_add_record(arm, initialization_seed, card_seed, checkpoint, result, checksum)

func _new_table(initialization_seed: int):
	var table := T3QTable.new()
	table.configure(_fingerprint, initialization_seed, _schema)
	return table

func _run_table_episode(table, card_seed: int, training: bool, rng: RandomNumberGenerator) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var state: String = table.state_key(scenario.observation())
		var action: int = table.select_epsilon_greedy(state, 0.20, rng) if training else table.select_greedy(state)
		result = await scenario.execute_action(action)
		var next_state: String = table.state_key(scenario.observation())
		var reward := float(result["reward_event"]) + 0.25 * float(result["progress"]) - 0.01
		table.apply_transition(state, action, reward, next_state, bool(result["terminated"]), training)
	await _free_scenario(scenario)
	return result

func _run_scripted_episode(card_seed: int) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		result = await scenario.execute_action(scenario.scripted_action())
	await _free_scenario(scenario)
	return result

func _run_random_episode(card_seed: int, rng: RandomNumberGenerator) -> Dictionary:
	var scenario = await _new_scenario(card_seed)
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		result = await scenario.execute_action(rng.randi_range(0, 7))
	await _free_scenario(scenario)
	return result

func _new_scenario(card_seed: int):
	var scenario := T3Scenario.new()
	scenario.configure(card_seed, _competitors, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _add_record(arm: String, initialization_seed: int, card_seed: int, checkpoint: int, result: Dictionary, checksum: String) -> void:
	_records.append({"experiment_id": _experiment_id, "arm": arm, "initialization_seed": initialization_seed, "card_seed": card_seed, "checkpoint": checkpoint, "survived": bool(result.get("survived", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "terminated": bool(result.get("terminated", false)), "truncated": bool(result.get("truncated", false)), "actions": int(result.get("actions", 0)), "table_checksum": checksum, "config_fingerprint": _fingerprint})

func _write_records() -> bool:
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		return false
	for record in _records:
		file.store_line(JSON.stringify(record))
	file.close()
	return true

func positive_modulo(value: int, divisor: int) -> int:
	return ((value % divisor) + divisor) % divisor
