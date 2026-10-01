extends Node

const DangerContract = preload("res://scripts/danger_zone_contract.gd")
const DangerPlacement = preload("res://scripts/danger_zone_placement.gd")
const CharacterScript = preload("res://scripts/character.gd")

# Vérifications automatisées pour les anciens tests manuels trop coûteux à reproduire.
# Usage : python tools/run_manual_checks.py

class TestRonce:
	extends Node3D

	var berries := 1

	func harvest_one() -> bool:
		if berries <= 0:
			return false
		berries -= 1
		return true

class TestDangerZone:
	extends Node3D

	var zone_id := "danger_test"
	var hunger_cost_rate := 1.0
	var radius := 4.0

	func is_character_exposed(world_position: Vector3) -> bool:
		var offset := world_position - global_position
		offset.y = 0.0
		return offset.length_squared() <= radius * radius

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_danger_detour()
	_test_detour_decider_integration()
	_test_detour_collision_recovery()
	_test_game_data_settings()
	_test_manual_berry_harvest()
	_test_memory_navigation()
	_test_memory_ignores_empty_ronce()
	_test_memory_decay()
	_test_memory_replacement()
	_test_memory_slider()
	_test_experiment_config_defaults()
	_test_experiment_config_overrides()
	_test_experiment_config_validation()
	_test_danger_zone_contract()
	_test_danger_approach_placement_contract()
	_test_danger_zone_integration()
	_test_experiment_config_teleport_event()
	_test_danger_perception_visible_direction_and_distance()
	_test_danger_perception_behind_ignored()
	_test_danger_perception_out_of_range_ignored()
	_test_danger_response_direction_prioritizes_active_zone()
	_test_danger_response_direction_respects_reaction_range()
	_test_danger_response_direction_within_reaction_range()
	_test_danger_response_direction_active_zone_ignores_reaction_range()
	_test_fixed_policy_danger_dispatch()
	_test_fixed_policy_danger_ignorer_unaffected()
	_test_fixed_policy_danger_eviter_overrides_direction()
	_test_fixed_policy_danger_viser_overrides_direction()
	_test_fixed_policy_danger_no_direction_leaves_action_untouched()
	_test_fixed_policy_danger_respects_manual_control()
	_test_fixed_policy_danger_aleatoire_registry()
	_test_fixed_policy_danger_aleatoire_only_eviter_or_viser()
	_test_fixed_policy_danger_aleatoire_choice_held_within_window()
	_test_fixed_policy_danger_aleatoire_deterministic_by_seed()
	_test_fixed_policy_danger_aleatoire_no_direction_leaves_action_untouched()
	_test_vision_range_and_angle()
	_test_vision_memorization()
	_test_vision_memory_capacity_no_churn()
	_test_vision_priority_over_memory()
	_test_adaptive_situations()
	_test_adaptive_navigation_actions()
	_test_adaptive_greedy_selection()
	_test_adaptive_matches_baseline_outside_hunger()
	_test_adaptive_determinism()
	_test_adaptive_engagement()
	_test_adaptive_registry_and_dispatch()
	_test_adaptive_online_reward()
	_test_adaptive_credit_assignment_approach()
	_test_adaptive_td_bootstrap()
	_test_adaptive_flush_on_hunger_exit()
	_test_adaptive_terminal_penalty()
	_test_continuous_harvest_while_in_contact()
	_test_baseline_ignores_full_inventory()
	_test_adaptive_ignores_full_inventory()
	_test_llm_survie_config()
	_test_ronce_memory_on_sight()
	_test_ronce_memory_on_contact()
	_test_ronce_memory_own_pick_countdown()
	_test_ronce_memory_stale_then_corrected()
	_test_ronce_memory_never_forgets()
	_test_ronce_memory_absent_for_other_deciders()
	_test_survie_no_automatic_pickup_or_meal()
	_test_survie_full_sequence()
	_test_survie_refusals()
	_test_survie_arrival_block_and_empty_target()
	_test_survie_mock_backend_integration()
	_test_survie_turn_cadence_and_wait()
	_test_survie_events_queued_during_wait()
	_test_survie_fallback_backoff()
	_test_survie_safety_interval()
	_test_survie_zero_latency_determinism()
	_test_survie_ollama_prompt_schema_and_parsing()
	if _failures.is_empty():
		print("SUCCÈS : tests manuels 6, 8, 9, 10 et 11, ExperimentConfig, vision (Phase 8), décideur adaptatif (Phases 1 et 2) et perception/politique du danger (Phase 2 v3) validés automatiquement.")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _make_character() -> CharacterBody3D:
	var character := CharacterScript.new()
	get_tree().root.add_child(character)
	return character

func _make_ronce(local_position: Vector3) -> Area3D:
	var ronce := Area3D.new()
	ronce.set_script(load("res://scripts/ronce.gd"))
	ronce.berries = 1
	ronce.position = local_position
	get_tree().root.add_child(ronce)
	ronce.add_to_group("perceptible")
	return ronce

func _test_vision_range_and_angle() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 90.0
	character.vision_blocked_by_terrain = false

	var in_front := _make_ronce(Vector3(0.0, 0.0, -5.0))
	var behind_out_of_angle := _make_ronce(Vector3(0.0, 0.0, 5.0))
	var in_front_out_of_range := _make_ronce(Vector3(0.0, 0.0, -50.0))

	character._update_vision_perception()

	_expect(character._visible_entities.size() == 1, "Phase 8 vision : le nombre d'entités perçues est incorrect (angle/portée).")
	var seen_nodes: Array = []
	for entry in character._visible_entities:
		seen_nodes.append(entry["node"])
	_expect(seen_nodes.has(in_front), "Phase 8 vision : une entité dans le champ et la portée n'est pas perçue.")
	_expect(not seen_nodes.has(behind_out_of_angle), "Phase 8 vision : une entité hors du champ de vision est perçue à tort.")
	_expect(not seen_nodes.has(in_front_out_of_range), "Phase 8 vision : une entité hors de portée est perçue à tort.")

	character.free()
	in_front.free()
	behind_out_of_angle.free()
	in_front_out_of_range.free()

func _test_vision_memorization() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 360.0
	character.memory_capacity = 5

	var ronce := _make_ronce(Vector3(0.0, 0.0, -5.0))
	character._update_vision_perception()

	_expect(character.memorized_ronces_count() == 1, "Phase 8 vision : un roncier vu à distance n'est pas mémorisé.")
	_expect(character.ronces_discovered_by_vision_total == 1, "Phase 8 vision : le compteur de découvertes par vision est incorrect.")
	_expect(character.vision_detections_total == 1, "Phase 8 vision : le compteur de détections est incorrect.")

	character._update_vision_perception()
	_expect(character.ronces_discovered_by_vision_total == 1, "Phase 8 vision : une entité déjà mémorisée est comptée deux fois.")

	character.free()
	ronce.free()

func _test_vision_memory_capacity_no_churn() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 360.0
	character.memory_capacity = 2

	var ronces: Array = []
	for i in 5:
		ronces.append(_make_ronce(Vector3(float(i) - 2.0, 0.0, -5.0)))

	for i in 10:
		character._update_vision_perception()

	_expect(character.ronces_discovered_by_vision_total == 5, "Phase 8 vision : la mémorisation par vision boucle sans fin quand plus d'entités sont visibles que memory_capacity.")
	_expect(character.memorized_ronces_count() == 2, "Phase 8 vision : la capacité de mémoire n'est pas respectée avec plusieurs ronciers visibles.")

	character.free()
	for r in ronces:
		r.free()

func _test_vision_priority_over_memory() -> void:
	var visible_direction := Vector3(1.0, 0.0, 0.0)
	var memory_direction := Vector3(0.0, 0.0, 1.0)
	var observation := {
		"manual_control": false,
		"manual_direction": Vector3.ZERO,
		"hunger": 85.0,
		"pickup_hunger_threshold": 90.0,
		"berries_carried": 0,
		"max_berries_carried": 3,
		"has_memories": true,
		"memory_direction": memory_direction,
		"has_visible_ronce": true,
		"visible_ronce_direction": visible_direction,
		"social_goal": "",
		"social_direction": Vector3.ZERO,
		"current_direction": Vector3.ZERO,
		"wander_timer": 1.0,
		"delta": 0.1,
	}
	var action: Dictionary = BaselineDecider.new().decide(observation)
	_expect(action["direction"].is_equal_approx(visible_direction), "Phase 8 vision : l'automate ne priorise pas le roncier visible sur le roncier mémorisé.")

func _test_game_data_settings() -> void:
	var saved := {
		"max_berries_carried": GameConfig.max_berries_carried,
		"pickup_hunger_threshold": GameConfig.pickup_hunger_threshold,
		"eat_hunger_threshold": GameConfig.eat_hunger_threshold,
		"ronce_count": GameConfig.ronce_count,
		"berries_per_ronce": GameConfig.berries_per_ronce,
	}
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)

	# Les seuils et la capacité sont lus au moment de l'action, sans redémarrage.
	character.hunger = 80.0
	GameConfig.pickup_hunger_threshold = 70.0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 0, "Test 6 : la cueillette a ignoré le seuil immédiat.")
	GameConfig.pickup_hunger_threshold = 90.0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 1, "Test 6 : le nouveau seuil de cueillette n'est pas appliqué immédiatement.")

	character.berries_carried = 0
	ronce.berries = 1
	GameConfig.max_berries_carried = 0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 0, "Test 6 : la capacité maximale immédiate est ignorée.")
	GameConfig.max_berries_carried = 1
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 1, "Test 6 : la nouvelle capacité maximale n'est pas appliquée immédiatement.")

	character.hunger = 60.0
	GameConfig.eat_hunger_threshold = 50.0
	character._try_eat_berry()
	_expect(character.berries_carried == 1, "Test 6 : le personnage mange malgré un seuil de consommation trop bas.")
	GameConfig.eat_hunger_threshold = 70.0
	character._try_eat_berry()
	_expect(character.berries_carried == 0, "Test 6 : le nouveau seuil de consommation n'est pas appliqué immédiatement.")

	# Les paramètres de génération ne changent que la prochaine génération de ronces.
	var main: Node3D = load("res://scenes/Main.tscn").instantiate()
	GameConfig.ronce_count = 3
	GameConfig.berries_per_ronce = 2
	get_tree().root.add_child(main)
	_expect(main._ronces.size() == 3, "Test 6 : le nombre initial de ronciers est incorrect.")
	GameConfig.ronce_count = 5
	GameConfig.berries_per_ronce = 4
	_expect(main._ronces.size() == 3, "Test 6 : le nombre de ronciers change sans Relancer.")
	for spawned_ronce in main._ronces:
		_expect(spawned_ronce.berries == 2, "Test 6 : les mûres d'un roncier existant changent sans Relancer.")
	main.free()
	var restarted_main: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(restarted_main)
	_expect(restarted_main._ronces.size() == 5, "Test 6 : Relancer n'applique pas le nouveau nombre de ronciers.")
	for spawned_ronce in restarted_main._ronces:
		_expect(spawned_ronce.berries == 4, "Test 6 : Relancer n'applique pas le nouveau nombre de mûres.")
	restarted_main.queue_free()
	character.queue_free()
	ronce.queue_free()
	for key in saved:
		GameConfig.set(key, saved[key])

func _test_memory_replacement() -> void:
	var character := _make_character()
	character.memory_capacity = 5
	var ronciers: Array[TestRonce] = []
	for i in 6:
		var ronce := TestRonce.new()
		ronciers.append(ronce)
		get_tree().root.add_child(ronce)
		character._remember_ronce(ronce)
	if character._memories.size() >= 5:
		character._memories[0].strength = 1.0
		for i in range(1, character._memories.size()):
			character._memories[i].strength = float(i + 1)
		character._remember_ronce(ronciers[5])
	_expect(character.memorized_ronces_count() == 5, "Test 10 : la mémoire dépasse sa capacité.")
	var contains_weakest := false
	var contains_new := false
	for memory in character._memories:
		contains_weakest = contains_weakest or memory.ronce == ronciers[0]
		contains_new = contains_new or memory.ronce == ronciers[5]
	_expect(not contains_weakest, "Test 10 : le souvenir le plus faible n'a pas été remplacé.")
	_expect(contains_new, "Test 10 : le nouveau roncier n'a pas été mémorisé.")
	character.queue_free()
	for ronce in ronciers:
		ronce.queue_free()

func _test_memory_navigation() -> void:
	var saved_threshold := GameConfig.pickup_hunger_threshold
	var character := _make_character()
	var ronce := TestRonce.new()
	ronce.position = Vector3(10.0, 0.0, 0.0)
	get_tree().root.add_child(ronce)
	character.position = Vector3.ZERO
	character.hunger = 85.0
	character.manual_control = false
	GameConfig.pickup_hunger_threshold = 90.0
	character._remember_ronce(ronce)
	character._physics_process(0.0)
	_expect(character._direction.is_equal_approx(Vector3.RIGHT), "Test 8 : le personnage ne cible pas le roncier mémorisé le plus proche.")
	GameConfig.pickup_hunger_threshold = saved_threshold
	character.queue_free()
	ronce.queue_free()

func _test_manual_berry_harvest() -> void:
	var saved_max := GameConfig.max_berries_carried
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)
	GameConfig.max_berries_carried = 1
	character.hunger = 100.0
	_expect(character.try_pick_berry_from_ronce(ronce, true), "Interaction E : le ramassage manuel échoue près d'un roncier plein.")
	_expect(character.berries_carried == 1, "Interaction E : la mûre ramassée n'est pas ajoutée à l'inventaire.")
	GameConfig.max_berries_carried = saved_max
	character.queue_free()
	ronce.queue_free()

