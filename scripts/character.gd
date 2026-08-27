extends CharacterBody3D

@export var map_half_x: float = 18.0
@export var map_half_z: float = 18.0
@export var move_speed: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["move_speed"])
@export var gravity: float = 9.8
@export var hunger: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["hunger"])
@export var hunger_depletion_rate: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["hunger_depletion_rate"])
@export var aging_factor: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["aging_factor"])
@export var feeding_capacity: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["feeding_capacity"])
@export var memory_capacity: int = VariableRegistry.default_value(VariableRegistry.CHARACTER["memory_capacity"])
@export var memory_decay_rate: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["memory_decay_rate"])
# 0.5 est neutre : une valeur élevée raccourcit les phases d'errance et augmente
# la fréquence des changements de direction.
@export_range(0.0, 1.0, 0.01) var exploration_tendency: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["exploration_tendency"])
@export_range(0.0, 1.0, 0.01) var goal_persistence: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["goal_persistence"])
@export_range(0.0, 1.0, 0.01) var known_zone_preference: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["known_zone_preference"])
@export_range(0.0, 1.0, 0.01) var curiosity: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["curiosity"])
@export var vision_range: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["vision_range"])
@export_range(0.0, 360.0, 0.1) var vision_angle_degrees: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["vision_angle_degrees"])
@export var vision_blocked_by_terrain: bool = VariableRegistry.default_value(VariableRegistry.CHARACTER["vision_blocked_by_terrain"])
@export var social_radius: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["social_radius"])
@export_range(0.0, 1.0, 0.01) var follow_probability: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["follow_probability"])
@export_range(0.0, 1.0, 0.01) var avoid_probability: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["avoid_probability"])
@export_range(0.0, 1.0, 0.01) var communication_probability: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["communication_probability"])
@export_range(0.0, 1.0, 0.01) var cooperation_probability: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["cooperation_probability"])
@export_range(0.0, 1.0, 0.01) var aggression_probability: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["aggression_probability"])
@export var decider_type: String = VariableRegistry.default_value(VariableRegistry.CHARACTER["decider_type"])
@export var llm_model: String = VariableRegistry.default_value(VariableRegistry.CHARACTER["llm_model"])
@export var llm_decision_interval_seconds: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["llm_decision_interval_seconds"])
@export var llm_timeout_seconds: float = VariableRegistry.default_value(VariableRegistry.CHARACTER["llm_timeout_seconds"])
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
var simulation_elapsed_seconds: float = -1.0
var visited_zones_total: int = 0
var zone_discoveries_total: int = 0
var zone_revisits_total: int = 0
var social_encounters_total: int = 0
var social_contact_seconds: float = 0.0
var current_social_neighbors: int = 0
var social_follow_decisions_total: int = 0
var social_avoid_decisions_total: int = 0
var social_shares_total: int = 0
var memories_received_total: int = 0
var food_shared_total: int = 0
var food_received_total: int = 0
var aggression_incidents_total: int = 0
var aggression_received_total: int = 0
var vision_detections_total: int = 0
var ronces_discovered_by_vision_total: int = 0
var vision_to_contact_delay_seconds_total: float = 0.0
var vision_to_contact_events_total: int = 0

var llm_calls_total: int:
	get: return _decider.calls_total if _decider is LLMDecider else 0
var llm_errors_total: int:
	get: return _decider.errors_total if _decider is LLMDecider else 0
var llm_total_latency_ms: float:
	get: return _decider.total_latency_ms if _decider is LLMDecider else 0.0

var _direction := Vector3.ZERO
var _manual_direction := Vector3.ZERO
var _timer := 0.0
var _memories: Array = []
var _decider = null
var _last_position := Vector3.ZERO
var _visited_zone_ids: Dictionary = {}
var _current_zone_id: String = ""
var _position_sample_clock: float = 0.0
var _active_social_contacts: Dictionary = {}
var _social_target = null
var _social_goal: String = ""
var _visible_entities: Array = []
var _active_vision_contacts: Dictionary = {}
var _first_vision_time: Dictionary = {}
var _first_contact_recorded: Dictionary = {}

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _body_base_y: float = 0.0
var _head_base_y: float = 0.0
var _walk_time: float = 0.0

