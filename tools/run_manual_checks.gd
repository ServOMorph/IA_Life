extends Node

# Vérifications automatisées pour les anciens tests manuels trop coûteux à reproduire.
# Usage : python tools/run_manual_checks.py

class TestRonce:
	extends Node3D

	var berries := 1

	func harvest_one() -> bool:
		if berries <= 0:
			return false
		berries -= 1
		return true

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_game_data_settings()
	_test_manual_berry_harvest()
	_test_memory_navigation()
	_test_memory_decay()
	_test_memory_replacement()
	_test_memory_slider()
	if _failures.is_empty():
		print("SUCCÈS : tests manuels 6, 8, 9, 10 et 11 validés automatiquement.")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _make_character() -> CharacterBody3D:
	var character := CharacterBody3D.new()
	character.set_script(load("res://scripts/character.gd"))
	get_tree().root.add_child(character)
	return character

func _test_game_data_settings() -> void:
	var saved := {
		"max_berries_carried": GameConfig.max_berries_carried,
		"pickup_hunger_threshold": GameConfig.pickup_hunger_threshold,
		"eat_hunger_threshold": GameConfig.eat_hunger_threshold,
		"ronce_count": GameConfig.ronce_count,
		"berries_per_ronce": GameConfig.berries_per_ronce,
	}
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)

	# Les seuils et la capacité sont lus au moment de l'action, sans redémarrage.
	character.hunger = 80.0
	GameConfig.pickup_hunger_threshold = 70.0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 0, "Test 6 : la cueillette a ignoré le seuil immédiat.")
	GameConfig.pickup_hunger_threshold = 90.0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 1, "Test 6 : le nouveau seuil de cueillette n'est pas appliqué immédiatement.")

	character.berries_carried = 0
	ronce.berries = 1
	GameConfig.max_berries_carried = 0
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 0, "Test 6 : la capacité maximale immédiate est ignorée.")
	GameConfig.max_berries_carried = 1
	character._on_ronce_contact(ronce)
	_expect(character.berries_carried == 1, "Test 6 : la nouvelle capacité maximale n'est pas appliquée immédiatement.")

	character.hunger = 60.0
	GameConfig.eat_hunger_threshold = 50.0
	character._try_eat_berry()
	_expect(character.berries_carried == 1, "Test 6 : le personnage mange malgré un seuil de consommation trop bas.")
	GameConfig.eat_hunger_threshold = 70.0
	character._try_eat_berry()
	_expect(character.berries_carried == 0, "Test 6 : le nouveau seuil de consommation n'est pas appliqué immédiatement.")

	# Les paramètres de génération ne changent que la prochaine génération de ronces.
	var main: Node3D = load("res://scenes/Main.tscn").instantiate()
	GameConfig.ronce_count = 3
	GameConfig.berries_per_ronce = 2
	get_tree().root.add_child(main)
	_expect(main._ronces.size() == 3, "Test 6 : le nombre initial de ronciers est incorrect.")
	GameConfig.ronce_count = 5
	GameConfig.berries_per_ronce = 4
	_expect(main._ronces.size() == 3, "Test 6 : le nombre de ronciers change sans Relancer.")
	for spawned_ronce in main._ronces:
		_expect(spawned_ronce.berries == 2, "Test 6 : les mûres d'un roncier existant changent sans Relancer.")
	main.free()
	var restarted_main: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(restarted_main)
	_expect(restarted_main._ronces.size() == 5, "Test 6 : Relancer n'applique pas le nouveau nombre de ronciers.")
	for spawned_ronce in restarted_main._ronces:
		_expect(spawned_ronce.berries == 4, "Test 6 : Relancer n'applique pas le nouveau nombre de mûres.")
	restarted_main.queue_free()
	character.queue_free()
	ronce.queue_free()
	for key in saved:
		GameConfig.set(key, saved[key])

