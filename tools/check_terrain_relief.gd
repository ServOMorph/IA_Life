extends SceneTree

func _init() -> void:
	await process_frame
	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var floor_body: StaticBody3D = scene.get_node("Floor")
	var mesh_instance: MeshInstance3D
	var collision: CollisionShape3D
	for child in floor_body.get_children():
		if child is MeshInstance3D:
			mesh_instance = child
		elif child is CollisionShape3D:
			collision = child
	if mesh_instance == null or collision == null or collision.shape is not HeightMapShape3D:
		_fail("Sol visuel ou collision absent")
		return
	var vertices: PackedVector3Array = mesh_instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var heights: PackedFloat32Array = collision.shape.map_data
	if vertices.size() != 161 * 161 or heights.size() != vertices.size():
		_fail("Résolution du sol inattendue")
		return
	var replica: Node3D = scene.get_script().new()
	replica._init_terrain_noise()
	var min_height := INF
	var max_height := -INF
	var max_grade := 0.0
	var varied_cells := 0
	for vertex in vertices:
		var xi := roundi(vertex.x + 80.0)
		var zi := roundi(vertex.z + 80.0)
		var height: float = heights[zi * 161 + xi]
		if absf(vertex.y - height) > 0.0001 or absf(scene._terrain_height(vertex.x, vertex.z) - height) > 0.0001:
			replica.free()
			_fail("Sol visible et collision désalignés")
			return
		if absf(replica._terrain_height(vertex.x, vertex.z) - height) > 0.0001:
			replica.free()
			_fail("Relief non déterministe à seed identique")
			return
	for index in heights.size():
		var height: float = heights[index]
		min_height = minf(min_height, height)
		max_height = maxf(max_height, height)
		if index % 161 == 0 or index % 161 == 160 or index < 161 or index >= 161 * 160:
			if absf(height) > 0.0001:
				replica.free()
				_fail("Le bord du terrain ne rejoint plus les murs")
				return
		if index % 161 < 160 and index < 161 * 160:
			var dx: float = heights[index + 1] - height
			var dz: float = heights[index + 161] - height
			var grade := Vector2(dx, dz).length()
			max_grade = maxf(max_grade, grade)
			if grade > 0.12:
				varied_cells += 1
	for point in [Vector2(-40, -40), Vector2(40, -40), Vector2(-40, 40), Vector2(40, 40)]:
		for offset in [Vector2.ZERO, Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
			var location: Vector2 = point + offset
			if absf(scene._terrain_height(location.x, location.y)) > 1.0:
				replica.free()
				_fail("Départ trop accidenté")
				return
	if max_height - min_height < 2.5 or max_grade > 0.95 or varied_cells < 100:
		replica.free()
		_fail("Relief trop plat ou pente excessive : amplitude %.2f, pente %.2f, cellules variées %d" % [max_height - min_height, max_grade, varied_cells])
		return
	for test_seed in [42, 1338, 2026]:
		replica.set("_experiment_seed", test_seed)
		replica._init_terrain_noise()
		var seed_max_grade := 0.0
		for zi in range(0, 160, 2):
			for xi in range(0, 160, 2):
				var x := float(xi) - 80.0
				var z := float(zi) - 80.0
				var h: float = replica._terrain_height(x, z)
				var dx: float = (replica._terrain_height(x + 2.0, z) - h) / 2.0
				var dz: float = (replica._terrain_height(x, z + 2.0) - h) / 2.0
				seed_max_grade = maxf(seed_max_grade, Vector2(dx, dz).length())
		if seed_max_grade > 1.0:
			replica.free()
			_fail("Pente excessive à la seed %d : %.2f" % [test_seed, seed_max_grade])
			return
	print("Relief validé : amplitude %.2f m, pente max %.2f, cellules variées %d" % [max_height - min_height, max_grade, varied_cells])
	replica.free()
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
