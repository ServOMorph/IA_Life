extends Node

const LOG_DIR := "res://logs/"

var _file: FileAccess = null
var _session_start_unix: int = 0

func _ready() -> void:
	start_session()

func start_session() -> void:
	if _file != null:
		log_event("session", "Fin de session (relancer)")
		_file.close()
		_file = null

	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists("logs"):
		dir.make_dir("logs")

	_session_start_unix = Time.get_unix_time_from_system()
	var stamp: String = Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var path := LOG_DIR + "session_%s_pid%d.log" % [stamp, OS.get_process_id()]
	_file = FileAccess.open(path, FileAccess.WRITE)
	log_event("session", "Nouvelle session démarrée")

func log_event(category: String, message: String) -> void:
	if _file == null:
		return
	var elapsed := Time.get_unix_time_from_system() - _session_start_unix
	_file.store_line("[%6.1fs][%s] %s" % [elapsed, category, message])
	_file.flush()