func _test_memory_decay() -> void:
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)
	character.memory_decay_rate = 1.0
	character._remember_ronce(ronce)
	character._decay_memories(9.9)
	_expect(character.memorized_ronces_count() == 1, "Test 9 : un souvenir disparaît avant d'atteindre une force nulle.")
	character._decay_memories(0.2)
	_expect(character.memorized_ronces_count() == 0, "Test 9 : un souvenir à force nulle ne disparaît pas.")
	character.queue_free()
	ronce.queue_free()

func _test_experiment_config_defaults() -> void:
	var config := ExperimentConfig.from_raw({})
	_expect(config.is_valid(), "ExperimentConfig défauts : une config vide devrait être valide.")
	_expect(config.normalized["seed"] == 1337, "ExperimentConfig défauts : la seed par défaut est incorrecte.")
	_expect(is_equal_approx(config.normalized["simulation"]["game_speed"], 1.0), "ExperimentConfig défauts : game_speed par défaut incorrect.")
	_expect(is_equal_approx(config.normalized["simulation"]["max_simulation_seconds"], 120.0), "ExperimentConfig défauts : durée simulée par défaut incorrecte.")
	_expect(config.normalized["agents"]["defaults"].is_empty(), "ExperimentConfig défauts : agents.defaults devrait rester vide sans override.")

	var character := _make_character()
	var move_speed_default: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["move_speed"])
	_expect(is_equal_approx(character.move_speed, move_speed_default), "VariableRegistry défauts : Character.move_speed ne correspond pas au registre.")
	character.queue_free()

func _test_experiment_config_overrides() -> void:
	var raw := {
		"environment": {"game_config": {"ronce_count": 10}},
		"agents": {
			"defaults": {"move_speed": 5.0},
			"individual": {"A": {"move_speed": 7.0}},
		},
	}
	var config := ExperimentConfig.from_raw(raw)
	_expect(config.is_valid(), "ExperimentConfig overrides : une config valide a été rejetée.")
	_expect(config.normalized["environment"]["game_config"]["ronce_count"] == 10, "ExperimentConfig overrides : override global.game_config non appliqué.")
	_expect(is_equal_approx(config.normalized["agents"]["defaults"]["move_speed"], 5.0), "ExperimentConfig overrides : override agents.defaults non appliqué.")
	_expect(is_equal_approx(config.normalized["agents"]["individual"]["A"]["move_speed"], 7.0), "ExperimentConfig overrides : override agents.individual non appliqué.")
	var initial_state := ExperimentConfig.from_raw({"agents": {"initial_state": {"defaults": {"hunger": 80.0}}}})
	_expect(initial_state.is_valid() and is_equal_approx(initial_state.normalized["agents"]["initial_state"]["defaults"]["hunger"], 80.0), "ExperimentConfig état initial : la faim dynamique doit être distincte et valide.")
	var dynamic_as_fixed := ExperimentConfig.from_raw({"agents": {"defaults": {"hunger": 80.0}}})
	_expect(not dynamic_as_fixed.is_valid(), "ExperimentConfig état initial : une variable dynamique ne doit pas être acceptée comme configuration fixe.")
	var legacy_duration := ExperimentConfig.from_raw({"simulation": {"max_wall_seconds": 12.0}})
	_expect(legacy_duration.is_valid() and is_equal_approx(legacy_duration.normalized["simulation"]["max_simulation_seconds"], 12.0), "ExperimentConfig migration : max_wall_seconds doit rester accepté.")

func _test_experiment_config_validation() -> void:
	var out_of_bounds := ExperimentConfig.from_raw({"agents": {"defaults": {"move_speed": 999.0}}})
	_expect(not out_of_bounds.is_valid(), "ExperimentConfig validation : une valeur hors bornes a été acceptée.")

	var unknown_key := ExperimentConfig.from_raw({"agents": {"defaults": {"variable_inexistante": 1.0}}})
	_expect(not unknown_key.is_valid(), "ExperimentConfig validation : une clé inconnue a été acceptée.")

	var probabilities_over_one := ExperimentConfig.from_raw({"agents": {"defaults": {"follow_probability": 0.7, "avoid_probability": 0.6}}})
	_expect(not probabilities_over_one.is_valid(), "ExperimentConfig validation : follow_probability + avoid_probability > 1 a été accepté.")

func _test_danger_zone_contract() -> void:
	# Phase 0 v3 : sans paramètres de danger, les anciens JSON restent valides et la
	# mécanique demeure désactivée. Les effets, collisions et événements sont introduits
	# seulement en Phase 1.
	var legacy := ExperimentConfig.from_raw({"environment": {"game_config": {"ronce_count": 30}}})
	_expect(legacy.is_valid(), "Danger Phase 0 : un ancien JSON sans paramètres de danger doit rester valide.")
	_expect(not legacy.normalized["environment"]["game_config"].has("danger_zone_count"), "Danger Phase 0 : la normalisation ne doit pas injecter de clé dans un ancien JSON.")
	_expect(GameConfig.danger_zone_count == 0, "Danger Phase 0 : le défaut zéro doit désactiver strictement les zones dangereuses.")

	var configured := ExperimentConfig.from_raw({"environment": {"game_config": {
		"danger_zone_count": 2,
		"danger_zone_radius": 6.0,
		"danger_hunger_cost_rate": 1.5,
		"danger_zone_visible": true,
		"danger_zone_safety_radius": 10.0,
	}}})
	_expect(configured.is_valid(), "Danger Phase 0 : les paramètres de contrat valides doivent être acceptés.")
	_expect(configured.normalized["environment"]["game_config"]["danger_zone_count"] == 2, "Danger Phase 0 : le nombre de zones doit être normalisé.")
	_expect(is_equal_approx(configured.normalized["environment"]["game_config"]["danger_hunger_cost_rate"], 1.5), "Danger Phase 0 : le coût de faim doit être normalisé.")
	var invalid_radius := ExperimentConfig.from_raw({"environment": {"game_config": {"danger_zone_radius": 0.0}}})
	_expect(not invalid_radius.is_valid(), "Danger Phase 0 : un rayon nul doit être refusé quand une zone est configurée.")

	# Les quatre scénarios sont purs à cette phase : ils verrouillent le calcul avant
	# son raccord à Character et Area3D en Phase 1.
	_expect(is_equal_approx(DangerContract.hunger_cost([], 5.0), 0.0), "Danger Phase 0 : zéro zone ne doit produire aucun coût.")
	_expect(is_equal_approx(DangerContract.hunger_cost([1.5], 4.0), 6.0), "Danger Phase 0 : une exposition simple doit coûter taux × durée simulée.")
	_expect(is_equal_approx(DangerContract.hunger_cost([1.5, 0.75], 4.0), 6.0), "Danger Phase 0 : deux zones superposées doivent appliquer le coût maximal, pas la somme.")
	_expect(is_equal_approx(DangerContract.hunger_cost([], 2.0), 0.0), "Danger Phase 0 : après sortie, le coût de danger doit cesser immédiatement.")

func _test_danger_approach_placement_contract() -> void:
	_expect((VariableRegistry.GAME_CONFIG["danger_zone_placement_mode"]["options"] as Array).has(DangerPlacement.MODE_APPROCHE_RONCIER), "Danger approche : le mode approche_roncier doit être déclaré.")
	var configured := ExperimentConfig.from_raw({"environment": {"game_config": {
		"danger_zone_count": 2,
		"danger_zone_radius": 6.0,
		"danger_zone_placement_mode": DangerPlacement.MODE_APPROCHE_RONCIER,
		"danger_zone_approach_spawn_index": 0,
		"danger_zone_approach_clearance": 2.0,
	}}})
	_expect(configured.is_valid(), "Danger approche : les paramètres de placement valides doivent être acceptés.")
	_expect(configured.normalized["environment"]["game_config"]["danger_zone_placement_mode"] == DangerPlacement.MODE_APPROCHE_RONCIER, "Danger approche : le mode doit être normalisé.")
	var invalid_spawn := ExperimentConfig.from_raw({"environment": {"game_config": {"danger_zone_approach_spawn_index": 4}}})
	_expect(not invalid_spawn.is_valid(), "Danger approche : un index de spawn hors [0,3] doit être refusé.")
	var spawn := Vector3(-40.0, 0.0, -40.0)
	var ronce := Vector3(20.0, 0.5, 20.0)
	var placed := DangerPlacement.approach_position(spawn, ronce, 6.0, 2.0)
	var horizontal_offset := placed - ronce
	horizontal_offset.y = 0.0
	_expect(is_equal_approx(horizontal_offset.length(), 8.0), "Danger approche : la zone doit rester à rayon + marge du roncier source.")
	var spawn_to_ronce := ronce - spawn
	spawn_to_ronce.y = 0.0
	var spawn_to_zone := placed - spawn
	spawn_to_zone.y = 0.0
	_expect(spawn_to_zone.normalized().is_equal_approx(spawn_to_ronce.normalized()), "Danger approche : la zone doit être sur le segment spawn-roncier.")
	_expect(DangerPlacement.approach_position(spawn, spawn, 6.0, 2.0).is_zero_approx(), "Danger approche : un roncier confondu avec le spawn ne doit pas produire de position exploitable.")

func _test_danger_zone_integration() -> void:
	var character := _make_character()
	character.hunger = 100.0
	character.hunger_depletion_rate = 0.0
	character.move_speed = 0.0
	var danger_a := TestDangerZone.new()
	danger_a.zone_id = "danger_test_a"
	danger_a.hunger_cost_rate = 1.5
	var danger_b := TestDangerZone.new()
	danger_b.zone_id = "danger_test_b"
	danger_b.hunger_cost_rate = 0.75
	get_tree().root.add_child(danger_a)
	get_tree().root.add_child(danger_b)
	character.set_danger_zones([danger_a, danger_b])
	character._physics_process(2.0)
	_expect(is_equal_approx(character.hunger, 97.0), "Danger Phase 1 : le coût mesuré doit être taux maximal × durée simulée.")
	_expect(character.danger_entries_total == 2, "Danger Phase 1 : les entrées de zone doivent être comptées.")
	_expect(is_equal_approx(character.danger_exposure_seconds_total, 2.0), "Danger Phase 1 : la durée d'exposition doit utiliser le temps simulé.")
	_expect(is_equal_approx(character.danger_hunger_cost_total, 3.0), "Danger Phase 1 : le coût cumulé de danger est incohérent.")
	character.position = Vector3(10.0, 0.0, 0.0)
	character._physics_process(1.0)
	_expect(is_equal_approx(character.danger_hunger_cost_total, 3.0), "Danger Phase 1 : le coût doit cesser à la sortie.")
	character.queue_free()
	danger_a.queue_free()
	danger_b.queue_free()

func _test_experiment_config_teleport_event() -> void:
	# Phase 2 v3 : l'événement teleport_agent scripte l'entrée/sortie d'un agent dans une
	# zone dangereuse en headless, sans manipulation fenêtrée (contrat Phase 2).
	var valid := ExperimentConfig.from_raw({"events": [{"type": "teleport_agent", "at_seconds": 1.0, "agent": "Rouge", "position": [1.0, 0.0, 2.0]}]})
	_expect(valid.is_valid(), "ExperimentConfig events : un événement teleport_agent valide doit être accepté.")
	_expect(valid.normalized["events"].size() == 1, "ExperimentConfig events : l'événement teleport_agent normalisé doit être conservé.")
	var missing_agent := ExperimentConfig.from_raw({"events": [{"type": "teleport_agent", "at_seconds": 1.0, "position": [1.0, 0.0, 2.0]}]})
	_expect(not missing_agent.is_valid(), "ExperimentConfig events : teleport_agent sans agent doit être refusé.")
	var bad_position := ExperimentConfig.from_raw({"events": [{"type": "teleport_agent", "at_seconds": 1.0, "agent": "Rouge", "position": [1.0, 0.0]}]})
	_expect(not bad_position.is_valid(), "ExperimentConfig events : teleport_agent avec une position incomplète doit être refusé.")

func _make_danger(local_position: Vector3, cost_rate: float = 1.0, radius: float = 2.0) -> Area3D:
	var zone := Area3D.new()
	zone.set_script(load("res://scripts/danger_zone.gd"))
	zone.zone_id = "test_danger"
	zone.radius = radius
	zone.hunger_cost_rate = cost_rate
	zone.position = local_position
	get_tree().root.add_child(zone)
	zone.add_to_group("perceptible")
	return zone

## Phase 2 v3 : la zone dangereuse rejoint le groupe "perceptible" générique (comme un
## roncier) et suit les mêmes règles de portée, d'angle et d'occlusion — cas « devant ».
func _test_danger_perception_visible_direction_and_distance() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 90.0
	character.vision_blocked_by_terrain = false
	var ahead := _make_danger(Vector3(0.0, 0.0, -5.0))
	character._update_vision_perception()
	var info: Dictionary = character._visible_danger_info()
	_expect(bool(info["has_visible_danger"]), "Danger Phase 2 : un danger devant, dans la portée, doit être perçu.")
	_expect(Vector3(info["visible_danger_direction"]).is_equal_approx(Vector3(0, 0, -1)), "Danger Phase 2 : la direction perçue doit pointer vers le danger.")
	_expect(is_equal_approx(float(info["visible_danger_distance"]), 5.0), "Danger Phase 2 : la distance perçue doit être correcte.")
	character.free()
	ahead.free()

## Cas « derrière » : hors du champ de vision angulaire, un danger n'est pas perçu — même
## mécanisme générique que pour un roncier (_test_vision_range_and_angle).
func _test_danger_perception_behind_ignored() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 90.0
	character.vision_blocked_by_terrain = false
	var behind := _make_danger(Vector3(0.0, 0.0, 5.0))
	character._update_vision_perception()
	_expect(not bool(character._visible_danger_info()["has_visible_danger"]), "Danger Phase 2 : un danger hors du champ de vision ne doit pas être perçu.")
	character.free()
	behind.free()

