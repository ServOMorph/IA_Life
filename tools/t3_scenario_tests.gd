extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTable = preload("res://scripts/t3_q_table.gd")
const T2QTable = preload("res://scripts/t2_q_table.gd")

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_world_contract()
	await _test_competitor_contract()
	await _test_competitor_reset()
	await _test_scripted_training_cards()
	await _test_death_and_reset()
	_test_table_checkpoint()
	if _failures.is_empty():
		print("SUCCÈS : scénarios T3 mono-agent et concurrence validés.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_world_contract() -> void:
	var scenario = await _new_scenario(390000001)
	_expect(scenario.world.training_resources().size() == 24, "T3 doit générer 24 ronciers.")
	_expect(scenario.active_competitor_count() == 0, "Les trois concurrents doivent être inactifs et non collisionnels.")
	_expect(GameConfig.danger_zone_count == 0 and scenario.world.get("_danger_zones").is_empty(), "Le danger doit être strictement désactivé.")
	var observation: Dictionary = scenario.observation()
	_expect(set_keys(observation) == set_keys({"hunger": [], "inventory": [], "targets": [], "memories": [], "collision": 0, "progress": [], "previous_action": 8}), "L'observation T3 ne doit pas exposer la carte.")
	_expect(observation["targets"].size() == 3 and observation["memories"].size() == 3, "L'observation T3 doit borner cibles et souvenirs.")
	await _free_scenario(scenario)

func _test_competitor_contract() -> void:
	var scenario := T3Scenario.new()
	scenario.configure(410000001, true, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	_expect(scenario.active_competitor_count() == 3, "T3 v3 doit conserver trois concurrents actifs et collisionnels.")
	var agents: Array = scenario.world.training_agents()
	for index in range(1, agents.size()):
		var competitor = agents[index]
		_expect(competitor.decider_type == "politique_fixe" and not competitor.rl_controlled, "Chaque concurrent T3 v3 doit utiliser la politique fixe.")
		_expect(is_equal_approx(competitor.hunger, 50.0) and is_equal_approx(competitor.hunger_depletion_rate, 4.0), "Chaque concurrent T3 v3 doit partager les paramètres de faim.")
		_expect(is_equal_approx(competitor.vision_range, 40.0) and competitor.memory_capacity == 5, "Chaque concurrent T3 v3 doit partager vision et mémoire.")
	await _free_scenario(scenario)

func _test_competitor_reset() -> void:
	var first := T3Scenario.new()
	first.configure(410000002, true, 40.0)
	add_child(first)
	await get_tree().physics_frame
	var expected := _world_snapshot(first)
	await first.execute_action(0)
	await first.execute_action(2)
	await _free_scenario(first)
	var second := T3Scenario.new()
	second.configure(410000002, true, 40.0)
	add_child(second)
	await get_tree().physics_frame
	_expect(_world_snapshot(second) == expected, "Le reset T3 v3 doit reproduire les quatre agents et les stocks partagés.")
	await _free_scenario(second)

func _world_snapshot(scenario) -> String:
	var agents: Array = []
	for agent in scenario.world.training_agents():
		agents.append([agent.position, agent.hunger, agent.berries_carried, agent.berries_picked_total, agent.berries_eaten_total, agent.is_dead])
	var resources: Array = []
	for ronce in scenario.world.training_resources():
		resources.append([ronce.position, ronce.berries])
	return JSON.stringify({"agents": agents, "resources": resources})

func _test_scripted_training_cards() -> void:
	for seed_value in [390000001, 390000002, 390000003]:
		var scenario = await _new_scenario(seed_value)
		var saw_meal_without_end := false
		var result: Dictionary = {}
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			result = await scenario.execute_action(scenario.scripted_action())
			if int(result.get("berries_eaten_delta", 0)) > 0 and not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
				saw_meal_without_end = true
		_expect(saw_meal_without_end, "Un repas ne doit pas terminer prématurément T3.")
		_expect(bool(result.get("survived", false)), "Le contrôle scripté doit survivre sur les cartes de probe.")
		_expect(int(result.get("berries_eaten", 0)) >= 1, "La survie scriptée doit reposer sur un repas réel.")
		await _free_scenario(scenario)

func _test_death_and_reset() -> void:
	var scenario = await _new_scenario(390000004)
	scenario.actor.hunger = 0.01
	var result: Dictionary = await scenario.execute_action(0)
	_expect(bool(result.get("terminated", false)) and not bool(result.get("truncated", true)), "La mort T3 doit être terminale et non tronquée.")
	await _free_scenario(scenario)
	var reset = await _new_scenario(390000004)
	_expect(is_equal_approx(reset.actor.hunger, 50.0) and reset.actor.berries_eaten_total == 0 and reset.action_count == 0, "Le reset T3 doit restaurer faim, repas et compteur.")
	_expect(reset.world.training_resources().all(func(ronce): return ronce.berries == 3), "Le reset T3 doit restaurer tous les stocks.")
	await _free_scenario(reset)

func _test_table_checkpoint() -> void:
	var table := T3QTable.new()
	table.configure("t3_test", 390001001)
	var observation := {"hunger": [0.5], "inventory": [0.0], "targets": [[1.0, 1.0, 0.0, 0.1, 1.0], [0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0]], "memories": [[0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0]], "collision": 0, "progress": [0.0], "previous_action": 8}
	var state := table.state_key(observation)
	_expect(state.begins_with("visible:2:"), "La clé T3 doit encoder la cible visible.")
	var checksum := table.checksum()
	_expect(not table.apply_transition(state, 2, 1.0, state, false, false) and table.checksum() == checksum, "L'évaluation T3 doit être figée.")
	_expect(table.apply_transition(state, 2, 1.0, state, false, true), "La transition T3 doit mettre à jour la table en entraînement.")
	_expect(table.select_greedy(state) == 2, "La table T3 doit retenir l'action récompensée.")
	var path := "user://t3_contract_checkpoint.json"
	_expect(table.save_checkpoint(path) == OK, "Le checkpoint T3 doit être écrit.")
	var loaded = T3QTable.load_checkpoint(path, "t3_test")
	_expect(loaded != null and loaded.checksum() == table.checksum(), "Le checkpoint T3 doit se recharger exactement.")
	_expect(T3QTable.load_checkpoint(path, "autre") == null, "Une empreinte T3 étrangère doit être rejetée.")
	_expect(T2QTable.load_checkpoint(path, "t3_test") == null, "Le schéma T2 doit rejeter un checkpoint T3.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _new_scenario(seed_value: int):
	var scenario := T3Scenario.new()
	scenario.configure(seed_value, false)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func set_keys(dictionary: Dictionary) -> Array:
	var keys := dictionary.keys()
	keys.sort()
	return keys

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
