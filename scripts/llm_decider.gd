class_name LLMDecider
extends Node

## Décideur asynchrone : interroge un LLM local (Ollama) ou simule une réponse déterministe
## (mode mock, sans appel réseau). decide() ne bloque jamais : il retourne immédiatement la
## dernière action connue et déclenche une requête en arrière-plan quand le cooldown expire.

const OLLAMA_URL := "http://127.0.0.1:11434/api/generate"
const COMPASS_DIRECTIONS := ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
const COMPASS_VECTORS := {
	"N": Vector3(0, 0, -1),
	"S": Vector3(0, 0, 1),
	"E": Vector3(1, 0, 0),
	"O": Vector3(-1, 0, 0),
	"NE": Vector3(1, 0, -1),
	"NO": Vector3(-1, 0, -1),
	"SE": Vector3(1, 0, 1),
	"SO": Vector3(-1, 0, 1),
}
const INTENTIONS := ["manger", "explorer", "suivre", "eviter", "attendre"]

var calls_total: int = 0
var errors_total: int = 0
var total_latency_ms: float = 0.0

var _model := "gemma3:4b"
var _decision_interval := 3.0
var _timeout_seconds := 8.0
var _mock := false
var _agent_name := ""

var _cooldown := 0.0
var _in_flight := false
var _request_started_ms: int = 0
var _cached_action: Dictionary = {"goal": "errance", "direction": Vector3.ZERO, "renew_wander": true}
var _last_observation: Dictionary = {}
var _last_prompt := ""
var _last_raw_response := ""
var _fallback := BaselineDecider.new()
var _http: HTTPRequest = null

func configure(model: String, decision_interval: float, timeout_seconds: float, mock: bool, agent_name: String) -> void:
	_model = model
	_decision_interval = decision_interval
	_timeout_seconds = timeout_seconds
	_mock = mock
	_agent_name = agent_name

func _ready() -> void:
	if _mock:
		return
	_http = HTTPRequest.new()
	add_child(_http)
	_http.use_threads = false
	_http.timeout = _timeout_seconds
	_http.request_completed.connect(_on_request_completed)

func decide(observation: Dictionary) -> Dictionary:
	_last_observation = observation
	_cooldown -= float(observation.get("delta", 0.0))
	if not _in_flight and _cooldown <= 0.0:
		_cooldown = _decision_interval
		_start_request(observation)
	return _cached_action

func _start_request(observation: Dictionary) -> void:
	_in_flight = true
	_request_started_ms = Time.get_ticks_msec()
	_last_raw_response = ""
	if _mock:
		_last_prompt = "(mode mock, aucun appel réseau)"
		_last_raw_response = "(mode mock, aucun appel réseau)"
		_resolve_mock(observation)
		return
	var prompt := _build_prompt(observation)
	_last_prompt = prompt
	var response_schema := {
		"type": "object",
		"properties": {
			"intention": {"type": "string", "enum": INTENTIONS},
			"direction": {"type": "string", "enum": COMPASS_DIRECTIONS + ["aucune"]},
		},
		"required": ["intention", "direction"],
	}
	var payload := {"model": _model, "prompt": prompt, "format": response_schema, "stream": false}
	var headers := ["Content-Type: application/json"]
	var error := _http.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_fail("connexion_refusee", "request() a échoué avec le code %d" % error)

func _resolve_mock(observation: Dictionary) -> void:
	var wants_food: bool = observation.get("has_memories", false) and float(observation.get("hunger", 0.0)) > float(observation.get("pickup_hunger_threshold", 90.0))
	var intention := "manger" if wants_food else "explorer"
	var direction: String = COMPASS_DIRECTIONS[calls_total % COMPASS_DIRECTIONS.size()]
	_apply_success(intention, direction, 0.0)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var latency_ms := float(Time.get_ticks_msec() - _request_started_ms)
	_last_raw_response = body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("reseau", "result Godot = %d" % result)
		return
	if response_code != 200:
		_fail("http_%d" % response_code, _last_raw_response)
		return
	var parsed = JSON.parse_string(_last_raw_response)
	if not (parsed is Dictionary) or not parsed.has("response"):
		_fail("reponse_invalide", "champ 'response' absent")
		return
	_last_raw_response = String(parsed["response"])
	var inner = JSON.parse_string(_last_raw_response)
	if not (inner is Dictionary) or not inner.has("intention") or not inner.has("direction"):
		_fail("json_invalide", _last_raw_response)
		return
	var intention := String(inner["intention"])
	var direction := String(inner["direction"])
	if not INTENTIONS.has(intention) or not (direction == "aucune" or COMPASS_VECTORS.has(direction)):
		_fail("hors_enumeration", "intention=%s direction=%s" % [intention, direction])
		return
	_apply_success(intention, direction, latency_ms)

func _apply_success(intention: String, direction: String, latency_ms: float) -> void:
	calls_total += 1
	total_latency_ms += latency_ms
	var vector: Vector3
	if intention == "manger" and bool(_last_observation.get("has_visible_ronce", false)):
		vector = _last_observation.get("visible_ronce_direction", Vector3.ZERO)
	elif intention == "manger" and bool(_last_observation.get("has_memories", false)):
		# Même précision de visée que l'automate pour cette intention : l'espace d'action
		# comparé n'est alors plus la géométrie (que ni l'un ni l'autre décideur ne "choisit"
		# vraiment), mais le choix d'intention lui-même.
		vector = _last_observation.get("memory_direction", Vector3.ZERO)
	elif direction == "aucune":
		vector = Vector3.ZERO
	else:
		vector = COMPASS_VECTORS[direction].normalized()
	_cached_action = {"goal": "llm_%s" % intention, "direction": vector, "renew_wander": false}
	_in_flight = false
	GameLogger.log_event_data("llm_decision", "%s : décision LLM (%s)" % [_agent_name, intention], {
		"agent": _agent_name,
		"model": _model,
		"latency_ms": latency_ms,
		"intention": intention,
		"direction": direction,
		"prompt": _last_prompt,
		"raw_response": _last_raw_response,
	})

func _fail(reason: String, detail: String) -> void:
	errors_total += 1
	_cached_action = _fallback.decide(_last_observation)
	_in_flight = false
	GameLogger.log_event_data("llm_decider_erreur", "%s : repli automate (%s)" % [_agent_name, reason], {
		"agent": _agent_name,
		"model": _model,
		"reason": reason,
		"detail": detail,
		"prompt": _last_prompt,
		"raw_response": _last_raw_response,
	})

func _build_prompt(observation: Dictionary) -> String:
	return "Tu contrôles un agent dans une simulation de survie. Faim: %.0f/100 (0 = mort). A un roncier mémorisé: %s. Voit un roncier avec des mûres à proximité: %s. Réponds uniquement avec un objet JSON strict à deux clés : intention (une valeur parmi %s) et direction (une valeur parmi %s, ou 'aucune')." % [
		float(observation.get("hunger", 0.0)),
		observation.get("has_memories", false),
		observation.get("has_visible_ronce", false),
		INTENTIONS,
		COMPASS_DIRECTIONS,
	]