## Cas « hors portée ».
func _test_danger_perception_out_of_range_ignored() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 10.0
	character.vision_angle_degrees = 360.0
	character.vision_blocked_by_terrain = false
	var far := _make_danger(Vector3(0.0, 0.0, -50.0))
	character._update_vision_perception()
	_expect(not bool(character._visible_danger_info()["has_visible_danger"]), "Danger Phase 2 : un danger hors de portée ne doit pas être perçu.")
	character.free()
	far.free()

## Cas « zone déjà occupée » : un danger physiquement subi (in_danger) doit produire une
## direction d'éloignement stable même quand la vision ne le perçoit pas (ici vision
## nulle, qui recouvre aussi le cas d'un danger occlus ou hors du champ de vision alors
## que l'agent est déjà dedans) — l'exposition physique prime sur la perception visuelle.
func _test_danger_response_direction_prioritizes_active_zone() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 0.0
	character.hunger_depletion_rate = 0.0
	character.move_speed = 0.0
	var zone := TestDangerZone.new()
	zone.zone_id = "danger_occupied"
	zone.radius = 4.0
	zone.hunger_cost_rate = 1.0
	zone.position = Vector3(2.0, 0.0, 0.0)
	get_tree().root.add_child(zone)
	character.set_danger_zones([zone])
	character._physics_process(0.5)
	var info: Dictionary = character._visible_danger_info()
	_expect(not bool(info["has_visible_danger"]), "Danger Phase 2 : ce scénario suppose une zone occupée non visible (vision nulle).")
	_expect(bool(character._active_danger_zones.has("danger_occupied")), "Danger Phase 2 : la zone occupée doit être physiquement active.")
	var response: Vector3 = character._danger_response_direction(info)
	_expect(not response.is_zero_approx(), "Danger Phase 2 : une zone déjà occupée doit produire une direction d'éloignement même sans perception visuelle.")
	_expect(response.is_equal_approx(Vector3(1, 0, 0)), "Danger Phase 2 : la direction doit pointer de l'agent vers le centre de la zone occupée.")
	character.free()
	zone.free()

## Phase 3 (roadmap_environnement_apprenable_v3) : un danger seulement visible au-delà de
## danger_reaction_range ne doit pas déclencher de réponse, même s'il reste perçu (la
## perception, elle, suit toujours vision_range).
func _test_danger_response_direction_respects_reaction_range() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 360.0
	character.vision_blocked_by_terrain = false
	character.danger_reaction_range = 5.0
	var far := _make_danger(Vector3(0.0, 0.0, -8.0))
	character._update_vision_perception()
	var info: Dictionary = character._visible_danger_info()
	_expect(bool(info["has_visible_danger"]), "Danger Phase 3 : un danger dans vision_range doit rester perçu même au-delà de danger_reaction_range.")
	var response: Vector3 = character._danger_response_direction(info)
	_expect(response.is_zero_approx(), "Danger Phase 3 : un danger visible au-delà de danger_reaction_range ne doit produire aucune direction de réponse.")
	character.free()
	far.free()

func _test_danger_response_direction_within_reaction_range() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 20.0
	character.vision_angle_degrees = 360.0
	character.vision_blocked_by_terrain = false
	character.danger_reaction_range = 5.0
	var near := _make_danger(Vector3(0.0, 0.0, -3.0))
	character._update_vision_perception()
	var info: Dictionary = character._visible_danger_info()
	var response: Vector3 = character._danger_response_direction(info)
	_expect(response.is_equal_approx(Vector3(0, 0, -1)), "Danger Phase 3 : un danger visible sous danger_reaction_range doit produire la direction normale.")
	character.free()
	near.free()

## Une zone physiquement subie déclenche toujours la réponse, y compris avec
## danger_reaction_range à 0 : l'exposition prime, elle n'est jamais soumise à ce filtre.
func _test_danger_response_direction_active_zone_ignores_reaction_range() -> void:
	var character := _make_character()
	character.position = Vector3.ZERO
	character.vision_range = 0.0
	character.hunger_depletion_rate = 0.0
	character.move_speed = 0.0
	character.danger_reaction_range = 0.0
	var zone := TestDangerZone.new()
	zone.zone_id = "danger_occupied_reaction"
	zone.radius = 4.0
	zone.hunger_cost_rate = 1.0
	zone.position = Vector3(2.0, 0.0, 0.0)
	get_tree().root.add_child(zone)
	character.set_danger_zones([zone])
	character._physics_process(0.5)
	var info: Dictionary = character._visible_danger_info()
	var response: Vector3 = character._danger_response_direction(info)
	_expect(not response.is_zero_approx(), "Danger Phase 3 : danger_reaction_range ne doit jamais s'appliquer à une zone physiquement active.")
	character.free()
	zone.free()

func _test_danger_detour() -> void:
	var script = preload("res://scripts/danger_detour.gd")
	var destination := {"id": "resource", "position": Vector3(12, 0, 0)}
	var zone := {"id": "zone", "position": Vector3.ZERO, "radius": 6.0}
	for step in [1.0 / 60.0, 1.0 / 30.0]:
		var nav = script.new()
		var pos := Vector3(-10, 0, 0)
		var min_distance := INF
		var kept_side := 0.0
		var resumed := false
		for tick in range(900):
			var candidate: Dictionary = destination if tick == 0 else {"id": "other", "position": Vector3(-20, 0, 20)}
			var direction: Vector3 = nav.steer(pos, candidate, [zone] if tick == 0 else [], step)
			if tick == 0:
				kept_side = nav.side
			if nav.phase == "detour":
				_expect(nav.side == kept_side, "Contournement : côté conservé sans visibilité.")
			if not nav.target.is_empty():
				_expect(nav.target["id"] == "resource", "Contournement : cible conservée malgré nouvelle ressource.")
			resumed = resumed or nav.phase == "resume"
			if nav.reason == "arrived":
				break
			pos += direction * 5.0 * step
			min_distance = minf(min_distance, pos.length())
		_expect(pos.distance_to(destination["position"]) <= script.ARRIVAL, "Contournement : ressource atteinte.")
		_expect(min_distance > 6.0 and resumed, "Contournement : sans exposition puis reprise directe.")
	var nav = script.new()
	_expect(nav.steer(Vector3(-10, 0, 20), destination, [zone], 0.1).is_zero_approx(), "Contournement : danger hors trajet ignoré.")
	nav.steer(Vector3(-10, 0, 0), destination, [zone], 0.1)
	nav.steer(Vector3(-10, 0, 0), {}, [], 0.1, ["resource"])
	_expect(nav.target.is_empty() and nav.reason == "target_invalid", "Contournement : ressource vidée libère la cible.")
	nav.steer(Vector3(-10, 0, 0), destination, [zone], 0.1)
	nav.steer(Vector3(-10, 0, 0), {}, [], 31.0)
	_expect(nav.target.is_empty() and nav.reason == "timeout", "Contournement : blocage physique borné.")
	var escape: Vector3 = nav.steer(Vector3.ZERO, destination, [zone], 0.1)
	_expect(escape.is_finite() and not escape.is_zero_approx(), "Contournement : centre de zone non singulier.")

func _test_fixed_policy_danger_dispatch() -> void:
	_expect(VariableRegistry.CHARACTER.has("fixed_policy_danger"), "Politique fixe danger registre : fixed_policy_danger (Phase 2 v3) doit être déclaré.")
	_expect((VariableRegistry.CHARACTER["fixed_policy_danger"]["options"] as Array).has("eviter"), "Politique fixe danger registre : 'eviter' doit figurer dans les options de fixed_policy_danger.")
	var character := _make_character()
	character.decider_type = "politique_fixe"
	character.fixed_policy_danger = "eviter"
	var fixed = character._build_decider()
	_expect(fixed is FixedPolicyDecider and fixed.fixed_policy_danger == "eviter", "Politique fixe danger dispatch : fixed_policy_danger doit être transmis au décideur.")
	character.queue_free()

## Observation de base hors situation de faim (fixed_policy_s1/s2/s3 sans effet), pour
## isoler la surcouche danger de la politique alimentaire — cf. principe d'isolation de la
## Phase 2 (roadmap_environnement_apprenable_v3).
func _test_detour_collision_recovery() -> void:
	var nav = preload("res://scripts/danger_detour.gd").new()
	var target := {"id": "resource", "position": Vector3(12, 0, 0)}
	var zone := {"id": "zone", "position": Vector3.ZERO, "radius": 6.0}
	var pos := Vector3(-10, 0, 0)
	nav.steer(pos, target, [zone], 0.1)
	var original_side: float = nav.side
	var reversals := 0
	for i in range(50):
		nav.steer(pos, {}, [], 0.1)
		if nav.reason == "blocked_reverse":
			reversals += 1
	_expect(reversals == 1 and nav.side == -original_side, "Contournement : un seul changement de côté après collision persistante.")
	_expect(nav.target["id"] == "resource", "Contournement : collision conserve la cible.")
	for i in range(400):
		var direction: Vector3 = nav.steer(pos, {}, [], 1.0 / 60.0)
		if nav.reason == "arrived":
			break
		pos += direction * 5.0 / 60.0
	_expect(pos.distance_to(target["position"]) < 0.8, "Contournement : rejoint la cible après récupération de collision.")

func _test_detour_decider_integration() -> void:
	var decider := _make_fixed_danger_decider("eviter", 7)
	decider.danger_navigation_mode = "contournement"
	var obs := _fixed_danger_observation({
		"hunger": 40.0, "has_visible_ronce": true,
		"position": Vector3(-10, 0, 0), "danger_response_direction": Vector3.RIGHT,
		"visible_ronce_direction": Vector3.RIGHT,
		"navigation_targets": {"ronce_visible": {"id": "resource", "position": Vector3(12, 0, 0)}},
		"navigation_dangers": [{"id": "zone", "position": Vector3.ZERO, "radius": 6.0}],
	})
	var action := decider.decide(obs)
	_expect(action["goal"] == "danger_detour", "Contournement : raccord au décideur fixe.")
	obs["danger_response_direction"] = Vector3.ZERO
	obs["navigation_dangers"] = []
	obs["navigation_targets"] = {}
	obs["has_visible_ronce"] = false
	action = decider.decide(obs)
	_expect(action["goal"] == "danger_detour", "Contournement : poursuit après perte de vision.")
	obs["manual_control"] = true
	action = decider.decide(obs)
	_expect(action["goal"] == "controle_manuel" and decider._detour.target.is_empty(), "Contournement : contrôle manuel annule la cible.")
	obs["manual_control"] = false
	obs["has_visible_ronce"] = true
	obs["danger_response_direction"] = Vector3.RIGHT
	obs["navigation_targets"] = {"ronce_visible": {"id": "resource", "position": Vector3(12, 0, 0)}}
	obs["navigation_dangers"] = [{"id": "zone", "position": Vector3.ZERO, "radius": 6.0}]
	var random_decider := _make_fixed_danger_decider("aleatoire", 7)
	random_decider.danger_navigation_mode = "contournement"
	random_decider._danger_aleatoire_timer = 1.0
	random_decider._danger_aleatoire_choice = "eviter"
	var random_action := random_decider.decide(obs)
	var fixed_action := decider.decide(obs)
	_expect(random_action == fixed_action, "Contournement : même primitive pour le choix aléatoire eviter.")
	random_decider._danger_aleatoire_choice = "viser"
	random_action = random_decider.decide(obs)
	_expect(random_action["goal"] == "danger_viser" and random_decider._detour.target.is_empty(), "Contournement : choix viser annule le détour.")
	_expect(decider.updates_total == 0 and random_decider.updates_total == 0, "Contournement : aucune mise à jour du learner.")
	decider._detour.reset()
	obs["position"] = Vector3.ZERO
	obs["danger_response_direction"] = Vector3.ZERO
	obs["in_danger"] = true
	action = decider.decide(obs)
	_expect(action["goal"] == "danger_detour" and not action["direction"].is_zero_approx(), "Contournement : démarre aussi au centre exact du danger.")

func _fixed_danger_observation(overrides: Dictionary = {}) -> Dictionary:
	var observation := _adaptive_observation({
		"hunger": 95.0,
		"has_visible_ronce": false,
		"has_memories": false,
		"in_danger": false,
		"has_visible_danger": false,
		"visible_danger_direction": Vector3.ZERO,
		"visible_danger_distance": 0.0,
		"danger_response_direction": Vector3.ZERO,
	})
	for key in overrides:
		observation[key] = overrides[key]
	return observation

func _make_fixed_danger_decider(danger_action: String, rng_seed: int = 0) -> FixedPolicyDecider:
	var decider := FixedPolicyDecider.new()
	decider.configure_fixed(AdaptiveDecider.ACTION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_MEMORISEE, AdaptiveDecider.ACTION_ERRANCE, danger_action, 2.0, "Test", rng_seed)
	return decider

func _test_fixed_policy_danger_ignorer_unaffected() -> void:
	var decider := _make_fixed_danger_decider("ignorer")
	var action: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": Vector3(1, 0, 0)}))
	_expect(action["goal"] == AdaptiveDecider.ACTION_ERRANCE, "Danger surcouche : 'ignorer' ne doit jamais modifier l'action de la politique alimentaire.")

func _test_fixed_policy_danger_eviter_overrides_direction() -> void:
	var decider := _make_fixed_danger_decider("eviter")
	var action: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": Vector3(1, 0, 0)}))
	_expect(action["goal"] == "danger_eviter", "Danger surcouche : 'eviter' doit produire le but danger_eviter quand un danger est pertinent.")
	_expect(action["direction"].is_equal_approx(Vector3(-1, 0, 0)), "Danger surcouche : 'eviter' doit orienter la direction à l'opposé du danger.")

