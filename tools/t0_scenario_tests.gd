extends Node

const T0Scenario = preload("res://scripts/t0_scenario.gd")
const T0QTable = preload("res://scripts/t0_q_table.gd")

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_scripted_all_sectors()
	await _test_no_reward_outside_contact()
	await _test_action_symmetry()
	await _test_reproducibility()
	await _test_reset_reconstructs_world()
	_test_neutral_table_has_no_sector_answer()
	if _failures.is_empty():
		print("SUCCÈS : scénario alimentaire T0 validé.")
		get_tree().quit(0)
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_scripted_all_sectors() -> void:
	for sector in range(8):
		var result := await _scripted_episode(310000000 + sector)
		_expect(bool(result["success"]), "Le contrôle scripté doit cueillir le secteur %d." % sector)
		_expect(int(result["berries_picked"]) == 1 and int(result["ronce_berries"]) == 0, "Le succès du secteur %d doit vider la vraie ronce." % sector)

func _test_no_reward_outside_contact() -> void:
	var scenario = await _new_scenario(310000101)
	for _tick in range(3):
		await get_tree().physics_frame
	_expect(scenario.character.berries_picked_total == 0, "Hors contact, aucune mûre ne doit être récoltée.")
	_expect(scenario.ronce.berries == 1, "Hors contact, le stock de la ronce doit rester intact.")
	await _free_scenario(scenario)

func _test_action_symmetry() -> void:
	var distances: Array[float] = []
	for action in range(8):
		var scenario = await _new_scenario(310000101)
		await scenario.execute_action(action)
		distances.append(Vector2(scenario.character.position.x, scenario.character.position.z).length())
		await _free_scenario(scenario)
	for distance in distances:
		_expect(is_equal_approx(distance, distances[0]), "Les huit actions T0 doivent parcourir la même distance.")

func _test_reproducibility() -> void:
	var first := await _scripted_episode(310000107)
	var second := await _scripted_episode(310000107)
	_expect(first == second, "Même carte et même trace doivent produire le même résumé T0.")

func _test_reset_reconstructs_world() -> void:
	var completed := await _scripted_episode(310000103)
	_expect(bool(completed["success"]), "Le prérequis de reset doit atteindre le succès.")
	var reset = await _new_scenario(310000103)
	_expect(reset.character.berries_picked_total == 0 and reset.ronce.berries == 1, "Un reset T0 doit reconstruire le personnage et le stock.")
	await _free_scenario(reset)

func _test_neutral_table_has_no_sector_answer() -> void:
	var table := T0QTable.new()
	table.configure("t0-contract-v1", 310001001)
	for sector in range(8):
		var state := table.state_key(sector, true, T0QTable.START_ACTION)
		_expect(table.select_greedy(state) == 0, "La table initiale ne doit pas précharger le secteur %d." % sector)

func _scripted_episode(seed: int) -> Dictionary:
	var scenario = await _new_scenario(seed)
	var result: Dictionary = {}
	while scenario.action_count < T0Scenario.HORIZON_ACTIONS and not bool(result.get("terminated", false)):
		result = await scenario.execute_action(scenario.resource_sector)
	var summary := {
		"success": bool(result.get("success", false)),
		"terminated": bool(result.get("terminated", false)),
		"truncated": bool(result.get("truncated", false)),
		"actions": int(result.get("actions", 0)),
		"berries_picked": scenario.character.berries_picked_total,
		"ronce_berries": scenario.ronce.berries,
	}
	await _free_scenario(scenario)
	return summary

func _new_scenario(seed: int):
	var scenario := T0Scenario.new()
	scenario.configure(seed)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
