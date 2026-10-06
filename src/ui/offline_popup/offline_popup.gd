class_name OfflinePopup
extends CanvasLayer
## "Welcome back" popup with the money the farm made while the game was closed.

const LAYER: int = 30
const PANEL_WIDTH: float = 860.0
const AMOUNT_SIZE: int = 110
const BACKDROP_COLOR: Color = Color(0, 0, 0, 0.55)
const SECONDS_PER_MINUTE: int = 60
const MINUTES_PER_HOUR: int = 60

var _root: Control
var _body: Label
var _amount: Label


func _ready() -> void:
	layer = LAYER
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	var panel := UiKit.panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -PANEL_WIDTH * 0.5
	panel.offset_right = PANEL_WIDTH * 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 24)
	panel.add_child(box)
	box.add_child(_centered(UiKit.label(tr("OFFLINE_TITLE"), UiKit.TITLE_SIZE)))
	_body = _centered(UiKit.label("", UiKit.BODY_SIZE, UiKit.TEXT_MUTED))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)
	_amount = _centered(UiKit.label("", AMOUNT_SIZE, UiKit.GREEN.darkened(0.2)))
	box.add_child(_amount)
	box.add_child(UiKit.button(tr("OFFLINE_COLLECT"), UiKit.GREEN, collect))

	visible = false
	EventBus.offline_earnings_ready.connect(show_earnings)


func show_earnings(amount: float, away_seconds: float) -> void:
	_body.text = tr("OFFLINE_BODY") % format_duration(away_seconds)
	_amount.text = Economy.format(amount)
	visible = true


func collect() -> void:
	Offline.collect()
	visible = false


func format_duration(seconds: float) -> String:
	var total_minutes := floori(seconds / SECONDS_PER_MINUTE)
	return (
		tr("TIME_HOURS_MINUTES")
		% [floori(total_minutes / float(MINUTES_PER_HOUR)), total_minutes % MINUTES_PER_HOUR]
	)


func _centered(label: Label) -> Label:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
