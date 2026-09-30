extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")
const T3QTable = preload("res://scripts/t3_q_table.gd")
const FINGERPRINT := "t3_world_v2|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const SCHEMA := "t3_q_table_v2"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 6 or args[0] != "--initialization-seed" or args[2] != "--output" or args[4] != "--checkpoint":
		push_error("Usage : --initialization-seed seed --output chemin --checkpoint chemin")
		get_tree().quit(2)
		return
	var initialization_seed := int(args[1])
	if initialization_seed not in [400001001, 400001002, 400001003]:
		get_tree().quit(2)
		return
	var table := T3QTable.new()
	table.configure(FINGERPRINT, initialization_seed, SCHEMA)
	var rng := RandomNumberGenerator.new()
	rng.seed = initialization_seed
	var started_ms := Time.get_ticks_msec()
	for episode in range(200):
		var training_index := positive_modulo(episode * 5 + initialization_seed, 32)
		await _run_episode(table, 400000001 + training_index, true, rng)
		table.finish_training_episode()
		table.training_rng_state = rng.state
	if table.save_checkpoint(args[5]) != OK:
		get_tree().quit(1)
		return
	var loaded = T3QTable.load_checkpoint(args[5], FINGERPRINT, SCHEMA)
	if loaded == null or loaded.checksum() != table.checksum():
		push_error("Recharge T3 v2 divergente.")
		get_tree().quit(1)
		return
	var file := FileAccess.open(args[3], FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	for card_seed in range(400000001, 400000033):
		var checksum: String = loaded.checksum()
		var result := await _run_episode(loaded, card_seed, false, rng)
		if loaded.checksum() != checksum:
			push_error("L'évaluation T3 v2 a modifié la table.")
			get_tree().quit(1)
			return
		file.store_line(JSON.stringify({"initialization_seed": initialization_seed, "card_seed": card_seed, "survived": bool(result.get("survived", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "actions": int(result.get("actions", 0)), "table_checksum": checksum}))
	file.close()
	print(JSON.stringify({"initialization_seed": initialization_seed, "training_episodes": 200, "elapsed_seconds": float(Time.get_ticks_msec() - started_ms) / 1000.0, "static_memory_bytes": OS.get_static_memory_usage()}))
	get_tree().quit(0)

func _run_episode(table, card_seed: int, training: bool, rng: RandomNumberGenerator) -> Dictionary:
	var scenario := T3Scenario.new()
	scenario.configure(card_seed, false, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	var result: Dictionary = {}
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var state: String = table.state_key(scenario.observation())
		var action: int = table.select_epsilon_greedy(state, 0.20, rng) if training else table.select_greedy(state)
		result = await scenario.execute_action(action)
		var next_state: String = table.state_key(scenario.observation())
		var reward := float(result["reward_event"]) + 0.25 * float(result["progress"]) - 0.01
		table.apply_transition(state, action, reward, next_state, bool(result["terminated"]), training)
	scenario.queue_free()
	await get_tree().physics_frame
	return result

func positive_modulo(value: int, divisor: int) -> int:
	return ((value % divisor) + divisor) % divisor
