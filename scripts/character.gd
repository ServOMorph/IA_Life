extends CharacterBody3D

@export var map_half_x: float = 18.0
@export var map_half_z: float = 18.0
@export var move_speed: float = 2.5
@export var gravity: float = 9.8
@export var hunger: float = 100.0
@export var hunger_depletion_rate: float = 0.6
@export var aging_factor: float = 1.0
@export var feeding_capacity: float = 1.0
@export var memory_capacity: int = 5
@export var memory_decay_rate: float = 0.15
@export var display_name: String = ""
@export var manual_control: bool = false
@export var immortal: bool = false

const MEMORY_MAX_STRENGTH := 10.0

var is_dead: bool = false
var berries_carried: int = 0
var berries_picked_total: int = 0
var berries_eaten_total: int = 0

var _direction := Vector3.ZERO
var _manual_direction := Vector3.ZERO
var _timer := 0.0
var _memories: Array = []

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _body_base_y: float = 0.0
var _head_base_y: float = 0.0
var _walk_time: float = 0.0

var _anim_player: AnimationPlayer = null
var _current_anim: String = ""

func _ready() -> void:
	_pick_new_direction()
	GameLogger.log_event("spawn", "%s apparaît en (%.1f, %.1f)" % [display_name, position.x, position.z])

func setup_visual(body_mesh: MeshInstance3D, head_mesh: MeshInstance3D) -> void:
	_body_mesh = body_mesh
	_head_mesh = head_mesh
	_body_base_y = body_mesh.position.y
	_head_base_y = head_mesh.position.y

func setup_rigged_visual(anim_player: AnimationPlayer) -> void:
	_anim_player = anim_player
	_play_anim("Idle")

func set_manual_direction(dir: Vector3) -> void:
	_manual_direction = dir

func _physics_process(delta: float) -> void:
	var scaled_delta := delta * GameSpeed.time_scale

	if is_dead:
		return

	if immortal:
		hunger = clamp(hunger - hunger_depletion_rate * aging_factor * scaled_delta, 1.0, 100.0)
	else:
		hunger -= hunger_depletion_rate * aging_factor * scaled_delta
		if hunger <= 0.0:
			hunger = 0.0
			_die()
			return

	_try_eat_berry()
	_decay_memories(scaled_delta)

	if manual_control:
		_direction = _manual_direction
	elif hunger > GameConfig.pickup_hunger_threshold and not _memories.is_empty():
		_direction = _direction_to_nearest_memory()
	else:
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
	_update_facing(scaled_delta)
	_update_walk_animation(scaled_delta)

func _update_facing(scaled_delta: float) -> void:
	var horizontal := Vector2(_direction.x, _direction.z)
	if horizontal.length() < 0.01:
		return
	var target_basis := Basis.looking_at(_direction, Vector3.UP)
	basis = basis.slerp(target_basis, clamp(scaled_delta * 8.0, 0.0, 1.0))

func _play_anim(anim_name: String) -> void:
	if _anim_player == null or _current_anim == anim_name:
		return
	if not _anim_player.has_animation(anim_name):
		return
	_anim_player.play(anim_name)
	_current_anim = anim_name

func _update_walk_animation(scaled_delta: float) -> void:
	if _anim_player != null:
		var rig_speed := Vector2(velocity.x, velocity.z).length()
		_play_anim("Walk" if rig_speed > 0.1 else "Idle")
		return
	if _body_mesh == null or _head_mesh == null:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.1:
		_walk_time += scaled_delta * (4.0 + speed)
		var bob := sin(_walk_time) * 0.05
		_body_mesh.position.y = _body_base_y + bob
		_head_mesh.position.y = _head_base_y + bob * 0.6
		_body_mesh.rotation.z = sin(_walk_time) * 0.08
	else:
		_body_mesh.position.y = lerp(_body_mesh.position.y, _body_base_y, scaled_delta * 6.0)
		_head_mesh.position.y = lerp(_head_mesh.position.y, _head_base_y, scaled_delta * 6.0)
		_body_mesh.rotation.z = lerp(_body_mesh.rotation.z, 0.0, scaled_delta * 6.0)

