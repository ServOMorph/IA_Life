extends Node

const T2Scenario = preload("res://scripts/t2_scenario.gd")
const T2QTable = preload("res://scripts/t2_q_table.gd")
const T1V5Table = preload("res://scripts/t1_v5_table.gd")

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_perception_and_memory()
	await _test_cards_and_consumption()
	await _test_reproducibility()
	_test_table_and_checkpoint()
	if _failures.is_empty():
		print("SUCCÈS : scénario T2 validé.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_perception_and_memory() -> void:
	var scenario = await _new_scenario(380000001)
	var preview: Dictionary = scenario.observation(true)
	_expect(preview["visible_targets"].size() == 1, "La ronce doit être perçue avant la rotation.")
	_expect(int(preview["last_seen_sector"]) == -1, "La mémoire doit être vide au début de l'épisode.")
	_expect(scenario.begin_decision(true), "Le passage en décision doit capturer une perception réelle.")
	var memory_observation: Dictionary = scenario.observation(true)
	var current_observation: Dictionary = scenario.observation(false)
	_expect(memory_observation["visible_targets"].is_empty(), "La ronce doit être hors du cône au moment du choix.")
	_expect(int(memory_observation["last_seen_sector"]) == scenario.target_sector, "La dernière perception doit mémoriser le secteur.")
	_expect(int(current_observation["last_seen_sector"]) == -1, "L'observation seule ne doit pas recevoir le secteur mémorisé.")
	_expect(not memory_observation.has("seed") and not memory_observation.has("coordinates"), "L'observation T2 ne doit exposer ni seed ni coordonnées.")
	await _free_scenario(scenario)
	var reset = await _new_scenario(380000001)
	_expect(int(reset.observation(true)["last_seen_sector"]) == -1, "Le reset doit vider la mémoire T2.")
	await _free_scenario(reset)

func _test_cards_and_consumption() -> void:
	var sectors: Dictionary = {}
	var distances: Dictionary = {}
	for seed_value in range(380000001, 380000033):
		var scenario = await _new_scenario(seed_value)
		sectors[scenario.target_sector] = int(sectors.get(scenario.target_sector, 0)) + 1
		distances[scenario.target_distance] = true
		_expect(scenario.begin_decision(true), "Chaque carte T2 doit avoir une perception initiale.")
		var result: Dictionary = await scenario.execute_held_action(scenario.target_sector)
		_expect(bool(result.get("consumed", false)), "Le cap mémorisé doit produire une consommation réelle.")
		_expect(int(result.get("berries_picked", 0)) == 1 and int(result.get("berries_eaten", 0)) == 1, "T2 doit compter une cueillette et une consommation uniques.")
		_expect(int(result.get("policy_decisions", 0)) == 1, "L'exécutant T2 doit recevoir un choix unique.")
		await _free_scenario(scenario)
	_expect(sectors.size() == 8 and distances.size() == 3, "Les cartes T2 doivent couvrir huit secteurs et trois distances.")
	for count in sectors.values():
		_expect(int(count) == 4, "Les 32 cartes T2 doivent équilibrer les secteurs.")

func _test_reproducibility() -> void:
	var first := await _summary(380000017)
	var second := await _summary(380000017)
	_expect(first == second, "Même seed et même cap doivent reproduire le résumé T2.")

func _test_table_and_checkpoint() -> void:
	var table := T2QTable.new()
	table.configure("t2_test", 380001001)
	var memory_observation := {"visible_targets": [], "last_seen_sector": 6, "decision_started": true}
	var empty_observation := {"visible_targets": [], "last_seen_sector": -1, "decision_started": true}
	var memory_state := table.state_key(memory_observation)
	_expect(memory_state == "memory:6" and table.state_key(empty_observation) == "current_empty", "Les états mémoire et observation seule doivent être distincts.")
	for index in range(24):
		table.begin_episode()
		var action := table.select_training(memory_state)
		_expect(action == index % 8, "L'exploration T2 doit équilibrer les actions par état.")
		_expect(table.apply_transition(memory_state, action, 1.0 if action == 6 else 0.0, true), "La transition T2 doit être créditée une fois.")
		_expect(not table.apply_transition(memory_state, action, 1.0, true), "Le crédit T2 ne doit pas être doublé.")
		table.finish_training_episode()
	_expect(table.select_greedy(memory_state) == 6, "La table T2 doit rappeler le cap appris.")
	var checksum := table.checksum()
	table.begin_episode()
	_expect(not table.apply_transition(memory_state, 0, 1.0, false) and table.checksum() == checksum, "L'évaluation T2 doit rester figée.")
	var path := "user://t2_contract_checkpoint.json"
	_expect(table.save_checkpoint(path) == OK, "Le checkpoint T2 doit être écrit.")
	var loaded = T2QTable.load_checkpoint(path, "t2_test")
	_expect(loaded != null and loaded.checksum() == checksum, "Le checkpoint T2 doit se recharger exactement.")
	_expect(T2QTable.load_checkpoint(path, "autre") == null, "Une empreinte étrangère doit être rejetée.")
	_expect(T1V5Table.load_checkpoint(path, "t2_test") == null, "Le schéma T1 doit rejeter un checkpoint T2.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _summary(seed_value: int) -> Dictionary:
	var scenario = await _new_scenario(seed_value)
	scenario.begin_decision(true)
	var result: Dictionary = await scenario.execute_held_action(scenario.target_sector)
	await _free_scenario(scenario)
	return result

func _new_scenario(seed_value: int):
	var scenario := T2Scenario.new()
	scenario.configure(seed_value)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
