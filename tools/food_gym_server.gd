extends Node

const T0Scenario = preload("res://scripts/t0_scenario.gd")
const T3Scenario = preload("res://scripts/t3_scenario.gd")
const RLBridgeScript = preload("res://scripts/rl_bridge.gd")
const RLProtocolScript = preload("res://scripts/rl_protocol.gd")
const WorldScene = preload("res://scenes/Main.tscn")

@export var level := "t0"

var _bridge
var _protocol = RLProtocolScript.new()
var _scenario
var _previous_action := 8
var _busy := false
var _ended := false
var _ticks_left := 0
var _elapsed_ticks := 0
var _actor
var _eaten_before := 0
var _position_before := Vector3.ZERO
var _progress_direction := Vector3.ZERO
var _collided := false
var _progress := 0.0

func _ready() -> void:
	process_physics_priority = 1000
	var port := 11008
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--port":
		port = int(args[1])
	if port < 1024 or port > 65535:
		get_tree().quit(2)
		return
	_bridge = RLBridgeScript.new()
	_bridge.configure_port(port)
	add_child(_bridge)
	_bridge.message_received.connect(_on_message)
	if _bridge.start() != OK:
		get_tree().quit(2)

func _on_message(message: Dictionary) -> void:
	if _busy:
		_error("busy")
		return
	match String(message.get("type", "")):
		"debug_set_resource_stock":
			if OS.get_environment("IA_LIFE_GYM_DIAGNOSTICS") != "1" or level != "world" or _scenario == null or not _nonnegative_integer(message.get("index")) or not _nonnegative_integer(message.get("stock")):
				_error("diagnostic indisponible")
				return
			var index: int = int(message["index"])
			var stock: int = int(message["stock"])
			if index >= _scenario.training_resources().size() or stock > 3:
				_error("stock invalide")
				return
			_scenario.training_resources()[index].berries = stock
			_bridge.send({"type": "updated"})
		"debug_place_at_west_wall":
			if OS.get_environment("IA_LIFE_GYM_DIAGNOSTICS") != "1" or level != "world" or _scenario == null:
				_error("diagnostic indisponible")
				return
			_actor.position.x = -_actor.map_half_x + 0.1
			_actor.velocity = Vector3.ZERO
			_bridge.send({"type": "updated"})
		"metrics":
			_bridge.send({"type": "metrics", "static_memory_bytes": OS.get_static_memory_usage()})
		"debug_set_resource_distance":
			if OS.get_environment("IA_LIFE_GYM_DIAGNOSTICS") != "1" or level != "t0" or _scenario == null or not _nonnegative_integer(message.get("distance_cm")):
				_error("diagnostic indisponible")
				return
			var distance: float = float(message["distance_cm"]) / 100.0
			if distance < 2.0 or distance > 5.0:
				_error("distance invalide")
				return
			_scenario.ronce.position = _scenario._sector_direction(_scenario.resource_sector) * distance + Vector3(0, 0.5, 0)
			_bridge.send({"type": "updated"})
		"debug_snapshot":
			if OS.get_environment("IA_LIFE_GYM_DIAGNOSTICS") != "1" or _scenario == null:
				_error("diagnostic indisponible")
				return
			_bridge.send({"type": "snapshot", "state": _debug_snapshot()})
		"inspect":
			if _scenario == null:
				_error("episode absent")
				return
			_bridge.send({"type": "observation", "observation": _observation(), "info": _info()})
		"reset":
			if not _nonnegative_integer(message.get("seed")):
				_error("seed invalide")
				return
			_reset(int(message["seed"]))
		"step":
			if _scenario == null or _ended:
				_error("episode termine ou absent")
				return
			if not _nonnegative_integer(message.get("episode_id")) or not _nonnegative_integer(message.get("step_id")):
				_error("identifiants invalides")
				return
			if not _nonnegative_integer(message.get("action")) or int(message["action"]) >= T0Scenario.ACTION_COUNT:
				_error("action invalide")
				return
			if not _protocol.accept_step(int(message["episode_id"]), int(message["step_id"])):
				_error("pas perime")
				return
			if _is_t3():
				_step_t3(int(message["action"]))
			else:
				_step(int(message["action"]))
		"close":
			_bridge.send({"type": "closed"})
			get_tree().quit()
		_:
			_error("commande inconnue")

