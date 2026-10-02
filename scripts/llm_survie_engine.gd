class_name LLMSurieEngine
extends RefCounted

## Moteur d'actions du décideur llm_survie (contrat experiments/llm_survie_contrat_v1.md) :
## valide chaque action proposée sur l'état courant de l'agent, l'applique, calcule la direction
## de marche et détecte arrivée, cible vide et blocage. Les événements détectés sont empilés dans
## `events` pour le déclenchement des tours de décision.

const BLOCK_DISTANCE := 0.5
const BLOCK_SECONDS := 3.0
const ABSENT_DISTANCE := 1.0
const EDGE_MARGIN := 12.0
const BLOCKED_MEMORY_RADIUS := 6.0

var current_action: String = ""
var target_id: String = ""
var direction := Vector3.ZERO
var turn_id: int = 0
var refusals_total: int = 0
var refusals_by_code: Dictionary = {}
var accepted_by_action: Dictionary = {}
var last_result: Dictionary = {}
var last_issue: String = ""
var events: Array = []
var map_memory: SurvieMapMemory = null

var _agent = null
var _memory: RonceMemory = null
var _anchor := Vector3.ZERO
var _stalled_seconds: float = 0.0
var _current_compass: String = ""
var _blocked_spots: Array = []

func setup(agent, memory: RonceMemory) -> void:
	_agent = agent
	_memory = memory

func take_events() -> Array:
	var taken := events
	events = []
	return taken

func submit(action: Dictionary) -> Dictionary:
	var action_name := String(action.get("action", ""))
	var code := _refusal_code(action_name, action)
	var result := {"action": action_name, "accepted": code == "", "code": code}
	if code != "":
		refusals_total += 1
		refusals_by_code[code] = int(refusals_by_code.get(code, 0)) + 1
		events.append({"type": "refus", "code": code})
		GameLogger.log_event_data("llm_survie_refus", "%s : action %s refusée (%s)" % [_agent.display_name, action_name, code], {
			"agent": _agent.display_name,
			"tour_id": turn_id,
			"action": action_name,
			"code": code,
			"etat": {"faim": _agent.hunger, "portees": _agent.berries_carried, "cible": String(action.get("roncier_id", "aucun"))},
		})
	else:
		accepted_by_action[action_name] = int(accepted_by_action.get(action_name, 0)) + 1
		_apply(action_name, action)
	last_result = result
	return result

func tick(delta: float) -> Vector3:
	_record_map()
	match current_action:
		"aller_vers":
			return _tick_go_to(delta)
		"explorer":
			if _is_blocked(delta):
				_finish("blocage", "blocage")
				return Vector3.ZERO
			return direction
	return Vector3.ZERO

func view() -> Dictionary:
	_record_map()
	var known: Array = []
	for id in _memory.known_ids():
		var offset: Vector3 = _memory.position_of(id) - _agent.position
		offset.y = 0.0
		known.append({
			"id": id,
			"distance": offset.length(),
			"direction": offset.normalized() if offset.length_squared() > 0.0001 else Vector3.ZERO,
			"estimated_berries": _memory.estimated_berries(id),
			"last_observed_seconds": _memory.last_observed_seconds(id),
		})
	var contact = _agent.contact_ronce()
	var result := {
		"hunger": _agent.hunger,
		"berries_carried": _agent.berries_carried,
		"max_berries_carried": GameConfig.max_berries_carried,
		"eat_hunger_threshold": GameConfig.eat_hunger_threshold,
		"contact_ronce_id": contact.ronce_id if contact != null else "",
		"known": known,
		"current_action": current_action,
		"target_id": target_id,
		"last_result": last_result,
		"last_issue": last_issue,
		"blocked_directions": blocked_directions(),
		"blocked_targets": blocked_targets(),
		"edges": _near_edges(),
	}
	if map_memory != null:
		result["map"] = map_memory.view(_agent.position)
	return result

func _record_map() -> void:
	if map_memory == null:
		return
	for side in map_memory.record_position(_agent.position, _agent.map_half_x, _agent.map_half_z):
		GameLogger.log_event_data("llm_survie_carte", "%s : bord %s découvert" % [_agent.display_name, side], {
			"agent": _agent.display_name,
			"tour_id": turn_id,
			"bord": side,
			"position": [_agent.position.x, _agent.position.z],
			"cases_visitees": map_memory.visited_count(),
		})

func blocked_directions() -> Array:
	var blocked: Array = []
	for spot in _blocked_spots:
		if String(spot["direction"]) != "" and _is_near(spot["position"]) and not blocked.has(spot["direction"]):
			blocked.append(spot["direction"])
	return LLMDecider.COMPASS_DIRECTIONS.filter(func(name): return blocked.has(name))

