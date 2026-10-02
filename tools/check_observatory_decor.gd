extends SceneTree

func _init() -> void:
	await process_frame
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var rocks: Array = []
	var trees: Array = []
	var walls: Array = []
	var ronces: Array = []
	for child in scene.get_children():
		if child is StaticBody3D and child.get_node_or_null("RockVisual") != null:
			rocks.append(child)
		elif child is Node3D and child.get_node_or_null("TreeVisual") != null:
			trees.append(child)
		elif child is StaticBody3D and child.name != "Floor":
			walls.append(child)
		elif child is Area3D and child.get_node_or_null("RonceVisual") != null:
			ronces.append(child)
	if rocks.size() != 8 or trees.size() != 108 or walls.size() != 4 or ronces.size() != root.get_node("GameConfig").get("ronce_count"):
		print("Décor : rochers=%d arbres=%d murs=%d ronciers=%d attendus=%d" % [rocks.size(), trees.size(), walls.size(), ronces.size(), root.get_node("GameConfig").get("ronce_count")])
		_fail("Nombre d'objets modifié")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var half := 160.0 / 2.0 - 1.0 - 3.0
	for index in rocks.size():
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var scale := rng.randf_range(0.5, 1.1)
		var rock: StaticBody3D = rocks[index]
		var shape: BoxShape3D = _direct_collision(rock).shape
		if rock.position.distance_to(Vector3(x, scene._terrain_height(x, z) + 0.35 * scale, z)) > 0.001:
			_fail("Position d'un rocher modifiée")
			return
		if shape.size.distance_to(Vector3(1.0, 0.7, 0.9) * scale) > 0.001:
			_fail("Collision d'un rocher modifiée")
			return
		if not _has_mesh(rock.get_node("RockVisual")) or _has_collision(rock.get_node("RockVisual")):
			_fail("Modèle de rocher manquant ou collision supplémentaire")
			return

	for index in trees.size():
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var scale := rng.randf_range(0.85, 1.3)
		var tree: Node3D = trees[index]
		var tree_body: StaticBody3D
		for child in tree.get_children():
			if child is StaticBody3D:
				tree_body = child
				break
		var collision := _direct_collision(tree_body)
		var shape: CylinderShape3D = collision.shape
		if tree.position.distance_to(Vector3(x, scene._terrain_height(x, z), z)) > 0.001:
			_fail("Position d'un arbre modifiée")
			return
		if absf(shape.radius - 0.2 * scale) > 0.001 or absf(shape.height - 2.0 * scale) > 0.001:
			_fail("Collision d'un arbre modifiée")
			return
		if not collision.disabled:
			_fail("Collision d'un arbre encore active")
			return
		if not _has_mesh(tree.get_node("TreeVisual")) or _has_collision(tree.get_node("TreeVisual")):
			_fail("Modèle d'arbre manquant ou collision supplémentaire")
			return

	var wall_positions := [Vector3(0, 1.5, -80), Vector3(0, 1.5, 80), Vector3(-80, 1.5, 0), Vector3(80, 1.5, 0)]
	var wall_sizes := [Vector3(161, 3, 1), Vector3(161, 3, 1), Vector3(1, 3, 161), Vector3(1, 3, 161)]
	for index in walls.size():
		var wall: StaticBody3D = walls[index]
		var collision := _direct_collision(wall)
		if collision == null or collision.shape is not BoxShape3D:
			_fail("Collision d'un mur modifiée")
			return
		if wall.position.distance_to(wall_positions[index]) > 0.001 or collision.shape.size.distance_to(wall_sizes[index]) > 0.001:
			_fail("Position ou taille d'un mur modifiée")
			return
	for ronce in ronces:
		var visual: Node3D = ronce.get_node("RonceVisual")
		if not _has_mesh(visual) or _has_collision(visual):
			_fail("Modèle de roncier manquant ou collision supplémentaire")
			return
		var shape: CylinderShape3D = _direct_collision(ronce.get_node("RonceCollision")).shape
		if absf(shape.radius - 1.0) > 0.001 or absf(shape.height - 1.4) > 0.001:
			_fail("Collision d'un roncier modifiée")
			return
		if absf(_direct_collision(ronce).shape.radius - 2.0) > 0.001:
			_fail("Portée d'interaction d'un roncier modifiée")
			return
		var berries: Array = ronce.get("_berry_meshes")
		if berries.size() != ronce.get("berries"):
			_fail("Nombre de mûres visuelles incorrect")
			return
		for berry in berries:
			if not _berry_touches_bush(berry.position, ronce, visual):
				_fail("Mûre détachée de la surface du roncier")
				return
	var first_ronce: Area3D = ronces[0]
	var berries_before: int = first_ronce.get("berries")
	if berries_before < 1 or not first_ronce.harvest_one() or first_ronce.get("berries") != berries_before - 1:
		_fail("Cueillette d'un roncier altérée")
		return

	print("Observatoire : décor chargé, collisions d'arbres désactivées")
	quit(0)

func _has_mesh(node: Node) -> bool:
	if node is MeshInstance3D and node.mesh != null:
		return true
	for child in node.get_children():
		if _has_mesh(child):
			return true
	return false

func _direct_collision(node: Node) -> CollisionShape3D:
	for child in node.get_children():
		if child is CollisionShape3D:
			return child
	return null

func _has_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _has_collision(child):
			return true
	return false

func _berry_touches_bush(position: Vector3, ronce: Area3D, visual: Node3D) -> bool:
	for mesh_node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = mesh_node
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for triangle_index in range(0, indices.size(), 3):
				var a: Vector3 = ronce.to_local(mesh_instance.to_global(vertices[indices[triangle_index]]))
				var b: Vector3 = ronce.to_local(mesh_instance.to_global(vertices[indices[triangle_index + 1]]))
				var c: Vector3 = ronce.to_local(mesh_instance.to_global(vertices[indices[triangle_index + 2]]))
				if _projected_triangle_distance(position, a, b, c) <= 0.05:
					return true
	return false

func _projected_triangle_distance(point: Vector3, a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab := b - a
	var ac := c - a
	var normal := ab.cross(ac)
	var normal_length_squared := normal.length_squared()
	if normal_length_squared < 0.000001:
		return INF
	var projected := point - normal * ((point - a).dot(normal) / normal_length_squared)
	var ap := projected - a
	var d00 := ab.dot(ab)
	var d01 := ab.dot(ac)
	var d11 := ac.dot(ac)
	var d20 := ap.dot(ab)
	var d21 := ap.dot(ac)
	var denominator := d00 * d11 - d01 * d01
	if absf(denominator) < 0.000001:
		return INF
	var v := (d11 * d20 - d01 * d21) / denominator
	var w := (d00 * d21 - d01 * d20) / denominator
	if v < -0.001 or w < -0.001 or v + w > 1.001:
		return INF
	return point.distance_to(projected)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
