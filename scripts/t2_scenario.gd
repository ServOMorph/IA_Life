class_name T2Scenario
extends Node3D

const ACTION_COUNT := 8
const ACTION_TICKS := 15
const HORIZON_ACTIONS := 24
const ARENA_HALF_SIZE := 12.0
const DISTANCES := [3.0, 6.0, 9.0]
const VISION_RANGE := 10.0
const VISION_HALF_ANGLE := PI / 4.0

const CharacterScript = preload("res://scripts/character.gd")
const RonceScript = preload("res://scripts/ronce.gd")

var card_seed := 0
var target_sector := 0
var target_distance := 3.0
var character
var ronce
var action_count := 0
var decision_started := false
var last_seen_sector := -1
var _saved_max_berries := 0
var _saved_pickup_threshold := 0.0
var _saved_eat_threshold := 0.0

func configure(seed_value: int) -> void:
	card_seed = seed_value
	var card_index := positive_modulo(seed_value - 1, 32)
	target_sector = card_index % ACTION_COUNT
	target_distance = DISTANCES[int(card_index / ACTION_COUNT) % DISTANCES.size()]

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
	_add_ronce()
	_face_direction(_sector_direction(target_sector))

func _exit_tree() -> void:
	GameConfig.max_berries_carried = _saved_max_berries
	GameConfig.pickup_hunger_threshold = _saved_pickup_threshold
	GameConfig.eat_hunger_threshold = _saved_eat_threshold

func observation(include_memory: bool) -> Dictionary:
	var visible_targets: Array = []
	if _target_visible():
		visible_targets.append({"resource_sector": target_sector, "distance_bin": DISTANCES.find(target_distance), "available": ronce.berries > 0})
	return {
		"visible_targets": visible_targets,
		"last_seen_sector": last_seen_sector if include_memory else -1,
		"decision_started": decision_started,
	}

func begin_decision(store_memory: bool) -> bool:
	if decision_started:
		return false
	var visible := _target_visible()
	if store_memory and visible:
		last_seen_sector = target_sector
	decision_started = true
	_face_direction(-_sector_direction(target_sector))
	return visible

func execute_held_action(action: int) -> Dictionary:
	if not decision_started or action < 0 or action >= ACTION_COUNT:
		return {"invalid": true}
	var result: Dictionary = {}
	var first_reward := 0.0
	var first_distance_progress := 0.0
	while not bool(result.get("terminated", false)) and not bool(result.get("truncated", false)):
		result = await _execute_action(action)
		if int(result.get("actions", 0)) == 1:
			first_reward = float(result.get("reward", 0.0))
			first_distance_progress = float(result.get("distance_progress", 0.0))
	result["selected_action"] = action
	result["policy_decisions"] = 1
	result["first_reward"] = first_reward
	result["first_distance_progress"] = first_distance_progress
	result["selected_remembered_sector"] = action == target_sector
	return result

func _execute_action(action: int) -> Dictionary:
	if action_count >= HORIZON_ACTIONS:
		return {"invalid": true}
	var eaten_before: int = character.berries_eaten_total
	var distance_before := _horizontal_distance()
	character.set_t0_action(action)
	for _tick in ACTION_TICKS:
		await get_tree().physics_frame
		if character.berries_eaten_total > eaten_before or character.is_dead:
			break
	action_count += 1
	var consumed: bool = character.berries_eaten_total > eaten_before
	var terminated: bool = consumed or character.is_dead
	return {
		"reward": 1.0 if consumed else 0.0,
		"distance_progress": distance_before - _horizontal_distance(),
		"terminated": terminated,
		"truncated": not terminated and action_count >= HORIZON_ACTIONS,
		"consumed": consumed,
		"actions": action_count,
		"berries_picked": character.berries_picked_total,
		"berries_eaten": character.berries_eaten_total,
	}

func _target_visible() -> bool:
	if ronce == null or ronce.berries <= 0:
		return false
	var relative: Vector3 = ronce.global_position - character.global_position
	relative.y = 0.0
	if relative.length() <= 0.01 or relative.length() > VISION_RANGE:
		return false
	var forward: Vector3 = -character.global_basis.z
	forward.y = 0.0
	return forward.normalized().angle_to(relative.normalized()) <= VISION_HALF_ANGLE

func _face_direction(direction: Vector3) -> void:
	character.basis = Basis.looking_at(direction.normalized(), Vector3.UP)

func _horizontal_distance() -> float:
	var delta: Vector3 = character.global_position - ronce.global_position
	return Vector2(delta.x, delta.z).length()

func _add_character() -> void:
	character = CharacterScript.new()
	character.name = "Rouge"
	character.position = Vector3(0, 1.0, 0)
	character.display_name = "Rouge T2"
	character.map_half_x = ARENA_HALF_SIZE
	character.map_half_z = ARENA_HALF_SIZE
	character.hunger = 50.0
	character.hunger_depletion_rate = 0.0
	character.memory_capacity = 0
	character.vision_range = VISION_RANGE
	character.vision_angle_degrees = 90.0
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

func _add_ronce() -> void:
	ronce = RonceScript.new()
	ronce.position = _sector_direction(target_sector) * target_distance + Vector3(0, 0.5, 0)
	ronce.berries = 1
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

func positive_modulo(value: int, divisor: int) -> int:
	return ((value % divisor) + divisor) % divisor
