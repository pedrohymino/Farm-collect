class_name UiKit
extends RefCounted
## Shared look for the game UI (docs/06-arte-e-audio.md, section 6): chunky rounded panels and
## buttons with a darker bottom edge. Placeholder styling until the M7 art pass.

const TITLE_SIZE: int = 60
const BODY_SIZE: int = 44
const SMALL_SIZE: int = 34

const CREAM: Color = Color("fbf4e4")
const BROWN: Color = Color("6b4226")
const TEXT_DARK: Color = Color("3b2a1e")
const TEXT_MUTED: Color = Color("8a7462")
const GREEN: Color = Color("4caf50")
const YELLOW: Color = Color("f7c531")
const GRAY: Color = Color("b8aea2")
const RED: Color = Color("e5483b")
const CORNER: int = 32
const BORDER: int = 6
const BUTTON_EDGE: int = 10
const SLIDER_TRACK_HEIGHT: int = 18
const SLIDER_KNOB_SIZE: int = 52
const SLIDER_HEIGHT: float = 60.0


static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = BROWN
	style.set_border_width_all(BORDER)
	style.set_corner_radius_all(CORNER)
	style.set_content_margin_all(28.0)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style


static func panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override(&"panel", panel_style())
	return node


static func label(text: String, size: int = BODY_SIZE, color: Color = TEXT_DARK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", size)
	node.add_theme_color_override(&"font_color", color)
	return node


static func button(text: String, color: Color, on_pressed: Callable = Callable()) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", BODY_SIZE)
	node.add_theme_color_override(&"font_color", Color.WHITE)
	node.add_theme_color_override(&"font_hover_color", Color.WHITE)
	node.add_theme_color_override(&"font_pressed_color", Color.WHITE)
	node.add_theme_color_override(&"font_disabled_color", Color(1, 1, 1, 0.8))
	node.add_theme_stylebox_override(&"normal", button_style(color))
	node.add_theme_stylebox_override(&"hover", button_style(color.lightened(0.1)))
	node.add_theme_stylebox_override(&"pressed", button_style(color.darkened(0.1), true))
	node.add_theme_stylebox_override(&"disabled", button_style(GRAY))
	node.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	if on_pressed.is_valid():
		node.pressed.connect(on_pressed)
	return node


static func button_style(color: Color, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.35)
	style.border_width_bottom = 2 if pressed else BUTTON_EDGE
	style.set_corner_radius_all(CORNER)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0 + (0.0 if pressed else BUTTON_EDGE - 2.0)
	return style


## Horizontal slider with a thick track, green fill and a round knob (0..1 in steps of 0.05).
static func slider() -> HSlider:
	var node := HSlider.new()
	node.min_value = 0.0
	node.max_value = 1.0
	node.step = 0.05
	node.custom_minimum_size.y = SLIDER_HEIGHT
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.add_theme_stylebox_override(&"slider", _track_style(GRAY))
	node.add_theme_stylebox_override(&"grabber_area", _track_style(GREEN))
	node.add_theme_stylebox_override(&"grabber_area_highlight", _track_style(GREEN.lightened(0.1)))
	var knob := _knob_texture(CREAM, BROWN)
	node.add_theme_icon_override(&"grabber", knob)
	node.add_theme_icon_override(&"grabber_highlight", knob)
	node.add_theme_icon_override(&"grabber_disabled", knob)
	return node


## Drop-down styled like the buttons (cream text on a muted button face).
static func style_option(node: OptionButton) -> void:
	var color := GRAY.darkened(0.3)
	node.add_theme_font_size_override(&"font_size", BODY_SIZE)
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		node.add_theme_color_override(color_name, Color.WHITE)
	node.add_theme_stylebox_override(&"normal", button_style(color))
	node.add_theme_stylebox_override(&"hover", button_style(color.lightened(0.1)))
	node.add_theme_stylebox_override(&"pressed", button_style(color.darkened(0.1), true))
	node.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	node.get_popup().add_theme_font_size_override(&"font_size", BODY_SIZE)


## Small colored rounded square used as a placeholder icon.
static func swatch(color: Color, size: Vector2) -> Panel:
	var node := Panel.new()
	node.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.35)
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(minf(size.x, size.y) * 0.3))
	node.add_theme_stylebox_override(&"panel", style)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func _track_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(SLIDER_TRACK_HEIGHT / 2)
	style.content_margin_top = SLIDER_TRACK_HEIGHT / 2.0
	style.content_margin_bottom = SLIDER_TRACK_HEIGHT / 2.0
	return style


static func _knob_texture(fill: Color, edge: Color) -> ImageTexture:
	var size := SLIDER_KNOB_SIZE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var radius := size * 0.5 - 1.0
	for y in size:
		for x in size:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var coverage := clampf(radius - distance + 0.5, 0.0, 1.0)
			var color := edge if distance > radius - BORDER * 0.6 else fill
			image.set_pixel(x, y, Color(color, coverage))
	return ImageTexture.create_from_image(image)


## Roman numerals for tree tiers (1..39 is plenty).
static func roman(value: int) -> String:
	var numerals := [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var result := ""
	var remaining := value
	for pair: Array in numerals:
		while remaining >= pair[0]:
			result += pair[1]
			remaining -= pair[0]
	return result
