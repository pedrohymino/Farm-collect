class_name MainMenu
extends Node
## Title screen: Play / Continue, Settings and Quit (desktop only) over the diorama.

const GAME_SCENE: String = "res://src/main.tscn"
const TITLE_SIZE: int = 150
const TITLE_TOP: float = 0.07
const BUTTON_WIDTH: float = 640.0
const BUTTON_SPACING: int = 22
const BUTTONS_BOTTOM_MARGIN: float = 150.0
const OUTLINE_SIZE: int = 28

var _menu_box: VBoxContainer
var _settings_panel: SettingsPanel
var _play_button: Button
var _ui: CanvasLayer
var _rebuild_queued: bool = false


func _ready() -> void:
	add_child(MenuStage.new())
	_ui = CanvasLayer.new()
	add_child(_ui)
	_build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	var was_in_settings := _settings_panel.visible
	for child in _ui.get_children():
		child.queue_free()
	_build()
	if was_in_settings:
		_show_settings()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var title := UiKit.label(tr("GAME_TITLE"), TITLE_SIZE, UiKit.YELLOW)
	title.add_theme_color_override(&"font_outline_color", UiKit.BROWN)
	title.add_theme_constant_override(&"outline_size", OUTLINE_SIZE)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = TITLE_TOP
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override(&"separation", BUTTON_SPACING)
	_menu_box.custom_minimum_size.x = BUTTON_WIDTH
	_menu_box.anchor_left = 0.5
	_menu_box.anchor_right = 0.5
	_menu_box.anchor_top = 1.0
	_menu_box.anchor_bottom = 1.0
	_menu_box.offset_left = -BUTTON_WIDTH * 0.5
	_menu_box.offset_right = BUTTON_WIDTH * 0.5
	_menu_box.offset_bottom = -BUTTONS_BOTTOM_MARGIN
	_menu_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_menu_box)
	_play_button = UiKit.button(_play_text(), UiKit.GREEN, play)
	_menu_box.add_child(_play_button)
	_menu_box.add_child(
		UiKit.button(tr("SETTINGS_TITLE"), UiKit.YELLOW.darkened(0.15), _show_settings)
	)
	if _can_quit():
		_menu_box.add_child(UiKit.button(tr("MENU_QUIT"), UiKit.RED, get_tree().quit))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_settings_panel = SettingsPanel.new()
	_settings_panel.visible = false
	_settings_panel.closed.connect(_hide_settings)
	center.add_child(_settings_panel)


func play_button_text() -> String:
	return _play_button.text


func play() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _play_text() -> String:
	return tr("MENU_CONTINUE") if SaveManager.has_save() else tr("MENU_PLAY")


func _show_settings() -> void:
	_menu_box.visible = false
	_settings_panel.visible = true


func _hide_settings() -> void:
	_settings_panel.visible = false
	_menu_box.visible = true


func _can_quit() -> bool:
	return not OS.has_feature("mobile") and not OS.has_feature("web")
