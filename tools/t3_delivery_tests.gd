extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTableScript = preload("res://scripts/t3_q_table.gd")
const WorldScene = preload("res://scenes/Main.tscn")
const CHECKPOINT := "res://experiments/t3_v3_workers/trained_410001001.jsonl.410001001.200.checkpoint.json"
const BAD_CHECKPOINT := "res://experiments/_t3_delivery_bad_checkpoint.json"
const FINGERPRINT := "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const EQUIVALENCE_CARDS := [410000001, 410000002, 410000003]
const HORIZON_FRAMES := 1200

var _failures: Array[String] = []
var _saved_config: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_equivalence()
	await _test_missing_and_incompatible_model()
	await _test_world_mismatch_falls_back()
	await _test_game_speed_falls_back()
	await _test_manual_control_priority()
	if _failures.is_empty():
		print("SUCCÈS : livraison du modèle appliqué T3 validée.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_equivalence() -> void:
	var table = T3QTableScript.load_checkpoint(CHECKPOINT, FINGERPRINT, "t3_q_table_v3")
	_expect(table != null, "Le checkpoint de référence doit se charger.")
	if table == null:
		return
	var checksum: String = table.checksum()
	for card_seed in EQUIVALENCE_CARDS:
		var evaluated := await _run_evaluated(table, card_seed)
		var applied := await _run_applied(card_seed, CHECKPOINT, true, HORIZON_FRAMES)
		var trace: Array = applied["trace"]
		var expected_trace: Array = evaluated["trace"]
		var head: Array = trace.slice(0, expected_trace.size())
		var divergence := -1
		for index in expected_trace.size():
			if index >= head.size() or head[index] != expected_trace[index]:
				divergence = index
				break
		_expect(divergence < 0, "Carte %d : les actions du chemin livré diffèrent du chemin évalué (première divergence à l'indice %d ; évalué %s ; livré %s)." % [card_seed, divergence, str(expected_trace.slice(maxi(0, divergence - 2), divergence + 4)), str(trace.slice(maxi(0, divergence - 2), divergence + 4))])
		_expect(int(applied["berries_eaten"]) == int(evaluated["berries_eaten"]), "Carte %d : mûres consommées divergentes." % card_seed)
		_expect(bool(applied["dead"]) == bool(evaluated["terminated"]), "Carte %d : survie divergente." % card_seed)
		_expect(bool(applied["table_unchanged"]), "Carte %d : le modèle appliqué a modifié sa table." % card_seed)
		_expect(int(applied["fallback_cycles"]) == 0, "Carte %d : repli inattendu." % card_seed)
	_expect(table.checksum() == checksum, "L'évaluation a modifié la table de référence.")

func _test_missing_and_incompatible_model() -> void:
	var missing := await _run_applied(410000001, "res://experiments/_absent.json", true, 60)
	_expect(int(missing["decisions"]) == 0 and int(missing["fallback_cycles"]) >= 1, "Un modèle absent doit provoquer un repli compté.")
	_expect(str(missing["goal"]) != "modele", "Un modèle absent ne doit pas piloter le personnage.")
	var empty := await _run_applied(410000001, "", true, 60)
	_expect(int(empty["decisions"]) == 0 and int(empty["fallback_cycles"]) >= 1, "Un chemin vide doit provoquer un repli compté.")
	var file := FileAccess.open(CHECKPOINT, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	for mutation in ["config_fingerprint", "schema_version"]:
		var altered: Dictionary = parsed.duplicate(true)
		altered[mutation] = "incompatible"
		var out := FileAccess.open(BAD_CHECKPOINT, FileAccess.WRITE)
		out.store_string(JSON.stringify(altered))
		out.close()
		var result := await _run_applied(410000001, BAD_CHECKPOINT, true, 60)
		_expect(int(result["decisions"]) == 0 and int(result["fallback_cycles"]) >= 1, "Un checkpoint incompatible (%s) doit être rejeté avec repli." % mutation)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BAD_CHECKPOINT))

func _test_world_mismatch_falls_back() -> void:
	var result := await _run_applied(410000001, CHECKPOINT, false, 60)
	_expect(int(result["decisions"]) == 0 and int(result["fallback_cycles"]) >= 1, "Des paramètres monde hors contrat doivent provoquer un repli compté.")

