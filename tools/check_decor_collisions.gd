extends SceneTree

const SEED := 26103001
const PROBE_HEIGHT := 0.0

func _init() -> void:
	await process_frame
	for enabled in [false, true]:
		root.get_node("GameConfig").decor_collisions = enabled
		var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
		scene.configure_training_world(SEED)
		root.add_child(scene)
		await process_frame
		await physics_frame
		if not await _check(scene, enabled):
			return
		scene.queue_free()
		await process_frame
	root.get_node("GameConfig").decor_collisions = false
	print("Collisions de décor : interrupteur, blocage, comptage et occlusion conformes")
	quit(0)

func _check(scene: Node3D, enabled: bool) -> bool:
	var tag := "decor_collisions=%s" % enabled
	var trunks: Array = []
	for child in scene.get_children():
		if child is Node3D and child.get_node_or_null("TreeVisual") != null:
			trunks.append(child)
	if trunks.size() < 100:
		return _fail("%s : seulement %d arbres" % [tag, trunks.size()])
	for tree in trunks:
		var shape: CollisionShape3D = tree.get_node("TreeCollision").get_child(0)
		if shape.disabled == enabled:
			return _fail("%s : collision de tronc à l'état %s" % [tag, shape.disabled])

	var tree: Node3D = _isolated_tree(trunks)
	if tree == null:
		return _fail("%s : aucun arbre isolé pour la sonde" % tag)
	var agent = scene.training_character()
	agent.set_physics_process(false)
	var ground := tree.position.y
	var start := tree.position + Vector3(-4.0, 1.0, 0.0)
	agent.position = start
	agent.velocity = Vector3.ZERO
	var before: Dictionary = agent.obstacle_contacts.duplicate()
	for step in 240:
		agent.velocity = Vector3(4.0, -1.0, 0.0)
		agent.move_and_slide()
		var touched := {}
		for i in agent.get_slide_collision_count():
			var collision = agent.get_slide_collision(i)
			if absf(collision.get_normal().y) < 0.5:
				var kind: String = agent._obstacle_kind(collision.get_collider())
				if kind != "":
					touched[kind] = true
		agent._record_obstacle_contacts(touched)
		await physics_frame
	var passed: bool = agent.position.x > tree.position.x
	var contacts: int = agent.obstacle_contacts["tronc"] - before["tronc"]
	if enabled:
		if passed:
			return _fail("%s : l'agent a traversé le tronc (x=%.2f, tronc x=%.2f)" % [tag, agent.position.x, tree.position.x])
		if contacts < 1:
			return _fail("%s : aucun contact tronc journalisé" % tag)
	else:
		if not passed:
			return _fail("%s : l'agent est bloqué sans collisions (x=%.2f)" % [tag, agent.position.x])
		if contacts != 0:
			return _fail("%s : %d contacts tronc sans collisions" % [tag, contacts])

	var ronce = scene.training_resources()[0]
	var ronce_position: Vector3 = ronce.position
	var probe_from := tree.position + Vector3(-4.0, 1.0, 0.0)
	ronce.position = tree.position + Vector3(4.0, 0.0, 0.0)
	agent.position = probe_from
	await physics_frame
	await physics_frame
	var occluded: bool = agent._is_occluded(agent.get_world_3d().direct_space_state, ronce)
	ronce.position = ronce_position
	if occluded != enabled:
		return _fail("%s : occlusion=%s (attendue %s)" % [tag, occluded, enabled])
	return true

func _isolated_tree(trunks: Array) -> Node3D:
	for candidate in trunks:
		if absf(candidate.position.x) > 60.0 or absf(candidate.position.z) > 60.0:
			continue
		var clear := true
		for other in trunks:
			if other == candidate:
				continue
			var delta: Vector3 = other.position - candidate.position
			if absf(delta.z) < 3.0 and delta.x > -6.0 and delta.x < 6.0:
				clear = false
				break
		if clear:
			return candidate
	return null

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
