class_name DevUi
extends RefCounted
## Small builders for the dev panel controls (built in code, not scenes, so it stays one place).
## Callers pass already-translated text; the panel root disables auto-translation.

const FONT_SIZE: int = 34
const SMALL_FONT_SIZE: int = 26
const TITLE_FONT_SIZE: int = 40
const SPIN_WIDTH: float = 210.0
const SECTION_COLOR: Color = Color("ffd166")
const MUTED_COLOR: Color = Color(1, 1, 1, 0.65)


## Compact number text without trailing zeros (GDScript's % has no %g).
static func num(value: float) -> String:
	return String.num(value, 4)


## Like num(), with an explicit sign: +2, -0.5.
static func signed_num(value: float) -> String:
	return ("+" if value >= 0.0 else "") + num(value)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	return theme


static func label(text: String, font_size: int = FONT_SIZE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override(&"font_size", font_size)
	return node


static func section(text: String) -> Label:
	var node := label(text, TITLE_FONT_SIZE)
	node.add_theme_color_override(&"font_color", SECTION_COLOR)
	return node


static func button(text: String, on_pressed: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(on_pressed)
	return node


static func toggle(text: String, on_toggled: Callable) -> CheckButton:
	var node := CheckButton.new()
	node.text = text
	node.toggled.connect(on_toggled)
	return node


static func spin(min_value: float, max_value: float, step: float, value: float) -> SpinBox:
	var node := SpinBox.new()
	node.min_value = min_value
	node.max_value = max_value
	node.step = step
	node.allow_greater = true
	node.allow_lesser = true
	node.select_all_on_focus = true
	node.custom_minimum_size.x = SPIN_WIDTH
	node.value = value
	return node


static func flow(children: Array[Control]) -> HFlowContainer:
	var node := HFlowContainer.new()
	for child in children:
		node.add_child(child)
	return node
