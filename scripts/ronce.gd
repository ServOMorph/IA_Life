extends Area3D

var berries: int = 3

var _mesh: MeshInstance3D
var _full_mat: StandardMaterial3D
var _empty_mat: StandardMaterial3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()

func setup_visual(mesh: MeshInstance3D, full_mat: StandardMaterial3D, empty_mat: StandardMaterial3D) -> void:
	_mesh = mesh
	_full_mat = full_mat
	_empty_mat = empty_mat
	_update_visual()

func _on_body_entered(body: Node) -> void:
	if body.has_method("_on_ronce_contact"):
		body._on_ronce_contact(self)

func harvest_one() -> bool:
	if berries <= 0:
		return false
	berries -= 1
	_update_visual()
	return true

func _update_visual() -> void:
	if _mesh == null:
		return
	_mesh.material_override = _full_mat if berries > 0 else _empty_mat
