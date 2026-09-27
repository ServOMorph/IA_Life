extends Node

const Scenario = preload("res://scripts/t0_scenario.gd")
const Table = preload("res://scripts/t0_q_table.gd")
const FINGERPRINT := "t0_contract_v4|resource_distance=3.0|actions=8|ticks=15|horizon=48|alpha=0.20|gamma=0.90|progress=0.50"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		get_tree().quit(2)
		return
	var table = Table.load_checkpoint(args[0], FINGERPRINT)
	if table == null:
		get_tree().quit(2)
		return
	var records: Array = []
	for sector in range(8):
		var scenario = Scenario.new()
		scenario.configure(340000101 + sector, 3.0)
		add_child(scenario)
		await get_tree().physics_frame
		var policy: Array = []
		for previous in range(9):
			policy.append(table.select_greedy(table.state_key(scenario.resource_sector, true, previous)))
		var previous_action := 8
		var trace: Array = []
		var result: Dictionary = {}
		while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
			var obs: Dictionary = scenario.observation(previous_action)
			var state: String = table.state_key(obs["resource_sector"], obs["resource_visible"], obs["previous_action"])
			var action: int = table.select_greedy(state)
			trace.append(action)
			result = await scenario.execute_action(action)
			previous_action = action
		records.append({"seed": scenario.card_seed, "trace": trace, "policy": policy, "success": result["success"], "actions": result["actions"], "berries_picked": result["berries_picked"]})
		scenario.free()
		await get_tree().physics_frame
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(records))
	file.close()
	get_tree().quit(0)
