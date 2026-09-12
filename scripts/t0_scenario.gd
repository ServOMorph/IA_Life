class_name T0Scenario
extends Node3D

const ACTION_COUNT := 8
const ACTION_TICKS := 15
const HORIZON_ACTIONS := 48
const ARENA_HALF_SIZE := 12.0
const RESOURCE_DISTANCE := 2.0

const CharacterScript = preload("res://scripts/character.gd")
const RonceScript = preload("res://scripts/ronce.gd")

var card_seed := 0
var resource_sector := 0
var character
var ronce
var action_count := 0
var picked := false

func configure(seed: int) -> void:
	card_seed = seed
	resource_sector = posmod(seed, ACTION_COUNT)

func _ready() -> void:
	GameSpeed.time_scale = 1.0
	_add_ground_and_walls()
	_add_character()
	_add_ronce()

func observation(previous_action: int) -> Dictionary:
	return {
		"resource_sector": resource_sector,
		"resource_visible": true,
		"previous_action": previous_action,
	}

func execute_action(action: int) -> Dictionary:
	if action < 0 or action >= ACTION_COUNT:
		return {"invalid": true}
	if picked or action_count >= HORIZON_ACTIONS:
		return {"invalid": true}
	character.set_t0_action(action)
	for _tick in ACTION_TICKS:
		await get_tree().physics_frame
		if character.berries_picked_total == 1:
			picked = true
			break
	action_count += 1
	var terminated: bool = picked or character.is_dead
	var truncated: bool = not terminated and action_count >= HORIZON_ACTIONS
	return {
		"reward": 1.0 if picked else (-1.0 if character.is_dead else 0.0),
		"terminated": terminated,
		"truncated": truncated,
		"success": picked,
		"actions": action_count,
		"berries_picked": character.berries_picked_total,
		"ronce_berries": ronce.berries,
	}

func _add_character() -> void:
	character = CharacterScript.new()
	character.name = "Rouge"
	character.position = Vector3(0, 1.0, 0)
	character.display_name = "Rouge T0"
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

func _add_ronce() -> void:
	ronce = RonceScript.new()
	ronce.name = "RonceT0"
	ronce.position = _sector_direction(resource_sector) * RESOURCE_DISTANCE + Vector3(0, 0.5, 0)
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
	var directions := [
		Vector3.FORWARD,
		Vector3(1, 0, -1).normalized(),
		Vector3.RIGHT,
		Vector3(1, 0, 1).normalized(),
		Vector3.BACK,
		Vector3(-1, 0, 1).normalized(),
		Vector3.LEFT,
		Vector3(-1, 0, -1).normalized(),
	]
	return directions[sector]