func _test_fixed_policy_danger_viser_overrides_direction() -> void:
	var decider := _make_fixed_danger_decider("viser")
	var action: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": Vector3(0, 0, -1)}))
	_expect(action["goal"] == "danger_viser", "Danger surcouche : 'viser' doit produire le but danger_viser quand un danger est pertinent.")
	_expect(action["direction"].is_equal_approx(Vector3(0, 0, -1)), "Danger surcouche : 'viser' doit orienter la direction vers le danger.")

func _test_fixed_policy_danger_no_direction_leaves_action_untouched() -> void:
	var decider := _make_fixed_danger_decider("eviter")
	var action: Dictionary = decider.decide(_fixed_danger_observation())
	_expect(action["goal"] == AdaptiveDecider.ACTION_ERRANCE, "Danger surcouche : sans danger pertinent (direction nulle), la politique alimentaire doit rester inchangée.")

func _test_fixed_policy_danger_respects_manual_control() -> void:
	var decider := _make_fixed_danger_decider("eviter")
	var action: Dictionary = decider.decide(_fixed_danger_observation({"manual_control": true, "manual_direction": Vector3(0, 0, 1), "danger_response_direction": Vector3(1, 0, 0)}))
	_expect(action["goal"] == "controle_manuel", "Danger surcouche : le contrôle manuel ne doit jamais être remplacé par la surcouche danger.")

func _test_fixed_policy_danger_aleatoire_registry() -> void:
	_expect((VariableRegistry.CHARACTER["fixed_policy_danger"]["options"] as Array).has("aleatoire"), "Politique fixe danger registre : 'aleatoire' (Phase 3 v3) doit figurer dans les options de fixed_policy_danger.")

## 'aleatoire' doit toujours retomber sur eviter ou viser (jamais 'ignorer' ni une action de
## la politique alimentaire), et la direction doit toujours être colinéaire à l'axe du danger.
## delta > decision_interval_seconds (2.0) à chaque appel pour forcer un nouveau tirage :
## sinon le choix est tenu (cf. _test_fixed_policy_danger_aleatoire_choice_held_within_window).
func _test_fixed_policy_danger_aleatoire_only_eviter_or_viser() -> void:
	var decider := _make_fixed_danger_decider("aleatoire", 7)
	var toward := Vector3(1, 0, 0)
	var saw_eviter := false
	var saw_viser := false
	for _i in range(40):
		var action: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 3.0}))
		_expect(action["goal"] == "danger_eviter" or action["goal"] == "danger_viser", "Danger surcouche 'aleatoire' : chaque tirage doit résoudre en danger_eviter ou danger_viser.")
		if action["goal"] == "danger_eviter":
			saw_eviter = true
			_expect(action["direction"].is_equal_approx(-toward), "Danger surcouche 'aleatoire' : la branche eviter doit orienter à l'opposé du danger.")
		else:
			saw_viser = true
			_expect(action["direction"].is_equal_approx(toward), "Danger surcouche 'aleatoire' : la branche viser doit orienter vers le danger.")
	_expect(saw_eviter and saw_viser, "Danger surcouche 'aleatoire' : 40 tirages doivent produire les deux issues au moins une fois chacune.")

## Non-régression du bug de calibration Phase 3 : un choix tiré doit être tenu tant que
## decision_interval_seconds (2.0 dans _make_fixed_danger_decider) n'est pas écoulé, sinon
## decide() étant appelé à chaque frame physique, un nouveau tirage à chaque appel ferait
## osciller la direction en moyenne nulle (le bras aleatoire reproduisait alors exactement
## les statistiques du bras eviter sur les 96 runs de calibration).
func _test_fixed_policy_danger_aleatoire_choice_held_within_window() -> void:
	var decider := _make_fixed_danger_decider("aleatoire", 7)
	var toward := Vector3(1, 0, 0)
	var first: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 0.0}))
	for _i in range(20):
		var action: Dictionary = decider.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 0.05}))
		_expect(action["goal"] == first["goal"], "Danger surcouche 'aleatoire' : le choix doit être tenu tant que decision_interval_seconds n'est pas écoulé.")

## Reproductibilité : même rng_seed -> même séquence de tirages. Le rng_seed est dérivé de
## decider_seed + hash(display_name) (character.gd::_build_decider), donc distinct entre
## seeds d'expérience et entre agents, jamais figé à une constante partagée.
func _test_fixed_policy_danger_aleatoire_deterministic_by_seed() -> void:
	var toward := Vector3(1, 0, 0)
	var decider_a := _make_fixed_danger_decider("aleatoire", 42)
	var decider_b := _make_fixed_danger_decider("aleatoire", 42)
	var decider_c := _make_fixed_danger_decider("aleatoire", 43)
	var sequence_differs := false
	for _i in range(20):
		var goal_a: String = decider_a.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 3.0}))["goal"]
		var goal_b: String = decider_b.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 3.0}))["goal"]
		var goal_c: String = decider_c.decide(_fixed_danger_observation({"danger_response_direction": toward, "delta": 3.0}))["goal"]
		_expect(goal_a == goal_b, "Danger surcouche 'aleatoire' : même rng_seed doit produire la même séquence de tirages.")
		if goal_a != goal_c:
			sequence_differs = true
	_expect(sequence_differs, "Danger surcouche 'aleatoire' : deux rng_seed distincts doivent produire des séquences différentes sur 20 tirages.")

func _test_fixed_policy_danger_aleatoire_no_direction_leaves_action_untouched() -> void:
	var decider := _make_fixed_danger_decider("aleatoire")
	var action: Dictionary = decider.decide(_fixed_danger_observation())
	_expect(action["goal"] == AdaptiveDecider.ACTION_ERRANCE, "Danger surcouche 'aleatoire' : sans danger pertinent (direction nulle), la politique alimentaire doit rester inchangée.")

func _find_memory_slider(node: Node) -> HSlider:
	if node is HBoxContainer and node.get_child_count() >= 2:
		var label := node.get_child(0) as Label
		var slider := node.get_child(1) as HSlider
		if label != null and label.text == "Mémoire" and slider != null:
			return slider
	for child in node.get_children():
		var result := _find_memory_slider(child)
		if result != null:
			return result
	return null

func _test_memory_slider() -> void:
	var character := _make_character()
	var camera := Camera3D.new()
	get_tree().root.add_child(camera)
	var ui := CanvasLayer.new()
	ui.set_script(load("res://scripts/ui_manager.gd"))
	get_tree().root.add_child(ui)
	ui.setup([{
		"node": character,
		"name": "Test",
		"color": Color.WHITE,
		"corner": "top_left",
	}], camera, true)
	ui.set_test_character(character)
	var slider := _find_memory_slider(ui)
	_expect(slider != null, "Test 11 : le slider Mémoire est introuvable.")
	if slider != null:
		slider.value = 2
		_expect(character.memory_capacity == 2, "Test 11 : le slider Mémoire ne modifie pas la capacité.")
		var ronciers: Array[TestRonce] = []
		for i in 3:
			var ronce := TestRonce.new()
			ronciers.append(ronce)
			get_tree().root.add_child(ronce)
			character._remember_ronce(ronce)
		_expect(character.memorized_ronces_count() == 2, "Test 11 : la capacité de mémoire choisie par le slider n'est pas respectée.")
		for ronce in ronciers:
			ronce.queue_free()
	ui.queue_free()
	camera.queue_free()
	character.queue_free()

func _adaptive_observation(overrides: Dictionary = {}) -> Dictionary:
	var observation := {
		"manual_control": false,
		"manual_direction": Vector3.ZERO,
		"hunger": 50.0,
		"pickup_hunger_threshold": 90.0,
		"eat_hunger_threshold": 50.0,
		"berries_carried": 0,
		"berries_picked_total": 0,
		"max_berries_carried": 3,
		"elapsed_seconds": 0.0,
		"has_memories": false,
		"memory_direction": Vector3(0, 0, -1),
		"old_memory_direction": Vector3.ZERO,
		"has_visible_ronce": false,
		"visible_ronce_direction": Vector3(1, 0, 0),
		"unknown_zone_direction": Vector3.ZERO,
		"known_zone_direction": Vector3.ZERO,
		"social_goal": "",
		"social_direction": Vector3.ZERO,
		"current_direction": Vector3(0, 0, 1),
		"wander_timer": 5.0,
		"delta": 0.1,
	}
	for key in overrides:
		observation[key] = overrides[key]
	return observation

func _test_adaptive_situations() -> void:
	var decider := AdaptiveDecider.new()
	var visible := _adaptive_observation({"has_visible_ronce": true, "has_memories": true})
	var memorized := _adaptive_observation({"has_memories": true})
	var unknown := _adaptive_observation()
	_expect(decider.classify(visible) == AdaptiveDecider.SITUATION_RONCE_VISIBLE, "Adaptatif S1 : un roncier visible doit donner la situation S1.")
	_expect(decider.classify(memorized) == AdaptiveDecider.SITUATION_MEMOIRE, "Adaptatif S2 : un souvenir sans roncier visible doit donner la situation S2.")
	_expect(decider.classify(unknown) == AdaptiveDecider.SITUATION_INCONNU, "Adaptatif S3 : ni visible ni mémorisé doit donner la situation S3.")

	_expect(decider.available_actions(AdaptiveDecider.SITUATION_RONCE_VISIBLE, visible).size() == 3, "Adaptatif S1 : trois actions valides attendues avec un souvenir disponible.")
	var visible_no_memory := _adaptive_observation({"has_visible_ronce": true})
	_expect(not decider.available_actions(AdaptiveDecider.SITUATION_RONCE_VISIBLE, visible_no_memory).has(AdaptiveDecider.ACTION_RONCE_MEMORISEE), "Adaptatif S1 : viser un souvenir inexistant ne doit pas être une action valide.")
	_expect(decider.available_actions(AdaptiveDecider.SITUATION_MEMOIRE, memorized).size() == 3, "Adaptatif S2 : trois actions valides attendues (souvenir proche, souvenir ancien, errance).")
	_expect(not decider.available_actions(AdaptiveDecider.SITUATION_MEMOIRE, unknown).has(AdaptiveDecider.ACTION_SOUVENIR_ANCIEN), "Adaptatif S2 : viser un souvenir ancien inexistant ne doit pas être une action valide.")
	var s3_bare := decider.available_actions(AdaptiveDecider.SITUATION_INCONNU, unknown)
	_expect(s3_bare.has(AdaptiveDecider.ACTION_ERRANCE) and s3_bare.has(AdaptiveDecider.ACTION_CAP_MAINTENU) and s3_bare.has(AdaptiveDecider.ACTION_DEMI_TOUR), "Adaptatif S3 : errance, cap_maintenu et demi_tour sont toujours valides.")
	_expect(s3_bare.size() == 3, "Adaptatif S3 : sans direction de zone exploitable, S3 offre exactement trois actions.")
	var s3_full := decider.available_actions(AdaptiveDecider.SITUATION_INCONNU, _adaptive_observation({"unknown_zone_direction": Vector3(1, 0, 0), "known_zone_direction": Vector3(0, 0, 1)}))
	_expect(s3_full.size() == 5, "Adaptatif S3 : avec zone inconnue et zone connue exploitables, S3 offre cinq actions.")

	var neutral_score := decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE)
	_expect(is_equal_approx(neutral_score, AdaptiveDecider.INITIAL_SCORE), "Adaptatif : la table doit être initialisée neutre.")

## Phase 3 : les actions de navigation de S3 portent une direction explicite issue de
## l'observation ; le décideur les engage réellement au lieu de court-circuiter sur une
## action unique, et retombe sur le repli quand leur direction est indisponible.
func _test_adaptive_navigation_actions() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.2, 0.0, 10.0, 5, "Test")
	var obs := _adaptive_observation({
		"hunger": 20.0,
		"current_direction": Vector3(0, 0, 1),
		"unknown_zone_direction": Vector3(1, 0, 0),
		"known_zone_direction": Vector3(-1, 0, 0),
	})

	_expect(decider._build_targeted_action(AdaptiveDecider.ACTION_CAP_MAINTENU, obs)["direction"].is_equal_approx(Vector3(0, 0, 1)), "Adaptatif nav : cap_maintenu suit la direction courante.")
	_expect(decider._build_targeted_action(AdaptiveDecider.ACTION_DEMI_TOUR, obs)["direction"].is_equal_approx(Vector3(0, 0, -1)), "Adaptatif nav : demi_tour inverse la direction courante.")
	_expect(decider._build_targeted_action(AdaptiveDecider.ACTION_ZONE_INCONNUE, obs)["direction"].is_equal_approx(Vector3(1, 0, 0)), "Adaptatif nav : zone_inconnue suit la direction de zone inconnue de l'observation.")
	_expect(decider._build_targeted_action(AdaptiveDecider.ACTION_ZONE_CONNUE, obs)["direction"].is_equal_approx(Vector3(-1, 0, 0)), "Adaptatif nav : zone_connue suit la direction de zone connue de l'observation.")
	_expect(decider._build_targeted_action(AdaptiveDecider.ACTION_ZONE_INCONNUE, _adaptive_observation({"hunger": 20.0})).is_empty(), "Adaptatif nav : zone_inconnue sans direction retombe sur le repli.")

	# Une décision en S3 engage bien l'action au meilleur score, sans court-circuit.
	decider.set_score(AdaptiveDecider.SITUATION_INCONNU, AdaptiveDecider.ACTION_ZONE_INCONNUE, 1.0)
	var chosen: Dictionary = decider.decide(obs)
	_expect(chosen["goal"] == AdaptiveDecider.ACTION_ZONE_INCONNUE, "Adaptatif nav : S3 engage l'action de navigation au meilleur score.")
	_expect(chosen["direction"].is_equal_approx(Vector3(1, 0, 0)), "Adaptatif nav : la direction engagée en S3 est celle de l'action choisie.")
	_expect(decider.decisions_total == 1 and decider.engaged_action() == AdaptiveDecider.ACTION_ZONE_INCONNUE, "Adaptatif nav : l'action de navigation S3 est tenue comme une décision engagée.")

