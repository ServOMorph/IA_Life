class_name LLMSurieOllamaBackend
extends Node

## Backend Ollama de llm_survie : une requête HTTP asynchrone par tour, schéma JSON fermé
## (action, roncier_id, direction), options déterministes (temperature 0, seed fixée). N'applique
## rien lui-même : rend une réponse validée en forme, la légalité relève du moteur.
## Interface attendue par LLMSurieTurns : request(view, turn_id), advance(delta), poll().

const OLLAMA_URL := "http://127.0.0.1:11434/api/generate"
const ACTIONS := ["aller_vers", "explorer", "ramasser", "manger", "attendre"]
const MAX_LISTED_RONCIERS := 10
const NUM_PREDICT := 64

var requests_total: int = 0

var _model := "gemma3:1b"
var _timeout_seconds := 20.0
var _seed := 0
var _agent_name := ""
var _http: HTTPRequest = null
var _request_started_ms: int = 0
var _last_prompt := ""
var _last_known_ids: Array = []
var _response: Dictionary = {}

func configure(model: String, timeout_seconds: float, seed_value: int, agent_name: String) -> void:
	_model = model
	_timeout_seconds = timeout_seconds
	_seed = absi(seed_value) % 2147483647
	_agent_name = agent_name

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.use_threads = false
	_http.timeout = _timeout_seconds
	_http.request_completed.connect(_on_request_completed)

func prepare(view: Dictionary) -> void:
	_request_started_ms = Time.get_ticks_msec()
	_last_prompt = build_prompt(view)
	_last_known_ids = _known_ids(view).filter(func(id): return not view.get("blocked_targets", []).has(id))

func request(view: Dictionary, _turn_id: int) -> void:
	requests_total += 1
	_response = {}
	prepare(view)
	var payload := {
		"model": _model,
		"prompt": _last_prompt,
		"format": build_schema(_last_known_ids, view.get("blocked_directions", [])),
		"stream": false,
		"keep_alive": "30m",
		"options": {"temperature": 0, "seed": _seed, "num_predict": NUM_PREDICT},
	}
	var error := _http.request(OLLAMA_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_response = _failure("connexion_refusee", "request() a échoué avec le code %d" % error)

func advance(_delta: float) -> void:
	pass

func poll() -> Dictionary:
	if _response.is_empty():
		return {}
	var ready := _response
	_response = {}
	return ready

func build_schema(target_ids: Array, blocked_directions: Array = []) -> Dictionary:
	var branches: Array = []
	if not target_ids.is_empty():
		branches.append(_branch("aller_vers", target_ids, ["aucune"]))
	var free_directions: Array = LLMDecider.COMPASS_DIRECTIONS.filter(func(name): return not blocked_directions.has(name))
	branches.append(_branch("explorer", ["aucun"], free_directions if not free_directions.is_empty() else LLMDecider.COMPASS_DIRECTIONS))
	for fixed_action in ["ramasser", "manger", "attendre"]:
		branches.append(_branch(fixed_action, ["aucun"], ["aucune"]))
	return {"anyOf": branches}

func _branch(action_name: String, ids: Array, directions: Array) -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"action": {"type": "string", "enum": [action_name]},
			"roncier_id": {"type": "string", "enum": ids},
			"direction": {"type": "string", "enum": directions},
		},
		"required": ["action", "roncier_id", "direction"],
	}

func build_prompt(view: Dictionary) -> String:
	var known: Array = view.get("known", [])
	var blocked_targets: Array = view.get("blocked_targets", [])
	var with_berries: Array = known.filter(func(entry): return int(entry["estimated_berries"]) > 0 and not blocked_targets.has(entry["id"]))
	with_berries.sort_custom(func(a, b): return float(a["distance"]) < float(b["distance"]))
	var lines: Array = []
	for entry in with_berries.slice(0, MAX_LISTED_RONCIERS):
		lines.append("- %s : %d m, direction %s, environ %d mûre(s)" % [entry["id"], int(round(float(entry["distance"]))), compass_of(entry["direction"]), int(entry["estimated_berries"])])
	var listing := "
