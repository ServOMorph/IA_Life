class_name RonceMemory
extends RefCounted

## Mémoire des ronciers du décideur llm_survie : indexée par identifiant stable, sans capacité
## ni oubli. Ne lit jamais l'état interne d'un roncier : les mûres n'y entrent que par observation
## (vue ou contact), puis par décompte des cueillettes propres. L'estimation peut être périmée si un
## autre agent a cueilli ; la vue suivante la corrige.

var _entries: Dictionary = {}

## Retourne true si le roncier n'était pas encore connu.
func observe(id: String, position: Vector3, berries_seen: int, time_seconds: float) -> bool:
	var is_new := not _entries.has(id)
	_entries[id] = {
		"id": id,
		"position": position,
		"estimated_berries": maxi(0, berries_seen),
		"last_observed_seconds": time_seconds,
		"own_picks": (_entries[id]["own_picks"] if not is_new else 0),
	}
	return is_new

func note_own_pick(id: String) -> void:
	if not _entries.has(id):
		return
	var entry: Dictionary = _entries[id]
	entry["estimated_berries"] = maxi(0, int(entry["estimated_berries"]) - 1)
	entry["own_picks"] = int(entry["own_picks"]) + 1

func is_known(id: String) -> bool:
	return _entries.has(id)

func count() -> int:
	return _entries.size()

func known_ids() -> Array:
	var ids := _entries.keys()
	ids.sort()
	return ids

func estimated_berries(id: String) -> int:
	return int(_entries[id]["estimated_berries"]) if _entries.has(id) else 0

func position_of(id: String) -> Vector3:
	return _entries[id]["position"] if _entries.has(id) else Vector3.ZERO

func last_observed_seconds(id: String) -> float:
	return float(_entries[id]["last_observed_seconds"]) if _entries.has(id) else -1.0

func own_picks(id: String) -> int:
	return int(_entries[id]["own_picks"]) if _entries.has(id) else 0

func snapshot() -> Array:
	var result: Array = []
	for id in known_ids():
		result.append(_entries[id].duplicate())
	return result
