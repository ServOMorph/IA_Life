extends CharacterBody3D

const BaselineDeciderScript = preload("res://scripts/baseline_decider.gd")

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
# 0.5 est neutre : une valeur élevée raccourcit les phases d'errance et augmente
# la fréquence des changements de direction.
@export_range(0.0, 1.0, 0.01) var exploration_tendency: float = 0.5
@export var social_radius: float = 0.0
@export_range(0.0, 1.0, 0.01) var follow_probability: float = 0.0
@export_range(0.0, 1.0, 0.01) var avoid_probability: float = 0.0
@export var display_name: String = ""
@export var manual_control: bool = false
@export var immortal: bool = false
@export var rl_controlled: bool = false

const MEMORY_MAX_STRENGTH := 10.0
const POSITION_SAMPLE_INTERVAL_SECONDS := 1.0
const VISITED_ZONE_SIZE := 10.0

var is_dead: bool = false
var berries_carried: int = 0
var berries_picked_total: int = 0
var berries_eaten_total: int = 0
var current_goal: String = ""
var wander_reorientations_total: int = 0
var distance_travelled_total: float = 0.0
var death_elapsed_seconds: float = -1.0
var visited_zones_total: int = 0
var zone_discoveries_total: int = 0
var zone_revisits_total: int = 0
var social_encounters_total: int = 0
var social_contact_seconds: float = 0.0
var current_social_neighbors: int = 0
var social_follow_decisions_total: int = 0
var social_avoid_decisions_total: int = 0

var _direction := Vector3.ZERO
var _manual_direction := Vector3.ZERO
var _timer := 0.0
var _memories: Array = []
var _decider := BaselineDeciderScript.new()
var _last_position := Vector3.ZERO
var _visited_zone_ids: Dictionary = {}
var _current_zone_id: String = ""
var _position_sample_clock: float = 0.0
var _active_social_contacts: Dictionary = {}
var _social_target = null
var _social_goal: String = ""

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _body_base_y: float = 0.0
var _head_base_y: float = 0.0
var _walk_time: float = 0.0

var _anim_player: AnimationPlayer = null
var _current_anim: String = ""
var _rl_direction := Vector3.ZERO

func _ready() -> void:
	_pick_new_direction(false)
	_last_position = position
	_set_goal("errance")
	GameLogger.log_event_data("spawn", "%s apparaît en (%.1f, %.1f)" % [display_name, position.x, position.z], {
		"agent": display_name,
		"position": [position.x, position.y, position.z],
	})
	_record_position_sample()

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

func set_rl_action(action: int) -> void:
	var directions := [Vector3.FORWARD, Vector3(-1, 0, -1), Vector3.LEFT, Vector3(-1, 0, 1), Vector3.BACK, Vector3(1, 0, 1), Vector3.RIGHT]
	_rl_direction = directions[clamp(action, 0, directions.size() - 1)].normalized()

func reset_for_rl(spawn_position: Vector3) -> void:
	position = spawn_position
	velocity = Vector3.ZERO
	hunger = 100.0
	is_dead = false
	berries_carried = 0
	berries_picked_total = 0
	berries_eaten_total = 0
	distance_travelled_total = 0.0
	death_elapsed_seconds = -1.0
	_memories.clear()
	_visited_zone_ids.clear()
	_current_zone_id = ""
	_last_position = position
	_rl_direction = Vector3.ZERO
	_set_goal("rl")

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
	_update_social_perception(scaled_delta)

	_apply_decision(scaled_delta)

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
	_track_distance_travelled()
	_position_sample_clock += scaled_delta
	if _position_sample_clock >= POSITION_SAMPLE_INTERVAL_SECONDS:
		_position_sample_clock = fmod(_position_sample_clock, POSITION_SAMPLE_INTERVAL_SECONDS)
		_record_position_sample()
	_update_facing(scaled_delta)
	_update_walk_animation(scaled_delta)

