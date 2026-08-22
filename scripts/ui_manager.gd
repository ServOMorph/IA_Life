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
const LIGHT_ENERGY_MIN := 0.0
const LIGHT_ENERGY_MAX := 8.0

var _root: Control
var _menu_bar: HBoxContainer
var _entries: Array = []
var _camera: Camera3D
var _light: DirectionalLight3D
var _game_data_panel: PanelContainer = null
var _dev_panel: PanelContainer = null
var _dev_status_label: Label = null
var _checklist_panel: PanelContainer = null
var _checklist_state: Dictionary = {}
var _test_detail_panel: PanelContainer = null
const CHECKLIST_STATE_PATH := "res://logs/dev_checklist_state.json"
var _dev_frozen: bool = false
var _test_control_active: bool = false
var _test_character_node: Node = null
var _test_stats_panel: PanelContainer = null
var _test_stats_label: Label = null

func setup(characters: Array, camera: Camera3D, dev_mode: bool = false, light: DirectionalLight3D = null) -> void:
	_camera = camera
	_light = light
	_entries = []
	_build_root()
	_build_menu_bar()
	if dev_mode:
		_build_dev_panel()
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

func _build_dev_panel() -> void:
	_dev_panel = PanelContainer.new()
	_dev_panel.custom_minimum_size = Vector2(560, 0)

	var label := Label.new()
	label.text = "MODE DEV — Espace : geler/reprendre | N : avancer d'une frame | H : faim basse (repas) | G : faim haute (cueillette) | E : action perso de test (à définir) | K : tuer le perso de test | F1-F4 : téléporter perso au centre de la map (+ suivi caméra) | Shift+F1-F4 : téléporter perso au contact d'une ronce (+ suivi caméra) | F5 : contrôler le personnage de test (ZQSD + souris) | T : checklist de tests"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vbox := VBoxContainer.new()
	vbox.add_child(label)

	_dev_status_label = Label.new()
	_dev_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dev_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	vbox.add_child(_dev_status_label)

	_dev_panel.add_child(vbox)
	_root.add_child(_dev_panel)

func set_dev_frozen(frozen: bool) -> void:
	_dev_frozen = frozen
	_update_dev_status()

func set_test_control_active(active: bool) -> void:
	_test_control_active = active
	_update_dev_status()

func _update_dev_status() -> void:
	if _dev_status_label == null:
		return
	var parts: Array = []
	if _dev_frozen:
		parts.append("Temps gelé")
	if _test_control_active:
		parts.append("Contrôle personnage de test actif")
	_dev_status_label.text = " | ".join(parts)

func set_test_character(node: Node) -> void:
	_test_character_node = node
	if node == null:
		return
	_build_test_stats_panel()

func _build_test_stats_panel() -> void:
	_test_stats_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_test_stats_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	_test_stats_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Personnage de test"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_test_stats_label = Label.new()
	_test_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_test_stats_label)

	var node := _test_character_node
	vbox.add_child(_build_slider_row("Capacité à se nourrir", FEEDING_MIN, FEEDING_MAX, 0.1, node.get("feeding_capacity"), func(v: float) -> void:
		node.set("feeding_capacity", v)
		GameLogger.log_event("config", "Personnage de test capacité à se nourrir -> %.1f" % v)
	, 1))
	vbox.add_child(_build_slider_row("Mémoire", MEMORY_MIN, MEMORY_MAX, 1, node.get("memory_capacity"), func(v: float) -> void:
		node.set("memory_capacity", int(v))
		GameLogger.log_event("config", "Personnage de test mémoire -> %d" % int(v))
	, 0))

	_root.add_child(_test_stats_panel)

func toggle_dev_checklist() -> void:
	if _checklist_panel != null:
		_checklist_panel.queue_free()
		_checklist_panel = null
		return
	_build_checklist_panel()

