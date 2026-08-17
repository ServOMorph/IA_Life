extends Node3D

const MAP_SIZE := 160.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 1.0
const HEADLESS_ENV_VAR := "IA_LIFE_HEADLESS_CONFIG"

var _character_defaults: Dictionary = {}
var _quit_on_all_dead: bool = false
var _max_wall_seconds: float = 0.0
var _wall_clock: float = 0.0
var _characters: Array = []

func _ready() -> void:
	_load_headless_overrides()
	_build_environment()
	_build_light()
	_build_floor()
	_build_walls()
	var camera := _build_camera()
	var characters := [
		_spawn_character(Vector3(-40, 1, -40), Color(0.8, 0.2, 0.2), "Rouge", "top_left"),
		_spawn_character(Vector3(40, 1, -40), Color(0.2, 0.4, 0.8), "Bleu", "top_right"),
		_spawn_character(Vector3(-40, 1, 40), Color(0.2, 0.7, 0.3), "Vert", "bottom_left"),
		_spawn_character(Vector3(40, 1, 40), Color(0.9, 0.7, 0.1), "Jaune", "bottom_right"),
	]
	_spawn_ronces()
	_build_ui(characters, camera)
	for c in characters:
		_characters.append(c.node)

func _process(delta: float) -> void:
	if _quit_on_all_dead and _characters.size() > 0:
		var all_dead := true
		for c in _characters:
			if not c.get("is_dead"):
				all_dead = false
				break
		if all_dead:
			GameLogger.log_event("headless", "Tous les personnages sont morts — arrêt automatique")
			get_tree().quit()
			return

	if _max_wall_seconds > 0.0:
		_wall_clock += delta
		if _wall_clock >= _max_wall_seconds:
			GameLogger.log_event("headless", "Timeout atteint (%.0fs) — arrêt automatique" % _max_wall_seconds)
			get_tree().quit()

func _load_headless_overrides() -> void:
	var path := OS.get_environment(HEADLESS_ENV_VAR)
	if path == "":
		return
	if not FileAccess.file_exists(path):
		GameLogger.log_event("headless", "Fichier de config introuvable: %s" % path)
		return

	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		GameLogger.log_event("headless", "Config JSON invalide dans %s" % path)
		return

	if parsed.has("game_config"):
		GameConfig.apply_overrides(parsed["game_config"])
	if parsed.has("game_speed"):
		GameSpeed.time_scale = float(parsed["game_speed"])
	if parsed.has("character_defaults"):
		_character_defaults = parsed["character_defaults"]

	_quit_on_all_dead = parsed.get("quit_on_all_dead", true)
	_max_wall_seconds = float(parsed.get("max_wall_seconds", 120.0))
	GameLogger.log_event("headless", "Overrides appliqués depuis %s : %s" % [path, JSON.stringify(parsed)])

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.3, 0.5, 0.75)
	sky_material.sky_horizon_color = Color(0.85, 0.6, 0.4)
	sky_material.ground_bottom_color = Color(0.2, 0.16, 0.12)
	sky_material.ground_horizon_color = Color(0.85, 0.6, 0.4)
	sky_material.sun_angle_max = 30.0

	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.ssao_enabled = true
	env.ssr_enabled = true

	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.1

	env.tonemap_mode = Environment.TONE_MAPPER_ACES

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	get_viewport().use_taa = true

func _build_light() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_color = Color(1.0, 0.88, 0.68)
	light.light_energy = 1.2
	light.shadow_enabled = true
	light.light_angular_distance = 1.5
	add_child(light)