func _apply_decision(scaled_delta: float) -> void:
	if rl_controlled:
		_direction = _rl_direction
		_set_goal("rl")
		return
	var action := _decider.decide({
		"manual_control": manual_control,
		"manual_direction": _manual_direction,
		"hunger": hunger,
		"pickup_hunger_threshold": GameConfig.pickup_hunger_threshold,
		"has_memories": not _memories.is_empty(),
		"memory_direction": _direction_to_nearest_memory(),
		"social_goal": _social_goal_if_active(),
		"social_direction": _social_direction(),
		"current_direction": _direction,
		"wander_timer": _timer,
		"delta": scaled_delta,
	})
	_set_goal(action["goal"])
	if action["renew_wander"]:
		_pick_new_direction()
	else:
		_direction = action["direction"]
	if current_goal == "errance" and not action["renew_wander"]:
		_timer -= scaled_delta

func _set_goal(goal: String) -> void:
	if current_goal == goal:
		return
	current_goal = goal
	GameLogger.log_event_data("objectif", "%s : %s" % [display_name, goal], {
		"agent": display_name,
		"goal": goal,
	})

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
	death_elapsed_seconds = GameLogger.get_elapsed_seconds()
	velocity = Vector3.ZERO
	GameLogger.log_event_data("mort", "%s meurt de faim en (%.1f, %.1f) — mûres ramassées: %d, mangées: %d" % [display_name, position.x, position.z, berries_picked_total, berries_eaten_total], {
		"agent": display_name,
		"position": [position.x, position.y, position.z],
		"berries_picked_total": berries_picked_total,
		"berries_eaten_total": berries_eaten_total,
	})
	if _anim_player != null:
		_play_anim("Death")
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation:z", deg_to_rad(90.0), 0.6)
	tween.parallel().tween_property(self, "position:y", 0.35, 0.6)

func _pick_new_direction(count_as_reorientation: bool = true) -> void:
	var angle := randf_range(0.0, TAU)
	_direction = Vector3(cos(angle), 0.0, sin(angle))
	_timer = randf_range(1.5, 4.0) * _wander_interval_factor()
	if count_as_reorientation:
		wander_reorientations_total += 1
		GameLogger.log_event_data("decision", "%s : réorientation d'errance #%d" % [display_name, wander_reorientations_total], {
			"agent": display_name,
			"decision": "wander_reorientation",
			"reorientation_count": wander_reorientations_total,
			"exploration_tendency": exploration_tendency,
		})

func _bounce_back() -> void:
	_direction = -_direction
	_timer = randf_range(1.5, 4.0) * _wander_interval_factor()

func _wander_interval_factor() -> float:
	# À 0.5, le facteur vaut exactement 1.0 : le baseline reste inchangé.
	return lerpf(1.5, 0.5, exploration_tendency)

func _clamp_to_map() -> void:
	position.x = clamp(position.x, -map_half_x, map_half_x)
	position.z = clamp(position.z, -map_half_z, map_half_z)

func _track_distance_travelled() -> void:
	var displacement := position - _last_position
	displacement.y = 0.0
	distance_travelled_total += displacement.length()
	_last_position = position

func _record_position_sample() -> void:
	var zone_id := _zone_id_for_position(position)
	GameLogger.log_event_data("position", "%s : position échantillonnée" % display_name, {
		"agent": display_name,
		"position": [position.x, position.y, position.z],
		"zone_id": zone_id,
		"hunger": hunger,
		"goal": current_goal,
	})
	if zone_id == _current_zone_id:
		return
	_current_zone_id = zone_id
	if _visited_zone_ids.has(zone_id):
		zone_revisits_total += 1
		GameLogger.log_event_data("zone", "%s : revisite de %s" % [display_name, zone_id], {
			"agent": display_name,
			"zone_id": zone_id,
			"event": "revisit",
			"zone_revisits_total": zone_revisits_total,
		})
		return
	_visited_zone_ids[zone_id] = true
	visited_zones_total += 1
	zone_discoveries_total += 1
	GameLogger.log_event_data("zone", "%s : découverte de %s" % [display_name, zone_id], {
		"agent": display_name,
		"zone_id": zone_id,
		"event": "discovery",
		"visited_zones_total": visited_zones_total,
	})

