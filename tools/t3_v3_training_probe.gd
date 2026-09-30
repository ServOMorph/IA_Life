extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTable = preload("res://scripts/t3_q_table.gd")
const FINGERPRINT := "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const SCHEMA := "t3_q_table_v3"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--output":
		get_tree().quit(2)
		return
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 410002001
	var initial := T3QTable.new()
	initial.configure(FINGERPRINT, 410001001, SCHEMA)
	for card_seed in range(410000001, 410000033):
		for arm in ["scripted_food", "initial_frozen", "random_valid"]:
			var scenario = await _new_scenario(card_seed)
			var result: Dictionary = {}
			while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
				var action: int
				if arm == "scripted_food":
					action = scenario.scripted_action()
				elif arm == "initial_frozen":
					action = initial.select_greedy(initial.state_key(scenario.observation()))
				else:
					action = rng.randi_range(0, 7)
				result = await scenario.execute_action(action)
			file.store_line(JSON.stringify({"arm": arm, "card_seed": card_seed, "survived": bool(result.get("survived", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "actions": int(result.get("actions", 0)), "active_competitors": scenario.active_competitor_count(), "competitor_berries_eaten": _competitor_berries_eaten(scenario)}))
			await _free_scenario(scenario)
	file.close()
	print("SUCCÈS : probe T3 v3 entraînement écrit.")
	get_tree().quit(0)

func _new_scenario(card_seed: int):
	var scenario := T3Scenario.new()
	scenario.configure(card_seed, true, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	return scenario

func _free_scenario(scenario) -> void:
	scenario.queue_free()
	await get_tree().physics_frame

func _competitor_berries_eaten(scenario) -> int:
	var total := 0
	var agents: Array = scenario.world.training_agents()
	for index in range(1, agents.size()):
		total += agents[index].berries_eaten_total
	return total
