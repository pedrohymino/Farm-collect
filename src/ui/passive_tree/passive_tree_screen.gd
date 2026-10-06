class_name PassiveTreeScreen
extends CanvasLayer
## Full-screen passive tree: branches radiate from a central hub, one ring per tier.
## Tap a node to see it; buy it with stars when it is available (Progression.buy_passive).

const LAYER: int = 20
## Sized so the deepest key node still fits a 1080-wide portrait screen.
const HUB_SIZE: float = 100.0
const FIRST_RING_RADIUS: float = 110.0
const RING_SPACING: float = 90.0
const NODE_SIZE: float = 74.0
const KEY_NODE_SIZE: float = 100.0
const BACKDROP_COLOR: Color = Color(0.06, 0.08, 0.12, 0.92)
const OWNED_COLOR: Color = Color("4caf50")
const AVAILABLE_COLOR: Color = Color("f7c531")
const LOCKED_COLOR: Color = Color("5c5f66")
const KEY_BORDER_COLOR: Color = Color("ffd166")
const SELECTED_BORDER_COLOR: Color = Color.WHITE
const PULSE_SPEED: float = 5.0
const PULSE_AMOUNT: float = 0.06

var _root: Control
var _graph: PassiveTreeGraph
var _buttons: Dictionary = {}  # StringName -> Button
var _stars_label: Label
var _detail_title: Label
var _detail_effect: Label
var _buy_button: Button
var _selected: StringName = &""
var _time: float = 0.0


func _ready() -> void:
	layer = LAYER
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	_graph = PassiveTreeGraph.new()
	_graph.set_anchors_preset(Control.PRESET_CENTER)
	_graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_graph)
	_build_nodes()
	_build_header()
	_build_detail()

	visible = false
	EventBus.passive_tree_requested.connect(open)
	EventBus.currency_changed.connect(_refresh.unbind(2))
	EventBus.passive_purchased.connect(_refresh.unbind(1))
	_refresh()


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func node_button(node_id: StringName) -> Button:
	return _buttons.get(node_id)


func select(node_id: StringName) -> void:
	_selected = node_id
	_refresh()


func buy_selected() -> bool:
	return not _selected.is_empty() and Progression.buy_passive(_selected)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	var pulse := 1.0 + sin(_time * PULSE_SPEED) * PULSE_AMOUNT
	for node_id: StringName in _buttons:
		var button: Button = _buttons[node_id]
		var available := Progression.passive_state(node_id) == PassiveRules.NodeState.AVAILABLE
		button.scale = Vector2.ONE * (pulse if available else 1.0)


func _build_nodes() -> void:
	var rules := Progression.passives
	var branches := rules.branches()
	var hub := _make_circle_button(HUB_SIZE, LOCKED_COLOR, KEY_BORDER_COLOR)
	hub.disabled = true
	hub.position = -Vector2.ONE * HUB_SIZE * 0.5
	_graph.add_child(hub)
	for branch_index in branches.size():
		var angle := -PI * 0.5 + TAU * branch_index / branches.size()
		var direction := Vector2(cos(angle), sin(angle))
		for node_id in rules.nodes_in_branch(branches[branch_index]):
			var size := KEY_NODE_SIZE if rules.is_key(node_id) else NODE_SIZE
			var button := _make_circle_button(size, LOCKED_COLOR, LOCKED_COLOR)
			button.pivot_offset = Vector2.ONE * size * 0.5
			var radius := FIRST_RING_RADIUS + RING_SPACING * (rules.depth(node_id) - 1)
			button.position = direction * radius - button.pivot_offset
			button.pressed.connect(select.bind(node_id))
			_graph.add_child(button)
			_buttons[node_id] = button


