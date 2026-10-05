class_name DevSessionStore
extends RefCounted
## Persists dev tuning (stat overrides + edited bases) outside the player's save:
## the current session (restored on the next run) and named presets.
## Data shape:
##   {"overrides": {id: {"multiplier": float, "absolute": float|null}}, "bases": {id: float}}

const SESSION_FILE: String = "session.json"
const PRESETS_DIR: String = "presets"
const PRESET_NAME_PATTERN: String = "^[A-Za-z0-9_-]{1,40}$"

var _dir_path: String


func _init(dir_path: String) -> void:
	_dir_path = dir_path


static func is_valid_preset_name(preset_name: String) -> bool:
	var regex := RegEx.create_from_string(PRESET_NAME_PATTERN)
	return regex.search(preset_name) != null


static func capture(registry: StatRegistry, original_stats: Dictionary) -> Dictionary:
	var overrides := {}
	var dev := registry.dev_overrides()
	for stat_id: StringName in dev:
		overrides[String(stat_id)] = dev[stat_id]
	var bases := {}
	for change in BalanceWriter.changed_bases(original_stats, registry):
		bases[change["id"]] = change["new"]
	return {"overrides": overrides, "bases": bases}


## Replaces all current tuning with `data` (bases not listed go back to the original file values).
static func apply(registry: StatRegistry, data: Dictionary, original_stats: Dictionary) -> void:
	registry.clear_all_dev_overrides()
	var bases: Dictionary = (
		data.get("bases", {}) if typeof(data.get("bases")) == TYPE_DICTIONARY else {}
	)
	for stat_id: String in original_stats:
		var base: Variant = bases.get(stat_id, original_stats[stat_id].get("base", 0.0))
		registry.set_base(StringName(stat_id), float(base))
	var overrides: Variant = data.get("overrides", {})
	if typeof(overrides) != TYPE_DICTIONARY:
		return
	for stat_id: String in overrides:
		var entry: Variant = overrides[stat_id]
		if not registry.has_stat(StringName(stat_id)) or typeof(entry) != TYPE_DICTIONARY:
			continue
		registry.set_dev_override(
			StringName(stat_id), float(entry.get("multiplier", 1.0)), entry.get("absolute")
		)


func save_session(data: Dictionary) -> bool:
	return _write(_dir_path.path_join(SESSION_FILE), data)


func load_session() -> Dictionary:
	return _read(_dir_path.path_join(SESSION_FILE))


func save_preset(preset_name: String, data: Dictionary) -> bool:
	if not is_valid_preset_name(preset_name):
		return false
	return _write(_preset_path(preset_name), data)


func load_preset(preset_name: String) -> Dictionary:
	if not is_valid_preset_name(preset_name):
		return {}
	return _read(_preset_path(preset_name))


func delete_preset(preset_name: String) -> void:
	if is_valid_preset_name(preset_name) and FileAccess.file_exists(_preset_path(preset_name)):
		DirAccess.remove_absolute(_preset_path(preset_name))


func list_presets() -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(_dir_path.path_join(PRESETS_DIR))
	if dir == null:
		return names
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			names.append(file_name.get_basename())
	names.sort()
	return names


func _preset_path(preset_name: String) -> String:
	return _dir_path.path_join(PRESETS_DIR).path_join(preset_name + ".json")


func _write(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s: %s" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
