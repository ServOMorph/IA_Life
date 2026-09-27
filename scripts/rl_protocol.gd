class_name RLProtocol
extends RefCounted

var episode_id := 0
var next_step := 0
var active := false

func reset() -> int:
	episode_id += 1
	next_step = 0
	active = true
	return episode_id

func accept_step(request_episode_id: int, request_step: int) -> bool:
	if not active:
		return false
	if request_episode_id != episode_id or request_step != next_step:
		return false
	next_step += 1
	return true

func finish() -> void:
	active = false
