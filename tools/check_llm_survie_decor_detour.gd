extends SceneTree

const SEED := 26103001
const MAX_SECONDS := 25.0

var _target_id := ""

func _init() -> void:
	await process_frame
	if not await _scenario(true, "aller_vers"):
		return
	if not await _scenario(true, "explorer"):
		return
	if not await _scenario(false, "aller_vers"):
		return
	if not await _scenario(false, "explorer"):
		return
	if not await _failed_detour():
		return
	root.get_node("GameConfig").decor_collisions = false
	print("llm_survie : contournement aller_vers/explorer, échec et collisions désactivées conformes")
	quit(0)

func _scenario(collisions: bool, action_name: String) -> bool:
	root.get_node("GameConfig").decor_collisions = collisions
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	scene.configure_training_world(SEED)
	scene._character_overrides["Rouge"] = {"decider_type": "llm_survie", "vision_range": 25.0, "hunger": 50.0, "llm_decision_interval_seconds": 1000.0}
	root.add_child(scene)
	var tree: Node3D = _isolated_tree(scene)
	if tree == null:
		return _fail("aucun arbre isolé")
	var agent = scene.training_character()
	var ronce = scene.training_resources()[0]
	agent.position = tree.position + Vector3(-6.0, 1.0, 0.0)
	agent.velocity = Vector3.ZERO
	agent.hunger = 50.0
	for other in scene.training_resources():
		if other != ronce:
			other.position = tree.position + Vector3(0.0, 0.0, 200.0)
	ronce.position = tree.position + Vector3(6.0, 0.0, 0.0)
	_target_id = ronce.ronce_id
	agent.ronce_memory().observe(_target_id, ronce.position, ronce.berries, 0.0)
	var backend := LLMSurieMockBackend.new()
	backend.policy = Callable(self, "_mock_action").bind(action_name)
	agent.set_survie_backend(backend)
	var reached := false
	var delta := 1.0 / float(Engine.physics_ticks_per_second)
	for step in int(MAX_SECONDS / delta):
		await physics_frame
		var offset := Vector2(agent.position.x - ronce.position.x, agent.position.z - ronce.position.z)
		if action_name == "aller_vers" and offset.length() < 2.2:
			reached = true
			break
		if action_name == "explorer" and agent.position.x > tree.position.x + 2.0:
			reached = true
			break
		if agent.survie_engine().blocked_targets().has(_target_id) or (action_name == "explorer" and agent.survie_engine().blocked_directions().has("E")):
			return _fail("%s, collisions=%s : blocage déclaré avant passage" % [action_name, collisions])
	var detours: int = agent.decor_detour.detours_total
	var blocked: Array = agent.survie_engine().blocked_targets()
	print("%s, collisions=%s : passage=%s, détours=%d, cibles bloquées=%s" % [action_name, collisions, reached, detours, blocked])
	if not reached or not blocked.is_empty() or (collisions and detours == 0) or (not collisions and detours != 0):
		return _fail("%s, collisions=%s : gate non atteint" % [action_name, collisions])
	scene.queue_free()
	await process_frame
	return true

func _mock_action(_view: Dictionary, action_name: String) -> Dictionary:
	if action_name == "aller_vers":
		return {"action": "aller_vers", "roncier_id": _target_id, "direction": "aucune"}
	return {"action": "explorer", "roncier_id": "aucun", "direction": "E"}

func _failed_detour() -> bool:
	root.get_node("GameConfig").decor_collisions = true
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	scene.configure_training_world(SEED)
	scene._character_overrides["Rouge"] = {"decider_type": "llm_survie"}
	root.add_child(scene)
	var agent = scene.training_character()
	agent.set_physics_process(false)
	var engine = agent.survie_engine()
	agent.position = Vector3.ZERO
	agent.set_decor_obstacles([{"id": "test", "position": Vector3(2.0, 0.0, 0.0), "radius": 0.26}])
	var result: Dictionary = engine.submit({"action": "explorer", "direction": "E"})
	if not result["accepted"]:
		return _fail("explorer refusé dans le test d'échec")
	for step in 30:
		engine.tick(0.1)
	if engine.current_action != "explorer" or not engine.blocked_directions().is_empty():
		return _fail("blocage déclaré avant échec du contournement")
	for step in 30:
		engine.tick(0.1)
	if engine.current_action != "" or not engine.blocked_directions().has("E") or agent.decor_detour.failed_total == 0:
		return _fail("échec du contournement non déclaré")
	scene.queue_free()
	await process_frame
	return true

func _isolated_tree(scene: Node3D) -> Node3D:
	var trunks: Array = []
	for child in scene.get_children():
		if child is Node3D and child.get_node_or_null("TreeVisual") != null:
			trunks.append(child)
	for candidate in trunks:
		if absf(candidate.position.x) > 55.0 or absf(candidate.position.z) > 55.0:
			continue
		var clear := true
		for other in trunks:
			if other == candidate:
				continue
			var offset: Vector3 = other.position - candidate.position
			if absf(offset.z) < 4.0 and offset.x > -8.0 and offset.x < 8.0:
				clear = false
				break
		if clear:
			return candidate
	return null

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
