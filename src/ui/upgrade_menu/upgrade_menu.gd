class_name UpgradeMenu
extends CanvasLayer
## Bottom sheet with the money upgrades. Opens while the player stands on the upgrade
## board (EventBus.upgrade_board_entered/exited); buying goes through Progression.

const LAYER: int = 10
const PANEL_WIDTH: float = 1020.0
const BOTTOM_MARGIN: float = 40.0
const ROW_SPACING: int = 18
const ICON_SIZE: Vector2 = Vector2(96, 96)
const BUY_BUTTON_WIDTH: float = 260.0
const SLIDE_TIME: float = 0.2
const ICON_COLORS: Array[Color] = [
	Color("3fa7f2"),
	Color("b06be0"),
	Color("ff8f3f"),
	Color("4caf50"),
	Color("8bc34a"),
	Color("e5483b")
]

var _panel: PanelContainer
var _rows: Dictionary = {}  # StringName -> {"title": Label, "effect": Label, "button": Button}


func _ready() -> void:
	layer = LAYER
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = UiKit.panel()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -PANEL_WIDTH * 0.5
	_panel.offset_right = PANEL_WIDTH * 0.5
	_panel.offset_bottom = -BOTTOM_MARGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", ROW_SPACING)
	_panel.add_child(box)
	var header := HBoxContainer.new()
	var title := UiKit.label(tr("UPGRADES_TITLE"), UiKit.TITLE_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.button(tr("UI_CLOSE"), UiKit.RED, close))
	box.add_child(header)
	var upgrade_ids := Progression.upgrades.ids()
	for index in upgrade_ids.size():
		box.add_child(_build_row(upgrade_ids[index], ICON_COLORS[index % ICON_COLORS.size()]))

	_panel.visible = false
	EventBus.upgrade_board_entered.connect(open)
	EventBus.upgrade_board_exited.connect(close)
	EventBus.currency_changed.connect(_refresh_all.unbind(2))
	EventBus.upgrade_purchased.connect(_refresh_all.unbind(2))
	EventBus.unlock_completed.connect(_refresh_all.unbind(1))
	_refresh_all()


func open() -> void:
	_refresh_all()
	_panel.visible = true
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, SLIDE_TIME)


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func buy_button(upgrade_id: StringName) -> Button:
	return _rows[upgrade_id]["button"]


func _build_row(upgrade_id: StringName, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ROW_SPACING)
	row.add_child(UiKit.swatch(color, ICON_SIZE))
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiKit.label("")
	var effect := UiKit.label("", UiKit.SMALL_SIZE, UiKit.TEXT_MUTED)
	texts.add_child(title)
	texts.add_child(effect)
	row.add_child(texts)
	var button := UiKit.button("", UiKit.GREEN, Progression.buy_upgrade.bind(upgrade_id))
	button.custom_minimum_size.x = BUY_BUTTON_WIDTH
	row.add_child(button)
	_rows[upgrade_id] = {"root": row, "title": title, "effect": effect, "button": button}
	return row


func _refresh_all() -> void:
	for upgrade_id: StringName in _rows:
		_refresh_row(upgrade_id)


func _refresh_row(upgrade_id: StringName) -> void:
	var row: Dictionary = _rows[upgrade_id]
	(row["root"] as Control).visible = Progression.is_upgrade_visible(upgrade_id)
	var level := Progression.upgrade_level(upgrade_id)
	var maxed := Progression.upgrades.is_maxed(upgrade_id, level)
	(row["title"] as Label).text = (
		"%s  %s" % [tr("UPGRADE_" + String(upgrade_id).to_upper()), tr("UI_LEVEL_SHORT") % level]
	)
	(row["effect"] as Label).text = EffectText.describe(
		Progression.upgrades.effects(upgrade_id), tr
	)
	var button: Button = row["button"]
	button.text = tr("UI_MAX") if maxed else Economy.format(Progression.upgrade_cost(upgrade_id))
	button.disabled = not Progression.can_buy_upgrade(upgrade_id)
