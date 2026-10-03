extends SceneTree

const FIRST_SEED := 26103001
const MAP_COUNT := 12
const MAX_BLOCKED_SECONDS := 3.0
const MAP_SECONDS := 90.0
const SCENARIO_SECONDS := 25.0
const GOALS := ["ronce_visible", "ronce_memorisee", "souvenir_ancien"]

func _init() -> void:
	await process_frame
	if not _unit():
		return
	var config = root.get_node("GameConfig")
	config.decor_collisions = true
	if not await _scenario(FIRST_SEED):
		return
	var worst := 0.0
	var contacts := 0
	var detours := 0
	var steps := 0
	for i in MAP_COUNT:
		var stats: Dictionary = await _map(FIRST_SEED + i)
		if stats.is_empty():
			return
		worst = maxf(worst, stats["blocked_max"])
		contacts += stats["contacts"]
		detours += stats["detours"]
		steps += stats["goal_steps"]
		print("seed %d : blocage max %.2f s, contacts tronc %d, contournements %d, pas en ciblage %d" % [FIRST_SEED + i, stats["blocked_max"], stats["contacts"], stats["detours"], stats["goal_steps"]])
	if steps == 0:
		_fail("aucun pas en ciblage de roncier : mesure sans objet")
		return
	if worst > MAX_BLOCKED_SECONDS:
		_fail("blocage frontal de %.2f s (> %.1f s)" % [worst, MAX_BLOCKED_SECONDS])
		return
	config.decor_collisions = false
	print("Contournement automate : %d cartes, blocage max %.2f s, %d contacts, %d contournements" % [MAP_COUNT, worst, contacts, detours])
	quit(0)

func _unit() -> bool:
	var detour = preload("res://scripts/decor_detour.gd").new()
	var ahead := Vector3(1, 0, 0)
	var trunk := {"id": "t", "position": Vector3(2.0, 0.0, 0.0), "radius": 0.26}
	var out: Vector3 = detour.steer(Vector3.ZERO, ahead, [trunk], 0.016)
	if absf(out.z) < 0.3 or out.x <= 0.0:
		return _fail("tronc en face : direction %s non déviée" % out)
	var first_side: float = signf(out.z)
	for i in 5:
		out = detour.steer(Vector3(0.2 * i, 0.0, 0.0), ahead, [trunk], 0.016)
		if signf(out.z) != first_side:
			return _fail("côté de contournement instable")
	var aside := {"id": "a", "position": Vector3(2.0, 0.0, 3.0), "radius": 0.26}
	var free = preload("res://scripts/decor_detour.gd").new()
	if free.steer(Vector3.ZERO, ahead, [aside], 0.016) != ahead:
		return _fail("tronc hors trajectoire : direction modifiée")
	var behind := {"id": "b", "position": Vector3(-2.0, 0.0, 0.0), "radius": 0.26}
	if free.steer(Vector3.ZERO, ahead, [behind], 0.016) != ahead:
		return _fail("tronc derrière : direction modifiée")
	if free.steer(Vector3.ZERO, ahead, [], 0.016) != ahead:
		return _fail("sans obstacle : direction modifiée")
	return true

func _build(seed_value: int) -> Node3D:
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	scene.configure_training_world(seed_value)
	root.add_child(scene)
	await process_frame
	await physics_frame
	return scene

func _scenario(seed_value: int) -> bool:
	var scene: Node3D = await _build(seed_value)
	var trunks: Array = []
	for child in scene.get_children():
		if child is Node3D and child.get_node_or_null("TreeVisual") != null:
			trunks.append(child)
	var tree: Node3D = _isolated_tree(trunks)
	if tree == null:
		return _fail("scénario : aucun arbre isolé")
	var agent = scene.training_character()
	var ronce = scene.training_resources()[0]
	agent.position = tree.position + Vector3(-6.0, 1.0, 0.0)
	agent.velocity = Vector3.ZERO
	agent.basis = Basis.looking_at(Vector3(1, 0, 0), Vector3.UP)
	agent.hunger = 20.0
	for other in scene.training_resources():
		if other != ronce:
			other.position = tree.position + Vector3(0.0, 0.0, 200.0)
	ronce.position = tree.position + Vector3(6.0, 0.0, 0.0)
	var blocked := 0.0
	var worst := 0.0
	var reached := false
	var delta := 1.0 / float(Engine.physics_ticks_per_second)
	for step in int(SCENARIO_SECONDS / delta):
		await physics_frame
		if agent._obstacle_contact_active["tronc"]:
			blocked += delta
			worst = maxf(worst, blocked)
		else:
			blocked = 0.0
		var flat := Vector2(agent.position.x - ronce.position.x, agent.position.z - ronce.position.z)
		if flat.length() < 2.2:
			reached = true
			break
	print("scénario : atteint=%s, blocage max %.2f s, contournements %d, objectif %s" % [reached, worst, agent.decor_detour.detours_total, agent.current_goal])
	if not reached:
		return _fail("scénario : roncier derrière le tronc non rejoint (position %s, but %s)" % [agent.position, agent.current_goal])
	if worst > MAX_BLOCKED_SECONDS:
		return _fail("scénario : blocage %.2f s" % worst)
	scene.queue_free()
	await process_frame
	return true

func _map(seed_value: int) -> Dictionary:
	var scene: Node3D = await _build(seed_value)
	var agent = scene.training_character()
	var delta := 1.0 / float(Engine.physics_ticks_per_second)
	var blocked := 0.0
	var worst := 0.0
	var goal_steps := 0
	var before: int = agent.obstacle_contacts["tronc"]
	for step in int(MAP_SECONDS / delta):
		await physics_frame
		if agent.is_dead:
			break
		var targeting: bool = GOALS.has(agent.current_goal)
		if targeting:
			goal_steps += 1
		if targeting and agent._obstacle_contact_active["tronc"]:
			blocked += delta
			worst = maxf(worst, blocked)
		else:
			blocked = 0.0
	var stats := {
		"blocked_max": worst,
		"contacts": agent.obstacle_contacts["tronc"] - before,
		"detours": agent.decor_detour.detours_total,
		"goal_steps": goal_steps,
	}
	scene.queue_free()
	await process_frame
	return stats

func _isolated_tree(trunks: Array) -> Node3D:
	for candidate in trunks:
		if absf(candidate.position.x) > 55.0 or absf(candidate.position.z) > 55.0:
			continue
		var clear := true
		for other in trunks:
			if other == candidate:
				continue
			var delta: Vector3 = other.position - candidate.position
			if absf(delta.z) < 4.0 and delta.x > -8.0 and delta.x < 8.0:
				clear = false
				break
		if clear:
			return candidate
	return null

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
