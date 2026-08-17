extends CanvasLayer

const MENU_HEIGHT := 56.0
const MARGIN := 10.0
const SPEED_MIN := 0.5
const SPEED_MAX := 10.0
const ZONE_MIN := 5.0
const ZONE_MAX := 80.0
const GAME_SPEED_MIN := 0.1
const GAME_SPEED_MAX := 50.0
const AGING_MIN := 0.1
const AGING_MAX := 5.0
const FEEDING_MIN := 0.1
const FEEDING_MAX := 3.0
const MEMORY_MIN := 0
const MEMORY_MAX := 10
const PICKUP_THRESHOLD_MIN := 0.0
const PICKUP_THRESHOLD_MAX := 100.0
const EAT_THRESHOLD_MIN := 0.0
const EAT_THRESHOLD_MAX := 100.0
const MAX_BERRIES_MIN := 1
const MAX_BERRIES_MAX := 10
const FULL_LIFE_BERRIES_MIN := 1.0
const FULL_LIFE_BERRIES_MAX := 20.0

var _root: Control
var _menu_bar: HBoxContainer
var _entries: Array = []
var _camera: Camera3D
var _game_data_panel: PanelContainer = null

func setup(characters: Array, camera: Camera3D) -> void:
	_camera = camera
	_entries = []
	_build_root()
	_build_menu_bar()
	for info in characters:
		_entries.append({
			"node": info.node,
			"name": info.name,
			"color": info.color,
			"corner": info.corner,
			"panel": null,
		})
	for entry in _entries:
		_add_menu_button(entry)
		entry.panel = _build_character_panel(entry)
		_root.add_child(entry.panel)

func _build_root() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

func _build_menu_bar() -> void:
	var bar_panel := PanelContainer.new()
	bar_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_panel.custom_minimum_size = Vector2(0, MENU_HEIGHT)
	bar_panel.position.y -= MENU_HEIGHT
	_root.add_child(bar_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	bar_panel.add_child(row)

	row.add_child(_build_game_speed_control())

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_menu_bar = HBoxContainer.new()
	_menu_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu_bar.add_theme_constant_override("separation", 20)
	row.add_child(_menu_bar)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer2)

	row.add_child(_build_game_data_button())
	row.add_child(_build_large_view_button())
	row.add_child(_build_reset_button())

func _build_reset_button() -> Button:
	var button := Button.new()
	button.text = "Relancer"
	button.pressed.connect(_on_reset_pressed)
	return button

func _on_reset_pressed() -> void:
	GameSpeed.time_scale = 1.0
	GameLogger.start_session()
	get_tree().reload_current_scene()

func _build_large_view_button() -> Button:
	var button := Button.new()
	button.text = "Large"
	button.pressed.connect(_on_large_view_pressed)
	return button

func _on_large_view_pressed() -> void:
	_camera.reset_view()
	GameLogger.log_event("camera", "Retour plan large")

func _build_game_data_button() -> Button:
	var button := Button.new()
	button.text = "Données du jeu"
	button.pressed.connect(_on_game_data_pressed)
	return button

func _on_game_data_pressed() -> void:
	if _game_data_panel != null:
		_game_data_panel.queue_free()
		_game_data_panel = null
		return
	_game_data_panel = _build_game_data_panel()
	_root.add_child(_game_data_panel)

