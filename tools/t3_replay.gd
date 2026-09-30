extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTable = preload("res://scripts/t3_q_table.gd")
const FINGERPRINT_V2 := "t3_world_v2|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const FINGERPRINT_V3 := "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [6, 8] or args[0] != "--checkpoint" or args[2] != "--initialization-seed" or args[4] != "--output":
		push_error("Usage : --checkpoint chemin --initialization-seed seed --output chemin [--contract v3]")
		get_tree().quit(2)
		return
	var fingerprint := FINGERPRINT_V2
	var schema := "t3_q_table_v2"
	var seed_base := 400000000
	var competitors := false
	if args.size() == 8:
		if args[6] != "--contract" or args[7] != "v3":
			get_tree().quit(2)
			return
		fingerprint = FINGERPRINT_V3
		schema = "t3_q_table_v3"
		seed_base = 410000000
		competitors = true
	var table = T3QTable.load_checkpoint(args[1], fingerprint, schema)
	if table == null:
		push_error("Checkpoint T3 invalide.")
		get_tree().quit(2)
		return
	var initialization_seed := int(args[3])
	var file := FileAccess.open(args[5], FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	var checksum: String = table.checksum()
	for card_seed in range(seed_base + 101, seed_base + 133):
		var scenario := T3Scenario.new()
		scenario.configure(card_seed, competitors, 40.0)
		add_child(scenario)
		await get_tree().physics_frame
		var result: Dictionary = {}
		var action_trace: Array = []
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			var action: int = table.select_greedy(table.state_key(scenario.observation()))
			action_trace.append(action)
			result = await scenario.execute_action(action)
		file.store_line(JSON.stringify({"initialization_seed": initialization_seed, "card_seed": card_seed, "survived": bool(result["survived"]), "berries_picked": int(result["berries_picked"]), "berries_eaten": int(result["berries_eaten"]), "terminated": bool(result["terminated"]), "truncated": bool(result["truncated"]), "actions": int(result["actions"]), "action_trace": action_trace, "table_checksum": checksum}))
		scenario.queue_free()
		await get_tree().physics_frame
	file.close()
	if table.checksum() != checksum:
		push_error("Le replay T3 a modifié la table.")
		get_tree().quit(1)
		return
	print("SUCCÈS : replay T3 écrit.")
	get_tree().quit(0)
