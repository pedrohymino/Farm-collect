extends Node
## Live tuning (docs/05-dev-mode.md). Only in debug builds or exports with the "dev" feature tag.
## Inactive until activate() is called by the main scene, so tests never load a dev session.
## Toggle: F1 / ` (action dev_toggle), or 5 quick taps in the top-left corner on touch screens.

const SESSION_DIR: String = "user://dev"
const TAP_COUNT: int = 5
const TAP_WINDOW_SEC: float = 2.0
const TAP_CORNER_SIZE: float = 160.0
const SESSION_SAVE_DELAY_SEC: float = 0.5

var is_enabled: bool = false
var panel: DevPanel

var _store: DevSessionStore
var _tap_times: Array[float] = []
var _save_countdown: float = -1.0


func _ready() -> void:
	is_enabled = OS.is_debug_build() or OS.has_feature("dev")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)


func activate() -> void:
	if not is_enabled or panel != null:
		return
	_store = DevSessionStore.new(SESSION_DIR)
	DevSessionStore.apply(Stats.registry, _store.load_session(), ContentDB.balance.stats)
	panel = DevPanel.new(_store)
	add_child(panel)
	Stats.stat_changed.connect(_on_stat_changed.unbind(2))
	set_process(true)
	set_process_input(true)


func toggle() -> void:
	if panel != null:
		panel.toggle()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_toggle"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		if touch.position.x < TAP_CORNER_SIZE and touch.position.y < TAP_CORNER_SIZE:
			_register_tap()


func _process(delta: float) -> void:
	if _save_countdown < 0.0:
		return
	_save_countdown -= delta
	if _save_countdown < 0.0:
		_store.save_session(DevSessionStore.capture(Stats.registry, ContentDB.balance.stats))


func _register_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_tap_times.append(now)
	_tap_times = _tap_times.filter(func(t: float) -> bool: return now - t <= TAP_WINDOW_SEC)
	if _tap_times.size() >= TAP_COUNT:
		_tap_times.clear()
		toggle()


func _on_stat_changed() -> void:
	_save_countdown = SESSION_SAVE_DELAY_SEC
