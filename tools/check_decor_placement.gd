extends SceneTree

const SEEDS := [26103001, 26103002, 26103003, 26103004, 26103005, 26103006, 26103007, 26103008, 26103009, 26103010, 26103011, 26103012, 1337]
const SPAWNS := [Vector2(-40, -40), Vector2(40, -40), Vector2(-40, 40), Vector2(40, 40)]

func _init() -> void:
	var dump_only := OS.get_cmdline_user_args().has("--dump")
	var snapshot := {}
	for seed_value in SEEDS:
		await process_frame
		var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
		scene.configure_training_world(seed_value)
		root.add_child(scene)
		await process_frame
		var ronces: Array = []
		var decor: Array = []
		for child in scene.get_children():
			if child is StaticBody3D and child.get_node_or_null("RockVisual") != null:
				decor.append(Vector2(child.position.x, child.position.z))
			elif child is Node3D and child.get_node_or_null("TreeVisual") != null:
				decor.append(Vector2(child.position.x, child.position.z))
			elif child is Area3D and child.get_node_or_null("RonceVisual") != null:
				ronces.append(Vector2(child.position.x, child.position.z))
		snapshot[str(seed_value)] = ronces.map(func(p): return [snappedf(p.x, 0.0001), snappedf(p.y, 0.0001)])
		if not dump_only:
			if not _check(seed_value, ronces, decor):
				return
		scene.queue_free()
		await process_frame
	if dump_only:
		var file := FileAccess.open(OS.get_cmdline_user_args()[OS.get_cmdline_user_args().find("--dump") + 1], FileAccess.WRITE)
		file.store_string(JSON.stringify(snapshot))
		file.close()
	print("Placement du décor : %d graines conformes" % SEEDS.size())
	quit(0)

func _check(seed_value: int, ronces: Array, decor: Array) -> bool:
	if ronces.size() != 24:
		return _fail("graine %d : %d ronciers au lieu de 24" % [seed_value, ronces.size()])
	if decor.size() < 100:
		return _fail("graine %d : seulement %d décors placés" % [seed_value, decor.size()])
	var half := 160.0 / 2.0 - 1.0 - 3.0
	for i in decor.size():
		var p: Vector2 = decor[i]
		if absf(p.x) > half + 0.001 or absf(p.y) > half + 0.001:
			return _fail("graine %d : décor hors marge murale %s" % [seed_value, p])
		for r in ronces:
			if p.distance_to(r) < DecorPlacementContract.RONCE - 0.001:
				return _fail("graine %d : décor %s à %.2f m d'un roncier" % [seed_value, p, p.distance_to(r)])
		for s in SPAWNS:
			if p.distance_to(s) < DecorPlacementContract.SPAWN - 0.001:
				return _fail("graine %d : décor %s à %.2f m d'un départ" % [seed_value, p, p.distance_to(s)])
		for j in range(i + 1, decor.size()):
			if p.distance_to(decor[j]) < DecorPlacementContract.DECOR - 0.001:
				return _fail("graine %d : deux décors à %.2f m" % [seed_value, p.distance_to(decor[j])])
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false

class DecorPlacementContract:
	const RONCE := 3.0
	const SPAWN := 5.0
	const DECOR := 1.5