func _build_slider_row(label_text: String, min_v: float, max_v: float, step: float, value: float, on_change: Callable, decimals: int = 2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(160, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(140, 0)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%.*f" % [decimals, value]
	value_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(value_label)

	slider.value_changed.connect(func(v: float) -> void:
		on_change.call(v)
		value_label.text = "%.*f" % [decimals, v]
		GameLogger.log_event("config", "%s -> %.*f" % [label_text, decimals, v])
	)

	return row

func _build_game_data_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Données du jeu"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	vbox.add_child(_build_slider_row("Mûres max portées", MAX_BERRIES_MIN, MAX_BERRIES_MAX, 1, GameConfig.max_berries_carried, func(v: float) -> void:
		GameConfig.max_berries_carried = int(v)
	, 0))
	vbox.add_child(_build_slider_row("Seuil cueillette (faim)", PICKUP_THRESHOLD_MIN, PICKUP_THRESHOLD_MAX, 1, GameConfig.pickup_hunger_threshold, func(v: float) -> void:
		GameConfig.pickup_hunger_threshold = v
	, 0))
	vbox.add_child(_build_slider_row("Seuil consommation (faim)", EAT_THRESHOLD_MIN, EAT_THRESHOLD_MAX, 1, GameConfig.eat_hunger_threshold, func(v: float) -> void:
		GameConfig.eat_hunger_threshold = v
	, 0))
	vbox.add_child(_build_slider_row("Mûres pour vie complète", FULL_LIFE_BERRIES_MIN, FULL_LIFE_BERRIES_MAX, 1, GameConfig.full_life_berries, func(v: float) -> void:
		GameConfig.full_life_berries = v
	, 0))

	vbox.add_child(HSeparator.new())
	var note := Label.new()
	note.text = "Nombre de ronces et mûres/ronce : appliqué au prochain Relancer."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(note)

	vbox.add_child(_build_slider_row("Nombre de ronces", 1, 30, 1, GameConfig.ronce_count, func(v: float) -> void:
		GameConfig.ronce_count = int(v)
	, 0))
	vbox.add_child(_build_slider_row("Mûres par ronce", 1, 10, 1, GameConfig.berries_per_ronce, func(v: float) -> void:
		GameConfig.berries_per_ronce = int(v)
	, 0))

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(_on_game_data_pressed)
	vbox.add_child(close_button)

	return panel

func _build_game_speed_control() -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "Vitesse jeu"
	box.add_child(label)

	var slider := HSlider.new()
	slider.min_value = GAME_SPEED_MIN
	slider.max_value = GAME_SPEED_MAX
	slider.step = 0.05
	slider.value = GameSpeed.time_scale
	slider.custom_minimum_size = Vector2(140, 0)
	box.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%.2fx" % GameSpeed.time_scale
	value_label.custom_minimum_size = Vector2(50, 0)
	box.add_child(value_label)

	slider.value_changed.connect(func(v: float) -> void:
		GameSpeed.time_scale = v
		value_label.text = "%.2fx" % v
		GameLogger.log_event("config", "Vitesse jeu -> %.2fx" % v)
	)

	return box

func _add_menu_button(entry: Dictionary) -> void:
	var button := Button.new()
	button.text = entry.name
	button.add_theme_color_override("font_color", entry.color)
	button.add_theme_color_override("font_hover_color", entry.color)
	button.add_theme_color_override("font_pressed_color", entry.color)
	button.pressed.connect(_on_character_button_pressed.bind(entry))
	_menu_bar.add_child(button)

func _on_character_button_pressed(entry: Dictionary) -> void:
	var result: String = _camera.toggle_character(entry.node)
	match result:
		"follow":
			GameLogger.log_event("camera", "Suivi 3e personne de %s" % entry.name)
		"fps":
			GameLogger.log_event("camera", "Vue 1re personne de %s" % entry.name)
		"restored":
			GameLogger.log_event("camera", "Retour à la caméra précédente")

func _build_collapsible_section(title_text: String, content: Control, expanded: bool = true) -> VBoxContainer:
	var section := VBoxContainer.new()

	var header := Button.new()
	header.flat = true
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.text = ("▼ " if expanded else "▶ ") + title_text
	section.add_child(header)

	content.visible = expanded
	section.add_child(content)

	header.pressed.connect(func() -> void:
		content.visible = not content.visible
		header.text = ("▼ " if content.visible else "▶ ") + title_text
	)

	return section