func _reset(card_seed: int) -> void:
	_busy = true
	if _scenario != null:
		_scenario.free()
	var scenario
	if _is_t3():
		scenario = T3Scenario.new()
		scenario.configure(card_seed, level == "t3_v3", 40.0)
	elif level == "world":
		GameConfig.apply_overrides({
			"max_berries_carried": VariableRegistry.default_value(VariableRegistry.GAME_CONFIG["max_berries_carried"]),
			"pickup_hunger_threshold": VariableRegistry.default_value(VariableRegistry.GAME_CONFIG["pickup_hunger_threshold"]),
			"eat_hunger_threshold": VariableRegistry.default_value(VariableRegistry.GAME_CONFIG["eat_hunger_threshold"]),
			"full_life_berries": VariableRegistry.default_value(VariableRegistry.GAME_CONFIG["full_life_berries"]),
			"ronce_count": 24,
			"berries_per_ronce": 3,
			"danger_zone_count": 0,
		})
		GameSpeed.time_scale = 1.0
		scenario = WorldScene.instantiate()
		scenario.configure_training_world(card_seed)
	else:
		scenario = T0Scenario.new()
		scenario.configure(card_seed, 3.0)
	add_child(scenario)
	_scenario = scenario
	_actor = scenario.actor if _is_t3() else (scenario.training_character() if level == "world" else scenario.character)
	if level == "world":
		_actor.rl_controlled = true
		_actor.set_t0_action(0)
	_previous_action = 8
	_ended = false
	_elapsed_ticks = 0
	_ticks_left = 0
	_collided = false
	_progress = 0.0
	await get_tree().physics_frame
	if not _is_t3():
		_scenario.process_mode = Node.PROCESS_MODE_DISABLED
	_protocol.reset()
	_busy = false
	_bridge.send({"type": "observation", "observation": _observation(), "reward": 0.0, "terminated": false, "truncated": false, "info": _info()})

func _step_t3(action: int) -> void:
	_busy = true
	await get_tree().physics_frame
	var result: Dictionary = await _scenario.execute_action(action)
	var terminated: bool = bool(result.get("terminated", false))
	var truncated: bool = bool(result.get("truncated", false))
	_ended = terminated or truncated
	if _ended:
		_protocol.finish()
	_busy = false
	var reward := float(result.get("reward_event", 0.0)) + 0.25 * float(result.get("progress", 0.0)) - 0.01
	_bridge.send({"type": "observation", "observation": _observation(), "reward": reward, "terminated": terminated, "truncated": truncated, "info": _info()})

func _step(action: int) -> void:
	_busy = true
	_scenario.process_mode = Node.PROCESS_MODE_INHERIT
	_actor.set_t0_action(action)
	_previous_action = action
	_eaten_before = _actor.berries_eaten_total
	_position_before = _actor.position
	_progress_direction = Vector3.ZERO
	if level == "world":
		var food_observation: Dictionary = _actor.training_food_observation(_previous_action, false, 0.0)
		for target in food_observation["targets"]:
			if float(target[0]) > 0.5 and float(target[4]) > 0.5:
				_progress_direction = Vector3(float(target[1]), 0.0, float(target[2]))
				break
	_collided = false
	_progress = 0.0
	_ticks_left = T0Scenario.ACTION_TICKS

