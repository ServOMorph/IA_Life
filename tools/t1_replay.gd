extends Node

const T1Scenario = preload("res://scripts/t1_scenario.gd")
const T1V3Table = preload("res://scripts/t1_v3_table.gd")
const T1V4Table = preload("res://scripts/t1_v4_table.gd")
const T1V5Table = preload("res://scripts/t1_v5_table.gd")
const FINGERPRINT_V3 := "t1_choice_v3|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_bandit=sector|first_epsilon=0.50"
const FINGERPRINT_V4 := "t1_choice_v4|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|gamma=0.90|progress=0.50|first_explore=min_count|first_tie=lowest"
const FINGERPRINT_V5 := "t1_choice_v5|targets=3|available=1|distances=3,6,9|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|first_explore=min_count|first_tie=lowest|execution=hold_first"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [6, 10] or args[0] != "--checkpoint" or args[2] != "--output" or args[4] != "--initialization-seed":
		push_error("Usage : --checkpoint chemin --output chemin --initialization-seed seed")
		get_tree().quit(2)
		return
	var contract := "v3"
	var checkpoint_episodes := 1000
	if args.size() == 10:
		if args[6] != "--contract" or args[8] != "--checkpoint-episode":
			push_error("Arguments de replay invalides")
			get_tree().quit(2)
			return
		contract = String(args[7])
		checkpoint_episodes = int(args[9])
	if contract not in ["v3", "v4", "v5"] or checkpoint_episodes not in [0, 10, 50, 200, 1000]:
		push_error("Contrat ou checkpoint de replay invalide")
		get_tree().quit(2)
		return
	var seed_base: int = {"v3": 350000000, "v4": 360000000, "v5": 370000000}[contract]
	var initialization_base: int = {"v3": 350001000, "v4": 360001000, "v5": 370001000}[contract]
	var table_script = {"v3": T1V3Table, "v4": T1V4Table, "v5": T1V5Table}[contract]
	var fingerprint: String = {"v3": FINGERPRINT_V3, "v4": FINGERPRINT_V4, "v5": FINGERPRINT_V5}[contract]
	var initialization_seed := int(args[5])
	if initialization_seed not in [initialization_base + 1, initialization_base + 2, initialization_base + 3]:
		push_error("Seed d'initialisation T1 invalide")
		get_tree().quit(2)
		return
	var original = table_script.load_checkpoint(args[1], fingerprint)
	if original == null or original.episode_count != checkpoint_episodes:
		push_error("Checkpoint T1 invalide")
		get_tree().quit(1)
		return
	var copy_path := "user://t1_replay_%d.checkpoint.json" % initialization_seed
	if original.save_checkpoint(copy_path) != OK:
		push_error("Sauvegarde de replay impossible")
		get_tree().quit(1)
		return
	var reloaded = table_script.load_checkpoint(copy_path, fingerprint)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(copy_path))
	if reloaded == null or reloaded.checksum() != original.checksum():
		push_error("Recharge de replay divergente")
		get_tree().quit(1)
		return
	var file := FileAccess.open(args[3], FileAccess.WRITE)
	if file == null:
		push_error("Fichier de replay inaccessible")
		get_tree().quit(1)
		return
	for card_seed in range(seed_base + 101, seed_base + 133):
		var before: Dictionary = await _run_episode(original, card_seed, contract)
		var after: Dictionary = await _run_episode(reloaded, card_seed, contract)
		if before != after or original.checksum() != reloaded.checksum():
			push_error("Replay divergent pour la carte %d" % card_seed)
			file.close()
			get_tree().quit(1)
			return
		before["initialization_seed"] = initialization_seed
		before["card_seed"] = card_seed
		before["table_checksum"] = original.checksum()
		file.store_line(JSON.stringify(before))
	file.close()
	print("SUCCÈS : 32 replays T1 %s identiques avant et après recharge." % contract)
	get_tree().quit(0)

func _run_episode(table, card_seed: int, contract: String) -> Dictionary:
	var scenario := T1Scenario.new()
	scenario.configure(card_seed)
	add_child(scenario)
	await get_tree().physics_frame
	table.begin_episode()
	var previous_action := 8
	var rng := RandomNumberGenerator.new()
	rng.state = table.training_rng_state
	var actions: Array[int] = []
	var first_progress := 0.0
	var first_picked := 0
	var initial_observation: Dictionary = scenario.observation(previous_action)
	var available_sector := -1
	var available_distance_bin := -1
	var empty_sectors: Array[int] = []
	for target in initial_observation["targets"]:
		if bool(target["available"]):
			available_sector = int(target["resource_sector"])
			available_distance_bin = int(target["distance_bin"])
		else:
			empty_sectors.append(int(target["resource_sector"]))
	var result: Dictionary = {}
	if contract == "v5":
		var observation: Dictionary = scenario.observation(previous_action)
		var state: String = table.state_key(observation["targets"], observation["previous_action"])
		var action: int = table.select_epsilon_greedy(state, 0.0, rng)
		result = await scenario.execute_held_action(action)
		actions.append(action)
		first_progress = float(result["first_distance_progress"])
		first_picked = int(result["first_berries_picked"])
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		var observation: Dictionary = scenario.observation(previous_action)
		var state: String = table.state_key(observation["targets"], observation["previous_action"])
		var action: int = table.select_epsilon_greedy(state, 0.0, rng)
		result = await scenario.execute_action(action)
		var next_observation: Dictionary = scenario.observation(action)
		var next_state: String = table.state_key(next_observation["targets"], action)
		table.apply_transition(actions.size(), state, action, float(result["reward"]), next_state, bool(result["terminated"]), false)
		if actions.is_empty():
			first_progress = float(result["distance_progress"])
			first_picked = int(result["berries_picked"])
		actions.append(action)
		previous_action = action
	var summary := {
		"available_sector": available_sector,
		"available_distance_bin": available_distance_bin,
		"empty_sectors": empty_sectors,
		"first_action": actions[0],
		"first_distance_progress": first_progress,
		"first_step_berries_picked": first_picked,
		"action_trace": actions,
		"consumed": bool(result["consumed"]),
		"first_selected_available": bool(result["first_selected_available"]),
		"actions": int(result["actions"]),
		"berries_picked": int(result["berries_picked"]),
		"berries_eaten": int(result["berries_eaten"]),
		"terminated": bool(result["terminated"]),
		"truncated": bool(result["truncated"]),
	}
	scenario.queue_free()
	await get_tree().physics_frame
	return summary
