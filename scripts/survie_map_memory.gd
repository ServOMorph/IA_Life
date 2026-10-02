class_name SurvieMapMemory
extends RefCounted

## Mémoire cartographique du décideur llm_survie : cases de la grille parcourues par l'agent et
## bords de la carte qu'il a effectivement touchés. Rien n'est connu d'avance ni oublié : un bord
## n'entre en mémoire qu'au contact, une case qu'au passage de l'agent.

const CELL_SIZE := 10.0
const EDGE_TOUCH_DISTANCE := 1.5
const SECTOR_SAMPLE_DISTANCES := [10.0, 20.0, 30.0]

var _visited: Dictionary = {}
var _edges: Dictionary = {}

## Enregistre la position courante ; retourne les bords découverts à cet appel.
func record_position(position: Vector3, half_x: float, half_z: float) -> Array:
	_visited[cell_of(position)] = true
	var discovered: Array = []
	var limits := {
		"N": [position.z <= -half_z + EDGE_TOUCH_DISTANCE, -half_z],
		"S": [position.z >= half_z - EDGE_TOUCH_DISTANCE, half_z],
		"E": [position.x >= half_x - EDGE_TOUCH_DISTANCE, half_x],
		"O": [position.x <= -half_x + EDGE_TOUCH_DISTANCE, -half_x],
	}
	for side in ["N", "S", "E", "O"]:
		if limits[side][0] and not _edges.has(side):
			_edges[side] = float(limits[side][1])
			discovered.append(side)
	return discovered

static func cell_of(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.z / CELL_SIZE))

func is_visited(position: Vector3) -> bool:
	return _visited.has(cell_of(position))

func visited_count() -> int:
	return _visited.size()

func known_edges() -> Dictionary:
	return _edges.duplicate()

func edge_distances(position: Vector3) -> Dictionary:
	var distances := {}
	for side in _edges:
		var limit: float = _edges[side]
		var coordinate: float = position.z if side == "N" or side == "S" else position.x
		distances[side] = absf(limit - coordinate)
	return distances

func is_beyond_edges(point: Vector3) -> bool:
	if _edges.has("N") and point.z < float(_edges["N"]):
		return true
	if _edges.has("S") and point.z > float(_edges["S"]):
		return true
	if _edges.has("E") and point.x > float(_edges["E"]):
		return true
	if _edges.has("O") and point.x < float(_edges["O"]):
		return true
	return false

## Statut de chaque direction de la boussole autour de la position : "bord" (aucun point
## échantillonné en deçà d'un bord connu), "exploree", "partielle" ou "inexploree".
func sector_status(position: Vector3) -> Dictionary:
	var status := {}
	for name in LLMDecider.COMPASS_DIRECTIONS:
		var direction: Vector3 = LLMDecider.COMPASS_VECTORS[name].normalized()
		var inside := 0
		var visited := 0
		for distance in SECTOR_SAMPLE_DISTANCES:
			var point: Vector3 = position + direction * float(distance)
			if is_beyond_edges(point):
				break
			inside += 1
			if is_visited(point):
				visited += 1
		if inside == 0:
			status[name] = "bord"
		elif visited == inside:
			status[name] = "exploree"
		elif visited == 0:
			status[name] = "inexploree"
		else:
			status[name] = "partielle"
	return status

func view(position: Vector3) -> Dictionary:
	return {
		"visited_cells": visited_count(),
		"edges": edge_distances(position),
		"sectors": sector_status(position),
	}