func _physics_process(_delta: float) -> void:
	if _ticks_left <= 0 or _scenario == null:
		return
	_ticks_left -= 1
	_elapsed_ticks += 1
	if level == "world":
		for index in _actor.get_slide_collision_count():
			if absf(_actor.get_slide_collision(index).get_normal().y) < 0.5:
				_collided = true
				break
		if absf(_actor.position.x) >= _actor.map_half_x - 0.01 or absf(_actor.position.z) >= _actor.map_half_z - 0.01:
			_collided = true
	var succeeded: bool = _actor.berries_eaten_total > _eaten_before if level == "world" else _actor.berries_picked_total > 0
	if _ticks_left > 0 and not succeeded and not _actor.is_dead:
		return
	_ticks_left = 0
	_scenario.process_mode = Node.PROCESS_MODE_DISABLED
	if level == "world":
		if _progress_direction != Vector3.ZERO:
			var displacement: Vector3 = _actor.position - _position_before
			displacement.y = 0.0
			_progress = clampf(displacement.dot(_progress_direction) / maxf(0.01, _actor.move_speed * 0.25), -1.0, 1.0)
	else:
		_scenario.action_count += 1
		_scenario.picked = succeeded
	var actions: int = _protocol.next_step
	var terminated: bool = succeeded or _actor.is_dead
	var truncated: bool = not terminated and actions >= (120 if level == "world" else T0Scenario.HORIZON_ACTIONS)
	_ended = terminated or truncated
	if _ended:
		_protocol.finish()
	_busy = false
	_bridge.send({"type": "observation", "observation": _observation(), "reward": 1.0 if succeeded else (-1.0 if _actor.is_dead else 0.0), "terminated": terminated, "truncated": truncated, "info": _info()})

func _observation() -> Dictionary:
	if _is_t3():
		return _scenario.observation()
	if level == "world":
		return _actor.training_food_observation(_previous_action, _collided, _progress)
	return _scenario.observation(_previous_action)

func _info() -> Dictionary:
	var mask := [0, 0, 0, 0, 0, 0, 0, 0] if _ended else [1, 1, 1, 1, 1, 1, 1, 1]
	if _is_t3():
		return {"episode_id": _protocol.episode_id, "step_id": _protocol.next_step, "actions": _scenario.action_count, "berries_picked": _actor.berries_picked_total, "berries_eaten": _actor.berries_eaten_total, "survived": _ended and not _actor.is_dead, "simulated_seconds": float(_scenario.action_count * T3Scenario.ACTION_TICKS) / float(Engine.physics_ticks_per_second), "action_mask": mask}
	if level == "world":
		return {"episode_id": _protocol.episode_id, "step_id": _protocol.next_step, "actions": _protocol.next_step, "berries_picked": _actor.berries_picked_total, "berries_eaten": _actor.berries_eaten_total, "simulated_seconds": float(_elapsed_ticks) / float(Engine.physics_ticks_per_second), "action_mask": mask}
	return {"episode_id": _protocol.episode_id, "step_id": _protocol.next_step, "actions": _scenario.action_count, "success": _scenario.picked, "berries_picked": _scenario.character.berries_picked_total, "ronce_berries": _scenario.ronce.berries, "simulated_seconds": float(_elapsed_ticks) / float(Engine.physics_ticks_per_second), "action_mask": mask}

func _debug_snapshot() -> Dictionary:
	if _is_t3():
		var agents: Array = []
		for agent in _scenario.world.training_agents():
			agents.append([agent.display_name, agent.position.x, agent.position.y, agent.position.z, agent.hunger, agent.berries_carried, agent.is_dead])
		var resources: Array = []
		for ronce in _scenario.world.training_resources():
			resources.append([ronce.position.x, ronce.position.y, ronce.position.z, ronce.berries])
		return {"agents": agents, "resources": resources, "actions": _scenario.action_count}
	if level == "world":
		var agents: Array = []
		for agent in _scenario.training_agents():
			agents.append([agent.display_name, agent.position.x, agent.position.y, agent.position.z, agent.hunger, agent.berries_carried, agent.is_dead])
		var resources: Array = []
		for ronce in _scenario.training_resources():
			resources.append([ronce.position.x, ronce.position.y, ronce.position.z, ronce.berries])
		return {"agents": agents, "resources": resources, "actions": _protocol.next_step}
	return {"agent": [_actor.position.x, _actor.position.y, _actor.position.z, _actor.hunger, _actor.berries_carried], "resource": [_scenario.ronce.position.x, _scenario.ronce.position.y, _scenario.ronce.position.z, _scenario.ronce.berries], "actions": _protocol.next_step}

func _error(message: String) -> void:
	_bridge.send({"type": "error", "message": message})

func _nonnegative_integer(value) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) >= 0.0 and float(value) == float(int(value))

func _is_t3() -> bool:
	return level == "t3" or level == "t3_v3"