".join(lines) if not lines.is_empty() else "(aucun roncier connu avec des mûres)"
	var contact := String(view.get("contact_ronce_id", ""))
	var carried := int(view.get("berries_carried", 0))
	var contact_has_berries := false
	for entry in with_berries:
		if entry["id"] == contact:
			contact_has_berries = true
	var actions: Array = []
	if contact_has_berries and carried < int(view.get("max_berries_carried", 3)):
		actions.append("ramasser")
	if carried > 0 and float(view.get("hunger", 100.0)) <= float(view.get("eat_hunger_threshold", 50.0)):
		actions.append("manger")
	if not with_berries.is_empty():
		actions.append("aller_vers (un roncier de la liste)")
	actions.append("explorer (une direction)")
	actions.append("attendre")
	var last: Dictionary = view.get("last_result", {})
	var last_text := "aucune"
	if not last.is_empty():
		last_text = "%s -> %s" % [String(last.get("action", "")), "accepté" if bool(last.get("accepted", false)) else "refusé (%s)" % String(last.get("code", ""))]
	var issue_texts := {"arrivee": "arrivé au roncier", "blocage": "bloqué par un obstacle ou le bord de la carte", "interrompue": "cible devenue vide"}
	var last_issue := String(view.get("last_issue", ""))
	if issue_texts.has(last_issue):
		last_text += " ; dernier déplacement terminé : %s" % issue_texts[last_issue]
	var edges: Array = view.get("edges", [])
	var current := String(view.get("current_action", ""))
	if current == "aller_vers":
		current += " " + String(view.get("target_id", ""))
	var parts: Array = [
		"Tu pilotes un agent affamé dans une forêt. Objectif : ne pas mourir de faim en mangeant des mûres.",
		"Règles : les mûres se ramassent au contact d'un roncier, puis se mangent quand la faim est inférieure ou égale à %d. Sac vide : rejoins (aller_vers) le roncier avec des mûres le plus proche ; s'il n'y en a aucun de connu, explore. Au contact d'un roncier avec des mûres et sac non plein : ramasse. Sac non vide et faim basse : mange." % int(round(float(view.get("eat_hunger_threshold", 50.0)))),
		"SITUATION",
		"Faim : %d/100 (0 = mort). Mûres dans le sac : %d sur %d." % [int(round(float(view.get("hunger", 0.0)))), carried, int(view.get("max_berries_carried", 3))],
		"Au contact d'un roncier : %s." % (contact if contact != "" else "aucun"),
		"Déplacement en cours : %s." % (current if current != "" else "aucun"),
		"Résultat de ta dernière action : %s." % last_text,
		"Directions déjà bloquées à cet endroit : %s." % (", ".join(view.get("blocked_directions", [])) if not view.get("blocked_directions", []).is_empty() else "aucune"),
		"Bord de la carte tout proche (aucune terre au-delà) : %s." % (", ".join(edges) if not edges.is_empty() else "aucun"),
		"RONCIERS AVEC DES MÛRES",
		listing,
		"ACTIONS POSSIBLES MAINTENANT : %s." % ", ".join(actions),
		"Choisis l'action la plus utile pour survivre. Réponds uniquement par un objet JSON avec les clés action, roncier_id (ou \"aucun\") et direction (ou \"aucune\").",
	]
	return "
".join(parts)

static func compass_of(direction: Vector3) -> String:
	if direction.length_squared() < 0.0001:
		return "aucune"
	var index := int(roundf(atan2(direction.x, -direction.z) / (PI / 4.0)))
	return LLMDecider.COMPASS_DIRECTIONS[posmod(index, 8)]

func parse_body(result: int, response_code: int, body_text: String) -> Dictionary:
	var latency_ms := float(Time.get_ticks_msec() - _request_started_ms)
	if result != HTTPRequest.RESULT_SUCCESS:
		return _failure("reseau", "result Godot = %d" % result, latency_ms)
	if response_code != 200:
		return _failure("http_%d" % response_code, body_text, latency_ms)
	var parsed = _parse_json(body_text)
	if not (parsed is Dictionary) or not parsed.has("response"):
		return _failure("reponse_invalide", "champ 'response' absent", latency_ms)
	var raw := String(parsed["response"])
	var inner = _parse_json(raw)
	if not (inner is Dictionary) or not inner.has("action") or not inner.has("roncier_id") or not inner.has("direction"):
		return _failure("json_invalide", raw, latency_ms)
	var action_name := String(inner["action"])
	var roncier_id := String(inner["roncier_id"])
	var direction := String(inner["direction"])
	var direction_ok: bool = direction == "aucune" or LLMDecider.COMPASS_VECTORS.has(direction)
	var roncier_ok: bool = roncier_id == "aucun" or _last_known_ids.has(roncier_id)
	if not ACTIONS.has(action_name) or not direction_ok or not roncier_ok:
		return _failure("hors_enumeration", "action=%s roncier_id=%s direction=%s" % [action_name, roncier_id, direction], latency_ms, raw)
	return {
		"ok": true,
		"action": {"action": action_name, "roncier_id": roncier_id, "direction": direction},
		"prompt": _last_prompt,
		"raw_response": raw,
		"latency_ms": latency_ms,
	}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_response = parse_body(result, response_code, body.get_string_from_utf8())

func _parse_json(text: String):
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

func _known_ids(view: Dictionary) -> Array:
	var ids: Array = []
	for entry in view.get("known", []):
		if int(entry["estimated_berries"]) > 0:
			ids.append(String(entry["id"]))
	ids.sort()
	return ids

func _failure(reason: String, detail: String, latency_ms: float = 0.0, raw: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "detail": detail, "prompt": _last_prompt, "raw_response": raw, "latency_ms": latency_ms}
