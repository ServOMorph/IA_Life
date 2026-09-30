extends Node

const T3Scenario = preload("res://scripts/t3_scenario.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [4, 6] or args[0] != "--seed" or args[2] != "--actions":
		get_tree().quit(2)
		return
	var with_competitors := false
	if args.size() == 6:
		if args[4] != "--competitors" or args[5] != "1":
			get_tree().quit(2)
			return
		with_competitors = true
	var scenario := T3Scenario.new()
	scenario.configure(int(args[1]), with_competitors, 40.0)
	add_child(scenario)
	await get_tree().physics_frame
	_emit_trace(scenario, {}, true)
	for raw_action in String(args[3]).split(",", false):
		var result: Dictionary = await scenario.execute_action(int(raw_action))
		_emit_trace(scenario, result, false)
		if bool(result.get("terminated", false)) or bool(result.get("truncated", false)):
			break
	get_tree().quit(0)

func _emit_trace(scenario, result: Dictionary, initial: bool) -> void:
	var ended := bool(result.get("terminated", false)) or bool(result.get("truncated", false))
	var reward := 0.0 if initial else float(result.get("reward_event", 0.0)) + 0.25 * float(result.get("progress", 0.0)) - 0.01
	var mask := [0, 0, 0, 0, 0, 0, 0, 0] if ended else [1, 1, 1, 1, 1, 1, 1, 1]
	print("T3_TRACE " + JSON.stringify({
		"observation": scenario.observation(),
		"reward": reward,
		"terminated": bool(result.get("terminated", false)),
		"truncated": bool(result.get("truncated", false)),
		"info": {
			"actions": scenario.action_count,
			"berries_picked": scenario.actor.berries_picked_total,
			"berries_eaten": scenario.actor.berries_eaten_total,
			"survived": ended and not scenario.actor.is_dead,
			"simulated_seconds": float(scenario.action_count * T3Scenario.ACTION_TICKS) / float(Engine.physics_ticks_per_second),
			"action_mask": mask,
		},
	}))
