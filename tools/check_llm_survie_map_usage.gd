extends SceneTree

## Banc d'usage de la mémoire cartographique par le LLM de llm_survie (Ollama réel, gemma3:1b,
## température 0). Deux familles de situations verrouillées, chacune jouée avec la carte dans le
## prompt (bras carte) et sans (bras témoin, prompt v1) :
## - inexploree : sac vide, aucun roncier connu, une seule direction inexplorée sur 8 ; succès si
##   le LLM explore cette direction.
## - bord : bord cardinal touché, la direction et ses deux diagonales marquées bord ; succès si le
##   LLM explore une autre direction.
## Gate (fixé avant la première mesure) : bras carte >= 6/8 en inexploree, 4/4 en bord, et strictement
## meilleur que le témoin en inexploree. Usage :
##   godot --headless --path . -s tools/check_llm_survie_map_usage.gd
## Résultat détaillé : results/llm_survie_carte_usage.json. Code de sortie 0 si le gate est atteint.

const MODEL := "gemma3:1b"
const TIMEOUT_SECONDS := 60.0
const OUTPUT_PATH := "res://results/llm_survie_carte_usage.json"
const DIRECTIONS := ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]

func _init() -> void:
	await process_frame
	var backend_script = load("res://scripts/llm_survie_ollama_backend.gd")
	var backend = backend_script.new()
	backend.configure(MODEL, TIMEOUT_SECONDS, 42, "banc_carte")
	root.add_child(backend)
	await process_frame
	var records: Array = []
	for scenario in _scenarios():
		for arm in ["carte", "temoin"]:
			var view: Dictionary = scenario["view"].duplicate(true)
			if arm == "temoin":
				view.erase("map")
			backend.request(view, records.size() + 1)
			var response: Dictionary = {}
			while response.is_empty():
				await process_frame
				response = backend.poll()
			var action: Dictionary = response.get("action", {})
			var direction := String(action.get("direction", ""))
			var success: bool = bool(response.get("ok", false)) and String(action.get("action", "")) == "explorer" and scenario["accept"].has(direction)
			records.append({
				"famille": scenario["family"],
				"situation": scenario["name"],
				"bras": arm,
				"ok": bool(response.get("ok", false)),
				"raison": String(response.get("reason", "")),
				"action": String(action.get("action", "")),
				"direction": direction,
				"succes": success,
				"latence_ms": float(response.get("latency_ms", 0.0)),
			})
			print("%-10s %-14s %-6s -> %s %s %s" % [scenario["family"], scenario["name"], arm, String(action.get("action", response.get("reason", ""))), direction, "OK" if success else "--"])
	var score := func(family: String, arm: String) -> int:
		return records.filter(func(r): return r["famille"] == family and r["bras"] == arm and r["succes"]).size()
	var map_unexplored: int = score.call("inexploree", "carte")
	var control_unexplored: int = score.call("inexploree", "temoin")
	var map_edge: int = score.call("bord", "carte")
	var control_edge: int = score.call("bord", "temoin")
	var gate: bool = map_unexplored >= 6 and map_edge == 4 and map_unexplored > control_unexplored
	var summary := {
		"modele": MODEL,
		"inexploree": {"carte": map_unexplored, "temoin": control_unexplored, "total": 8},
		"bord": {"carte": map_edge, "temoin": control_edge, "total": 4},
		"gate": "carte inexploree >= 6/8, carte bord = 4/4, carte inexploree > temoin",
		"gate_atteint": gate,
		"essais": records,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://results"))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(summary, "  "))
		file.close()
	print("inexploree : carte %d/8, temoin %d/8 | bord : carte %d/4, temoin %d/4 | gate %s" % [map_unexplored, control_unexplored, map_edge, control_edge, "ATTEINT" if gate else "NON ATTEINT"])
	quit(0 if gate else 1)

func _base_view() -> Dictionary:
	return {
		"hunger": 60.0,
		"berries_carried": 0,
		"max_berries_carried": 3,
		"eat_hunger_threshold": 50.0,
		"contact_ronce_id": "",
		"known": [],
		"current_action": "",
		"target_id": "",
		"last_result": {},
		"last_issue": "",
		"blocked_directions": [],
		"blocked_targets": [],
		"edges": [],
	}

func _scenarios() -> Array:
	var result: Array = []
	for target in DIRECTIONS:
		var view := _base_view()
		var sectors := {}
		for name in DIRECTIONS:
			sectors[name] = "inexploree" if name == target else "exploree"
		view["map"] = {"visited_cells": 12, "edges": {}, "sectors": sectors}
		result.append({"family": "inexploree", "name": "seule_" + target, "view": view, "accept": [target]})
	for side in ["N", "E", "S", "O"]:
		var index := DIRECTIONS.find(side)
		var blocked := [DIRECTIONS[posmod(index - 1, 8)], side, DIRECTIONS[posmod(index + 1, 8)]]
		var view := _base_view()
		view["edges"] = [side]
		var sectors := {}
		for name in DIRECTIONS:
			sectors[name] = "bord" if blocked.has(name) else "partielle"
		view["map"] = {"visited_cells": 12, "edges": {side: 1.0}, "sectors": sectors}
		result.append({"family": "bord", "name": "bord_" + side, "view": view, "accept": DIRECTIONS.filter(func(name): return not blocked.has(name))})
	return result
