class_name SaveMigrator
extends RefCounted
## Brings old save payloads up to the current schema, one version step at a time.
##
## To change the save format: bump CURRENT_VERSION and add a step keyed by the OLD version
## in create_default(), e.g. 1: func(data): ...; return data. Never edit an existing step.

const CURRENT_VERSION: int = 1


class MigrationResult:
	extends RefCounted
	var ok: bool = false
	var data: Dictionary = {}
	var error: String = ""


var _current_version: int
var _steps: Dictionary  # int (from version) -> Callable(Dictionary) -> Dictionary


func _init(current_version: int, steps: Dictionary) -> void:
	_current_version = current_version
	_steps = steps


static func create_default() -> SaveMigrator:
	return SaveMigrator.new(CURRENT_VERSION, {})


## Payload shape: {"schema_version": int, "data": Dictionary, ...}
func migrate(payload: Dictionary) -> MigrationResult:
	var result := MigrationResult.new()
	var raw_version: Variant = payload.get("schema_version")
	if typeof(raw_version) != TYPE_INT and typeof(raw_version) != TYPE_FLOAT:
		result.error = "save has no schema_version"
		return result
	if typeof(payload.get("data")) != TYPE_DICTIONARY:
		result.error = "save has no data"
		return result

	var version := int(raw_version)
	if version > _current_version:
		result.error = "save is from a newer game version (%d > %d)" % [version, _current_version]
		return result

	var data: Dictionary = payload["data"].duplicate(true)
	while version < _current_version:
		if not _steps.has(version):
			result.error = "no migration step from version %d" % version
			return result
		data = _steps[version].call(data)
		version += 1

	result.ok = true
	result.data = data
	return result
