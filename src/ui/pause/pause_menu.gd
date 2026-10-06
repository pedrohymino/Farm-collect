class_name PauseMenu
extends CanvasLayer
## Pause screen: Resume, Settings, Main menu (saves first) and Quit (desktop only).
## Opened by the "pause" action (Esc / Start) or the HUD pause button; pauses the game tree.

const LAYER: int = 40
const MENU_SCENE: String = "res://src/ui/menu/main_menu.tscn"
const BACKDROP_COLOR: Color = Color(0, 0, 0, 0.55)
const BUTTON_WIDTH: float = 620.0
const PANEL_SPACING: int = 24

var _root: Control
var _menu_panel: PanelContainer
var _settings_panel: SettingsPanel
var _rebuild_queued: bool = false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false
	EventBus.pause_requested.connect(toggle)


func _exit_tree() -> void:
	if is_open():
		get_tree().paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	var was_open := is_open()
	var was_in_settings := _settings_panel.visible
	_root.queue_free()
	_build()
	_root.visible = was_open
	if was_in_settings:
		_show_settings()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_menu_panel = UiKit.panel()
	center.add_child(_menu_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", PANEL_SPACING)
	box.custom_minimum_size.x = BUTTON_WIDTH
	_menu_panel.add_child(box)
	box.add_child(UiKit.label(tr("MENU_PAUSED"), UiKit.TITLE_SIZE))
	box.add_child(UiKit.button(tr("MENU_RESUME"), UiKit.GREEN, close))
	box.add_child(UiKit.button(tr("SETTINGS_TITLE"), UiKit.YELLOW.darkened(0.15), _show_settings))
	box.add_child(UiKit.button(tr("MENU_MAIN_MENU"), UiKit.GRAY.darkened(0.25), _to_main_menu))
	if _can_quit():
		box.add_child(UiKit.button(tr("MENU_QUIT"), UiKit.RED, _quit))

	_settings_panel = SettingsPanel.new()
	_settings_panel.visible = false
	_settings_panel.closed.connect(_hide_settings)
	center.add_child(_settings_panel)


func is_open() -> bool:
	return _root.visible


func is_settings_visible() -> bool:
	return _settings_panel.visible


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open() -> void:
	_root.visible = true
	_hide_settings()
	get_tree().paused = true


## Opens the pause menu directly on the settings screen.
func open_settings() -> void:
	open()
	_show_settings()


func close() -> void:
	_root.visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if is_open() and _settings_panel.visible:
			_hide_settings()
		else:
			toggle()


func _show_settings() -> void:
	_menu_panel.visible = false
	_settings_panel.visible = true


func _hide_settings() -> void:
	_settings_panel.visible = false
	_menu_panel.visible = true


func _to_main_menu() -> void:
	# A failed save keeps the player here (NoticeToast explains) instead of losing progress.
	if not SaveManager.save_game():
		return
	close()
	get_tree().change_scene_to_file(MENU_SCENE)


func _quit() -> void:
	SaveManager.save_game()
	get_tree().quit()


func _can_quit() -> bool:
	return not OS.has_feature("mobile") and not OS.has_feature("web")