func _test_game_speed_falls_back() -> void:
	GameSpeed.time_scale = 2.0
	var result := await _run_applied(410000001, CHECKPOINT, true, 60)
	GameSpeed.time_scale = 1.0
	_expect(int(result["decisions"]) == 0 and int(result["fallback_cycles"]) >= 1, "Une vitesse de jeu différente de x1 doit provoquer un repli compté.")

func _test_manual_control_priority() -> void:
	var setup := await _new_applied_world(410000001, CHECKPOINT, true)
	var actor = setup["actor"]
	actor.manual_control = true
	actor.set_manual_direction(Vector3.RIGHT)
	var start: Vector3 = actor.position
	for _frame in 45:
		await get_tree().physics_frame
	var displacement: Vector3 = actor.position - start
	var controller = actor._applied_controller
	_expect(controller.decisions_total == 0 and controller.manual_cycles_total >= 1, "Le contrôle manuel doit primer sur le modèle.")
	_expect(displacement.dot(Vector3.RIGHT) > 0.5, "Le personnage doit suivre la direction manuelle.")
	await _free_world(setup["world"])

func _run_evaluated(table, card_seed: int) -> Dictionary:
	var scenario := T3Scenario.new()
	scenario.configure(card_seed, true, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	var trace: Array = []
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var action: int = table.select_greedy(table.state_key(scenario.observation()))
		trace.append(action)
		result = await scenario.execute_action(action)
	scenario.queue_free()
	await get_tree().physics_frame
	return {"trace": trace, "berries_eaten": int(result["berries_eaten"]), "terminated": bool(result["terminated"])}

func _run_applied(card_seed: int, checkpoint: String, apply_world_contract: bool, frames: int) -> Dictionary:
	var setup := await _new_applied_world(card_seed, checkpoint, apply_world_contract)
	var actor = setup["actor"]
	var controller = actor._applied_controller
	for _frame in frames:
		await get_tree().physics_frame
		if actor.is_dead:
			break
	var summary := {
		"trace": controller.action_trace.duplicate(),
		"berries_eaten": actor.berries_eaten_total,
		"dead": actor.is_dead,
		"decisions": controller.decisions_total,
		"fallback_cycles": controller.fallback_cycles_total,
		"table_unchanged": controller.table_unchanged() if controller.table != null else true,
		"goal": actor.current_goal,
	}
	await _free_world(setup["world"])
	return summary

func _new_applied_world(card_seed: int, checkpoint: String, apply_world_contract: bool) -> Dictionary:
	await get_tree().process_frame
	if _saved_config.is_empty():
		_saved_config = {
			"max_berries_carried": GameConfig.max_berries_carried,
			"pickup_hunger_threshold": GameConfig.pickup_hunger_threshold,
			"eat_hunger_threshold": GameConfig.eat_hunger_threshold,
			"full_life_berries": GameConfig.full_life_berries,
			"ronce_count": GameConfig.ronce_count,
			"berries_per_ronce": GameConfig.berries_per_ronce,
			"danger_zone_count": GameConfig.danger_zone_count,
		}
	GameConfig.apply_overrides({"max_berries_carried": 3, "pickup_hunger_threshold": 90.0, "eat_hunger_threshold": 50.0, "full_life_berries": 6.0, "ronce_count": 24, "berries_per_ronce": 3, "danger_zone_count": 0})
	var world = WorldScene.instantiate()
	world.configure_applied_world(card_seed, checkpoint)
	add_child(world)
	var agents: Array = world.training_agents()
	for index in agents.size():
		var agent = agents[index]
		if index > 0 or apply_world_contract:
			agent.hunger = 50.0
			agent.hunger_depletion_rate = 4.0
			agent.memory_capacity = 5
			agent.vision_range = 40.0
			agent.vision_angle_degrees = 360.0
	return {"world": world, "actor": agents[0]}

func _free_world(world) -> void:
	world.queue_free()
	await get_tree().physics_frame
	GameConfig.apply_overrides(_saved_config)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