func _test_adaptive_greedy_selection() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.2, 0.0, 0.0, 42, "Test")
	var observation := _adaptive_observation({"has_visible_ronce": true, "has_memories": true})
	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_MEMORISEE, 0.9)
	for i in 20:
		var action: Dictionary = decider.decide(observation)
		_expect(action["goal"] == AdaptiveDecider.ACTION_RONCE_MEMORISEE, "Adaptatif ε=0 : l'action au meilleur score doit toujours être choisie.")
		_expect(not decider.last_explored, "Adaptatif ε=0 : aucune décision ne doit être marquée comme exploration.")
	_expect(decider.pending_decision()["situation"] == AdaptiveDecider.SITUATION_RONCE_VISIBLE, "Adaptatif : la décision en attente doit mémoriser la situation.")
	_expect(is_equal_approx(float(decider.pending_decision()["hunger"]), 50.0), "Adaptatif : la décision en attente doit mémoriser la faim du moment.")

	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE, 1.5)
	var best_action: Dictionary = decider.decide(observation)
	_expect(best_action["goal"] == AdaptiveDecider.ACTION_RONCE_VISIBLE, "Adaptatif ε=0 : le changement de meilleur score doit changer l'action choisie.")

func _test_adaptive_matches_baseline_outside_hunger() -> void:
	var adaptive := AdaptiveDecider.new()
	adaptive.configure(0.2, 0.5, 0.0, 7, "Test")
	var baseline := BaselineDecider.new()

	var manual := _adaptive_observation({"manual_control": true, "manual_direction": Vector3(1, 0, 0)})
	_expect(adaptive.decide(manual) == baseline.decide(manual), "Adaptatif : le contrôle manuel doit être identique à l'automate.")

	var social := _adaptive_observation({"hunger": 95.0, "social_goal": "suivi", "social_direction": Vector3(0, 0, -1)})
	_expect(adaptive.decide(social) == baseline.decide(social), "Adaptatif : hors situation de faim, le but social doit être identique à l'automate.")

	var wander := _adaptive_observation({"hunger": 95.0, "wander_timer": 0.05})
	_expect(adaptive.decide(wander) == baseline.decide(wander), "Adaptatif : hors situation de faim, l'errance doit être identique à l'automate.")

	var wander_no_renew := _adaptive_observation({"hunger": 95.0})
	_expect(adaptive.decide(wander_no_renew) == baseline.decide(wander_no_renew), "Adaptatif : hors situation de faim, l'errance sans réorientation doit être identique à l'automate.")

	# S3, sélection gloutonne, table neutre : errance est en tête de liste et retombe sur
	# le comportement de repli (but social puis errance), identique à l'automate.
	var greedy_s3 := AdaptiveDecider.new()
	greedy_s3.configure(0.2, 0.0, 0.0, 7, "Test")
	var hungry_social := _adaptive_observation({"hunger": 20.0, "social_goal": "suivi", "social_direction": Vector3(0, 0, -1)})
	_expect(greedy_s3.decide(hungry_social)["goal"] == "suivi", "Adaptatif S3 : l'action errance doit laisser jouer le but social.")

func _test_adaptive_determinism() -> void:
	var observation := _adaptive_observation({"has_visible_ronce": true, "has_memories": true})
	var first: Array[String] = []
	var second: Array[String] = []
	var diverging: Array[String] = []

	var run_a := AdaptiveDecider.new()
	run_a.configure(0.2, 1.0, 0.0, 4321, "Test")
	for i in 40:
		first.append(String(run_a.decide(observation)["goal"]))

	var run_b := AdaptiveDecider.new()
	run_b.configure(0.2, 1.0, 0.0, 4321, "Test")
	for i in 40:
		second.append(String(run_b.decide(observation)["goal"]))

	var run_c := AdaptiveDecider.new()
	run_c.configure(0.2, 1.0, 0.0, 9999, "Test")
	for i in 40:
		diverging.append(String(run_c.decide(observation)["goal"]))

	_expect(first == second, "Adaptatif : deux exécutions à seed identique doivent produire les mêmes tirages ε-greedy.")
	_expect(first != diverging, "Adaptatif : deux seeds différents doivent produire des tirages différents.")
	_expect(first.has(AdaptiveDecider.ACTION_ERRANCE) and first.has(AdaptiveDecider.ACTION_RONCE_VISIBLE), "Adaptatif ε=1 : l'exploration doit couvrir plusieurs actions valides.")

func _test_adaptive_registry_and_dispatch() -> void:
	var options: Array = VariableRegistry.CHARACTER["decider_type"]["options"]
	_expect(options.has("adaptatif"), "Adaptatif registre : 'adaptatif' doit figurer dans les options de decider_type.")
	_expect(VariableRegistry.CHARACTER.has("learning_rate") and VariableRegistry.CHARACTER.has("exploration_epsilon") and VariableRegistry.CHARACTER.has("adaptive_decision_interval_seconds"), "Adaptatif registre : learning_rate, exploration_epsilon et adaptive_decision_interval_seconds doivent être déclarés.")
	_expect(VariableRegistry.CHARACTER.has("survival_cost_rate") and VariableRegistry.CHARACTER.has("td_discount_gamma"), "Adaptatif registre : survival_cost_rate et td_discount_gamma (Phase 2) doivent être déclarés.")

	var config := ExperimentConfig.from_raw({"agents": {"defaults": {"decider_type": "adaptatif", "learning_rate": 0.3, "exploration_epsilon": 0.1, "adaptive_decision_interval_seconds": 3.0, "survival_cost_rate": 0.1, "td_discount_gamma": 0.8}}})
	_expect(config.is_valid(), "Adaptatif config : une configuration adaptative valide a été rejetée.")

	var character := _make_character()
	character.display_name = "Test"
	character.decider_type = "adaptatif"
	character.learning_rate = 0.3
	character.exploration_epsilon = 0.0
	character.adaptive_decision_interval_seconds = 4.0
	character.survival_cost_rate = 0.2
	character.td_discount_gamma = 0.7
	character.decider_seed = 1337
	var decider = character._build_decider()
	_expect(decider is AdaptiveDecider, "Adaptatif dispatch : decider_type 'adaptatif' doit construire un AdaptiveDecider.")
	_expect(is_equal_approx(decider.learning_rate, 0.3) and is_equal_approx(decider.exploration_epsilon, 0.0) and is_equal_approx(decider.decision_interval_seconds, 4.0), "Adaptatif dispatch : les variables du registre doivent être transmises au décideur.")
	_expect(is_equal_approx(decider.survival_cost_rate, 0.2) and is_equal_approx(decider.td_discount_gamma, 0.7), "Adaptatif dispatch : survival_cost_rate et td_discount_gamma doivent être transmis au décideur.")
	character.decider_type = "automate"
	_expect(character._build_decider() is BaselineDecider, "Adaptatif dispatch : les autres valeurs de decider_type ne doivent pas être affectées.")

	# Phase 3 : la politique fixe route désormais aussi S3 via fixed_policy_s3.
	_expect(VariableRegistry.CHARACTER.has("fixed_policy_s3"), "Politique fixe registre : fixed_policy_s3 (Phase 3) doit être déclaré.")
	_expect((VariableRegistry.CHARACTER["fixed_policy_s3"]["options"] as Array).has(AdaptiveDecider.ACTION_ZONE_INCONNUE), "Politique fixe registre : zone_inconnue doit figurer dans les options de fixed_policy_s3.")
	character.decider_type = "politique_fixe"
	character.fixed_policy_s3 = AdaptiveDecider.ACTION_DEMI_TOUR
	var fixed = character._build_decider()
	_expect(fixed is FixedPolicyDecider and fixed.fixed_action_s3 == AdaptiveDecider.ACTION_DEMI_TOUR, "Politique fixe dispatch : fixed_policy_s3 doit être transmis au décideur.")
	var s3_pick: String = fixed._select_action(AdaptiveDecider.SITUATION_INCONNU, [AdaptiveDecider.ACTION_ERRANCE, AdaptiveDecider.ACTION_DEMI_TOUR])
	_expect(s3_pick == AdaptiveDecider.ACTION_DEMI_TOUR, "Politique fixe S3 : l'action S3 configurée doit être choisie quand elle est valide.")
	character.queue_free()

func _test_adaptive_online_reward() -> void:
	# Récompense événementielle (Phase 2) : +PICK_REWARD par cueillette dans la fenêtre,
	# moins survival_cost_rate * durée, cible amorcée sur l'état suivant.
	var decider := AdaptiveDecider.new()
	decider.configure(0.5, 0.0, 2.0, 5, "Test")
	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE, 0.4)
	decider.decide(_adaptive_observation({"hunger": 40.0, "has_visible_ronce": true, "delta": 0.0, "elapsed_seconds": 0.0, "berries_picked_total": 0}))
	_expect(decider.pending_decision()["action"] == AdaptiveDecider.ACTION_RONCE_VISIBLE, "Adaptatif reward : la première décision doit être mise en attente.")
	_expect(decider.updates_total == 0, "Adaptatif reward : aucune mise à jour tant qu'une seule décision a été prise.")

	# Fenêtre sans cueillette : r = -survival_cost_rate * durée, cible = r + gamma * maxQ(s').
	decider.decide(_adaptive_observation({"hunger": 43.0, "has_visible_ronce": true, "delta": 2.0, "elapsed_seconds": 2.0, "berries_picked_total": 0}))
	var r1 := clampf(0.0 * AdaptiveDecider.PICK_REWARD - decider.survival_cost_rate * 2.0, -1.0, 1.0)
	var boot1 := 0.4
	var target1 := r1 + decider.td_discount_gamma * boot1
	var expected1 := 0.4 + 0.5 * (target1 - 0.4)
	_expect(decider.updates_total == 1, "Adaptatif reward : une reprise de décision doit produire exactement une mise à jour.")
	_expect(is_equal_approx(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE), expected1), "Adaptatif reward : le score doit suivre score += lr * (r + gamma * maxQ(s') - score).")

	# Fenêtre avec une cueillette : picks = 1 -> r positif, cellule tirée vers le haut.
	decider.decide(_adaptive_observation({"hunger": 80.0, "has_visible_ronce": true, "delta": 2.0, "elapsed_seconds": 4.0, "berries_picked_total": 1}))
	var r2 := clampf(1.0 * AdaptiveDecider.PICK_REWARD - decider.survival_cost_rate * 2.0, -1.0, 1.0)
	var target2 := r2 + decider.td_discount_gamma * expected1
	var expected2 := expected1 + 0.5 * (target2 - expected1)
	_expect(is_equal_approx(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE), expected2), "Adaptatif reward : une cueillette dans la fenêtre crédite la cellule tenue.")
	_expect(r2 <= 1.0, "Adaptatif reward : la récompense immédiate reste bornée à +1.")
	_expect(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE) > 0.0, "Adaptatif reward : la cellule finit positive après une cueillette.")

	# Le coût de survie sature la récompense immédiate à -1 sur une longue fenêtre.
	var starving := AdaptiveDecider.new()
	starving.configure(1.0, 0.0, 1.0, 5, "Test")
	starving.survival_cost_rate = 0.1
	starving.decide(_adaptive_observation({"has_visible_ronce": true, "delta": 0.0, "elapsed_seconds": 0.0, "berries_picked_total": 0}))
	starving.decide(_adaptive_observation({"has_visible_ronce": true, "delta": 20.0, "elapsed_seconds": 20.0, "berries_picked_total": 0}))
	_expect(is_equal_approx(starving.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE), -1.0), "Adaptatif reward : le coût de survie sature la récompense immédiate à -1.")

func _test_adaptive_terminal_penalty() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.5, 0.0, 5.0, 5, "Test")
	decider.decide(_adaptive_observation({"hunger": 20.0, "has_visible_ronce": true, "has_memories": true, "delta": 0.0, "elapsed_seconds": 0.0}))
	var pending := decider.pending_decision()
	var before := decider.get_score(pending["situation"], pending["action"])
	var expected := before + 0.5 * (AdaptiveDecider.TERMINAL_REWARD - before)

	decider.on_terminal_starvation()
	_expect(decider.updates_total == 1, "Adaptatif terminal : la pénalité terminale compte pour une mise à jour.")
	_expect(is_equal_approx(decider.get_score(pending["situation"], pending["action"]), expected), "Adaptatif terminal : la mort de faim pénalise la dernière cellule tenue.")

	decider.on_terminal_starvation()
	_expect(decider.updates_total == 1, "Adaptatif terminal : la pénalité terminale ne s'applique qu'une seule fois.")
	_expect(is_equal_approx(decider.get_score(pending["situation"], pending["action"]), expected), "Adaptatif terminal : un second appel ne modifie pas le score.")

	var untouched := AdaptiveDecider.new()
	untouched.configure(0.5, 0.0, 5.0, 5, "Test")
	untouched.on_terminal_starvation()
	_expect(untouched.updates_total == 0, "Adaptatif terminal : sans décision mémorisée, la mort ne produit aucune mise à jour.")