func _build_character_panel(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)

	var outer_vbox := VBoxContainer.new()
	panel.add_child(outer_vbox)

	var title := Label.new()
	title.text = entry.name
	title.add_theme_color_override("font_color", entry.color)
	outer_vbox.add_child(title)

	var dead_label := Label.new()
	dead_label.text = "DEAD"
	dead_label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	dead_label.add_theme_font_size_override("font_size", 28)
	dead_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_label.visible = false
	outer_vbox.add_child(dead_label)

	var live_vbox := VBoxContainer.new()
	outer_vbox.add_child(live_vbox)

	var etat_content := VBoxContainer.new()

	var pos_label := Label.new()
	etat_content.add_child(pos_label)

	var speed_label := Label.new()
	etat_content.add_child(speed_label)

	var zone_label := Label.new()
	etat_content.add_child(zone_label)

	var berries_label := Label.new()
	etat_content.add_child(berries_label)

	etat_content.visible = false
	live_vbox.add_child(etat_content)

	var reglages_content := VBoxContainer.new()

	var speed_row := HBoxContainer.new()
	var speed_row_label := Label.new()
	speed_row_label.text = "Vitesse"
	var speed_slider := HSlider.new()
	speed_slider.min_value = SPEED_MIN
	speed_slider.max_value = SPEED_MAX
	speed_slider.step = 0.1
	speed_slider.custom_minimum_size = Vector2(120, 0)
	speed_slider.value = entry.node.get("move_speed")
	speed_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("move_speed", v)
		GameLogger.log_event("config", "%s vitesse -> %.1f" % [entry.name, v])
	)
	speed_row.add_child(speed_row_label)
	speed_row.add_child(speed_slider)
	reglages_content.add_child(speed_row)

	var zone_row := HBoxContainer.new()
	var zone_row_label := Label.new()
	zone_row_label.text = "Exploration"
	var zone_slider := HSlider.new()
	zone_slider.min_value = ZONE_MIN
	zone_slider.max_value = ZONE_MAX
	zone_slider.step = 1.0
	zone_slider.custom_minimum_size = Vector2(120, 0)
	zone_slider.value = entry.node.get("map_half_x")
	zone_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("map_half_x", v)
		entry.node.set("map_half_z", v)
		GameLogger.log_event("config", "%s exploration -> %.0f" % [entry.name, v])
	)
	zone_row.add_child(zone_row_label)
	zone_row.add_child(zone_slider)
	reglages_content.add_child(zone_row)

	var aging_row := HBoxContainer.new()
	var aging_row_label := Label.new()
	aging_row_label.text = "Vieillissement"
	var aging_slider := HSlider.new()
	aging_slider.min_value = AGING_MIN
	aging_slider.max_value = AGING_MAX
	aging_slider.step = 0.1
	aging_slider.custom_minimum_size = Vector2(120, 0)
	aging_slider.value = entry.node.get("aging_factor")
	aging_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("aging_factor", v)
		GameLogger.log_event("config", "%s vieillissement -> %.1f" % [entry.name, v])
	)
	aging_row.add_child(aging_row_label)
	aging_row.add_child(aging_slider)
	reglages_content.add_child(aging_row)

	var feeding_row := HBoxContainer.new()
	var feeding_row_label := Label.new()
	feeding_row_label.text = "Capacité à se nourrir"
	var feeding_slider := HSlider.new()
	feeding_slider.min_value = FEEDING_MIN
	feeding_slider.max_value = FEEDING_MAX
	feeding_slider.step = 0.1
	feeding_slider.custom_minimum_size = Vector2(120, 0)
	feeding_slider.value = entry.node.get("feeding_capacity")
	feeding_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("feeding_capacity", v)
		GameLogger.log_event("config", "%s capacité à se nourrir -> %.1f" % [entry.name, v])
	)
	feeding_row.add_child(feeding_row_label)
	feeding_row.add_child(feeding_slider)
	reglages_content.add_child(feeding_row)

	var memory_row := HBoxContainer.new()
	var memory_row_label := Label.new()
	memory_row_label.text = "Mémoire"
	var memory_slider := HSlider.new()
	memory_slider.min_value = MEMORY_MIN
	memory_slider.max_value = MEMORY_MAX
	memory_slider.step = 1
	memory_slider.custom_minimum_size = Vector2(120, 0)
	memory_slider.value = entry.node.get("memory_capacity")
	memory_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("memory_capacity", int(v))
		GameLogger.log_event("config", "%s mémoire -> %d" % [entry.name, int(v)])
	)
	memory_row.add_child(memory_row_label)
	memory_row.add_child(memory_slider)
	reglages_content.add_child(memory_row)

	live_vbox.add_child(_build_collapsible_section("Réglages", reglages_content, false))

	var historique_content := VBoxContainer.new()

	var berries_picked_label := Label.new()
	historique_content.add_child(berries_picked_label)

	var berries_eaten_label := Label.new()
	historique_content.add_child(berries_eaten_label)

	var memories_label := Label.new()
	historique_content.add_child(memories_label)

	outer_vbox.add_child(_build_collapsible_section("Historique", historique_content, true))

	var hunger_bar := ProgressBar.new()
	hunger_bar.min_value = 0.0
	hunger_bar.max_value = 100.0
	hunger_bar.show_percentage = false
	hunger_bar.custom_minimum_size = Vector2(0, 4)
	hunger_bar.value = entry.node.get("hunger")
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.1, 0.1)
	hunger_bar.add_theme_stylebox_override("fill", fill_style)
	outer_vbox.add_child(hunger_bar)

	entry["vbox"] = live_vbox
	entry["dead_label"] = dead_label
	entry["hunger_bar"] = hunger_bar
	entry["pos_label"] = pos_label
	entry["speed_label"] = speed_label
	entry["zone_label"] = zone_label
	entry["berries_label"] = berries_label
	entry["berries_picked_label"] = berries_picked_label
	entry["berries_eaten_label"] = berries_eaten_label
	entry["memories_label"] = memories_label

	return panel

