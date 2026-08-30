extends Area3D

var berries: int = 3
var solid_body: StaticBody3D = null

var _berry_meshes: Array = []

## La cueillette ne se limite pas à l'instant d'entrée dans la zone : sans reprise
## continue, un agent qui cueille une mûre puis reste au contact (buisson pas encore
## vide, inventaire pas encore plein) n'a plus jamais l'occasion de récolter le reste et
## se fige sur place. `_on_ronce_contact` est idempotent au-delà des seuils autorisés
## (character.gd::try_pick_berry_from_ronce), donc l'appeler à chaque frame de contact
## est sans effet une fois le buisson vide ou l'inventaire plein. Remplace le signal
## body_entered (déclenché une seule fois) pour éviter aussi un double appel la frame
## où le corps entre dans la zone.
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.has_method("_on_ronce_contact"):
			body._on_ronce_contact(self)

func setup_visual(berry_positions: Array, berry_mat: StandardMaterial3D) -> void:
	var berry_container := Node3D.new()
	add_child(berry_container)
	for pos in berry_positions:
		var berry := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.09
		sphere.height = 0.18
		sphere.radial_segments = 6
		sphere.rings = 4
		berry.mesh = sphere
		berry.material_override = berry_mat
		berry.position = pos
		berry_container.add_child(berry)
		_berry_meshes.append(berry)

func harvest_one() -> bool:
	if berries <= 0:
		return false
	berries -= 1
	if not _berry_meshes.is_empty():
		var removed: MeshInstance3D = _berry_meshes.pop_back()
		removed.queue_free()
	return true

func get_perception_type() -> String:
	return "roncier"

func get_perception_state() -> Dictionary:
	return {"has_berries": berries > 0}

func get_occlusion_exclude_rids() -> Array:
	return [solid_body.get_rid()] if solid_body != null else []
