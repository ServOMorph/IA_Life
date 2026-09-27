extends Node

const T1Scenario = preload("res://scripts/t1_scenario.gd")
const T1QTable = preload("res://scripts/t1_q_table.gd")
const T1V3Table = preload("res://scripts/t1_v3_table.gd")
const T1V4Table = preload("res://scripts/t1_v4_table.gd")

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_cards()
	await _test_scripted_consumption()
	await _test_reproducibility()
	await _test_empty_contact_and_reset()
	_test_table_and_checkpoint()
	_test_v3_first_choice()
	_test_v4_balanced_first_choice()
	if _failures.is_empty():
		print("SUCCÈS : scénario T1 validé.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_cards() -> void:
	for seed_value in range(320000001, 320000033):
		var scenario = await _new_scenario(seed_value)
		var observation: Dictionary = scenario.observation(8)
		var slots: Array = observation["targets"]
		var sectors: Dictionary = {}
		var bins: Dictionary = {}
		var available := 0
		for slot in slots:
			sectors[int(slot["resource_sector"])] = true
			bins[int(slot["distance_bin"])] = true
			if bool(slot["available"]):
				available += 1
		_expect(slots.size() == 3 and sectors.size() == 3 and bins.size() == 3 and available == 1, "Chaque seed T1 doit produire trois cibles distinctes et une seule mûre.")
		_expect(not observation.has("seed") and not observation.has("coordinates"), "L'observation T1 ne doit pas exposer la seed ni les coordonnées.")
		for ronce in scenario.ronces:
			_expect(ronce.get_child_count() >= 2 and ronce.solid_body != null, "Chaque roncier T1 doit avoir les collisions de contact et physique.")
		await _free_scenario(scenario)

func _test_scripted_consumption() -> void:
	for seed_value in [320000001, 320000002, 320000003]:
		var scenario = await _new_scenario(seed_value)
		var action := _available_action(scenario)
		var result: Dictionary = {}
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			result = await scenario.execute_action(action)
		_expect(bool(result.get("consumed", false)), "Le bras scripté doit consommer réellement la mûre T1.")
		_expect(float(result.get("reward", 0.0)) == 1.0 and int(result.get("berries_picked", 0)) == 1 and int(result.get("berries_eaten", 0)) == 1, "La récompense T1 doit suivre une cueillette puis une consommation uniques.")
		_expect(bool(result.get("first_selected_available", false)), "La métrique causale doit reconnaître la première action scriptée.")
		var remaining := 0
		for slot in scenario.observation(action)["targets"]:
			if bool(slot["available"]):
				remaining += 1
		_expect(remaining == 0, "L'observation doit refléter la ronce vidée.")
		await _free_scenario(scenario)

func _test_reproducibility() -> void:
	var first := await _summary(320000004)
	var second := await _summary(320000004)
	_expect(first == second, "Même seed et même trace doivent produire le même résumé T1.")

func _test_empty_contact_and_reset() -> void:
	var scenario = await _new_scenario(320000005)
	var empty_action := -1
	for slot in scenario.observation(8)["targets"]:
		if not bool(slot["available"]):
			empty_action = int(slot["resource_sector"])
			if int(slot["distance_bin"]) == 0:
				break
	for _index in range(10):
		var result: Dictionary = await scenario.execute_action(empty_action)
		_expect(not bool(result.get("consumed", false)) and int(result.get("berries_picked", -1)) == 0 and float(result.get("reward", -1.0)) == 0.0, "Une ronce vide ne rapporte rien.")
		if bool(result.get("terminated", false)) or bool(result.get("truncated", false)):
			break
	await _free_scenario(scenario)
	var reset_scenario = await _new_scenario(320000005)
	_expect(reset_scenario.action_count == 0 and reset_scenario.character.berries_picked_total == 0, "Le reset doit effacer les compteurs.")
	_expect(_available_action(reset_scenario) == _available_action_for_seed(320000005), "Le reset doit restaurer la disponibilité.")
	await _free_scenario(reset_scenario)

func _available_action_for_seed(seed_value: int) -> int:
	var scenario := T1Scenario.new()
	scenario.configure(seed_value)
	var selected := -1
	for target in scenario.targets:
		if bool(target["available"]):
			selected = int(target["sector"])
			break
	scenario.free()
	return selected

func _test_table_and_checkpoint() -> void:
	var table := T1QTable.new()
	var fingerprint := "t1_test_v2"
	table.configure(fingerprint, 320001001)
	var first := [{"resource_sector": 1, "distance_bin": 2, "available": false}, {"resource_sector": 6, "distance_bin": 1, "available": true}, {"resource_sector": 3, "distance_bin": 0, "available": false}]
	var second := [{"resource_sector": 4, "distance_bin": 0, "available": false}, {"resource_sector": 2, "distance_bin": 2, "available": false}, {"resource_sector": 6, "distance_bin": 1, "available": true}]
	var state := table.state_key(first, 8)
	_expect(state == table.state_key(second, 8), "La clé doit transférer entre cartes ayant la même cible disponible.")
	_expect(table.select_greedy(state) == 0, "La table initiale doit être neutre.")
	var initial_checksum := table.checksum()
	table.begin_episode()
	_expect(not table.apply_transition(0, state, 6, 1.0, "", true, false), "L'évaluation ne doit pas mettre à jour la table.")
	_expect(table.checksum() == initial_checksum, "L'évaluation doit conserver le checksum.")
	_expect(table.apply_transition(0, state, 6, 1.0, "", true, true), "Le crédit terminal doit être appliqué.")
	_expect(not table.apply_transition(0, state, 6, 1.0, "", true, true), "Le crédit terminal ne doit pas être doublé.")
	_expect(table.select_greedy(state) == 6, "La table doit mémoriser le bon choix.")
	var path := "user://t1_contract_checkpoint.json"
	_expect(table.save_checkpoint(path) == OK, "Le checkpoint T1 doit être écrit.")
	var loaded = T1QTable.load_checkpoint(path, fingerprint)
	_expect(loaded != null and loaded.checksum() == table.checksum(), "Le checkpoint T1 doit se recharger exactement.")
	_expect(T1QTable.load_checkpoint(path, "autre") == null, "Une empreinte étrangère doit être rejetée.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_v3_first_choice() -> void:
	var table := T1V3Table.new()
	table.configure("t1_v3_test", 350001001)
	var rng := RandomNumberGenerator.new()
	rng.seed = 350001001
	_expect(table.select_epsilon_greedy("6:1:8", 0.0, rng) == 0, "La table T1 v3 initiale doit choisir l'ex aequo neutre.")
	for _index in range(20):
		table.begin_episode()
		_expect(table.apply_transition(0, "6:1:8", 6, 0.5, "6:1:6", false, true), "La première action doit être créditée une fois.")
		_expect(not table.apply_transition(0, "6:1:8", 6, 0.5, "6:1:6", false, true), "Un pas répété ne doit pas être crédité.")
	_expect(table.select_epsilon_greedy("6:2:8", 0.0, rng) == 6, "Le choix initial doit transférer entre distances.")
	var checksum := table.checksum()
	table.begin_episode()
	_expect(not table.apply_transition(0, "6:1:8", 0, 1.0, "", true, false), "L'évaluation v3 doit être figée.")
	_expect(table.checksum() == checksum, "L'évaluation v3 ne doit modifier ni table ni RNG.")
	var path := "user://t1_v3_contract_checkpoint.json"
	_expect(table.save_checkpoint(path) == OK, "Le checkpoint T1 v3 doit être écrit.")
	var loaded = T1V3Table.load_checkpoint(path, "t1_v3_test")
	_expect(loaded != null and loaded.checksum() == checksum and loaded.select_epsilon_greedy("6:0:8", 0.0, rng) == 6, "Le checkpoint v3 doit conserver le premier choix.")
	_expect(T1V3Table.load_checkpoint(path, "autre") == null, "La recharge v3 doit rejeter une empreinte étrangère.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_v4_balanced_first_choice() -> void:
	var table := T1V4Table.new()
	table.configure("t1_v4_test", 360001001)
	var rng := RandomNumberGenerator.new()
	rng.seed = 360001001
	for index in range(24):
		table.begin_episode()
		var action: int = table.select_epsilon_greedy("6:1:8", 0.20, rng)
		_expect(action == index % 8, "L'exploration initiale doit équilibrer les huit actions par secteur.")
		var reward := 1.0 if action == 6 else 0.1
		_expect(table.apply_transition(0, "6:1:8", action, reward, "6:1:%d" % action, false, true), "La première transition doit être créditée.")
		_expect(not table.apply_transition(0, "6:1:8", action, reward, "6:1:%d" % action, false, true), "Une transition dupliquée ne doit pas incrémenter le compteur.")
		table.finish_training_episode()
	var checksum: String = table.checksum()
	var parsed: Dictionary = JSON.parse_string(checksum)
	var first_counts: Array = parsed["first_counts"]
	_expect(first_counts.size() == 1 and String(first_counts[0][0]) == "6", "Le compteur du secteur doit être présent.")
	for count in first_counts[0][1]:
		_expect(float(count) == 3.0, "Les compteurs doivent rester équilibrés.")
	_expect(table.select_epsilon_greedy("6:2:8", 0.0, rng) == 6, "L'évaluation doit exploiter la valeur apprise.")
	table.begin_episode()
	_expect(not table.apply_transition(0, "6:1:8", 0, 1.0, "", true, false), "L'évaluation ne doit pas incrémenter les compteurs.")
	_expect(table.checksum() == checksum, "L'évaluation v4 doit être figée.")
	var path := "user://t1_v4_contract_checkpoint.json"
	_expect(table.save_checkpoint(path) == OK, "Le checkpoint v4 doit être écrit.")
	var loaded = T1V4Table.load_checkpoint(path, "t1_v4_test")
	_expect(loaded != null and loaded.checksum() == checksum and loaded.select_epsilon_greedy("6:0:8", 0.0, rng) == 6, "La recharge v4 doit conserver valeurs et compteurs.")
	_expect(T1V4Table.load_checkpoint(path, "autre") == null, "La recharge v4 doit rejeter une empreinte étrangère.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _summary(seed_value: int) -> Dictionary:
	var scenario = await _new_scenario(seed_value)
	var action := _available_action(scenario)
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		result = await scenario.execute_action(action)
	await _free_scenario(scenario)
	return result

func _available_action(scenario) -> int:
	for slot in scenario.observation(8)["targets"]:
		if bool(slot["available"]):
			return int(slot["resource_sector"])
	return -1

func _new_scenario(seed_value: int):
	var scenario := T1Scenario.new()
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
