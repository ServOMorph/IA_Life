extends CharacterBody3D

@export var map_half_x: float = 18.0
@export var map_half_z: float = 18.0
@export var move_speed: float = 2.5
@export var gravity: float = 9.8
@export var hunger: float = 100.0
@export var hunger_depletion_rate: float = 2.0
@export var aging_factor: float = 1.0

var is_dead: bool = false

var _direction := Vector3.ZERO
var _timer := 0.0

func _ready() -> void:
	_pick_new_direction()

func _physics_process(delta: float) -> void:
	var scaled_delta := delta * GameSpeed.time_scale

	if is_dead:
		return

	hunger -= hunger_depletion_rate * aging_factor * scaled_delta
	if hunger <= 0.0:
		hunger = 0.0
		_die()
		return

	_timer -= scaled_delta
	if _timer <= 0.0:
		_pick_new_direction()

	velocity.x = _direction.x * move_speed * GameSpeed.time_scale
	velocity.z = _direction.z * move_speed * GameSpeed.time_scale
	if not is_on_floor():
		velocity.y -= gravity * scaled_delta
	else:
		velocity.y = 0.0

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if absf(collision.get_normal().y) < 0.5:
			_bounce_back()
			break

	_clamp_to_map()

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	rotation_degrees.z = 90.0
	position.y = 0.35

func _pick_new_direction() -> void:
	var angle := randf_range(0.0, TAU)
	_direction = Vector3(cos(angle), 0.0, sin(angle))
	_timer = randf_range(1.5, 4.0)

func _bounce_back() -> void:
	_direction = -_direction
	_timer = randf_range(1.5, 4.0)

func _clamp_to_map() -> void:
	position.x = clamp(position.x, -map_half_x, map_half_x)
	position.z = clamp(position.z, -map_half_z, map_half_z)
