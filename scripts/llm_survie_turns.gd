class_name LLMSurieTurns
extends RefCounted

## Cadence des tours de décision de llm_survie (contrat experiments/llm_survie_contrat_v1.md,
## sections 5 à 7) : une seule requête en vol par agent, déclenchement sur événement ou à
## l'intervalle maximal, réponse appliquée au tick suivant sa réception, aucune pause de la
## simulation, télémétrie d'attente. Le backend est un objet exposant request(view, turn_id),
## advance(delta) et poll() ; poll() rend un dictionnaire vide tant que la réponse n'est pas prête.

var turns_total: int = 0
var replis_total: int = 0
var wait_total_seconds: float = 0.0
var hunger_lost_total: float = 0.0
var latency_total_ms: float = 0.0
var action_distribution: Dictionary = {}
var in_flight: bool = false
var backend = null
var chat_log: Array = []
var chat_version: int = 0

const CHAT_LOG_MAX := 40

var _agent = null
var _engine: LLMSurieEngine = null
var _memory: RonceMemory = null
var _interval_seconds: float = 10.0
var _sim_time: float = 0.0
var _interval_timer: float = 0.0
var _pending: Dictionary = {}
var _started: bool = false
var _backoff_until: float = -1.0
var _skip_start: bool = false
var _turn_id: int = 0
var _request_time: float = 0.0
var _request_triggers: Array = []
var _wait_hunger_lost: float = 0.0
var _previous_hunger: float = 0.0
var _known_count: int = 0

func setup(agent, engine: LLMSurieEngine, memory: RonceMemory, response_backend, interval_seconds: float) -> void:
	_agent = agent
	_engine = engine
	_memory = memory
	backend = response_backend
	_interval_seconds = interval_seconds

func step(delta: float) -> void:
	_sim_time += delta
	_interval_timer += delta
	_collect_triggers()
	_skip_start = false
	if in_flight:
		backend.advance(delta)
		var response: Dictionary = backend.poll()
		if not response.is_empty():
			_finish_turn(response)
	if not in_flight and not _skip_start and not _pending.is_empty() and _sim_time >= _backoff_until:
		_start_turn()

func pending_triggers() -> Array:
	return _pending.keys()

func summary() -> Dictionary:
	var result := {
		"llm_survie_tours": turns_total,
		"llm_survie_refus": _engine.refusals_total,
		"llm_survie_replis": replis_total,
		"llm_survie_latence_moyenne_ms": latency_total_ms / float(turns_total) if turns_total > 0 else 0.0,
		"llm_survie_attente_sim_totale_s": wait_total_seconds,
		"llm_survie_faim_perdue_attente": hunger_lost_total,
		"llm_survie_distribution_actions": action_distribution.duplicate(),
	}
	if _engine.map_memory != null:
		result["llm_survie_cases_visitees"] = _engine.map_memory.visited_count()
		result["llm_survie_bords_decouverts"] = _engine.map_memory.known_edges().keys()
	return result

func _collect_triggers() -> void:
	var hunger: float = _agent.hunger
	if not _started:
		_started = true
		_pending["demarrage"] = true
		_previous_hunger = hunger
		_known_count = _memory.count()
	for event in _engine.take_events():
		var key := String(event["type"])
		if event.has("id") and String(event["id"]) != "":
			key += ":" + String(event["id"])
		elif event.has("code"):
			key += ":" + String(event["code"])
		_pending[key] = true
	if _memory.count() > _known_count:
		_pending["nouveau_roncier"] = true
	_known_count = _memory.count()
	var threshold: float = GameConfig.eat_hunger_threshold
	if _previous_hunger > threshold and hunger <= threshold:
		_pending["seuil_repas"] = true
	if in_flight:
		_wait_hunger_lost += maxf(0.0, _previous_hunger - hunger)
	_previous_hunger = hunger
	if _interval_timer >= _interval_seconds:
		_pending["intervalle_max"] = true

func _start_turn() -> void:
	_turn_id += 1
	_engine.turn_id = _turn_id
	_request_triggers = _pending.keys()
	_pending.clear()
	_interval_timer = 0.0
	in_flight = true
	_request_time = _sim_time
	_wait_hunger_lost = 0.0
	var view := _engine.view()
	view["declencheurs"] = _request_triggers.duplicate()
	view["tour_id"] = _turn_id
	backend.request(view, _turn_id)
	GameLogger.log_event_data("llm_survie_attente_debut", "%s : requête LLM #%d envoyée" % [_agent.display_name, _turn_id], {
		"agent": _agent.display_name,
		"tour_id": _turn_id,
		"t_sim": _sim_time,
		"faim": _agent.hunger,
		"action_en_cours": _engine.current_action,
	})

func _record_chat(response: Dictionary, wait: float) -> void:
	var ok := bool(response.get("ok", false))
	var answer := String(response.get("raw_response", ""))
	if not ok:
		answer = "(échec : %s) %s" % [String(response.get("reason", "inconnue")), answer if answer != "" else String(response.get("detail", ""))]
	chat_log.append({
		"turn": _turn_id,
		"triggers": _request_triggers.duplicate(),
		"prompt": String(response.get("prompt", "")),
		"response": answer,
		"ok": ok,
		"latency_ms": float(response.get("latency_ms", 0.0)),
		"wait_sim_s": wait,
	})
	if chat_log.size() > CHAT_LOG_MAX:
		chat_log.pop_front()
	chat_version += 1

func _finish_turn(response: Dictionary) -> void:
	in_flight = false
	_skip_start = true
	var wait := _sim_time - _request_time
	turns_total += 1
	wait_total_seconds += wait
	hunger_lost_total += _wait_hunger_lost
	latency_total_ms += float(response.get("latency_ms", 0.0))
	_record_chat(response, wait)
	GameLogger.log_event_data("llm_survie_attente_fin", "%s : réponse LLM #%d reçue après %.2f s simulées" % [_agent.display_name, _turn_id, wait], {
		"agent": _agent.display_name,
		"tour_id": _turn_id,
		"t_sim": _sim_time,
		"faim": _agent.hunger,
		"attente_sim_s": wait,
		"faim_perdue_attente": _wait_hunger_lost,
	})
	if not bool(response.get("ok", false)):
		replis_total += 1
		_backoff_until = _sim_time + _interval_seconds
		GameLogger.log_event_data("llm_survie_repli", "%s : repli (%s)" % [_agent.display_name, String(response.get("reason", "inconnue"))], {
			"agent": _agent.display_name,
			"tour_id": _turn_id,
			"raison": String(response.get("reason", "inconnue")),
			"detail": String(response.get("detail", "")),
			"action_repli": "poursuite" if _engine.current_action != "" else "attendre",
		})
		return
	var action: Dictionary = response["action"]
	var action_name := String(action.get("action", ""))
	action_distribution[action_name] = int(action_distribution.get(action_name, 0)) + 1
	GameLogger.log_event_data("llm_survie_tour", "%s : décision LLM #%d (%s)" % [_agent.display_name, _turn_id, action_name], {
		"agent": _agent.display_name,
		"tour_id": _turn_id,
		"declencheurs": _request_triggers,
		"prompt": String(response.get("prompt", "")),
		"raw_response": String(response.get("raw_response", "")),
		"action": action_name,
		"roncier_id": String(action.get("roncier_id", "aucun")),
		"direction": String(action.get("direction", "aucune")),
		"latence_ms": float(response.get("latency_ms", 0.0)),
		"attente_sim_s": wait,
		"faim_perdue_attente": _wait_hunger_lost,
	})
	_engine.submit(action)
