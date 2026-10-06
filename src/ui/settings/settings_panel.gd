class_name SettingsPanel
extends PanelContainer
## Settings screen used by both the main menu and the pause menu. Every change applies and
## saves immediately (Settings.update); "Reset progress" needs a second tap to confirm.

signal closed

const PANEL_WIDTH: float = 940.0
const ROW_SPACING: int = 22
const LABEL_WIDTH: float = 340.0
const SLIDER_WIDTH: float = 420.0
const CONFIRM_WINDOW_SEC: float = 3.0
const LANGUAGE_NAMES: Dictionary = {"en": "English", "pt_BR": "Português"}

var _sliders: Dictionary = {}  # String (SettingsData field) -> HSlider
var _language: OptionButton
var _vibration: Button
var _quality: OptionButton
var _reset_button: Button
var _reset_armed: bool = false
var _reset_timer: SceneTreeTimer
var _updating: bool = false


func _ready() -> void:
	add_theme_stylebox_override(&"panel", UiKit.panel_style())
	custom_minimum_size.x = PANEL_WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", ROW_SPACING)
	add_child(box)
	box.add_child(UiKit.label(tr("SETTINGS_TITLE"), UiKit.TITLE_SIZE))
	box.add_child(_slider_row("master_volume", tr("SETTINGS_MASTER")))
	box.add_child(_slider_row("music_volume", tr("SETTINGS_MUSIC")))
	box.add_child(_slider_row("sfx_volume", tr("SETTINGS_SFX")))
	box.add_child(_language_row())
	box.add_child(_quality_row())
	_vibration = UiKit.button("", UiKit.GREEN)
	_vibration.toggle_mode = true
	_vibration.toggled.connect(_on_vibration_toggled)
	box.add_child(_vibration)
	_reset_button = UiKit.button(tr("SETTINGS_RESET_SAVE"), UiKit.RED, _on_reset_pressed)
	box.add_child(_reset_button)
	box.add_child(UiKit.button(tr("SETTINGS_BACK"), UiKit.GREEN, closed.emit))
	Settings.changed.connect(refresh)
	refresh()


## Loads the current settings into the controls (without writing them back).
func refresh() -> void:
	_updating = true
	var data := Settings.data
	for field: String in _sliders:
		(_sliders[field] as HSlider).value = data.get(field)
	_language.select(_language_index(data.language))
	_quality.select(int(data.quality))
	_vibration.button_pressed = data.vibration
	_update_vibration_text()
	_updating = false


func slider(field: String) -> HSlider:
	return _sliders[field]


func language_option() -> OptionButton:
	return _language


func quality_option() -> OptionButton:
	return _quality


func vibration_toggle() -> Button:
	return _vibration


func press_reset() -> void:
	_on_reset_pressed()


func is_reset_armed() -> bool:
	return _reset_armed


func _slider_row(field: String, text: String) -> Control:
	var row := HBoxContainer.new()
	var label := UiKit.label(text)
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	var slider_node := UiKit.slider()
	slider_node.custom_minimum_size.x = SLIDER_WIDTH
	slider_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_node.value_changed.connect(_on_slider_changed.bind(field))
	row.add_child(slider_node)
	_sliders[field] = slider_node
	return row


func _language_row() -> Control:
	var row := HBoxContainer.new()
	var label := UiKit.label(tr("SETTINGS_LANGUAGE"))
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	_language = _option_button()
	_language.add_item(tr("SETTINGS_LANGUAGE_AUTO"))
	for code: String in SettingsData.LANGUAGES.slice(1):
		_language.add_item(LANGUAGE_NAMES[code])
	_language.item_selected.connect(_on_language_selected)
	row.add_child(_language)
	return row


func _quality_row() -> Control:
	var row := HBoxContainer.new()
	var label := UiKit.label(tr("SETTINGS_QUALITY"))
	label.custom_minimum_size.x = LABEL_WIDTH
	row.add_child(label)
	_quality = _option_button()
	_quality.add_item(tr("SETTINGS_QUALITY_LOW"))
	_quality.add_item(tr("SETTINGS_QUALITY_MEDIUM"))
	_quality.add_item(tr("SETTINGS_QUALITY_HIGH"))
	_quality.item_selected.connect(_on_quality_selected)
	row.add_child(_quality)
	return row


func _option_button() -> OptionButton:
	var button := OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.style_option(button)
	return button


func _language_index(code: String) -> int:
	return maxi(SettingsData.LANGUAGES.find(code), 0)


func _changed_copy() -> SettingsData:
	return Settings.data.duplicate_data()


func _on_slider_changed(value: float, field: String) -> void:
	if _updating:
		return
	var data := _changed_copy()
	data.set(field, value)
	Settings.update(data)


func _on_language_selected(index: int) -> void:
	if _updating:
		return
	var data := _changed_copy()
	data.language = SettingsData.LANGUAGES[index]
	Settings.update(data)


func _on_quality_selected(index: int) -> void:
	if _updating:
		return
	var data := _changed_copy()
	data.quality = index as SettingsData.Quality
	Settings.update(data)


func _update_vibration_text() -> void:
	var state := tr("SETTINGS_ON") if _vibration.button_pressed else tr("SETTINGS_OFF")
	_vibration.text = "%s: %s" % [tr("SETTINGS_VIBRATION"), state]


func _on_vibration_toggled(enabled: bool) -> void:
	_update_vibration_text()
	if _updating:
		return
	var data := _changed_copy()
	data.vibration = enabled
	Settings.update(data)


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = tr("SETTINGS_RESET_CONFIRM")
		_reset_timer = get_tree().create_timer(CONFIRM_WINDOW_SEC, true, false, true)
		_reset_timer.timeout.connect(_disarm_reset)
		return
	_disarm_reset()
	SaveManager.delete_save()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _disarm_reset() -> void:
	_reset_armed = false
	if _reset_button != null:
		_reset_button.text = tr("SETTINGS_RESET_SAVE")
