class_name BaselineDecider
extends RefCounted

## Décideur de référence déterministe.
## Il ne modifie pas le monde : il reçoit une observation et retourne une action.

func decide(observation: Dictionary) -> Dictionary:
	if observation["manual_control"]:
		return {"goal": "controle_manuel", "direction": observation["manual_direction"], "renew_wander": false}
	if observation["hunger"] > observation["pickup_hunger_threshold"]:
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
