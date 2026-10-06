extends GutTest

var store: SaveStore
var dir_path: String


func before_each() -> void:
	dir_path = "user://test_saves_%d" % Time.get_ticks_usec()
	store = SaveStore.new(dir_path, "slot_0")


func after_each() -> void:
	_remove_dir(dir_path)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
	DirAccess.remove_absolute(path)


func _write_raw(file_name: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(dir_path.path_join(file_name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_read_without_save_reports_none() -> void:
	var result := store.read()
	assert_eq(result.status, SaveStore.ReadStatus.NONE)


func test_write_then_read_round_trip() -> void:
	assert_true(store.write({"schema_version": 1, "data": {"money": 10}}))
	var result := store.read()
	assert_eq(result.status, SaveStore.ReadStatus.OK)
	assert_eq(result.source, "main")
	assert_eq(result.payload["data"]["money"], 10.0)


func test_second_write_keeps_previous_as_backup() -> void:
	store.write({"schema_version": 1, "n": 1})
	store.write({"schema_version": 1, "n": 2})
	assert_true(FileAccess.file_exists(store.backup_path()))
	assert_eq(store.read().payload["n"], 2.0)


func test_corrupt_main_falls_back_to_backup() -> void:
	store.write({"schema_version": 1, "n": 1})
	store.write({"schema_version": 1, "n": 2})
	_write_raw("slot_0.json", "{ not json")
	var result := store.read()
	assert_eq(result.status, SaveStore.ReadStatus.OK)
	assert_eq(result.source, "backup")
	assert_eq(result.payload["n"], 1.0)


func test_corrupt_main_without_backup_is_reported() -> void:
	_write_raw("slot_0.json", "[1, 2")
	assert_eq(store.read().status, SaveStore.ReadStatus.CORRUPT)


func test_quarantine_moves_main_file_aside() -> void:
	_write_raw("slot_0.json", "garbage")
	var moved_to := store.quarantine_main()
	assert_false(FileAccess.file_exists(store.main_path()))
	assert_true(FileAccess.file_exists(moved_to))


func test_quarantine_also_moves_the_backup() -> void:
	store.write({"schema_version": 1, "n": 1})
	store.write({"schema_version": 1, "n": 2})
	store.quarantine_main()
	assert_false(store.exists(), "nothing left that looks like a continuable save")


func test_delete_all_removes_every_slot_file() -> void:
	store.write({"schema_version": 1, "n": 1})
	store.write({"schema_version": 1, "n": 2})
	store.delete_all()
	assert_false(FileAccess.file_exists(store.main_path()))
	assert_false(FileAccess.file_exists(store.backup_path()))
	assert_eq(store.read().status, SaveStore.ReadStatus.NONE)


func test_exists_reports_main_or_backup() -> void:
	assert_false(store.exists())
	store.write({"schema_version": 1, "n": 1})
	assert_true(store.exists())


func test_corrupt_main_does_not_overwrite_good_backup() -> void:
	store.write({"schema_version": 1, "n": 1})
	store.write({"schema_version": 1, "n": 2})
	_write_raw("slot_0.json", "{ broken")
	store.write({"schema_version": 1, "n": 3})
	assert_eq(store.read().payload["n"], 3.0)
	_write_raw("slot_0.json", "{ broken again")
	assert_eq(store.read().payload["n"], 1.0, "backup still holds the last good main file")


func test_write_fails_cleanly_when_temp_file_cannot_be_created() -> void:
	store.write({"schema_version": 1, "n": 1})
	DirAccess.make_dir_recursive_absolute(store.temp_path())
	assert_false(store.write({"schema_version": 1, "n": 2}))
	assert_push_error("Cannot write save")
	DirAccess.remove_absolute(store.temp_path())
	assert_eq(store.read().payload["n"], 1.0, "previous save untouched")