func blocked_targets() -> Array:
	var blocked: Array = []
	for spot in _blocked_spots:
		if String(spot["target"]) != "" and _is_near(spot["position"]) and not blocked.has(spot["target"]):
			blocked.append(spot["target"])
	blocked.sort()
	return blocked

func _is_near(spot_position: Vector3) -> bool:
	var offset: Vector3 = _agent.position - spot_position
	offset.y = 0.0
	return offset.length() <= BLOCKED_MEMORY_RADIUS

func _near_edges() -> Array:
	var edges: Array = []
	var position: Vector3 = _agent.position
	if position.z <= -_agent.map_half_z + EDGE_MARGIN:
		edges.append("N")
	if position.z >= _agent.map_half_z - EDGE_MARGIN:
		edges.append("S")
	if position.x >= _agent.map_half_x - EDGE_MARGIN:
		edges.append("E")
	if position.x <= -_agent.map_half_x + EDGE_MARGIN:
		edges.append("O")
	return edges

func _refusal_code(action_name: String, action: Dictionary) -> String:
	match action_name:
		"aller_vers":
			var id := String(action.get("roncier_id", "aucun"))
			if not _memory.is_known(id):
				return "cible_inconnue"
			if _memory.estimated_berries(id) <= 0:
				return "cible_epuisee"
		"explorer":
			if not LLMDecider.COMPASS_VECTORS.has(String(action.get("direction", "aucune"))):
				return "direction_invalide"
		"ramasser":
			var contact = _agent.contact_ronce()
			if contact == null:
				return "hors_contact"
			if _agent.berries_carried >= GameConfig.max_berries_carried:
				return "inventaire_plein"
			if int(contact.get_perception_state().get("berries", 0)) <= 0:
				return "roncier_vide"
		"manger":
			if _agent.berries_carried <= 0:
				return "aucune_mure"
			if _agent.hunger > GameConfig.eat_hunger_threshold:
				return "trop_rassasie"
		"attendre":
			return ""
		_:
			return "action_inconnue"
	return ""

func _apply(action_name: String, action: Dictionary) -> void:
	match action_name:
		"aller_vers":
			current_action = action_name
			target_id = String(action["roncier_id"])
			direction = Vector3.ZERO
			_reset_stall()
		"explorer":
			current_action = action_name
			target_id = ""
			_current_compass = String(action["direction"])
			direction = LLMDecider.COMPASS_VECTORS[String(action["direction"])].normalized()
			_reset_stall()
		"attendre":
			current_action = action_name
			target_id = ""
			direction = Vector3.ZERO
			_reset_stall()
		"ramasser":
			_agent.survie_harvest(_agent.contact_ronce())
			_log_action(action_name, "ramasse")
			events.append({"type": "action_terminee", "action": action_name})
		"manger":
			_agent.survie_eat()
			_log_action(action_name, "mange")
			events.append({"type": "action_terminee", "action": action_name})

func _tick_go_to(delta: float) -> Vector3:
	var contact = _agent.contact_ronce()
	if contact != null and contact.ronce_id == target_id:
		_finish("arrivee", "cible_atteinte")
		return Vector3.ZERO
	if _memory.estimated_berries(target_id) <= 0:
		_finish("interrompue", "cible_invalide")
		return Vector3.ZERO
	var to_target: Vector3 = _memory.position_of(target_id) - _agent.position
	to_target.y = 0.0
	if to_target.length() <= ABSENT_DISTANCE:
		_memory.observe(target_id, _memory.position_of(target_id), 0, _agent._now_elapsed_seconds())
		_finish("interrompue", "cible_invalide")
		return Vector3.ZERO
	if _is_blocked(delta):
		_finish("blocage", "blocage")
		return Vector3.ZERO
	direction = to_target.normalized()
	return direction

func _is_blocked(delta: float) -> bool:
	var moved: Vector3 = _agent.position - _anchor
	moved.y = 0.0
	if moved.length() >= BLOCK_DISTANCE:
		_reset_stall()
		return false
	_stalled_seconds += delta
	return _stalled_seconds >= BLOCK_SECONDS

func _reset_stall() -> void:
	_anchor = _agent.position
	_stalled_seconds = 0.0

func _finish(issue: String, event_type: String) -> void:
	last_issue = issue
	if issue == "blocage":
		_blocked_spots.append({"position": _agent.position, "direction": _current_compass if current_action == "explorer" else "", "target": target_id})
	_log_action(current_action, issue)
	events.append({"type": event_type, "id": target_id})
	current_action = ""
	target_id = ""
	direction = Vector3.ZERO

func _log_action(action_name: String, issue: String) -> void:
	GameLogger.log_event_data("llm_survie_action", "%s : %s (%s)" % [_agent.display_name, action_name, issue], {
		"agent": _agent.display_name,
		"tour_id": turn_id,
		"action": action_name,
		"issue": issue,
	})