func _parse_tests_manuels() -> Array:
	var tests: Array = []
	var path := "res://tests_manuels.md"
	if not FileAccess.file_exists(path):
		return tests

	var id_regex := RegEx.new()
	id_regex.compile("^(\\d+)\\.\\s+(.*)$")

	var category := ""
	var current: Dictionary = {}
	for raw_line in FileAccess.get_file_as_string(path).split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("## "):
			if current.size() > 0:
				tests.append(current)
				current = {}
			category = line.substr(3).strip_edges()
			continue
		if line.begins_with("#") or line.begins_with("-") or line == "":
			continue
		var m := id_regex.search(line)
		if m != null:
			if current.size() > 0:
				tests.append(current)
			current = {"id": m.get_string(1), "category": category, "text": m.get_string(2)}
			continue
		if current.size() > 0:
			current.text += " " + line
	if current.size() > 0:
		tests.append(current)
	return tests

func _load_checklist_state() -> Dictionary:
	if not FileAccess.file_exists(CHECKLIST_STATE_PATH):
		return {}
	var file := FileAccess.open(CHECKLIST_STATE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _persist_checklist_entry(id: String, status: String, commentaire: String) -> void:
	_checklist_state[id] = {"status": status, "commentaire": commentaire}
	var dir := DirAccess.open("res://")
	if dir != null and not dir.dir_exists("logs"):
		dir.make_dir("logs")
	var file := FileAccess.open(CHECKLIST_STATE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_checklist_state, "\t"))
	file.close()
	GameLogger.log_event("dev", "Checklist : test %s -> %s" % [id, status])

func _format_test_text(text: String) -> String:
	var with_break := text.replace("**Étapes :**", "\n\n[b]Étapes :[/b]")
	var parts := with_break.split("**")
	var result := ""
	var bold := false
	for part in parts:
		result += "[b]%s[/b]" % part if bold else part
		bold = not bold
	return result

