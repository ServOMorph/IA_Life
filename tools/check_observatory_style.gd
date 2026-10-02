extends SceneTree

const ObservatoryStyle = preload("res://scripts/observatory_style.gd")

func _init() -> void:
	await process_frame
	var colors := [
		ObservatoryStyle.RED,
		ObservatoryStyle.BLUE,
		ObservatoryStyle.GREEN,
		ObservatoryStyle.YELLOW,
	]
	var names := ["Rouge", "Bleu", "Vert", "Jaune"]
	var symbols := {}
	for index in names.size():
		var symbol: String = ObservatoryStyle.agent_symbol(names[index])
		if symbol.is_empty() or symbols.has(symbol):
			push_error("Repère d'agent manquant ou dupliqué : %s" % names[index])
			quit(1)
			return
		symbols[symbol] = true
		for previous in range(index):
			if colors[index] == colors[previous]:
				push_error("Couleur d'agent dupliquée")
				quit(1)
				return

	var theme: Theme = ObservatoryStyle.make_theme()
	if theme.default_font == null or theme.get_stylebox("panel", "PanelContainer") == null:
		push_error("Thème Observatoire incomplet")
		quit(1)
		return
	if theme.get_stylebox("fill", "ProgressBar") == null:
		push_error("Jauge de faim sans style")
		quit(1)
		return

	var scene: Node3D = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var ui = scene.get("_ui")
	var entries: Array = ui.get("_entries")
	if entries.size() != 4:
		push_error("Nombre d'agents inattendu dans l'interface")
		quit(1)
		return
	var entry: Dictionary = entries[0]
	var agent: CharacterBody3D = entry["node"]
	var marker: Label3D = agent.get_node("LocatorMarker")
	if not marker.text.begins_with(ObservatoryStyle.agent_symbol("Rouge")):
		push_error("Repère 3D absent")
		quit(1)
		return

	agent.set("hunger", 31.0)
	ui._update_panel_texts(entry)
	if entry["hunger_bar"].value != 31.0 or not entry["hunger_label"].text.contains("31"):
		push_error("Affichage de la faim incorrect")
		quit(1)
		return

	var zone = load("res://scripts/danger_zone.gd").new()
	zone.radius = 4.0
	scene.add_child(zone)
	zone.global_position = agent.global_position
	zone.add_to_group("danger_zone")
	ui._update_panel_texts(entry)
	if not entry["danger_label"].visible:
		push_error("Alerte de danger absente")
		quit(1)
		return
	zone.remove_from_group("danger_zone")
	ui._update_panel_texts(entry)
	if entry["danger_label"].visible:
		push_error("Alerte de danger persistante")
		quit(1)
		return

	agent.set("is_dead", true)
	ui._update_panel_texts(entry)
	if not entry["dead_label"].visible or entry["hunger_bar"].visible:
		push_error("État de mort incorrect")
		quit(1)
		return
	print("Observatoire : palette, polices, repères et états UI validés")
	quit(0)