func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for entry in _entries:
		if entry.panel == null:
			continue
		_update_panel_texts(entry)
		_position_panel(entry, viewport_size)
	if _game_data_panel != null:
		_game_data_panel.position = (viewport_size - _game_data_panel.size) / 2.0

func _update_panel_texts(entry: Dictionary) -> void:
	var node = entry.node
	var dead: bool = node.get("is_dead")
	entry.dead_label.visible = dead
	entry.vbox.visible = not dead
	entry.hunger_bar.value = node.get("hunger")
	entry.berries_picked_label.text = "Mûres ramassées (total) : %d" % node.get("berries_picked_total")
	entry.berries_eaten_label.text = "Mûres mangées (total) : %d" % node.get("berries_eaten_total")
	entry.memories_label.text = "Ronciers mémorisés : %d/%d" % [node.memorized_ronces_count(), node.get("memory_capacity")]
	if dead:
		return

	var pos: Vector3 = node.position
	entry.pos_label.text = "Position : (%.1f, %.1f)" % [pos.x, pos.z]
	entry.speed_label.text = "Vitesse actuelle : %.1f" % node.get("move_speed")
	entry.zone_label.text = "Exploration : %.0f" % node.get("map_half_x")
	entry.berries_label.text = "Mûres portées : %d/%d" % [node.get("berries_carried"), GameConfig.max_berries_carried]

func _position_panel(entry: Dictionary, viewport_size: Vector2) -> void:
	var panel: PanelContainer = entry.panel
	var size := panel.size
	match entry.corner:
		"top_left":
			panel.position = Vector2(MARGIN, MARGIN)
		"top_right":
			panel.position = Vector2(viewport_size.x - size.x - MARGIN, MARGIN)
		"bottom_left":
			panel.position = Vector2(MARGIN, viewport_size.y - size.y - MENU_HEIGHT - MARGIN)
		"bottom_right":
			panel.position = Vector2(viewport_size.x - size.x - MARGIN, viewport_size.y - size.y - MENU_HEIGHT - MARGIN)
