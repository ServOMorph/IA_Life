extends Node

const T2Scenario = preload("res://scripts/t2_scenario.gd")
const T2QTable = preload("res://scripts/t2_q_table.gd")
const FINGERPRINT := "t2_memory_v1|target=1|distances=3,6,9|sectors=8|fov=90|turn=180|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|explore=min_count|execution=hold_first"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 6 or args[0] != "--checkpoint" or args[2] != "--initialization-seed" or args[4] != "--output":
		push_error("Usage : --checkpoint chemin --initialization-seed seed --output chemin")
		get_tree().quit(2)
		return
	var table = T2QTable.load_checkpoint(args[1], FINGERPRINT)
	if table == null:
		push_error("Checkpoint T2 invalide.")
		get_tree().quit(2)
		return
	var initialization_seed := int(args[3])
	var file := FileAccess.open(args[5], FileAccess.WRITE)
	if file == null:
		push_error("Sortie replay T2 impossible.")
		get_tree().quit(1)
		return
	var checksum: String = table.checksum()
	for card_seed in range(380000101, 380000133):
		var scenario := T2Scenario.new()
		scenario.configure(card_seed)
		add_child(scenario)
		await get_tree().physics_frame
		scenario.begin_decision(true)
		var state: String = table.state_key(scenario.observation(true))
		var action: int = table.select_greedy(state)
		var result: Dictionary = await scenario.execute_held_action(action)
		file.store_line(JSON.stringify({"initialization_seed": initialization_seed, "card_seed": card_seed, "selected_action": action, "remembered_sector": scenario.target_sector, "consumed": bool(result["consumed"]), "berries_picked": int(result["berries_picked"]), "berries_eaten": int(result["berries_eaten"]), "terminated": bool(result["terminated"]), "truncated": bool(result["truncated"]), "actions": int(result["actions"]), "table_checksum": checksum}))
		scenario.queue_free()
		await get_tree().physics_frame
	file.close()
	if table.checksum() != checksum:
		push_error("Le replay T2 a modifié la table.")
		get_tree().quit(1)
		return
	print("SUCCÈS : replay T2 écrit.")
	get_tree().quit(0)
