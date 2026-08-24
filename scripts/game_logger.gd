extends Node

const LOG_DIR := "res://logs/"
const EVENT_SCHEMA_VERSION := 1

var _file: FileAccess = null
var _structured_file: FileAccess = null
var _session_start_ticks: int = 0
var _session_id: String = ""

func _ready() -> void:
	start_session()

func start_session() -> void:
	if _file != null:
		_close_session("Fin de session (relancer)")

	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists("logs"):
		dir.make_dir("logs")

	_session_start_ticks = Time.get_ticks_msec()
	var stamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	_session_id = "session_%s_pid%d" % [stamp, OS.get_process_id()]
	_file = FileAccess.open(LOG_DIR + _session_id + ".log", FileAccess.WRITE)
	_structured_file = FileAccess.open(LOG_DIR + _session_id + ".jsonl", FileAccess.WRITE)
	log_event("session", "Nouvelle session démarrée")

func log_event(category: String, message: String) -> void:
	log_event_data(category, message, {})

func log_event_data(category: String, message: String, data: Dictionary) -> void:
	if _file == null:
		return
	var elapsed := _elapsed_seconds()
	_file.store_line("[%6.1fs][%s] %s" % [elapsed, category, message])
	_file.flush()
	if _structured_file != null:
		_structured_file.store_line(JSON.stringify({
			"schema_version": EVENT_SCHEMA_VERSION,
			"session_id": _session_id,
			"elapsed_seconds": elapsed,
			"category": category,
			"message": message,
			"data": data,
		}))
		_structured_file.flush()

func log_experiment_config(config: Dictionary) -> void:
	log_event_data("experiment", JSON.stringify(config), {"config": config})

func get_structured_log_path() -> String:
	return LOG_DIR + _session_id + ".jsonl"

func get_elapsed_seconds() -> float:
	return _elapsed_seconds()

func write_summary(summary: Dictionary) -> String:
	if _session_id == "":
		return ""
	var payload := summary.duplicate(true)
	payload["schema_version"] = EVENT_SCHEMA_VERSION
	payload["session_id"] = _session_id
	payload["elapsed_seconds"] = payload.get("elapsed_seconds", _elapsed_seconds())
	var path := LOG_DIR + _session_id + ".summary.json"
	var summary_file := FileAccess.open(path, FileAccess.WRITE)
	if summary_file == null:
		log_event("summary", "Impossible d'écrire le résumé : %s" % path)
		return ""
	summary_file.store_string(JSON.stringify(payload, "\t"))
	summary_file.close()
	log_event_data("summary", "Résumé écrit : %s" % path, {"path": path, "status": payload.get("status", "unknown")})
	return path

func _elapsed_seconds() -> float:
	return float(Time.get_ticks_msec() - _session_start_ticks) / 1000.0

func _exit_tree() -> void:
	if _file != null:
		_close_session("Fin de session")

func _close_session(message: String) -> void:
	log_event("session", message)
	_file.close()
	_file = null
	if _structured_file != null:
		_structured_file.close()
		_structured_file = null
