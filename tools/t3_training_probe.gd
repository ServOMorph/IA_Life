extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [2, 4, 6] or args[0] != "--output":
		push_error("Usage : --output chemin [--vision portée] [--seed-base base]")
		get_tree().quit(2)
		return
	var vision_range := 25.0
	var seed_base := 390000000
	for index in range(2, args.size(), 2):
		if args[index] == "--vision":
			vision_range = float(args[index + 1])
		elif args[index] == "--seed-base":
			seed_base = int(args[index + 1])
		else:
			get_tree().quit(2)
			return
	if vision_range < 1.0 or vision_range > 250.0:
		get_tree().quit(2)
		return
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		get_tree().quit(1)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 390002001
	for card_seed in range(seed_base + 1, seed_base + 33):
		for arm in ["scripted_food", "initial_frozen", "random_valid"]:
			var started_ms := Time.get_ticks_msec()
			var scenario := T3Scenario.new()
			scenario.configure(card_seed, false, vision_range)
			add_child(scenario)
			await get_tree().physics_frame
			var initial_observation: Dictionary = scenario.observation()
			var initial_visible := 0
			for target in initial_observation["targets"]:
				if float(target[0]) > 0.5 and float(target[4]) > 0.5:
					initial_visible += 1
			var result: Dictionary = {}
			while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
				var action := scenario.scripted_action() if arm == "scripted_food" else 0 if arm == "initial_frozen" else rng.randi_range(0, 7)
				result = await scenario.execute_action(action)
			file.store_line(JSON.stringify({"arm": arm, "card_seed": card_seed, "vision_range": vision_range, "initial_visible": initial_visible, "survived": bool(result.get("survived", false)), "berries_picked": int(result.get("berries_picked", 0)), "berries_eaten": int(result.get("berries_eaten", 0)), "actions": int(result.get("actions", 0)), "elapsed_seconds": float(Time.get_ticks_msec() - started_ms) / 1000.0, "static_memory_bytes": OS.get_static_memory_usage()}))
			scenario.queue_free()
			await get_tree().physics_frame
	file.close()
	print("SUCCÈS : probe T3 entraînement écrit.")
	get_tree().quit(0)