var _anim_player: AnimationPlayer = null
var _current_anim: String = ""
var _rl_direction := Vector3.ZERO

func _ready() -> void:
	_decider = _build_decider()
	_pick_new_direction(false)
	_last_position = position
	_set_goal("errance")
	GameLogger.log_event_data("spawn", "%s apparaît en (%.1f, %.1f)" % [display_name, position.x, position.z], {
		"agent": display_name,
		"position": [position.x, position.y, position.z],
	})
	_record_position_sample()

func _build_decider():
	match decider_type:
		"llm", "llm_mock":
			var decider := LLMDecider.new()
			decider.configure(llm_model, llm_decision_interval_seconds, llm_timeout_seconds, decider_type == "llm_mock", display_name)
			add_child(decider)
			return decider
		_:
			return BaselineDecider.new()

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
	_update_vision_perception()

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
	var visible_ronce_direction := _direction_to_nearest_visible_ronce()
	var action: Dictionary = _decider.decide({
		"manual_control": manual_control,
		"manual_direction": _manual_direction,
		"hunger": hunger,
		"pickup_hunger_threshold": GameConfig.pickup_hunger_threshold,
		"has_memories": not _memories.is_empty(),
		"memory_direction": _direction_to_nearest_memory(),
		"has_visible_ronce": visible_ronce_direction != Vector3.ZERO,
		"visible_ronce_direction": visible_ronce_direction,
		"social_goal": _social_goal_if_active(),
		"social_direction": _social_direction(),
		"current_direction": _direction,
		"wander_timer": _timer,
		"delta": scaled_delta,
	})
	if not (action.has("goal") and action.has("direction") and action.has("renew_wander")
			and action["goal"] is String and action["direction"] is Vector3 and action["renew_wander"] is bool):
		GameLogger.log_event_data("decideur_erreur", "%s : action invalide ignorée" % display_name, {
			"agent": display_name,
			"decider_type": decider_type,
		})
		action = {"goal": current_goal, "direction": _direction, "renew_wander": false}
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

func _now_elapsed_seconds() -> float:
	return simulation_elapsed_seconds if simulation_elapsed_seconds >= 0.0 else GameLogger.get_elapsed_seconds()

func _die() -> void:
	is_dead = true
	death_elapsed_seconds = _now_elapsed_seconds()
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
	if curiosity > 0.0 and not _visited_zone_ids.is_empty():
		var curious_direction := _direction_to_unknown_zone_candidate(_direction)
		if curious_direction.length_squared() > 0.01:
			_direction = _direction.lerp(curious_direction, curiosity).normalized()
	if known_zone_preference > 0.0:
		var known_direction := _direction_to_nearest_known_zone()
		if known_direction.length_squared() > 0.01:
			_direction = _direction.lerp(known_direction, known_zone_preference).normalized()
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
	return lerpf(1.5, 0.5, exploration_tendency) * lerpf(0.7, 1.3, goal_persistence)

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

func _direction_to_nearest_known_zone() -> Vector3:
	var nearest_distance := INF
	var nearest_center := Vector3.ZERO
	for zone_id_variant in _visited_zone_ids:
		var parts := String(zone_id_variant).split(":")
		if parts.size() != 2:
			continue
		var center := Vector3((float(parts[0]) + 0.5) * VISITED_ZONE_SIZE, position.y, (float(parts[1]) + 0.5) * VISITED_ZONE_SIZE)
		var distance := position.distance_squared_to(center)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_center = center
	var direction := nearest_center - position
	direction.y = 0.0
	return direction.normalized() if nearest_distance < INF and direction.length_squared() > 0.01 else Vector3.ZERO