func _zone_id_for_position(world_position: Vector3) -> String:
	var x_index := floori(world_position.x / VISITED_ZONE_SIZE)
	var z_index := floori(world_position.z / VISITED_ZONE_SIZE)
	return "%d:%d" % [x_index, z_index]

func _update_social_perception(scaled_delta: float) -> void:
	if social_radius <= 0.0:
		current_social_neighbors = 0
		return
	var nearby_ids: Dictionary = {}
	for other in get_tree().get_nodes_in_group("agents"):
		if other == self or not is_instance_valid(other) or other.is_dead:
			continue
		var distance := position.distance_to(other.position)
		if distance > social_radius:
			continue
		var other_id := other.get_instance_id()
		nearby_ids[other_id] = true
		if not _active_social_contacts.has(other_id):
			social_encounters_total += 1
			GameLogger.log_event_data("social", "%s rencontre %s" % [display_name, other.display_name], {
				"agent": display_name,
				"other_agent": other.display_name,
				"event": "encounter_start",
				"distance": distance,
				"social_encounters_total": social_encounters_total,
			})
			_choose_social_response(other)
	for other_id in _active_social_contacts:
		if not nearby_ids.has(other_id):
			GameLogger.log_event_data("social", "%s quitte une rencontre" % display_name, {
				"agent": display_name,
				"event": "encounter_end",
			})
			if _social_target != null and _social_target.get_instance_id() == other_id:
				_social_target = null
				_social_goal = ""
	_active_social_contacts = nearby_ids
	current_social_neighbors = nearby_ids.size()
	if current_social_neighbors > 0:
		social_contact_seconds += scaled_delta

func _choose_social_response(other) -> void:
	if _social_target != null or follow_probability <= 0.0 and avoid_probability <= 0.0:
		return
	var roll := randf()
	if roll < follow_probability:
		_social_target = other
		_social_goal = "suivi_social"
		social_follow_decisions_total += 1
	elif roll < follow_probability + avoid_probability:
		_social_target = other
		_social_goal = "evitement_social"
		social_avoid_decisions_total += 1
	else:
		return
	GameLogger.log_event_data("social", "%s adopte %s vers %s" % [display_name, _social_goal, other.display_name], {
		"agent": display_name,
		"other_agent": other.display_name,
		"event": _social_goal,
		"social_follow_decisions_total": social_follow_decisions_total,
		"social_avoid_decisions_total": social_avoid_decisions_total,
	})

func _social_goal_if_active() -> String:
	if _social_target == null or not is_instance_valid(_social_target):
		_social_target = null
		_social_goal = ""
		return ""
	if position.distance_to(_social_target.position) > social_radius:
		return ""
	return _social_goal

func _social_direction() -> Vector3:
	if _social_goal_if_active() == "":
		return _direction
	var direction: Vector3 = _social_target.position - position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return _direction
	return direction.normalized() if _social_goal == "suivi_social" else -direction.normalized()

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
		GameLogger.log_event_data("objectif", "%s : cueillette" % display_name, {"agent": display_name, "goal": "cueillette"})
		GameLogger.log_event_data("cueillette", "%s ramasse une mûre (faim: %.0f, portées: %d/%d)" % [display_name, hunger, berries_carried, GameConfig.max_berries_carried], {
			"agent": display_name,
			"hunger": hunger,
			"berries_carried": berries_carried,
			"berries_picked_total": berries_picked_total,
		})
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
	GameLogger.log_event_data("objectif", "%s : consommation" % display_name, {"agent": display_name, "goal": "consommation"})
	var pv_gained := GameConfig.pv_per_berry(feeding_capacity)
	hunger = min(100.0, hunger + pv_gained)
	GameLogger.log_event_data("repas", "%s mange une mûre (+%.1f PV, faim -> %.0f, restantes: %d)" % [display_name, pv_gained, hunger, berries_carried], {
		"agent": display_name,
		"hunger": hunger,
		"pv_gained": pv_gained,
		"berries_carried": berries_carried,
		"berries_eaten_total": berries_eaten_total,
	})
