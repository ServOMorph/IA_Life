extends Node3D

const MAP_SIZE := 160.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 1.0

func _ready() -> void:
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
	_build_ui(characters, camera)

func _build_light() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.shadow_enabled = true
	add_child(light)

func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.3)
	mesh_instance.material_override = mat
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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.55)
	mesh_instance.material_override = mat
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
	camera.position = Vector3(0, 60, 80)
	camera.rotation_degrees = Vector3(-30, 0, 0)
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
	var half := MAP_SIZE / 2.0 - WALL_THICKNESS / 2.0 - 0.4
	character.set("map_half_x", half)
	character.set("map_half_z", half)

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

	return {
		"node": character,
		"name": char_name,
		"color": color,
		"corner": corner,
	}
