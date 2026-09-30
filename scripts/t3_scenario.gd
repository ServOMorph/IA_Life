class_name T3Scenario
extends Node

const ACTION_COUNT := 8
const ACTION_TICKS := 15
const HORIZON_ACTIONS := 80
const WorldScene = preload("res://scenes/Main.tscn")

var card_seed := 0
var world
var actor
var action_count := 0
var previous_action := 8
var collided := false
var progress := 0.0
var competitors_enabled := false
var configured_vision_range := 25.0
var _saved_config: Dictionary = {}

func configure(seed_value: int, with_competitors: bool = false, vision_range: float = 25.0) -> void:
	card_seed = seed_value
	competitors_enabled = with_competitors
	configured_vision_range = vision_range

func _ready() -> void:
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
	GameSpeed.time_scale = 1.0
	world = WorldScene.instantiate()
	world.configure_training_world(card_seed)
	add_child(world)
	actor = world.training_character()
	actor.rl_controlled = true
	actor.hunger = 50.0
	actor.hunger_depletion_rate = 4.0
	actor.memory_capacity = 5
	actor.vision_range = configured_vision_range
	actor.vision_angle_degrees = 360.0
	actor.set_t0_action(0)
	var agents: Array = world.training_agents()
	if competitors_enabled:
		for index in range(1, agents.size()):
			var competitor = agents[index]
			competitor.rl_controlled = false
			competitor.hunger = 50.0
			competitor.hunger_depletion_rate = 4.0
			competitor.memory_capacity = 5
			competitor.vision_range = configured_vision_range
			competitor.vision_angle_degrees = 360.0
	else:
		for index in range(1, agents.size()):
			agents[index].process_mode = Node.PROCESS_MODE_DISABLED
			agents[index].collision_layer = 0
			agents[index].collision_mask = 0
			agents[index].visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED

func _exit_tree() -> void:
	if not _saved_config.is_empty():
		GameConfig.apply_overrides(_saved_config)

func observation() -> Dictionary:
	return actor.training_food_observation(previous_action, collided, progress)

func execute_action(action: int) -> Dictionary:
	if action < 0 or action >= ACTION_COUNT or action_count >= HORIZON_ACTIONS or actor.is_dead:
		return {"invalid": true}
	var eaten_before: int = actor.berries_eaten_total
	var picked_before: int = actor.berries_picked_total
	var hunger_before: float = actor.hunger
	var position_before: Vector3 = actor.position
	var target_direction := _priority_direction(observation())
	world.process_mode = Node.PROCESS_MODE_INHERIT
	actor.set_t0_action(action)
	previous_action = action
	collided = false
	for _tick in ACTION_TICKS:
		await get_tree().physics_frame
		for index in actor.get_slide_collision_count():
			if absf(actor.get_slide_collision(index).get_normal().y) < 0.5:
				collided = true
		if actor.is_dead:
			break
	world.process_mode = Node.PROCESS_MODE_DISABLED
	action_count += 1
	progress = 0.0
	if target_direction != Vector3.ZERO:
		var displacement: Vector3 = actor.position - position_before
		displacement.y = 0.0
		progress = clampf(displacement.dot(target_direction) / maxf(0.01, actor.move_speed * 0.25), -1.0, 1.0)
	var terminated: bool = actor.is_dead
	var truncated: bool = not terminated and action_count >= HORIZON_ACTIONS
	return {
		"reward_event": float(actor.berries_eaten_total - eaten_before) - (1.0 if terminated else 0.0),
		"progress": progress,
		"terminated": terminated,
		"truncated": truncated,
		"survived": truncated and not actor.is_dead,
		"actions": action_count,
		"berries_picked": actor.berries_picked_total,
		"berries_eaten": actor.berries_eaten_total,
		"berries_picked_delta": actor.berries_picked_total - picked_before,
		"berries_eaten_delta": actor.berries_eaten_total - eaten_before,
		"hunger_before": hunger_before,
		"hunger": actor.hunger,
		"collision": collided,
	}

func scripted_action() -> int:
	var obs := observation()
	var direction := _priority_direction(obs)
	if direction != Vector3.ZERO:
		return _direction_sector(direction)
	if collided:
		return (previous_action + 2) % ACTION_COUNT if previous_action < ACTION_COUNT else 0
	return previous_action if previous_action < ACTION_COUNT else positive_modulo(card_seed, ACTION_COUNT)

func active_competitor_count() -> int:
	var count := 0
	for index in range(1, world.training_agents().size()):
		var agent = world.training_agents()[index]
		if agent.process_mode != Node.PROCESS_MODE_DISABLED or agent.collision_layer != 0 or agent.collision_mask != 0:
			count += 1
	return count

func _priority_direction(obs: Dictionary) -> Vector3:
	for target in obs["targets"]:
		if float(target[0]) > 0.5 and float(target[4]) > 0.5:
			return Vector3(float(target[1]), 0.0, float(target[2])).normalized()
	for memory in obs["memories"]:
		if float(memory[0]) > 0.5:
			return Vector3(float(memory[1]), 0.0, float(memory[2])).normalized()
	return Vector3.ZERO

func _direction_sector(direction: Vector3) -> int:
	var directions := [Vector3.FORWARD, Vector3(1, 0, -1).normalized(), Vector3.RIGHT, Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3(-1, 0, 1).normalized(), Vector3.LEFT, Vector3(-1, 0, -1).normalized()]
	var best := 0
	for index in range(1, directions.size()):
		if direction.dot(directions[index]) > direction.dot(directions[best]):
			best = index
	return best

func positive_modulo(value: int, divisor: int) -> int:
	return ((value % divisor) + divisor) % divisor
