extends RefCounted

const PANEL := Color("#101D2B")
const TEXT := Color("#EFF4F2")
const SECONDARY := Color("#647C87")
const ACCENT := Color("#A9D8DE")
const HUNGER := Color("#E5A543")
const DEATH := Color("#808B96")
const DANGER := Color("#EB694F")
const RED := Color("#D85D59")
const BLUE := Color("#4698D2")
const GREEN := Color("#65B977")
const YELLOW := Color("#E4BE4B")

const SANS := preload("res://assets/fonts/ibm_plex/IBMPlexSans-Regular.ttf")
const SANS_SEMIBOLD := preload("res://assets/fonts/ibm_plex/IBMPlexSans-SemiBold.ttf")
const MONO := preload("res://assets/fonts/ibm_plex/IBMPlexMono-Regular.ttf")

static func agent_symbol(name: String) -> String:
	match name:
		"Rouge": return "●"
		"Bleu": return "▲"
		"Vert": return "■"
		"Jaune": return "◆"
	return "•"

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = SANS
	theme.default_font_size = 16
	theme.set_font("font", "Button", SANS_SEMIBOLD)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", PANEL)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", SECONDARY)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", SECONDARY)
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, ACCENT, 0.94, 1, 12))
	theme.set_stylebox("normal", "Button", _box(Color("#1C3041"), SECONDARY, 0.96, 1, 8))
	theme.set_stylebox("hover", "Button", _box(Color("#2A4658"), ACCENT, 0.98, 1, 8))
	theme.set_stylebox("pressed", "Button", _box(ACCENT, ACCENT, 1.0, 1, 8))
	theme.set_stylebox("disabled", "Button", _box(PANEL, SECONDARY, 0.65, 1, 8))
	theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, ACCENT, 0.0, 2, 8))
	theme.set_stylebox("normal", "LineEdit", _box(Color("#172938"), SECONDARY, 1.0, 1, 6))
	theme.set_stylebox("focus", "LineEdit", _box(Color.TRANSPARENT, ACCENT, 0.0, 2, 6))
	theme.set_stylebox("background", "ProgressBar", _box(Color("#243746"), SECONDARY, 1.0, 1, 3))
	theme.set_stylebox("fill", "ProgressBar", _box(HUNGER, HUNGER, 1.0, 0, 3))
	return theme

static func _box(fill: Color, border: Color, opacity: float, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill.r, fill.g, fill.b, opacity)
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