func _build_triplanar_material(dir: String, scale: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/triplanar.gdshader")
	mat.set_shader_parameter("albedo_tex", load("res://assets/textures/%s/diffuse_1k.jpg" % dir))
	mat.set_shader_parameter("normal_tex", load("res://assets/textures/%s/nor_gl_1k.jpg" % dir))
	mat.set_shader_parameter("arm_tex", load("res://assets/textures/%s/arm_1k.jpg" % dir))
	mat.set_shader_parameter("texture_scale", scale)
	return mat

func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _build_triplanar_material("leafy_grass", 0.25)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	collision.shape = shape
	body.add_child(collision)

	body.position = Vector3(0, -0.5, 0)
	add_child(body)

func _build_walls() -> void:
	var half := MAP_SIZE / 2.0
	_add_wall(Vector3(0, WALL_HEIGHT / 2.0, -half), Vector3(MAP_SIZE + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(Vector3(0, WALL_HEIGHT / 2.0, half), Vector3(MAP_SIZE + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(Vector3(-half, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, MAP_SIZE + WALL_THICKNESS))
	_add_wall(Vector3(half, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, MAP_SIZE + WALL_THICKNESS))

func _add_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Wall"

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _build_triplanar_material("brick_wall_001", 0.5)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	body.position = pos
	add_child(body)

func _build_camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.set_script(load("res://scripts/free_camera.gd"))
	camera.current = true
	add_child(camera)
	return camera

func _build_ui(characters: Array, camera: Camera3D) -> void:
	var ui := CanvasLayer.new()
	ui.set_script(load("res://scripts/ui_manager.gd"))
	add_child(ui)
	ui.setup(characters, camera)

func _spawn_character(spawn_pos: Vector3, color: Color, char_name: String, corner: String) -> Dictionary:
	var character := CharacterBody3D.new()
	character.set_script(load("res://scripts/character.gd"))
	character.position = spawn_pos
	character.set("display_name", char_name)
	var half := MAP_SIZE / 2.0 - WALL_THICKNESS / 2.0 - 0.4
	character.set("map_half_x", half)
	character.set("map_half_z", half)
	for key in _character_defaults:
		character.set(key, _character_defaults[key])

	var body_mesh := MeshInstance3D.new()
	var body_shape_mesh := BoxMesh.new()
	body_shape_mesh.size = Vector3(0.6, 1.0, 0.4)
	body_mesh.mesh = body_shape_mesh
	body_mesh.position = Vector3(0, 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	body_mesh.material_override = mat
	character.add_child(body_mesh)

	var head_mesh := MeshInstance3D.new()
	var head_shape_mesh := BoxMesh.new()
	head_shape_mesh.size = Vector3(0.4, 0.4, 0.4)
	head_mesh.mesh = head_shape_mesh
	head_mesh.position = Vector3(0, 1.2, 0)
	head_mesh.material_override = mat
	character.add_child(head_mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.4
	collision.shape = shape
	collision.position = Vector3(0, 0.7, 0)
	character.add_child(collision)

	add_child(character)
	character.setup_visual(body_mesh, head_mesh)

	return {
		"node": character,
		"name": char_name,
		"color": color,
		"corner": corner,
	}

func _spawn_ronces() -> void:
	var quadrant_half := MAP_SIZE / 2.0 - WALL_THICKNESS - 2.0
	var quadrants := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	var per_quadrant := GameConfig.ronce_count / 4
	var remainder := GameConfig.ronce_count % 4
	for i in quadrants.size():
		var sign_vec: Vector2 = quadrants[i]
		var count := per_quadrant + (1 if i < remainder else 0)
		for j in count:
			var x := randf_range(0.0, quadrant_half) * sign_vec.x
			var z := randf_range(0.0, quadrant_half) * sign_vec.y
			_spawn_ronce(Vector3(x, 0.5, z))

func _build_bush_mesh() -> ArrayMesh:
	var lobes := [
		{"pos": Vector3(0, 0.4, 0), "radius": 1.0, "height": 1.4},
		{"pos": Vector3(0.7, 0.6, 0.3), "radius": 0.6, "height": 0.85},
		{"pos": Vector3(-0.6, 0.55, -0.4), "radius": 0.65, "height": 0.9},
		{"pos": Vector3(0.1, 0.9, -0.6), "radius": 0.55, "height": 0.75},
		{"pos": Vector3(-0.4, 0.85, 0.6), "radius": 0.5, "height": 0.7},
	]
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lobe in lobes:
		var sphere := SphereMesh.new()
		sphere.radius = lobe["radius"]
		sphere.height = lobe["height"]
		sphere.radial_segments = 8
		sphere.rings = 5
		var transform := Transform3D(Basis(), lobe["pos"])
		surface_tool.append_from(sphere, 0, transform)
	return surface_tool.commit()

func _spawn_ronce(pos: Vector3) -> void:
	var ronce := Area3D.new()
	ronce.name = "Ronce"
	ronce.set_script(load("res://scripts/ronce.gd"))
	ronce.berries = GameConfig.berries_per_ronce
	ronce.position = pos

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_bush_mesh()
	ronce.add_child(mesh_instance)

	var full_mat := StandardMaterial3D.new()
	full_mat.albedo_color = Color(0.25, 0.15, 0.35)
	var empty_mat := StandardMaterial3D.new()
	empty_mat.albedo_color = Color(0.3, 0.3, 0.25)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.0
	collision.shape = shape
	ronce.add_child(collision)

	var solid_body := StaticBody3D.new()
	solid_body.name = "RonceCollision"
	var solid_collision := CollisionShape3D.new()
	var solid_shape := CylinderShape3D.new()
	solid_shape.radius = 1.0
	solid_shape.height = 1.4
	solid_collision.shape = solid_shape
	solid_collision.position = Vector3(0, 0.7, 0)
	solid_body.add_child(solid_collision)
	ronce.add_child(solid_body)

	add_child(ronce)
	ronce.setup_visual(mesh_instance, full_mat, empty_mat)
