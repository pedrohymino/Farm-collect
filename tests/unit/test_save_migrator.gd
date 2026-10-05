extends GutTest


func _fake_migrator() -> SaveMigrator:
	var steps := {
		0:
		func(data: Dictionary) -> Dictionary:
			data["coins"] = data.get("gold", 0)
			data.erase("gold")
			return data,
		1:
		func(data: Dictionary) -> Dictionary:
			data["farm_level"] = 1
			return data,
	}
	return SaveMigrator.new(2, steps)


func test_current_version_passes_through() -> void:
	var result := _fake_migrator().migrate({"schema_version": 2, "data": {"a": 1}})
	assert_true(result.ok)
	assert_eq(result.data, {"a": 1})


func test_old_version_runs_every_step_in_order() -> void:
	var result := _fake_migrator().migrate({"schema_version": 0, "data": {"gold": 7}})
	assert_true(result.ok)
	assert_eq(result.data, {"coins": 7, "farm_level": 1})


func test_newer_version_is_rejected() -> void:
	var result := _fake_migrator().migrate({"schema_version": 3, "data": {}})
	assert_false(result.ok)
	assert_string_contains(result.error, "newer")


func test_missing_step_is_rejected() -> void:
	var migrator := SaveMigrator.new(2, {})
	var result := migrator.migrate({"schema_version": 1, "data": {}})
	assert_false(result.ok)


func test_payload_without_version_or_data_is_rejected() -> void:
	assert_false(_fake_migrator().migrate({"data": {}}).ok)
	assert_false(_fake_migrator().migrate({"schema_version": 2}).ok)


func test_production_migrator_accepts_current_version() -> void:
	var migrator := SaveMigrator.create_default()
	var result := migrator.migrate({"schema_version": SaveMigrator.CURRENT_VERSION, "data": {}})
	assert_true(result.ok)