func _build_checklist_test_row(test: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var text_label := RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.text = "[b]%s.[/b] %s" % [test.id, _format_test_text(test.text)]
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(520, 0)
	row.add_child(text_label)

	var saved: Dictionary = _checklist_state.get(test.id, {})
	var select_button := Button.new()
	select_button.text = "Invalidé -> Sélectionner" if saved.get("status", "") == "invalide" else "Sélectionner"
	select_button.pressed.connect(func() -> void:
		_open_test_detail(test)
	)
	row.add_child(select_button)

	return row

func _open_test_detail(test: Dictionary) -> void:
	if _checklist_panel != null:
		_checklist_panel.queue_free()
		_checklist_panel = null
	if _test_detail_panel != null:
		_test_detail_panel.queue_free()
		_test_detail_panel = null

	_test_detail_panel = PanelContainer.new()
	_test_detail_panel.custom_minimum_size = Vector2(360, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_test_detail_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	_test_detail_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Test %s" % test.id
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var text_scroll := ScrollContainer.new()
	text_scroll.custom_minimum_size = Vector2(336, 260)
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(text_scroll)

	var text_label := RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.text = _format_test_text(test.text)
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2(336, 0)
	text_scroll.add_child(text_label)
	vbox.add_child(HSeparator.new())

	var saved: Dictionary = _checklist_state.get(test.id, {})

	var comment_edit := LineEdit.new()
	comment_edit.text = saved.get("commentaire", "")
	comment_edit.placeholder_text = "Commentaire"
	comment_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(comment_edit)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)

	var valide_button := Button.new()
	valide_button.text = "Valide"
	controls.add_child(valide_button)

	var invalide_button := Button.new()
	invalide_button.text = "Invalide"
	controls.add_child(invalide_button)

	vbox.add_child(controls)

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(_close_test_detail)
	vbox.add_child(close_button)

	var decided_status: String = saved.get("status", "")

	valide_button.pressed.connect(func() -> void:
		_persist_checklist_entry(test.id, "valide", comment_edit.text)
		_close_test_detail()
	)
	invalide_button.pressed.connect(func() -> void:
		decided_status = "invalide"
		_persist_checklist_entry(test.id, "invalide", comment_edit.text)
	)
	comment_edit.text_changed.connect(func(new_text: String) -> void:
		if decided_status != "":
			_persist_checklist_entry(test.id, decided_status, new_text)
	)

	_root.add_child(_test_detail_panel)

func _close_test_detail() -> void:
	if _test_detail_panel != null:
		_test_detail_panel.queue_free()
		_test_detail_panel = null

func _build_checklist_panel() -> void:
	_checklist_panel = PanelContainer.new()
	_checklist_panel.custom_minimum_size = Vector2(640, 500)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_checklist_panel.add_theme_stylebox_override("panel", style)

	var outer := VBoxContainer.new()
	_checklist_panel.add_child(outer)

	var title := Label.new()
	title.text = "Checklist de tests manuels"
	title.add_theme_font_size_override("font_size", 20)
	outer.add_child(title)
	outer.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)

	_checklist_state = _load_checklist_state()
	var tests := _parse_tests_manuels()
	var by_category: Dictionary = {}
	var category_order: Array = []
	for test in tests:
		if _checklist_state.get(test.id, {}).get("status", "") == "valide":
			continue
		if not by_category.has(test.category):
			by_category[test.category] = []
			category_order.append(test.category)
		by_category[test.category].append(test)

	for category in category_order:
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for test in by_category[category]:
			content.add_child(_build_checklist_test_row(test))
		scroll_content.add_child(_build_collapsible_section(category, content, true))

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.pressed.connect(toggle_dev_checklist)
	outer.add_child(close_button)

	_root.add_child(_checklist_panel)

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
		GameConfig.save_to_disk()
	, 0))
	vbox.add_child(_build_slider_row("Seuil cueillette (faim)", PICKUP_THRESHOLD_MIN, PICKUP_THRESHOLD_MAX, 1, GameConfig.pickup_hunger_threshold, func(v: float) -> void:
		GameConfig.pickup_hunger_threshold = v
		GameConfig.save_to_disk()
	, 0))
	vbox.add_child(_build_slider_row("Seuil consommation (faim)", EAT_THRESHOLD_MIN, EAT_THRESHOLD_MAX, 1, GameConfig.eat_hunger_threshold, func(v: float) -> void:
		GameConfig.eat_hunger_threshold = v
		GameConfig.save_to_disk()
	, 0))
	vbox.add_child(_build_slider_row("Mûres pour vie complète", FULL_LIFE_BERRIES_MIN, FULL_LIFE_BERRIES_MAX, 1, GameConfig.full_life_berries, func(v: float) -> void:
		GameConfig.full_life_berries = v
		GameConfig.save_to_disk()
	, 0))
	vbox.add_child(_build_slider_row("Intensité lumineuse", LIGHT_ENERGY_MIN, LIGHT_ENERGY_MAX, 0.1, GameConfig.light_energy, func(v: float) -> void:
		GameConfig.light_energy = v
		if _light != null:
			_light.light_energy = v
		GameConfig.save_to_disk()
	, 1))

	vbox.add_child(HSeparator.new())
	var note := Label.new()
	note.text = "Nombre de ronces et mûres/ronce : appliqué au prochain Relancer."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(note)

	vbox.add_child(_build_slider_row("Nombre de ronces", 1, 30, 1, GameConfig.ronce_count, func(v: float) -> void:
		GameConfig.ronce_count = int(v)
		GameConfig.save_to_disk()
	, 0))
	vbox.add_child(_build_slider_row("Mûres par ronce", 1, 10, 1, GameConfig.berries_per_ronce, func(v: float) -> void:
		GameConfig.berries_per_ronce = int(v)
		GameConfig.save_to_disk()
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
	if _dev_panel != null:
		_dev_panel.position = Vector2((viewport_size.x - _dev_panel.size.x) / 2.0, MARGIN)
	if _checklist_panel != null:
		_checklist_panel.position = (viewport_size - _checklist_panel.size) / 2.0
	if _test_detail_panel != null:
		_test_detail_panel.position = Vector2(MARGIN, (viewport_size.y - _test_detail_panel.size.y) / 2.0)
	if _test_stats_panel != null and _test_character_node != null:
		_test_stats_label.text = "Mûres portées : %d/%d | Mûres ramassées (total) : %d | Faim : %.0f" % [
			_test_character_node.get("berries_carried"), GameConfig.max_berries_carried,
			_test_character_node.get("berries_picked_total"), _test_character_node.get("hunger"),
		]
		_test_stats_panel.position = Vector2(
			(viewport_size.x - _test_stats_panel.size.x) / 2.0,
			viewport_size.y - MENU_HEIGHT - _test_stats_panel.size.y - MARGIN
		)

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
