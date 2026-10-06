extends GutTest
## SaveManager reports save problems on the EventBus (shown to the player by NoticeToast).

var _original_store: SaveStore
var _dir_path: String
var _store: SaveStore
var _kinds: Array[StringName] = []
var _failed_count: int = 0


func before_each() -> void:
	_original_store = SaveManager._store
	_dir_path = "user://test_problems_%d" % Time.get_ticks_usec()
	_store = SaveStore.new(_dir_path, "slot_0")
	SaveManager._store = _store
	_kinds.clear()
	_failed_count = 0
	EventBus.save_problem.connect(_on_problem)
	EventBus.save_failed.connect(_on_failed)


func after_each() -> void:
	EventBus.save_problem.disconnect(_on_problem)
	EventBus.save_failed.disconnect(_on_failed)
	SaveManager._store = _original_store
	SaveManager._is_active = false
	var dir := DirAccess.open(_dir_path)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(_dir_path)


func _on_problem(kind: StringName) -> void:
	_kinds.append(kind)


func _on_failed() -> void:
	_failed_count += 1


func _write_raw(file_name: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(_dir_path)
	var file := FileAccess.open(_dir_path.path_join(file_name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_has_save_follows_the_store() -> void:
	assert_false(SaveManager.has_save())
	_write_raw("slot_0.json", "{}")
	assert_true(SaveManager.has_save())


func test_missing_save_is_not_a_problem() -> void:
	SaveManager.load_game()
	assert_eq(_kinds.size(), 0)


func test_unreadable_save_starts_fresh_and_reports_it() -> void:
	_write_raw("slot_0.json", "{ not json")
	SaveManager.load_game()
	assert_push_error("Save could not be loaded")
	assert_eq(_kinds, [&"corrupt_reset"] as Array[StringName])
	assert_false(FileAccess.file_exists(_store.main_path()), "corrupt file moved aside")


func test_backup_is_used_and_reported() -> void:
	SaveManager.load_game()
	assert_true(SaveManager.save_game())
	assert_true(SaveManager.save_game())
	_write_raw("slot_0.json", "{ broken")
	_kinds.clear()
	SaveManager.load_game()
	assert_eq(_kinds, [&"restored_from_backup"] as Array[StringName])


func test_failed_write_is_reported() -> void:
	SaveManager.load_game()
	DirAccess.make_dir_recursive_absolute(_store.temp_path())
	assert_false(SaveManager.save_game())
	assert_push_error("Cannot write save")
	assert_eq(_failed_count, 1)
	DirAccess.remove_absolute(_store.temp_path())


func test_save_dated_in_the_future_gives_no_offline_time() -> void:
	var now := Time.get_unix_time_from_system()
	assert_eq(OfflineRules.away_seconds(now + 86400.0, now), 0.0)