func kill() -> void:
	if is_dead:
		return
	hunger = 0.0
	_die()

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	GameLogger.log_event("mort", "%s meurt de faim en (%.1f, %.1f) — mûres ramassées: %d, mangées: %d" % [display_name, position.x, position.z, berries_picked_total, berries_eaten_total])
	if _anim_player != null:
		_play_anim("Death")
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation:z", deg_to_rad(90.0), 0.6)
	tween.parallel().tween_property(self, "position:y", 0.35, 0.6)

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

func _on_ronce_contact(ronce) -> void:
	try_pick_berry_from_ronce(ronce)

func try_pick_berry_from_ronce(ronce, ignore_hunger_threshold: bool = false) -> bool:
	if is_dead:
		return false
	_remember_ronce(ronce)
	if berries_carried >= GameConfig.max_berries_carried:
		return false
	if not ignore_hunger_threshold and hunger > GameConfig.pickup_hunger_threshold:
		return false
	if ronce.harvest_one():
		berries_carried += 1
		berries_picked_total += 1
		GameLogger.log_event("cueillette", "%s ramasse une mûre (faim: %.0f, portées: %d/%d)" % [display_name, hunger, berries_carried, GameConfig.max_berries_carried])
		return true
	return false

func _remember_ronce(ronce) -> void:
	for m in _memories:
		if m.ronce == ronce:
			m.strength = MEMORY_MAX_STRENGTH
			return
	if memory_capacity <= 0:
		return
	if _memories.size() >= memory_capacity:
		var weakest_idx := 0
		for i in range(1, _memories.size()):
			if _memories[i].strength < _memories[weakest_idx].strength:
				weakest_idx = i
		GameLogger.log_event("memoire", "%s oublie un roncier pour en retenir un nouveau (mémoire pleine: %d/%d)" % [display_name, _memories.size(), memory_capacity])
		_memories.remove_at(weakest_idx)
	_memories.append({"ronce": ronce, "strength": MEMORY_MAX_STRENGTH})
	GameLogger.log_event("memoire", "%s mémorise un nouveau roncier en (%.1f, %.1f) (%d/%d)" % [display_name, ronce.position.x, ronce.position.z, _memories.size(), memory_capacity])

func _decay_memories(scaled_delta: float) -> void:
	for i in range(_memories.size() - 1, -1, -1):
		var m = _memories[i]
		if not is_instance_valid(m.ronce):
			_memories.remove_at(i)
			continue
		m.strength -= memory_decay_rate * scaled_delta
		if m.strength <= 0.0:
			GameLogger.log_event("memoire", "%s oublie un roncier (mémoire estompée)" % display_name)
			_memories.remove_at(i)

func memorized_ronces_count() -> int:
	return _memories.size()

func _direction_to_nearest_memory() -> Vector3:
	var nearest = null
	var nearest_dist := INF
	for m in _memories:
		if not is_instance_valid(m.ronce):
			continue
		var dist := position.distance_squared_to(m.ronce.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = m.ronce
	if nearest == null:
		return _direction
	var to_target: Vector3 = nearest.position - position
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return _direction
	return to_target.normalized()

func _try_eat_berry() -> void:
	if berries_carried <= 0:
		return
	if hunger > GameConfig.eat_hunger_threshold:
		return
	berries_carried -= 1
	berries_eaten_total += 1
	var pv_gained := GameConfig.pv_per_berry(feeding_capacity)
	hunger = min(100.0, hunger + pv_gained)
	GameLogger.log_event("repas", "%s mange une mûre (+%.1f PV, faim -> %.0f, restantes: %d)" % [display_name, pv_gained, hunger, berries_carried])
