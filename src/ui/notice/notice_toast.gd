class_name NoticeToast
extends CanvasLayer
## Short message at the bottom of the screen (save problems). Never blocks the game.

const LAYER: int = 50
const SHOW_SEC: float = 5.0
const FADE_SEC: float = 0.5
const BOTTOM_MARGIN: float = 160.0
const WIDTH: float = 900.0

var _panel: PanelContainer
var _label: Label
var _tween: Tween


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = UiKit.panel()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -WIDTH * 0.5
	_panel.offset_right = WIDTH * 0.5
	_panel.offset_bottom = -BOTTOM_MARGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiKit.label("", UiKit.SMALL_SIZE + 6)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	EventBus.save_problem.connect(_on_save_problem)
	EventBus.save_failed.connect(func() -> void: show_notice(tr("NOTICE_SAVE_FAILED")))


func is_showing() -> bool:
	return _panel.visible


func current_text() -> String:
	return _label.text


func show_notice(text: String) -> void:
	_label.text = text
	_panel.visible = true
	_panel.modulate.a = 1.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(SHOW_SEC)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_SEC)
	_tween.tween_callback(func() -> void: _panel.visible = false)


func _on_save_problem(kind: StringName) -> void:
	match kind:
		&"restored_from_backup":
			show_notice(tr("NOTICE_SAVE_RESTORED"))
		_:
			show_notice(tr("NOTICE_SAVE_RESET"))
