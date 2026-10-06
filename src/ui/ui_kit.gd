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


static func button(text: String, color: Color, on_pressed: Callable) -> Button:
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
