extends Node

const SAVE_PATH := "res://logs/game_config.json"
const PERSISTED_KEYS := ["max_berries_carried", "pickup_hunger_threshold", "eat_hunger_threshold",
	"full_life_berries", "ronce_count", "berries_per_ronce", "light_energy"]

var max_berries_carried: int = 3
var pickup_hunger_threshold: float = 90.0
var eat_hunger_threshold: float = 50.0
var full_life_berries: float = 6.0
var ronce_count: int = 24
var berries_per_ronce: int = 3
var light_energy: float = 3.0

func _ready() -> void:
	load_from_disk()

func pv_per_berry(feeding_capacity: float) -> float:
	return (100.0 / full_life_berries) * feeding_capacity

func apply_overrides(values: Dictionary) -> void:
	for key in values:
		if key in PERSISTED_KEYS:
			set(key, values[key])

func save_to_disk() -> void:
	var data := {}
	for key in PERSISTED_KEYS:
		data[key] = get(key)
	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists("logs"):
		dir.make_dir("logs")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		apply_overrides(parsed)
