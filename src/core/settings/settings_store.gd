class_name SettingsStore
extends RefCounted
## Reads and writes settings as a ConfigFile (user://settings.cfg). A missing or damaged file
## gives defaults; it never raises.

const SECTION: String = "settings"

var _path: String


func _init(path: String) -> void:
	_path = path


func load_settings() -> SettingsData:
	var config := ConfigFile.new()
	if config.load(_path) != OK:
		return SettingsData.new()
	var raw := {}
	for key in config.get_section_keys(SECTION):
		raw[key] = config.get_value(SECTION, key)
	return SettingsData.from_dict(raw)


func save_settings(data: SettingsData) -> bool:
	var config := ConfigFile.new()
	var values := data.to_dict()
	for key: String in values:
		config.set_value(SECTION, key, values[key])
	var error := config.save(_path)
	if error != OK:
		push_error("Cannot save settings to %s: %s" % [_path, error])
	return error == OK