## Attribution du crédit 1 : un scénario scripté d'approche en S1 sur plusieurs fenêtres
## d'engagement, terminé par une cueillette, doit rendre la cellule (S1, ronce_visible)
## positive. Le mécanisme d'avant Phase 2 (variation de faim) la laissait nulle ou
## négative, la faim montant pendant l'approche et le repas tombant hors fenêtre de faim.
func _test_adaptive_credit_assignment_approach() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.5, 0.0, 2.0, 5, "Test")
	decider.survival_cost_rate = 0.05
	decider.td_discount_gamma = 0.9
	# Ancrer l'errance en négatif : l'approche (ronce_visible) reste engagée sur toutes
	# les fenêtres même après des crédits de fenêtre négatifs.
	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_ERRANCE, -1.0)
	var elapsed := 0.0
	decider.decide(_adaptive_observation({"hunger": 35.0, "has_visible_ronce": true, "delta": 0.0, "elapsed_seconds": elapsed, "berries_picked_total": 0}))
	# Trois fenêtres d'approche sans cueillette.
	for i in 3:
		elapsed += 2.0
		decider.decide(_adaptive_observation({"hunger": 35.0, "has_visible_ronce": true, "delta": 2.0, "elapsed_seconds": elapsed, "berries_picked_total": 0}))
	_expect(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE) < 0.0, "Adaptatif crédit : sans cueillette, l'approche reste créditée négativement.")
	# Quatrième reprise : une cueillette est survenue dans la fenêtre écoulée.
	elapsed += 2.0
	decider.decide(_adaptive_observation({"hunger": 80.0, "has_visible_ronce": true, "delta": 2.0, "elapsed_seconds": elapsed, "berries_picked_total": 1}))
	_expect(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE) > 0.0, "Adaptatif crédit : une approche terminée par une cueillette rend la cellule (S1, ronce_visible) positive.")

## Attribution du crédit 2 : amorçage TD. Une fenêtre sans cueillette qui débouche sur un
## état à forte valeur doit hériter de gamma * max Q(s', .), même récompense immédiate
## nulle. Le mécanisme d'avant Phase 2 (moyenne mobile de la récompense immédiate) ne
## propageait aucune valeur entre cellules.
func _test_adaptive_td_bootstrap() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(1.0, 0.0, 2.0, 5, "Test")
	decider.survival_cost_rate = 0.0
	decider.td_discount_gamma = 0.9
	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE, 0.8)
	# Décision en S2 (souvenir), aucune cueillette, puis passage en S1 : le roncier devient visible.
	decider.decide(_adaptive_observation({"has_memories": true, "delta": 0.0, "elapsed_seconds": 0.0, "berries_picked_total": 0}))
	_expect(decider.pending_decision()["situation"] == AdaptiveDecider.SITUATION_MEMOIRE, "Adaptatif TD : la décision en attente doit porter S2.")
	decider.decide(_adaptive_observation({"has_visible_ronce": true, "has_memories": true, "delta": 2.0, "elapsed_seconds": 2.0, "berries_picked_total": 0}))
	# r = 0, target = 0 + 0.9 * maxQ(S1) = 0.9 * 0.8 ; lr = 1 -> score = 0.72.
	_expect(is_equal_approx(decider.get_score(AdaptiveDecider.SITUATION_MEMOIRE, AdaptiveDecider.ACTION_RONCE_MEMORISEE), 0.72), "Adaptatif TD : une fenêtre sans repas hérite de gamma * max Q(s').")

## Sortie de la situation de faim (inventaire plein après cueillette) : la fenêtre en
## cours est clôturée sur ses conséquences réelles, pas laissée en attente pour être
## créditée plus tard sur une durée gonflée et sans ses cueillettes.
func _test_adaptive_flush_on_hunger_exit() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.5, 0.0, 2.0, 5, "Test")
	decider.survival_cost_rate = 0.05
	decider.td_discount_gamma = 0.9
	decider.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_ERRANCE, -1.0)
	decider.decide(_adaptive_observation({"hunger": 40.0, "has_visible_ronce": true, "delta": 0.0, "elapsed_seconds": 0.0, "berries_picked_total": 0}))
	_expect(decider.updates_total == 0, "Adaptatif flush : aucune mise à jour sur la seule décision d'ouverture.")
	# La fenêtre a produit une cueillette ; l'agent sort de la situation de faim (sac plein).
	decider.decide(_adaptive_observation({"hunger": 40.0, "has_visible_ronce": true, "berries_carried": 3, "max_berries_carried": 3, "delta": 2.0, "elapsed_seconds": 2.0, "berries_picked_total": 1}))
	_expect(decider.updates_total == 1, "Adaptatif flush : sortir de la situation de faim clôture la fenêtre en cours.")
	_expect(decider.get_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE) > 0.0, "Adaptatif flush : une cueillette dans la fenêtre laisse la cellule positive même si l'épisode finit par une sortie de faim.")
	_expect(decider.pending_decision().is_empty(), "Adaptatif flush : la décision en attente est purgée à la sortie de la situation de faim.")
	decider.decide(_adaptive_observation({"hunger": 40.0, "has_visible_ronce": true, "berries_carried": 3, "max_berries_carried": 3, "delta": 2.0, "elapsed_seconds": 4.0, "berries_picked_total": 1}))
	_expect(decider.updates_total == 1, "Adaptatif flush : aucune mise à jour supplémentaire hors situation de faim exploitable.")

func _test_adaptive_engagement() -> void:
	var stable := _adaptive_observation({"has_visible_ronce": true, "has_memories": true, "delta": 0.1})

	var held := AdaptiveDecider.new()
	held.configure(0.2, 1.0, 2.0, 31, "Test")
	for i in 20:
		held.decide(stable)
	_expect(held.decisions_total == 1, "Adaptatif engagement : l'action doit être tenue pendant l'intervalle (1 décision attendue sur 2,0 s).")

	var unheld := AdaptiveDecider.new()
	unheld.configure(0.2, 1.0, 0.0, 31, "Test")
	for i in 20:
		unheld.decide(stable)
	_expect(unheld.decisions_total == 20, "Adaptatif engagement : un intervalle nul doit faire redécider à chaque frame.")

	for i in 3:
		held.decide(stable)
	_expect(held.decisions_total == 2, "Adaptatif engagement : une nouvelle décision doit être prise à l'expiration de l'intervalle.")

	# La direction est recalculée à chaque frame : c'est l'action qui est tenue, pas la trajectoire.
	var tracker := AdaptiveDecider.new()
	tracker.configure(0.2, 0.0, 10.0, 31, "Test")
	tracker.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_VISIBLE, 1.0)
	var first: Dictionary = tracker.decide(stable)
	_expect(first["direction"].is_equal_approx(Vector3(1, 0, 0)), "Adaptatif engagement : la direction initiale ne suit pas le roncier visible.")
	var moved := _adaptive_observation({"has_visible_ronce": true, "has_memories": true, "delta": 0.1, "visible_ronce_direction": Vector3(0, 0, -1)})
	var second: Dictionary = tracker.decide(moved)
	_expect(tracker.decisions_total == 1, "Adaptatif engagement : suivre une cible qui bouge ne doit pas déclencher une nouvelle décision.")
	_expect(second["direction"].is_equal_approx(Vector3(0, 0, -1)), "Adaptatif engagement : la direction doit être recalculée pendant l'engagement.")

	# Un changement de situation reprend la décision, pour que le crédit d'une cellule
	# corresponde à une période où sa situation était réelle.
	var situation_change := AdaptiveDecider.new()
	situation_change.configure(0.2, 0.0, 10.0, 31, "Test")
	situation_change.decide(stable)
	_expect(situation_change.decisions_total == 1, "Adaptatif engagement : la première décision n'a pas été enregistrée.")
	var without_visible := _adaptive_observation({"has_memories": true, "delta": 0.1})
	situation_change.decide(without_visible)
	_expect(situation_change.decisions_total == 2, "Adaptatif engagement : un changement de situation doit reprendre la décision.")
	_expect(situation_change.pending_decision()["situation"] == AdaptiveDecider.SITUATION_MEMOIRE, "Adaptatif engagement : la décision en attente doit porter la nouvelle situation.")

	# Une action devenue inapplicable est reprise même à situation constante.
	var invalidated := AdaptiveDecider.new()
	invalidated.configure(0.2, 0.0, 10.0, 31, "Test")
	invalidated.set_score(AdaptiveDecider.SITUATION_RONCE_VISIBLE, AdaptiveDecider.ACTION_RONCE_MEMORISEE, 1.0)
	invalidated.decide(stable)
	_expect(invalidated.engaged_action() == AdaptiveDecider.ACTION_RONCE_MEMORISEE, "Adaptatif engagement : l'action au meilleur score n'a pas été retenue.")
	var memory_lost := _adaptive_observation({"has_visible_ronce": true, "delta": 0.1})
	invalidated.decide(memory_lost)
	_expect(invalidated.decisions_total == 2, "Adaptatif engagement : une action devenue invalide doit être reprise.")
	_expect(invalidated.engaged_action() != AdaptiveDecider.ACTION_RONCE_MEMORISEE, "Adaptatif engagement : l'action reprise ne doit pas rester celle qui est invalide.")

	# Sortir de la situation de faim libère l'engagement.
	var released := AdaptiveDecider.new()
	released.configure(0.2, 0.0, 10.0, 31, "Test")
	released.decide(stable)
	released.decide(_adaptive_observation({"hunger": 95.0, "has_visible_ronce": true, "has_memories": true}))
	_expect(released.engaged_action() == "", "Adaptatif engagement : sortir de la situation de faim doit libérer l'engagement.")
	released.decide(stable)
	_expect(released.decisions_total == 2, "Adaptatif engagement : revenir en situation de faim doit déclencher une nouvelle décision.")

## Un roncier mémorisé mais vidé ne doit plus être une cible : sinon l'agent affamé qui
## vient de le vider y reste collé (distance nulle) jusqu'à l'estompement du souvenir.
func _test_memory_ignores_empty_ronce() -> void:
	var saved_threshold := GameConfig.pickup_hunger_threshold
	GameConfig.pickup_hunger_threshold = 90.0
	var character := _make_character()
	character.position = Vector3.ZERO
	character.hunger = 85.0
	character.manual_control = false

	var emptied := TestRonce.new()
	emptied.berries = 0
	emptied.position = Vector3(1.0, 0.0, 0.0)
	get_tree().root.add_child(emptied)
	var stocked := TestRonce.new()
	stocked.berries = 2
	stocked.position = Vector3(0.0, 0.0, 10.0)
	get_tree().root.add_child(stocked)

	character._remember_ronce(emptied)
	_expect(not character._has_usable_memory(), "Mémoire : un roncier mémorisé sans mûres ne doit pas compter comme cible exploitable.")

	character._remember_ronce(stocked)
	_expect(character._has_usable_memory(), "Mémoire : un roncier mémorisé avec des mûres doit compter comme cible exploitable.")
	_expect(character._nearest_usable_memory() == stocked, "Mémoire : le roncier vide, pourtant plus proche, ne doit pas être choisi comme cible.")
	character._physics_process(0.0)
	_expect(character._direction.is_equal_approx(Vector3(0, 0, 1)), "Mémoire : l'agent affamé doit viser le roncier mémorisé encore pourvu, pas le plus proche vidé.")

	_expect(character.memorized_ronces_count() == 2, "Mémoire : le filtre de ciblage ne doit pas effacer les souvenirs eux-mêmes.")

	GameConfig.pickup_hunger_threshold = saved_threshold
	character.queue_free()
	emptied.queue_free()
	stocked.queue_free()

## Sans reprise continue, un agent au contact d'un roncier ne cueille qu'une mûre puis se
## fige (ronce.gd::_physics_process appelle _on_ronce_contact à chaque frame de contact,
## exactement comme un agent réel resterait dans la zone de collision plusieurs frames de
## suite). Le buisson a plus de mûres que la capacité de l'agent : la cueillette doit
## s'arrêter à la capacité, pas au buisson vide.
func _test_continuous_harvest_while_in_contact() -> void:
	var character := _make_character()
	character.hunger = 50.0
	GameConfig.max_berries_carried = 3
	var ronce := TestRonce.new()
	ronce.berries = 5
	get_tree().root.add_child(ronce)

	for i in 6:
		character._on_ronce_contact(ronce)

	_expect(character.berries_carried == 3, "Cueillette continue : l'inventaire doit se remplir jusqu'à sa capacité sur plusieurs frames de contact.")
	_expect(ronce.berries == 2, "Cueillette continue : le buisson ne doit perdre que les mûres effectivement prises.")

	character.queue_free()
	ronce.queue_free()

## Un roncier ciblé alors que l'inventaire est plein est un piège : la cueillette y est
## refusée (character.gd::try_pick_berry_from_ronce), donc l'agent s'y fige sans jamais
## pouvoir récolter. Le décideur ne doit plus le cibler dans ce cas.
func _test_baseline_ignores_full_inventory() -> void:
	var full_inventory := _adaptive_observation({
		"has_visible_ronce": true,
		"has_memories": true,
		"berries_carried": 3,
		"max_berries_carried": 3,
	})
	var action: Dictionary = BaselineDecider.new().decide(full_inventory)
	_expect(action["goal"] == "errance", "Automate inventaire plein : un roncier ne doit plus être ciblé quand la cueillette y est impossible.")

	var room_left := _adaptive_observation({
		"has_visible_ronce": true,
		"has_memories": true,
		"berries_carried": 2,
		"max_berries_carried": 3,
	})
	var still_targets: Dictionary = BaselineDecider.new().decide(room_left)
	_expect(still_targets["goal"] == "ronce_visible", "Automate inventaire non plein : le roncier visible doit rester ciblé.")

func _test_adaptive_ignores_full_inventory() -> void:
	var decider := AdaptiveDecider.new()
	decider.configure(0.2, 0.0, 0.0, 11, "Test")
	var full_inventory := _adaptive_observation({
		"has_visible_ronce": true,
		"has_memories": true,
		"berries_carried": 3,
		"max_berries_carried": 3,
	})
	var action: Dictionary = decider.decide(full_inventory)
	_expect(action["goal"] == AdaptiveDecider.ACTION_ERRANCE, "Adaptatif inventaire plein : un roncier ne doit plus être ciblé quand la cueillette y est impossible.")
	_expect(decider.engaged_action() == "", "Adaptatif inventaire plein : aucun engagement ne doit être pris hors situation de faim exploitable.")

