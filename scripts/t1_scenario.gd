class_name T1Scenario
extends Node3D

const ACTION_COUNT := 8
const ACTION_TICKS := 15
const HORIZON_ACTIONS := 24
const ARENA_HALF_SIZE := 12.0
const DISTANCES := [3.0, 6.0, 9.0]

const CharacterScript = preload("res://scripts/character.gd")
const RonceScript = preload("res://scripts/ronce.gd")

var card_seed := 0
var targets: Array = []
var character
var ronces: Array = []
var action_count := 0
var first_selected_available := false
var _saved_max_berries := 0
var _saved_pickup_threshold := 0.0
var _saved_eat_threshold := 0.0

func configure(seed_value: int) -> void:
	card_seed = seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = card_seed
	var sectors := [0, 1, 2, 3, 4, 5, 6, 7]
	_shuffle(sectors, rng)
	var distances := DISTANCES.duplicate()
	_shuffle(distances, rng)
	var available_slot := rng.randi_range(0, 2)
	for index in range(3):
		targets.append({"sector": sectors[index], "distance": distances[index], "available": index == available_slot})
	var order := [0, 1, 2]
	_shuffle(order, rng)
	var ordered: Array = []
	for index in order:
		ordered.append(targets[index])
	targets = ordered

func _ready() -> void:
	GameSpeed.time_scale = 1.0
	_saved_max_berries = GameConfig.max_berries_carried
	_saved_pickup_threshold = GameConfig.pickup_hunger_threshold
	_saved_eat_threshold = GameConfig.eat_hunger_threshold
	GameConfig.max_berries_carried = 1
	GameConfig.pickup_hunger_threshold = 50.0
	GameConfig.eat_hunger_threshold = 50.0
	_add_ground_and_walls()
	_add_character()
	for target in targets:
		_add_ronce(target)

func _exit_tree() -> void:
	GameConfig.max_berries_carried = _saved_max_berries
	GameConfig.pickup_hunger_threshold = _saved_pickup_threshold
	GameConfig.eat_hunger_threshold = _saved_eat_threshold

func observation(previous_action: int) -> Dictionary:
	var slots: Array = []
	for target in targets:
		var index := slots.size()
		slots.append({
			"resource_sector": int(target["sector"]),
			"distance_bin": DISTANCES.find(float(target["distance"])),
			"available": ronces[index].berries > 0,
		})
	return {"targets": slots, "previous_action": previous_action}

func execute_action(action: int) -> Dictionary:
	if action < 0 or action >= ACTION_COUNT or action_count >= HORIZON_ACTIONS:
		return {"invalid": true}
	if action_count == 0:
		first_selected_available = _action_targets_available(action)
	var eaten_before: int = character.berries_eaten_total
	var available_ronce = _available_ronce()
	var distance_before := _horizontal_distance(available_ronce)
	character.set_t0_action(action)
	for _tick in ACTION_TICKS:
		await get_tree().physics_frame
		if character.berries_eaten_total > eaten_before or character.is_dead:
			break
	action_count += 1
	var consumed: bool = character.berries_eaten_total > eaten_before
	var distance_progress := distance_before - _horizontal_distance(available_ronce)
	var terminated: bool = consumed or character.is_dead
	var truncated: bool = not terminated and action_count >= HORIZON_ACTIONS
	return {
		"reward": 1.0 if consumed else 0.0,
		"distance_progress": distance_progress,
		"terminated": terminated,
		"truncated": truncated,
		"consumed": consumed,
		"actions": action_count,
		"berries_picked": character.berries_picked_total,
		"berries_eaten": character.berries_eaten_total,
		"first_selected_available": first_selected_available,
	}

func _available_ronce():
	for index in range(targets.size()):
		if bool(targets[index]["available"]):
			return ronces[index]
	return null

func _horizontal_distance(ronce) -> float:
	var delta: Vector3 = character.global_position - ronce.global_position
	return Vector2(delta.x, delta.z).length()

func _action_targets_available(action: int) -> bool:
	for target in targets:
		if bool(target["available"]) and int(target["sector"]) == action:
			return true
	return false

func _add_character() -> void:
	character = CharacterScript.new()
	character.name = "Rouge"
	character.position = Vector3(0, 1.0, 0)
	character.display_name = "Rouge T1"
	character.map_half_x = ARENA_HALF_SIZE
	character.map_half_z = ARENA_HALF_SIZE
	character.hunger = 50.0
	character.hunger_depletion_rate = 0.0
	character.memory_capacity = 0
	character.vision_range = 0.0
	character.rl_controlled = true
	character.collision_layer = 1
	character.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	collision.shape = capsule
	character.add_child(collision)
	add_child(character)

func _add_ronce(target: Dictionary) -> void:
	var ronce = RonceScript.new()
	ronce.position = _sector_direction(int(target["sector"])) * float(target["distance"]) + Vector3(0, 0.5, 0)
	ronce.berries = 1 if bool(target["available"]) else 0
	ronce.collision_layer = 0
	ronce.collision_mask = 1
	var contact := CollisionShape3D.new()
	var contact_shape := SphereShape3D.new()
	contact_shape.radius = 1.1
	contact.shape = contact_shape
	ronce.add_child(contact)
	var solid := StaticBody3D.new()
	solid.name = "CollisionPhysique"
	solid.collision_layer = 1
	solid.collision_mask = 1
	var solid_collision := CollisionShape3D.new()
	var solid_shape := CylinderShape3D.new()
	solid_shape.radius = 0.35
	solid_shape.height = 1.0
	solid_collision.shape = solid_shape
	solid.add_child(solid_collision)
	ronce.add_child(solid)
	ronce.solid_body = solid
	add_child(ronce)
	ronces.append(ronce)

func _add_ground_and_walls() -> void:
	_add_static_box("Sol", Vector3(0, -0.25, 0), Vector3(ARENA_HALF_SIZE * 2.0, 0.5, ARENA_HALF_SIZE * 2.0))
	_add_static_box("MurNord", Vector3(0, 1.0, -ARENA_HALF_SIZE), Vector3(ARENA_HALF_SIZE * 2.0, 2.0, 0.4))
	_add_static_box("MurSud", Vector3(0, 1.0, ARENA_HALF_SIZE), Vector3(ARENA_HALF_SIZE * 2.0, 2.0, 0.4))
	_add_static_box("MurEst", Vector3(ARENA_HALF_SIZE, 1.0, 0), Vector3(0.4, 2.0, ARENA_HALF_SIZE * 2.0))
	_add_static_box("MurOuest", Vector3(-ARENA_HALF_SIZE, 1.0, 0), Vector3(0.4, 2.0, ARENA_HALF_SIZE * 2.0))

func _add_static_box(node_name: String, box_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _sector_direction(sector: int) -> Vector3:
	var directions := [Vector3.FORWARD, Vector3(1, 0, -1).normalized(), Vector3.RIGHT, Vector3(1, 0, 1).normalized(), Vector3.BACK, Vector3(-1, 0, 1).normalized(), Vector3.LEFT, Vector3(-1, 0, -1).normalized()]
	return directions[sector]

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary
