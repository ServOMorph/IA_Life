extends CanvasLayer

const MENU_HEIGHT := 56.0
const MARGIN := 10.0
const SPEED_MIN := 0.5
const SPEED_MAX := 10.0
const ZONE_MIN := 5.0
const ZONE_MAX := 80.0
const GAME_SPEED_MIN := 0.1
const GAME_SPEED_MAX := 5.0
const AGING_MIN := 0.1
const AGING_MAX := 5.0

var _root: Control
var _menu_bar: HBoxContainer
var _entries: Array = []
var _camera: Camera3D

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

	row.add_child(_build_reset_button())

func _build_reset_button() -> Button:
	var button := Button.new()
	button.text = "Relancer"
	button.pressed.connect(_on_reset_pressed)
	return button

func _on_reset_pressed() -> void:
	GameSpeed.time_scale = 1.0
	get_tree().reload_current_scene()

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
	if entry.panel != null:
		entry.panel.queue_free()
		entry.panel = null
	else:
		entry.panel = _build_character_panel(entry)
		_root.add_child(entry.panel)
		_camera.focus_on(entry.node.position)

func _build_character_panel(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = entry.name
	title.add_theme_color_override("font_color", entry.color)
	vbox.add_child(title)

	var hunger_bar := ProgressBar.new()
	hunger_bar.min_value = 0.0
	hunger_bar.max_value = 100.0
	hunger_bar.show_percentage = false
	hunger_bar.custom_minimum_size = Vector2(0, 4)
	hunger_bar.value = entry.node.get("hunger")
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.1, 0.1)
	hunger_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(hunger_bar)

	var pos_label := Label.new()
	vbox.add_child(pos_label)

	var speed_label := Label.new()
	vbox.add_child(speed_label)

	var zone_label := Label.new()
	vbox.add_child(zone_label)

	vbox.add_child(HSeparator.new())

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
	)
	speed_row.add_child(speed_row_label)
	speed_row.add_child(speed_slider)
	vbox.add_child(speed_row)

	var zone_row := HBoxContainer.new()
	var zone_row_label := Label.new()
	zone_row_label.text = "Zone"
	var zone_slider := HSlider.new()
	zone_slider.min_value = ZONE_MIN
	zone_slider.max_value = ZONE_MAX
	zone_slider.step = 1.0
	zone_slider.custom_minimum_size = Vector2(120, 0)
	zone_slider.value = entry.node.get("map_half_x")
	zone_slider.value_changed.connect(func(v: float) -> void:
		entry.node.set("map_half_x", v)
		entry.node.set("map_half_z", v)
	)
	zone_row.add_child(zone_row_label)
	zone_row.add_child(zone_slider)
	vbox.add_child(zone_row)

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
	)
	aging_row.add_child(aging_row_label)
	aging_row.add_child(aging_slider)
	vbox.add_child(aging_row)

	var dead_label := Label.new()
	dead_label.text = "DEAD"
	dead_label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	dead_label.add_theme_font_size_override("font_size", 28)
	dead_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_label.visible = false
	panel.add_child(dead_label)

	entry["vbox"] = vbox
	entry["dead_label"] = dead_label
	entry["hunger_bar"] = hunger_bar
	entry["pos_label"] = pos_label
	entry["speed_label"] = speed_label
	entry["zone_label"] = zone_label

	return panel

func _process(_delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for entry in _entries:
		if entry.panel == null:
			continue
		_update_panel_texts(entry)
		_position_panel(entry, viewport_size)

func _update_panel_texts(entry: Dictionary) -> void:
	var node = entry.node
	var dead: bool = node.get("is_dead")
	entry.dead_label.visible = dead
	entry.vbox.visible = not dead
	if dead:
		return

	var pos: Vector3 = node.position
	entry.hunger_bar.value = node.get("hunger")
	entry.pos_label.text = "Position : (%.1f, %.1f)" % [pos.x, pos.z]
	entry.speed_label.text = "Vitesse actuelle : %.1f" % node.get("move_speed")
	entry.zone_label.text = "Zone : %.0f" % node.get("map_half_x")

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