func _direction_to_unknown_zone_candidate(base_direction: Vector3) -> Vector3:
	# Trois directions déterministes évitent de consommer un aléa supplémentaire : ce trait
	# ne modifie donc pas la séquence aléatoire des autres agents.
	var candidates: Array[Vector3] = [base_direction, Vector3(-base_direction.z, 0.0, base_direction.x), Vector3(base_direction.z, 0.0, -base_direction.x)]
	for candidate: Vector3 in candidates:
		var projected_position := position + candidate.normalized() * VISITED_ZONE_SIZE * 1.5
		if not _visited_zone_ids.has(_zone_id_for_position(projected_position)):
			return candidate.normalized()
	return Vector3.ZERO

func _vision_forward() -> Vector3:
	var forward := -basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()

func _is_occluded(space_state: PhysicsDirectSpaceState3D, entity) -> bool:
	var eye_offset := Vector3(0.0, 1.0, 0.0)
	var exclude: Array = [get_rid()]
	if entity.has_method("get_occlusion_exclude_rids"):
		exclude.append_array(entity.get_occlusion_exclude_rids())
	var query := PhysicsRayQueryParameters3D.create(position + eye_offset, entity.position + eye_offset, 0xFFFFFFFF, exclude)
	return not space_state.intersect_ray(query).is_empty()

func _perceive(range_value: float, angle_degrees: float, blocked_by_terrain: bool, group_name: String, flatten_vertical: bool = true) -> Array:
	var result: Array = []
	if range_value <= 0.0:
		return result
	var forward := _vision_forward()
	var half_angle_rad := deg_to_rad(angle_degrees) * 0.5
	var omnidirectional := angle_degrees >= 360.0
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state if blocked_by_terrain else null
	for entity in get_tree().get_nodes_in_group(group_name):
		if entity == self or not is_instance_valid(entity):
			continue
		var to_entity: Vector3 = entity.position - position
		if flatten_vertical:
			to_entity.y = 0.0
		var distance := to_entity.length()
		if distance > range_value or distance < 0.01:
			continue
		var direction := to_entity / distance
		if not omnidirectional and forward.angle_to(direction) > half_angle_rad:
			continue
		if blocked_by_terrain and _is_occluded(space_state, entity):
			continue
		result.append({
			"node": entity,
			"type": entity.get_perception_type() if entity.has_method("get_perception_type") else "inconnu",
			"distance": distance,
			"direction": direction,
			"state": entity.get_perception_state() if entity.has_method("get_perception_state") else {},
		})
	return result

func _update_vision_perception() -> void:
	_visible_entities = _perceive(vision_range, vision_angle_degrees, vision_blocked_by_terrain, "perceptible")
	if _visible_entities.is_empty():
		_active_vision_contacts.clear()
		return
	var seen_ids: Dictionary = {}
	for entry in _visible_entities:
		var entity = entry["node"]
		var entity_id: int = entity.get_instance_id()
		seen_ids[entity_id] = true
		if not _active_vision_contacts.has(entity_id):
			vision_detections_total += 1
			GameLogger.log_event_data("vision", "%s détecte un %s à distance" % [display_name, entry["type"]], {
				"agent": display_name,
				"entity_type": entry["type"],
				"distance": entry["distance"],
				"vision_detections_total": vision_detections_total,
			})
			# Une fois par nouvelle apparition, pas par frame : sinon l'éviction en cas de dépassement de memory_capacity boucle indéfiniment.
			if entry["type"] == "roncier":
				if not _first_vision_time.has(entity_id):
					_first_vision_time[entity_id] = _now_elapsed_seconds()
				if _remember_ronce(entity):
					ronces_discovered_by_vision_total += 1
	_active_vision_contacts = seen_ids

func _direction_to_nearest_visible_ronce() -> Vector3:
	var nearest_distance := INF
	var nearest_direction := Vector3.ZERO
	for entry in _visible_entities:
		if entry["type"] != "roncier" or not bool(entry["state"].get("has_berries", false)):
			continue
		if entry["distance"] < nearest_distance:
			nearest_distance = entry["distance"]
			nearest_direction = entry["direction"]
	return nearest_direction