func _test_memory_replacement() -> void:
	var character := _make_character()
	character.memory_capacity = 5
	var ronciers: Array[TestRonce] = []
	for i in 6:
		var ronce := TestRonce.new()
		ronciers.append(ronce)
		get_tree().root.add_child(ronce)
		character._remember_ronce(ronce)
	if character._memories.size() >= 5:
		character._memories[0].strength = 1.0
		for i in range(1, character._memories.size()):
			character._memories[i].strength = float(i + 1)
		character._remember_ronce(ronciers[5])
	_expect(character.memorized_ronces_count() == 5, "Test 10 : la mémoire dépasse sa capacité.")
	var contains_weakest := false
	var contains_new := false
	for memory in character._memories:
		contains_weakest = contains_weakest or memory.ronce == ronciers[0]
		contains_new = contains_new or memory.ronce == ronciers[5]
	_expect(not contains_weakest, "Test 10 : le souvenir le plus faible n'a pas été remplacé.")
	_expect(contains_new, "Test 10 : le nouveau roncier n'a pas été mémorisé.")
	character.queue_free()
	for ronce in ronciers:
		ronce.queue_free()

func _test_memory_navigation() -> void:
	var saved_threshold := GameConfig.pickup_hunger_threshold
	var character := _make_character()
	var ronce := TestRonce.new()
	ronce.position = Vector3(10.0, 0.0, 0.0)
	get_tree().root.add_child(ronce)
	character.position = Vector3.ZERO
	character.hunger = 95.0
	character.manual_control = false
	GameConfig.pickup_hunger_threshold = 90.0
	character._remember_ronce(ronce)
	character._physics_process(0.0)
	_expect(character._direction.is_equal_approx(Vector3.RIGHT), "Test 8 : le personnage ne cible pas le roncier mémorisé le plus proche.")
	GameConfig.pickup_hunger_threshold = saved_threshold
	character.queue_free()
	ronce.queue_free()

func _test_manual_berry_harvest() -> void:
	var saved_max := GameConfig.max_berries_carried
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)
	GameConfig.max_berries_carried = 1
	character.hunger = 100.0
	_expect(character.try_pick_berry_from_ronce(ronce, true), "Interaction E : le ramassage manuel échoue près d'un roncier plein.")
	_expect(character.berries_carried == 1, "Interaction E : la mûre ramassée n'est pas ajoutée à l'inventaire.")
	GameConfig.max_berries_carried = saved_max
	character.queue_free()
	ronce.queue_free()

func _test_memory_decay() -> void:
	var character := _make_character()
	var ronce := TestRonce.new()
	get_tree().root.add_child(ronce)
	character.memory_decay_rate = 1.0
	character._remember_ronce(ronce)
	character._decay_memories(9.9)
	_expect(character.memorized_ronces_count() == 1, "Test 9 : un souvenir disparaît avant d'atteindre une force nulle.")
	character._decay_memories(0.2)
	_expect(character.memorized_ronces_count() == 0, "Test 9 : un souvenir à force nulle ne disparaît pas.")
	character.queue_free()
	ronce.queue_free()

func _find_memory_slider(node: Node) -> HSlider:
	if node is HBoxContainer and node.get_child_count() >= 2:
		var label := node.get_child(0) as Label
		var slider := node.get_child(1) as HSlider
		if label != null and label.text == "Mémoire" and slider != null:
			return slider
	for child in node.get_children():
		var result := _find_memory_slider(child)
		if result != null:
			return result
	return null

func _test_memory_slider() -> void:
	var character := _make_character()
	var camera := Camera3D.new()
	get_tree().root.add_child(camera)
	var ui := CanvasLayer.new()
	ui.set_script(load("res://scripts/ui_manager.gd"))
	get_tree().root.add_child(ui)
	ui.setup([{
		"node": character,
		"name": "Test",
		"color": Color.WHITE,
		"corner": "top_left",
	}], camera, true)
	ui.set_test_character(character)
	var slider := _find_memory_slider(ui)
	_expect(slider != null, "Test 11 : le slider Mémoire est introuvable.")
	if slider != null:
		slider.value = 2
		_expect(character.memory_capacity == 2, "Test 11 : le slider Mémoire ne modifie pas la capacité.")
		var ronciers: Array[TestRonce] = []
		for i in 3:
			var ronce := TestRonce.new()
			ronciers.append(ronce)
			get_tree().root.add_child(ronce)
			character._remember_ronce(ronce)
		_expect(character.memorized_ronces_count() == 2, "Test 11 : la capacité de mémoire choisie par le slider n'est pas respectée.")
		for ronce in ronciers:
			ronce.queue_free()
	ui.queue_free()
	camera.queue_free()
	character.queue_free()
