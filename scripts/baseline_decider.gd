class_name BaselineDecider
extends RefCounted

## Décideur de référence déterministe.
## Il ne modifie pas le monde : il reçoit une observation et retourne une action.

func decide(observation: Dictionary) -> Dictionary:
	if observation["manual_control"]:
		return {"goal": "controle_manuel", "direction": observation["manual_direction"], "renew_wander": false}
	# Cible un roncier seulement quand la cueillette y est effectivement possible
	# (character.gd::try_pick_berry_from_ronce) : faim sous le seuil ET inventaire non
	# plein. Sans la seconde condition, un agent l'inventaire plein reste ciblé sur un
	# roncier où il ne peut plus rien prendre et s'y fige.
	var can_pick_up: bool = observation["berries_carried"] < observation["max_berries_carried"]
	if observation["hunger"] <= observation["pickup_hunger_threshold"] and can_pick_up:
		if observation.get("has_visible_ronce", false):
			return {"goal": "ronce_visible", "direction": observation["visible_ronce_direction"], "renew_wander": false}
		if observation["has_memories"]:
			return {"goal": "ronce_memorisee", "direction": observation["memory_direction"], "renew_wander": false}
	if observation["social_goal"] != "":
		return {"goal": observation["social_goal"], "direction": observation["social_direction"], "renew_wander": false}
	return {
		"goal": "errance",
		"direction": observation["current_direction"],
		"renew_wander": observation["wander_timer"] - observation["delta"] <= 0.0,
	}
