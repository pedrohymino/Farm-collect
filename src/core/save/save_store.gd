class_name SaveStore
extends RefCounted
## Atomic JSON persistence for one save slot.
## write(): payload -> <slot>.tmp, current <slot>.json -> <slot>.bak, then .tmp -> .json.
## read(): <slot>.json, falling back to <slot>.bak if the main file is missing or corrupt.

enum ReadStatus { OK, NONE, CORRUPT }


class ReadResult:
	extends RefCounted
	var status: int = ReadStatus.NONE
	var source: String = ""
	var payload: Dictionary = {}
	var error: String = ""


var _dir_path: String
var _slot: String


func _init(dir_path: String, slot: String) -> void:
	_dir_path = dir_path
	_slot = slot


func main_path() -> String:
	return _dir_path.path_join(_slot + ".json")


func backup_path() -> String:
	return _dir_path.path_join(_slot + ".bak")


func temp_path() -> String:
	return _dir_path.path_join(_slot + ".tmp")


func write(payload: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(_dir_path)
	var file := FileAccess.open(temp_path(), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save %s: %s" % [temp_path(), FileAccess.get_open_error()])
		return false
	var stored := file.store_string(JSON.stringify(payload, "\t"))
	var flush_error := file.get_error()
	file.close()
	# A full disk can leave a truncated file: never promote a temp file that does not parse.
	if not stored or flush_error != OK or _parse(temp_path()) == null:
		push_error("Save write was incomplete (%s); keeping the previous save." % flush_error)
		DirAccess.remove_absolute(temp_path())
		return false

	# Only a readable main file may replace the backup, so a good backup is never overwritten.
	if _parse(main_path()) != null:
		var copy_error := DirAccess.copy_absolute(main_path(), backup_path())
		if copy_error != OK:
			push_error("Cannot back up save %s: %s" % [main_path(), copy_error])
			return false

	var rename_error := DirAccess.rename_absolute(temp_path(), main_path())
	if rename_error != OK:
		# Some platforms refuse to rename over an existing file.
		DirAccess.remove_absolute(main_path())
		rename_error = DirAccess.rename_absolute(temp_path(), main_path())
	if rename_error != OK:
		push_error("Cannot finalize save %s: %s" % [main_path(), rename_error])
		return false
	return true


func exists() -> bool:
	return FileAccess.file_exists(main_path()) or FileAccess.file_exists(backup_path())


func read() -> ReadResult:
	var result := ReadResult.new()
	var has_main := FileAccess.file_exists(main_path())
	var has_backup := FileAccess.file_exists(backup_path())
	if not has_main and not has_backup:
		result.status = ReadStatus.NONE
		return result

	for candidate: Array in [[main_path(), "main"], [backup_path(), "backup"]]:
		var payload: Variant = _parse(candidate[0])
		if payload != null:
			result.status = ReadStatus.OK
			result.source = candidate[1]
			result.payload = payload
			return result

	result.status = ReadStatus.CORRUPT
	result.error = "save and backup are unreadable"
	return result


## Deletes main, backup and temp files (dev "reset save"; never used for corrupt saves).
func delete_all() -> void:
	for path in [main_path(), backup_path(), temp_path()]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Moves the main save and its backup aside (never deletes player data), so a new game does not
## look like a continuable one. Returns the new path of the main file.
func quarantine_main() -> String:
	var stamp := int(Time.get_unix_time_from_system())
	var target := _dir_path.path_join("%s.corrupt-%d.json" % [_slot, stamp])
	DirAccess.rename_absolute(main_path(), target)
	if FileAccess.file_exists(backup_path()):
		DirAccess.rename_absolute(
			backup_path(), _dir_path.path_join("%s.corrupt-%d.bak" % [_slot, stamp])
		)
	return target


## Returns the payload Dictionary, or null if the file is missing or invalid.
func _parse(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	if typeof(parser.data) != TYPE_DICTIONARY:
		return null
	return parser.data
