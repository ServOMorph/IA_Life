extends SceneTree

const SEEDS := [26103101, 26103102, 26103103, 26103104, 26103105, 26103106]
const STARTS := [Vector2(-40, -40), Vector2(40, -40), Vector2(-40, 40), Vector2(40, 40)]
const STEP := 0.5
const EDGE := 78.0
const WIDTH := 313
const AGENT_RADIUS := 0.35
const MARGIN := STEP * 0.71

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dump: Dictionary = {}
	for seed_value in SEEDS:
		await process_frame
		root.get_node("GameConfig").decor_collisions = true
		var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
		scene.configure_training_world(seed_value)
		root.add_child(scene)
		await process_frame
		if args.has("--dump"):
			var obstacles: Array = scene.get("_decor_obstacles")
			dump[str(seed_value)] = obstacles.map(func(o): return {"x": Vector3(o["position"]).x, "z": Vector3(o["position"]).z, "radius": float(o["radius"])})
		if not _check(seed_value, scene):
			return
		scene.queue_free()
		await process_frame
	root.get_node("GameConfig").decor_collisions = false
	if args.has("--dump"):
		var path: String = args[args.find("--dump") + 1]
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(dump))
		file.close()
	print("Accessibilité décor : 6 cartes, 24 ronciers atteignables par carte")
	quit(0)

func _check(seed_value: int, scene: Node3D) -> bool:
	var blocked := PackedByteArray()
	blocked.resize(WIDTH * WIDTH)
	var ronces: Array = []
	for child in scene.get_children():
		if child is Area3D and child.get_node_or_null("RonceVisual") != null:
			ronces.append(Vector2(child.position.x, child.position.z))
		elif child is StaticBody3D and child.get_node_or_null("RockVisual") != null:
			var shape: BoxShape3D = _collision_shape(child)
			_mark_box(blocked, Vector2(child.position.x, child.position.z), Vector2(shape.size.x, shape.size.z) * 0.5 + Vector2.ONE * (AGENT_RADIUS + MARGIN))
		elif child is Node3D and child.get_node_or_null("TreeVisual") != null:
			var shape: CylinderShape3D = _collision_shape(child.get_node("TreeCollision"))
			_mark_circle(blocked, Vector2(child.position.x, child.position.z), shape.radius + AGENT_RADIUS + MARGIN)
	if ronces.size() != 24:
		return _fail("graine %d : %d ronciers" % [seed_value, ronces.size()])
	var visited := PackedByteArray()
	visited.resize(blocked.size())
	var queue := PackedInt32Array()
	for start in STARTS:
		var index := _index(start)
		if blocked[index] != 0:
			return _fail("graine %d : départ bloqué %s" % [seed_value, start])
		visited[index] = 1
		queue.append(index)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % WIDTH
		var z := index / WIDTH
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + offset.x
			var nz: int = z + offset.y
			if nx < 0 or nx >= WIDTH or nz < 0 or nz >= WIDTH:
				continue
			var next: int = nz * WIDTH + nx
			if blocked[next] == 0 and visited[next] == 0:
				visited[next] = 1
				queue.append(next)
	for ronce in ronces:
		var index := _index(ronce)
		if blocked[index] != 0 or visited[index] == 0:
			return _fail("graine %d : roncier inaccessible %s" % [seed_value, ronce])
	return true

func _collision_shape(body: Node) -> Shape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			return child.shape
	return null

func _mark_circle(blocked: PackedByteArray, center: Vector2, radius: float) -> void:
	var min_x := maxi(0, ceili((center.x - radius + EDGE) / STEP))
	var max_x := mini(WIDTH - 1, floori((center.x + radius + EDGE) / STEP))
	var min_z := maxi(0, ceili((center.y - radius + EDGE) / STEP))
	var max_z := mini(WIDTH - 1, floori((center.y + radius + EDGE) / STEP))
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			var point := Vector2(x * STEP - EDGE, z * STEP - EDGE)
			if point.distance_to(center) <= radius:
				blocked[z * WIDTH + x] = 1

func _mark_box(blocked: PackedByteArray, center: Vector2, half_size: Vector2) -> void:
	var min_x := maxi(0, ceili((center.x - half_size.x + EDGE) / STEP))
	var max_x := mini(WIDTH - 1, floori((center.x + half_size.x + EDGE) / STEP))
	var min_z := maxi(0, ceili((center.y - half_size.y + EDGE) / STEP))
	var max_z := mini(WIDTH - 1, floori((center.y + half_size.y + EDGE) / STEP))
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			blocked[z * WIDTH + x] = 1

func _index(point: Vector2) -> int:
	var x := clampi(roundi((point.x + EDGE) / STEP), 0, WIDTH - 1)
	var z := clampi(roundi((point.y + EDGE) / STEP), 0, WIDTH - 1)
	return z * WIDTH + x

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