func _update_social_perception(scaled_delta: float) -> void:
	if social_radius <= 0.0:
		current_social_neighbors = 0
		return
	var nearby_ids: Dictionary = {}
	for entry in _perceive(social_radius, 360.0, false, "agents", false):
		var other = entry["node"]
		if other.is_dead:
			continue
		var distance: float = entry["distance"]
		var other_id: int = other.get_instance_id()
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
			_attempt_communication(other)
			_attempt_cooperation(other)
			_attempt_aggression(other)
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

func _attempt_communication(other) -> void:
	if communication_probability <= 0.0 or _memories.is_empty():
		return
	if randf() >= communication_probability:
		return
	var shareable = null
	for m in _memories:
		if not is_instance_valid(m.ronce):
			continue
		var already_known := false
		for om in other._memories:
			if om.ronce == m.ronce:
				already_known = true
				break
		if not already_known:
			shareable = m.ronce
			break
	if shareable == null:
		return
	other._remember_ronce(shareable)
	social_shares_total += 1
	other.memories_received_total += 1
	GameLogger.log_event_data("communication", "%s partage un roncier connu avec %s" % [display_name, other.display_name], {
		"agent": display_name,
		"other_agent": other.display_name,
		"event": "partage_position",
		"social_shares_total": social_shares_total,
	})

func _attempt_cooperation(other) -> void:
	if cooperation_probability <= 0.0 or berries_carried <= 0:
		return
	if other.hunger > GameConfig.eat_hunger_threshold:
		return
	if other.berries_carried >= GameConfig.max_berries_carried:
		return
	if randf() >= cooperation_probability:
		return
	berries_carried -= 1
	other.berries_carried += 1
	food_shared_total += 1
	other.food_received_total += 1
	GameLogger.log_event_data("cooperation", "%s partage une mûre avec %s" % [display_name, other.display_name], {
		"agent": display_name,
		"other_agent": other.display_name,
		"event": "partage_nourriture",
		"food_shared_total": food_shared_total,
	})

func _attempt_aggression(other) -> void:
	if aggression_probability <= 0.0:
		return
	if randf() >= aggression_probability:
		return
	other._social_target = self
	other._social_goal = "evitement_social"
	aggression_incidents_total += 1
	other.aggression_received_total += 1
	GameLogger.log_event_data("agression", "%s repousse %s" % [display_name, other.display_name], {
		"agent": display_name,
		"other_agent": other.display_name,
		"event": "repulsion_imposee",
		"aggression_incidents_total": aggression_incidents_total,
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
	_record_first_contact(ronce)
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

func _record_first_contact(ronce) -> void:
	var ronce_id: int = ronce.get_instance_id()
	if _first_contact_recorded.has(ronce_id) or not _first_vision_time.has(ronce_id):
		return
	_first_contact_recorded[ronce_id] = true
	var delay: float = _now_elapsed_seconds() - float(_first_vision_time[ronce_id])
	if delay < 0.0:
		return
	vision_to_contact_delay_seconds_total += delay
	vision_to_contact_events_total += 1

func _remember_ronce(ronce) -> bool:
	for m in _memories:
		if m.ronce == ronce:
			m.strength = MEMORY_MAX_STRENGTH
			return false
	if memory_capacity <= 0:
		return false
	if _memories.size() >= memory_capacity:
		var weakest_idx := 0
		for i in range(1, _memories.size()):
			if _memories[i].strength < _memories[weakest_idx].strength:
				weakest_idx = i
		GameLogger.log_event("memoire", "%s oublie un roncier pour en retenir un nouveau (mémoire pleine: %d/%d)" % [display_name, _memories.size(), memory_capacity])
		_memories.remove_at(weakest_idx)
	_memories.append({"ronce": ronce, "strength": MEMORY_MAX_STRENGTH})
	GameLogger.log_event("memoire", "%s mémorise un nouveau roncier en (%.1f, %.1f) (%d/%d)" % [display_name, ronce.position.x, ronce.position.z, _memories.size(), memory_capacity])
	return true

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
