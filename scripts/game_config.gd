extends Node

var max_berries_carried: int = 3
var pickup_hunger_threshold: float = 90.0
var eat_hunger_threshold: float = 50.0
var full_life_berries: float = 6.0
var ronce_count: int = 24
var berries_per_ronce: int = 3

func pv_per_berry(feeding_capacity: float) -> float:
	return (100.0 / full_life_berries) * feeding_capacity

func apply_overrides(values: Dictionary) -> void:
	for key in values:
		set(key, values[key])