func _test_llm_survie_config() -> void:
	var file := FileAccess.open("res://experiments/llm_survie_v1.json", FileAccess.READ)
	_expect(file != null, "Config llm_survie : experiments/llm_survie_v1.json est illisible.")
	if file == null:
		return
	var raw = JSON.parse_string(file.get_as_text())
	_expect(raw is Dictionary, "Config llm_survie : JSON invalide.")
	if not (raw is Dictionary):
		return
	var config := ExperimentConfig.from_raw(raw)
	_expect(config.is_valid(), "Config llm_survie : rejetée par VariableRegistry : %s" % ", ".join(config.errors))
	var agents: Dictionary = config.normalized["agents"]["individual"]
	_expect(agents.size() == 4 and not agents.has("Test"), "Config llm_survie : seuls Rouge, Bleu, Vert et Jaune doivent être configurés.")
	for agent_name in ["Rouge", "Bleu", "Vert", "Jaune"]:
		var values: Dictionary = agents.get(agent_name, {})
		_expect(values.get("decider_type", "") == "llm_survie", "Config llm_survie : %s doit utiliser llm_survie." % agent_name)
		_expect(values.get("llm_model", "") == "gemma3:1b", "Config llm_survie : %s doit utiliser gemma3:1b." % agent_name)
		_expect(int(values.get("memory_capacity", 0)) >= int(config.normalized["environment"]["game_config"]["ronce_count"]), "Config llm_survie : la mémoire de %s doit couvrir tous les ronciers." % agent_name)
		_expect(is_zero_approx(float(values.get("memory_decay_rate", 1.0))), "Config llm_survie : %s ne doit rien oublier." % agent_name)
	_expect(int(config.normalized["environment"]["game_config"].get("danger_zone_count", -1)) == 0, "Config llm_survie : le danger doit être désactivé.")
	_expect(is_equal_approx(config.normalized["simulation"]["game_speed"], 1.0), "Config llm_survie : game_speed doit valoir 1.0.")
	var invalid := ExperimentConfig.from_raw({"agents": {"defaults": {"decider_type": "llm_survie_inconnu"}}})
	_expect(not invalid.is_valid(), "Config llm_survie : un decider_type inconnu doit rester rejeté.")
	_expect(VariableRegistry.CHARACTER["decider_type"]["options"].has("automate"), "Config llm_survie : l'option automate doit rester disponible.")

func _make_survie_character(vision: float) -> CharacterBody3D:
	var character := CharacterScript.new()
	character.decider_type = "llm_survie"
	character.vision_range = vision
	character.vision_angle_degrees = 360.0
	get_tree().root.add_child(character)
	return character

func _make_identified_ronce(id: String, local_position: Vector3, berries: int) -> Area3D:
	var ronce := _make_ronce(local_position)
	ronce.ronce_id = id
	ronce.berries = berries
	return ronce

func _test_ronce_memory_on_sight() -> void:
	var character := _make_survie_character(20.0)
	var near := _make_identified_ronce("R01", Vector3(0.0, 0.0, -5.0), 3)
	var far := _make_identified_ronce("R02", Vector3(0.0, 0.0, -60.0), 3)
	character._update_vision_perception()
	var memory: RonceMemory = character.ronce_memory()
	_expect(memory != null and memory.is_known("R01"), "Mémoire llm_survie : un roncier vu doit être mémorisé.")
	_expect(memory.position_of("R01").is_equal_approx(near.position), "Mémoire llm_survie : les coordonnées du roncier vu sont incorrectes.")
	_expect(memory.estimated_berries("R01") == 3, "Mémoire llm_survie : les mûres visibles doivent alimenter l'estimation.")
	_expect(not memory.is_known("R02"), "Mémoire llm_survie : un roncier hors de vue ne doit pas être connu.")
	character.free()
	near.free()
	far.free()

func _test_ronce_memory_on_contact() -> void:
	var character := _make_survie_character(0.0)
	var ronce := _make_identified_ronce("R07", Vector3(1.0, 0.0, 0.0), 2)
	character._update_vision_perception()
	var memory: RonceMemory = character.ronce_memory()
	_expect(not memory.is_known("R07"), "Mémoire llm_survie contact : sans vision, le roncier reste inconnu avant contact.")
	character.try_pick_berry_from_ronce(ronce, true)
	_expect(memory.is_known("R07"), "Mémoire llm_survie contact : le contact doit mémoriser le roncier.")
	character.free()
	ronce.free()

func _test_ronce_memory_own_pick_countdown() -> void:
	var character := _make_survie_character(0.0)
	var ronce := _make_identified_ronce("R03", Vector3(1.0, 0.0, 0.0), 3)
	var memory: RonceMemory = character.ronce_memory()
	character.try_pick_berry_from_ronce(ronce, true)
	_expect(memory.estimated_berries("R03") == 2 and ronce.berries == 2, "Mémoire llm_survie décompte : après une cueillette propre l'estimation doit valoir 2.")
	character.try_pick_berry_from_ronce(ronce, true)
	character.try_pick_berry_from_ronce(ronce, true)
	_expect(memory.estimated_berries("R03") == 0 and memory.own_picks("R03") == 3, "Mémoire llm_survie décompte : trois cueillettes propres doivent vider l'estimation.")
	character.try_pick_berry_from_ronce(ronce, true)
	_expect(memory.estimated_berries("R03") == 0, "Mémoire llm_survie décompte : l'estimation ne doit pas devenir négative.")
	character.free()
	ronce.free()

func _test_ronce_memory_stale_then_corrected() -> void:
	var character := _make_survie_character(20.0)
	var ronce := _make_identified_ronce("R04", Vector3(0.0, 0.0, -5.0), 3)
	var memory: RonceMemory = character.ronce_memory()
	character._update_vision_perception()
	_expect(memory.estimated_berries("R04") == 3, "Mémoire llm_survie périmée : estimation initiale incorrecte.")
	character.vision_range = 0.0
	ronce.harvest_one()
	ronce.harvest_one()
	character._update_vision_perception()
	_expect(memory.estimated_berries("R04") == 3 and ronce.berries == 1, "Mémoire llm_survie périmée : hors de vue, l'estimation doit rester périmée.")
	character.vision_range = 20.0
	character._update_vision_perception()
	_expect(memory.estimated_berries("R04") == 1, "Mémoire llm_survie périmée : la vue suivante doit corriger l'estimation.")
	character.free()
	ronce.free()

func _test_ronce_memory_never_forgets() -> void:
	var character := _make_survie_character(200.0)
	character.memory_capacity = 100
	character.memory_decay_rate = 0.0
	var ronces: Array = []
	for i in 30:
		ronces.append(_make_identified_ronce("R%02d" % (i + 1), Vector3(float(i) * 3.0 - 45.0, 0.0, -10.0), 3))
	character._update_vision_perception()
	character.vision_range = 0.0
	for i in 3000:
		character._decay_memories(1.0)
		character._update_vision_perception()
	var memory: RonceMemory = character.ronce_memory()
	_expect(memory.count() == 30, "Mémoire llm_survie long run : un roncier connu a été oublié (%d/30)." % memory.count())
	_expect(memory.known_ids().size() == 30 and memory.known_ids()[0] == "R01", "Mémoire llm_survie long run : liste d'identifiants incohérente.")
	character.free()
	for r in ronces:
		r.free()

func _test_ronce_memory_absent_for_other_deciders() -> void:
	var character := _make_character()
	var ronce := _make_identified_ronce("R05", Vector3(0.0, 0.0, -5.0), 3)
	character.vision_range = 20.0
	character.vision_angle_degrees = 360.0
	character._update_vision_perception()
	_expect(character.ronce_memory() == null, "Mémoire llm_survie : les autres décideurs ne doivent pas créer cette mémoire.")
	character.free()
	ronce.free()

func _survie_setup(ronce_position: Vector3, berries: int) -> Array:
	var character := _make_survie_character(0.0)
	character.position = Vector3.ZERO
	var ronce := _make_identified_ronce("R01", ronce_position, berries)
	character.ronce_memory().observe("R01", ronce.position, berries, 0.0)
	return [character, ronce, character.survie_engine()]

func _survie_touch(character, ronce) -> void:
	character.position = ronce.position - Vector3(2.0, 0.0, 0.0)
	character._on_ronce_contact(ronce)