func _build_header() -> void:
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 40.0
	header.offset_right = -40.0
	header.offset_top = 48.0
	var title := UiKit.label(tr("TREE_TITLE"), UiKit.TITLE_SIZE, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.swatch(UiKit.YELLOW, Vector2(56, 56)))
	_stars_label = UiKit.label("", UiKit.TITLE_SIZE, Color.WHITE)
	header.add_child(_stars_label)
	header.add_child(UiKit.button(tr("UI_CLOSE"), UiKit.RED, close))
	_root.add_child(header)


func _build_detail() -> void:
	var panel := UiKit.panel()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -480.0
	panel.offset_right = 480.0
	panel.offset_bottom = -40.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var box := VBoxContainer.new()
	_detail_title = UiKit.label("", UiKit.TITLE_SIZE)
	_detail_effect = UiKit.label("", UiKit.BODY_SIZE, UiKit.TEXT_MUTED)
	_buy_button = UiKit.button("", UiKit.GREEN, func() -> void: buy_selected())
	box.add_child(_detail_title)
	box.add_child(_detail_effect)
	box.add_child(_buy_button)
	panel.add_child(box)
	_root.add_child(panel)


func _refresh() -> void:
	if _stars_label == null:
		return
	_stars_label.text = Economy.format(Economy.balance(Wallet.STARS))
	var rules := Progression.passives
	for node_id: StringName in _buttons:
		var state := Progression.passive_state(node_id)
		var fill := LOCKED_COLOR
		if state == PassiveRules.NodeState.OWNED:
			fill = OWNED_COLOR
		elif state == PassiveRules.NodeState.AVAILABLE:
			fill = AVAILABLE_COLOR
		var border := KEY_BORDER_COLOR if rules.is_key(node_id) else fill.darkened(0.35)
		if node_id == _selected:
			border = SELECTED_BORDER_COLOR
		var button: Button = _buttons[node_id]
		_style_circle(button, button.custom_minimum_size.x, fill, border)
		button.text = UiKit.roman(rules.depth(node_id))
	_graph.set_links(_links())
	_refresh_detail()


func _refresh_detail() -> void:
	var rules := Progression.passives
	if _selected.is_empty():
		_detail_title.text = tr("TREE_HINT")
		_detail_effect.text = ""
		_buy_button.visible = false
		return
	_detail_title.text = passive_name(_selected)
	_detail_effect.text = EffectText.describe(rules.effects(_selected), tr)
	var state := Progression.passive_state(_selected)
	_buy_button.visible = state != PassiveRules.NodeState.OWNED
	_buy_button.text = tr("TREE_BUY") % rules.cost(_selected)
	_buy_button.disabled = not Progression.can_buy_passive(_selected)


func passive_name(node_id: StringName) -> String:
	var rules := Progression.passives
	if rules.is_key(node_id):
		return tr("PASSIVE_" + String(node_id).to_upper())
	return (
		"%s %s"
		% [
			tr("BRANCH_" + String(rules.branch_of(node_id)).to_upper()),
			UiKit.roman(rules.depth(node_id))
		]
	)


func _links() -> Array[Dictionary]:
	var rules := Progression.passives
	var result: Array[Dictionary] = []
	for node_id: StringName in _buttons:
		var to := _center(node_id)
		var parents := rules.requires(node_id)
		var state := Progression.passive_state(node_id)
		if parents.is_empty():
			result.append({"from": Vector2.ZERO, "to": to, "state": state})
		for parent in parents:
			result.append({"from": _center(parent), "to": to, "state": state})
	return result


func _center(node_id: StringName) -> Vector2:
	var button: Button = _buttons[node_id]
	return button.position + button.pivot_offset


func _make_circle_button(size: float, fill: Color, border: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2.ONE * size
	button.size = Vector2.ONE * size
	button.add_theme_font_size_override(&"font_size", UiKit.SMALL_SIZE)
	button.add_theme_color_override(&"font_color", Color.WHITE)
	button.add_theme_color_override(&"font_disabled_color", Color.WHITE)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_style_circle(button, size, fill, border)
	return button


func _style_circle(button: Button, size: float, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(8)
	style.set_corner_radius_all(int(size * 0.5))
	for state_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state_name, style)
