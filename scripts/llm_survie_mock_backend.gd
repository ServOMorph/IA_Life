class_name LLMSurieMockBackend
extends RefCounted

## Backend simulé de llm_survie (aucun appel réseau). La latence est exprimée en secondes
## simulées. Les réponses viennent d'abord de la file enqueue()/enqueue_failure(), puis de
## `policy` (Callable recevant la vue de la requête), puis d'un `attendre` par défaut.

var latency_seconds: float = 0.0
var policy: Callable = Callable()
var requests_total: int = 0
var overlaps_total: int = 0

var _queue: Array = []
var _pending: bool = false
var _remaining: float = 0.0
var _response: Dictionary = {}

func enqueue(action: Dictionary) -> void:
	_queue.append({"action": action})

func enqueue_failure(reason: String, detail: String = "") -> void:
	_queue.append({"fail": reason, "detail": detail})

func request(view: Dictionary, _turn_id: int) -> void:
	if _pending:
		overlaps_total += 1
	requests_total += 1
	_pending = true
	_remaining = latency_seconds
	_response = _build_response(view)

func advance(delta: float) -> void:
	if _pending:
		_remaining -= delta

func poll() -> Dictionary:
	if _pending and _remaining <= 0.0:
		_pending = false
		return _response
	return {}

func _build_response(view: Dictionary) -> Dictionary:
	var action: Dictionary = {"action": "attendre", "roncier_id": "aucun", "direction": "aucune"}
	if not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		if item.has("fail"):
			return {"ok": false, "reason": item["fail"], "detail": item["detail"], "latency_ms": latency_seconds * 1000.0}
		action = item["action"]
	elif policy.is_valid():
		action = policy.call(view)
	return {
		"ok": true,
		"action": action,
		"prompt": "(mode mock, aucun appel réseau)",
		"raw_response": JSON.stringify(action),
		"latency_ms": latency_seconds * 1000.0,
	}