func _test_survie_no_automatic_pickup_or_meal() -> void:
	var setup := _survie_setup(Vector3(1.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 0 and ronce.berries == 3, "llm_survie : la cueillette ne doit plus être automatique.")
	character.berries_carried = 2
	character.hunger = 10.0
	character._physics_process(0.016)
	_expect(character.berries_carried == 2, "llm_survie : le repas ne doit plus être automatique.")
	var control := _make_character()
	control.berries_carried = 2
	control.hunger = 10.0
	control._physics_process(0.016)
	_expect(control.berries_carried == 1, "llm_survie : l'automate doit garder son repas automatique.")
	var control_ronce := _make_identified_ronce("R09", Vector3(1.0, 0.0, 0.0), 3)
	control._on_ronce_contact(control_ronce)
	_expect(control.berries_carried == 2 and control_ronce.berries == 2, "llm_survie : l'automate doit garder sa cueillette automatique.")
	control.free()
	control_ronce.free()
	character.free()
	ronce.free()

func _test_survie_full_sequence() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	var maximum: int = GameConfig.max_berries_carried
	_expect(engine.submit({"action": "aller_vers", "roncier_id": "R01"})["accepted"], "llm_survie séquence : aller_vers doit être accepté.")
	for step in 300:
		var direction := engine.tick(0.1)
		if direction == Vector3.ZERO:
			break
		character.position += direction * 0.25
		if character.position.distance_to(ronce.position) <= 2.0:
			character._on_ronce_contact(ronce)
	_expect(engine.current_action == "" and character.position.distance_to(ronce.position) <= 2.1, "llm_survie séquence : l'agent doit arriver et s'arrêter.")
	var event_types: Array = engine.take_events().map(func(event): return event["type"])
	_expect(event_types.has("cible_atteinte"), "llm_survie séquence : l'arrivée doit émettre cible_atteinte.")
	for picked in range(mini(maximum, 3)):
		_expect(engine.submit({"action": "ramasser"})["accepted"], "llm_survie séquence : ramasser #%d doit être accepté." % (picked + 1))
	_expect(character.berries_carried == mini(maximum, 3) and ronce.berries == 3 - mini(maximum, 3), "llm_survie séquence : les mûres ramassées sont incorrectes.")
	_expect(character.ronce_memory().estimated_berries("R01") == ronce.berries, "llm_survie séquence : l'estimation doit suivre les cueillettes propres.")
	character.hunger = 40.0
	var hunger_before: float = character.hunger
	var carried_before: int = character.berries_carried
	_expect(engine.submit({"action": "manger"})["accepted"], "llm_survie séquence : manger sous le seuil doit être accepté.")
	_expect(character.berries_carried == carried_before - 1 and character.hunger > hunger_before and character.berries_eaten_total == 1, "llm_survie séquence : le repas doit consommer une mûre et restaurer la faim.")
	character.free()
	ronce.free()

func _test_survie_refusals() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	var maximum: int = GameConfig.max_berries_carried
	var threshold: float = GameConfig.eat_hunger_threshold
	_expect(engine.submit({"action": "ramasser"})["code"] == "hors_contact", "llm_survie refus : ramasser hors contact.")
	_expect(engine.submit({"action": "manger"})["code"] == "aucune_mure", "llm_survie refus : manger sans mûre.")
	_expect(engine.submit({"action": "aller_vers", "roncier_id": "R99"})["code"] == "cible_inconnue", "llm_survie refus : cible inconnue.")
	_expect(engine.submit({"action": "aller_vers", "roncier_id": "aucun"})["code"] == "cible_inconnue", "llm_survie refus : cible aucun.")
	_expect(engine.submit({"action": "explorer", "direction": "aucune"})["code"] == "direction_invalide", "llm_survie refus : direction invalide.")
	_expect(engine.submit({"action": "danser"})["code"] == "action_inconnue", "llm_survie refus : action inconnue.")
	_survie_touch(character, ronce)
	character.berries_carried = maximum
	_expect(engine.submit({"action": "ramasser"})["code"] == "inventaire_plein", "llm_survie refus : inventaire plein.")
	character.hunger = threshold + 10.0
	_expect(engine.submit({"action": "manger"})["code"] == "trop_rassasie", "llm_survie refus : trop rassasié.")
	_expect(character.berries_carried == maximum and character.berries_eaten_total == 0, "llm_survie refus : un refus ne doit avoir aucun effet.")
	character.berries_carried = 0
	ronce.berries = 0
	_expect(engine.submit({"action": "ramasser"})["code"] == "roncier_vide", "llm_survie refus : roncier vide.")
	character.ronce_memory().observe("R01", ronce.position, 0, 0.0)
	_expect(engine.submit({"action": "aller_vers", "roncier_id": "R01"})["code"] == "cible_epuisee", "llm_survie refus : cible épuisée.")
	_expect(engine.refusals_total == 10 and int(engine.refusals_by_code.get("hors_contact", 0)) == 1, "llm_survie refus : compteurs de refus incorrects (%d)." % engine.refusals_total)
	_expect(engine.submit({"action": "attendre"})["accepted"] and engine.current_action == "attendre", "llm_survie : attendre doit toujours être accepté.")
	character.free()
	ronce.free()

func _test_survie_arrival_block_and_empty_target() -> void:
	var setup := _survie_setup(Vector3(20.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	engine.submit({"action": "explorer", "direction": "N"})
	_expect(engine.tick(0.1).is_equal_approx(Vector3(0.0, 0.0, -1.0)), "llm_survie : explorer N doit viser (0, 0, -1).")
	var blocked := false
	for step in 40:
		engine.tick(0.1)
		if engine.current_action == "":
			blocked = true
			break
	_expect(blocked and engine.take_events().any(func(event): return event["type"] == "blocage"), "llm_survie : un agent immobile en explorer doit être détecté bloqué.")
	engine.submit({"action": "aller_vers", "roncier_id": "R01"})
	engine.tick(0.1)
	character.ronce_memory().observe("R01", ronce.position, 0, 1.0)
	engine.tick(0.1)
	_expect(engine.current_action == "" and engine.take_events().any(func(event): return event["type"] == "cible_invalide"), "llm_survie : une cible vidée doit émettre cible_invalide.")
	character.ronce_memory().observe("R01", ronce.position, 3, 2.0)
	engine.submit({"action": "aller_vers", "roncier_id": "R01"})
	character.position = ronce.position - Vector3(1.0, 0.0, 0.0)
	engine.tick(0.1)
	_expect(engine.current_action == "" and character.ronce_memory().estimated_berries("R01") == 0, "llm_survie : arriver sans contact doit invalider la cible absente.")
	character.free()
	ronce.free()
func _survie_advance(character, steps: int, delta: float, hunger_step: float = 0.0) -> void:
	var engine: LLMSurieEngine = character.survie_engine()
	for step in steps:
		character.hunger -= hunger_step
		character.survie_step(delta)
		character.position += engine.direction * 0.25

func _test_survie_mock_backend_integration() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var backend := LLMSurieMockBackend.new()
	character.set_survie_backend(backend)
	character.survie_step(0.1)
	_expect(backend.requests_total == 1 and character._direction == Vector3.ZERO, "llm_survie backend : le premier tick demande une décision et n'agit pas encore.")
	character.survie_step(0.1)
	_expect(character.survie_turns().turns_total == 1 and character.survie_engine().current_action == "attendre", "llm_survie backend : la réponse par défaut (attendre) doit être appliquée au tick suivant.")
	backend.enqueue({"action": "aller_vers", "roncier_id": "R01", "direction": "aucune"})
	character.survie_engine().events.append({"type": "blocage", "id": ""})
	character.survie_step(0.1)
	character.survie_step(0.1)
	_expect(character.survie_engine().current_action == "aller_vers" and character._direction.is_equal_approx(Vector3.RIGHT), "llm_survie backend : l'action reçue doit orienter l'agent vers la cible.")
	character.free()
	ronce.free()

func _test_survie_turn_cadence_and_wait() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	var backend := LLMSurieMockBackend.new()
	backend.latency_seconds = 1.0
	character.set_survie_backend(backend)
	engine.submit({"action": "explorer", "direction": "E", "roncier_id": "aucun"})
	var still_moving := true
	for step in 8:
		character.hunger -= 0.06
		character.survie_step(0.1)
		character.position += engine.direction * 0.25
		still_moving = still_moving and engine.current_action == "explorer" and engine.direction.is_equal_approx(Vector3.RIGHT)
	_expect(still_moving and character.survie_turns().in_flight, "llm_survie attente : l'action en cours doit continuer pendant la requête.")
	_survie_advance(character, 12, 0.1, 0.06)
	var turns: LLMSurieTurns = character.survie_turns()
	_expect(turns.turns_total >= 1 and backend.overlaps_total == 0, "llm_survie attente : une seule requête en vol à la fois.")
	_expect(absf(turns.wait_total_seconds / float(turns.turns_total) - 1.0) < 0.15, "llm_survie attente : l'attente simulée moyenne doit valoir la latence (%.2f)." % (turns.wait_total_seconds / float(maxi(turns.turns_total, 1))))
	_expect(absf(turns.hunger_lost_total / float(turns.turns_total) - 0.6) < 0.13, "llm_survie attente : la faim perdue en attente doit valoir ~0,6 (%.2f)." % (turns.hunger_lost_total / float(maxi(turns.turns_total, 1))))
	_expect(is_equal_approx(turns.summary()["llm_survie_latence_moyenne_ms"], 1000.0), "llm_survie attente : latence moyenne du résumé incorrecte.")
	character.free()
	ronce.free()

func _test_survie_events_queued_during_wait() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	var backend := LLMSurieMockBackend.new()
	backend.latency_seconds = 0.95
	character.set_survie_backend(backend)
	character.survie_step(0.1)
	_expect(backend.requests_total == 1, "llm_survie file : le démarrage doit déclencher un tour.")
	engine.events.append({"type": "blocage", "id": ""})
	engine.events.append({"type": "blocage", "id": ""})
	engine.events.append({"type": "cible_atteinte", "id": "R01"})
	for step in 9:
		character.survie_step(0.1)
	_expect(backend.requests_total == 1 and character.survie_turns().pending_triggers().size() == 2, "llm_survie file : deux événements distincts doivent attendre, dédoublonnés (%s)." % [character.survie_turns().pending_triggers()])
	character.survie_step(0.1)
	_expect(character.survie_turns().turns_total == 1 and backend.requests_total == 1, "llm_survie file : la réponse est appliquée avant toute nouvelle requête.")
	character.survie_step(0.1)
	_expect(backend.requests_total == 2 and character.survie_turns().pending_triggers().is_empty(), "llm_survie file : les événements en file doivent déclencher une seule nouvelle requête.")
	character.free()
	ronce.free()

func _test_survie_fallback_backoff() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var engine: LLMSurieEngine = setup[2]
	var backend := LLMSurieMockBackend.new()
	backend.enqueue_failure("timeout", "test")
	character.set_survie_backend(backend)
	engine.submit({"action": "explorer", "direction": "E", "roncier_id": "aucun"})
	character.survie_step(0.1)
	character.survie_step(0.1)
	var turns: LLMSurieTurns = character.survie_turns()
	_expect(turns.replis_total == 1 and engine.current_action == "explorer", "llm_survie repli : un échec doit être compté et l'action en cours poursuivie.")
	engine.events.append({"type": "blocage", "id": ""})
	var interval_steps := int(character.llm_decision_interval_seconds / 0.1)
	for step in interval_steps - 15:
		character.survie_step(0.1)
		character.position += engine.direction * 0.25
	_expect(backend.requests_total == 1, "llm_survie repli : aucune requête avant l'échéance de l'intervalle maximal (%d)." % backend.requests_total)
	for step in 30:
		character.survie_step(0.1)
		character.position += engine.direction * 0.25
	_expect(backend.requests_total >= 2, "llm_survie repli : la requête doit repartir après l'intervalle maximal.")
	character.free()
	ronce.free()

func _test_survie_safety_interval() -> void:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var backend := LLMSurieMockBackend.new()
	character.set_survie_backend(backend)
	_survie_advance(character, 350, 0.1)
	var expected := 1 + int(35.0 / character.llm_decision_interval_seconds)
	_expect(absi(backend.requests_total - expected) <= 1, "llm_survie intervalle : %d requêtes attendues (+/-1), %d observées." % [expected, backend.requests_total])
	character.free()
	ronce.free()

func _survie_run_trace(steps: int) -> Array:
	var setup := _survie_setup(Vector3(10.0, 0.0, 0.0), 3)
	var character = setup[0]
	var ronce = setup[1]
	var backend := LLMSurieMockBackend.new()
	var directions := ["E", "N", "O", "S"]
	var counter := [0]
	backend.policy = func(_view: Dictionary) -> Dictionary:
		counter[0] += 1
		return {"action": "explorer", "roncier_id": "aucun", "direction": directions[counter[0] % directions.size()]}
	character.set_survie_backend(backend)
	var trace: Array = []
	for step in steps:
		character.hunger -= 0.05
		character.survie_step(0.1)
		character.position += character.survie_engine().direction * 0.25
		trace.append([character.survie_engine().current_action, character.survie_engine().direction, backend.requests_total])
	trace.append(character.survie_summary())
	character.free()
	ronce.free()
	return trace

func _test_survie_zero_latency_determinism() -> void:
	var first := _survie_run_trace(300)
	var second := _survie_run_trace(300)
	_expect(first == second and first.size() == 301, "llm_survie déterminisme : deux runs mock sans latence doivent être identiques.")
	_expect(int(first[300]["llm_survie_tours"]) > 0, "llm_survie déterminisme : le run doit avoir décidé au moins une fois.")

func _test_survie_ollama_prompt_schema_and_parsing() -> void:
	var backend := LLMSurieOllamaBackend.new()
	backend.configure("gemma3:1b", 20.0, 42, "Rouge")
	var view := {
		"hunger": 42.4,
		"berries_carried": 1,
		"max_berries_carried": 3,
		"eat_hunger_threshold": 50.0,
		"contact_ronce_id": "",
		"current_action": "aller_vers",
		"target_id": "R07",
		"last_result": {"action": "manger", "accepted": false, "code": "trop_rassasie"},
		"known": [
			{"id": "R07", "distance": 12.2, "direction": Vector3(1, 0, -1).normalized(), "estimated_berries": 3},
			{"id": "R02", "distance": 30.0, "direction": Vector3(0, 0, 1), "estimated_berries": 0},
			{"id": "R11", "distance": 5.0, "direction": Vector3(-1, 0, 0), "estimated_berries": 2},
		],
	}
	var prompt := backend.build_prompt(view)
	_expect(prompt.contains("Faim : 42/100") and prompt.contains("1 sur 3"), "Prompt llm_survie : faim, inventaire et seuil de repas attendus.")
	_expect(prompt.contains("R07 : 12 m, direction NE, environ 3") and prompt.contains("R11 : 5 m, direction O"), "Prompt llm_survie : ronciers connus avec distance, direction et mûres attendus.")
	_expect(prompt.find("- R11") < prompt.find("- R07"), "Prompt llm_survie : ronciers triés par distance croissante attendus.")
	_expect(not prompt.contains("R02 :"), "Prompt llm_survie : un roncier estimé vide ne doit pas être listé.")
	_expect(prompt.contains("Déplacement en cours : aller_vers R07") and prompt.contains("manger -> refusé (trop_rassasie)"), "Prompt llm_survie : action en cours et dernier résultat attendus.")
	_expect(prompt.contains("ACTIONS POSSIBLES MAINTENANT : manger, aller_vers") and not prompt.contains("ramasser (") and not prompt.contains(": ramasser"), "Prompt llm_survie : seules les actions légales doivent être proposées (manger et aller_vers sans contact).")
	var contact_view: Dictionary = view.duplicate(true)
	contact_view["contact_ronce_id"] = "R11"
	contact_view["berries_carried"] = 0
	_expect(backend.build_prompt(contact_view).contains("ACTIONS POSSIBLES MAINTENANT : ramasser, aller_vers"), "Prompt llm_survie : ramasser doit être proposé au contact d'un roncier avec des mûres.")
	contact_view["berries_carried"] = 3
	contact_view["hunger"] = 80.0
	_expect(backend.build_prompt(contact_view).contains("ACTIONS POSSIBLES MAINTENANT : aller_vers"), "Prompt llm_survie : ni ramasser (sac plein) ni manger (faim au-dessus du seuil) ne doivent être proposés.")
	var schema := backend.build_schema(["R07", "R11"])
	var branches: Array = schema["anyOf"]
	_expect(branches.size() == 5 and branches[0]["properties"]["action"]["enum"] == ["aller_vers"] and branches[0]["properties"]["roncier_id"]["enum"] == ["R07", "R11"], "Schéma llm_survie : aller_vers doit être limité aux ronciers avec des mûres.")
	_expect(branches[1]["properties"]["direction"]["enum"].size() == 8 and not branches[1]["properties"]["direction"]["enum"].has("aucune"), "Schéma llm_survie : explorer doit imposer une vraie direction.")
	_expect(branches[2]["properties"]["direction"]["enum"] == ["aucune"] and branches[4]["properties"]["action"]["enum"] == ["attendre"], "Schéma llm_survie : les actions sans argument doivent fixer roncier_id et direction.")
	_expect(backend.build_schema([])["anyOf"].size() == 4, "Schéma llm_survie : sans roncier avec des mûres, aller_vers ne doit pas être proposé.")
	_expect(LLMSurieOllamaBackend.compass_of(Vector3(0, 0, -1)) == "N" and LLMSurieOllamaBackend.compass_of(Vector3(1, 0, 0)) == "E" and LLMSurieOllamaBackend.compass_of(Vector3(0, 0, 1)) == "S" and LLMSurieOllamaBackend.compass_of(Vector3(-1, 0, 1)) == "SO" and LLMSurieOllamaBackend.compass_of(Vector3(-1, 0, -1)) == "NO", "Boussole llm_survie : conversion vecteur vers direction incorrecte.")
	backend.prepare({"known": [{"id": "R07", "distance": 1.0, "direction": Vector3.RIGHT, "estimated_berries": 1}]})
	var good := backend.parse_body(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify({"response": JSON.stringify({"action": "aller_vers", "roncier_id": "R07", "direction": "aucune"})}))
	_expect(good["ok"] and good["action"]["roncier_id"] == "R07", "Parse llm_survie : une réponse valide doit être acceptée.")
	var unknown_id := backend.parse_body(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify({"response": JSON.stringify({"action": "aller_vers", "roncier_id": "R99", "direction": "aucune"})}))
	_expect(not unknown_id["ok"] and unknown_id["reason"] == "hors_enumeration", "Parse llm_survie : un identifiant hors mémoire doit être un repli hors_enumeration.")
	var bad_json := backend.parse_body(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify({"response": "pas du json"}))
	_expect(not bad_json["ok"] and bad_json["reason"] == "json_invalide", "Parse llm_survie : un JSON illisible doit être un repli json_invalide.")
	_expect(backend.parse_body(HTTPRequest.RESULT_SUCCESS, 500, "erreur")["reason"] == "http_500", "Parse llm_survie : un code HTTP 500 doit être un repli http_500.")
	_expect(backend.parse_body(HTTPRequest.RESULT_CANT_CONNECT, 0, "")["reason"] == "reseau", "Parse llm_survie : un échec réseau doit être un repli reseau.")
	_expect(backend.parse_body(HTTPRequest.RESULT_SUCCESS, 200, "{}")["reason"] == "reponse_invalide", "Parse llm_survie : un corps sans champ response doit être un repli reponse_invalide.")
	backend.free()
