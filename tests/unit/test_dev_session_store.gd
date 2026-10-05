extends GutTest

var store: DevSessionStore
var dir_path: String
var original: Dictionary
var registry: StatRegistry


func before_each() -> void:
	dir_path = "user://test_dev_%d" % Time.get_ticks_usec()
	store = DevSessionStore.new(dir_path)
	original = {"carry": {"base": 8, "integer": true}, "speed": {"base": 4.0}}
	registry = StatRegistry.new()
	registry.load_defs(original)


func after_each() -> void:
	for sub in ["", "presets"]:
		var path := dir_path.path_join(sub)
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(dir_path.path_join("presets"))
	DirAccess.remove_absolute(dir_path)


func test_capture_records_overrides_and_changed_bases() -> void:
	registry.set_dev_override(&"carry", 2.0)
	registry.set_base(&"speed", 5.0)
	var data := DevSessionStore.capture(registry, original)
	assert_eq(data["overrides"]["carry"]["multiplier"], 2.0)
	assert_eq(data["bases"], {"speed": 5.0})


func test_apply_restores_capture_on_a_fresh_registry() -> void:
	registry.set_dev_override(&"carry", 1.0, 30.0)
	registry.set_base(&"speed", 6.0)
	var data := DevSessionStore.capture(registry, original)

	var fresh := StatRegistry.new()
	fresh.load_defs(original)
	DevSessionStore.apply(fresh, data, original)
	assert_eq(fresh.get_value(&"carry"), 30.0)
	assert_eq(fresh.get_value(&"speed"), 6.0)


func test_apply_resets_previous_tuning() -> void:
	registry.set_dev_override(&"carry", 5.0)
	registry.set_base(&"speed", 9.0)
	DevSessionStore.apply(registry, {}, original)
	assert_eq(registry.get_value(&"carry"), 8.0)
	assert_eq(registry.get_value(&"speed"), 4.0)


func test_apply_ignores_unknown_stats() -> void:
	DevSessionStore.apply(registry, {"overrides": {"ghost": {"multiplier": 2.0}}}, original)
	assert_eq(registry.dev_overrides(), {})


func test_session_round_trip() -> void:
	store.save_session({"overrides": {"carry": {"multiplier": 2.0, "absolute": null}}})
	assert_eq(store.load_session()["overrides"]["carry"]["multiplier"], 2.0)


func test_missing_session_is_empty() -> void:
	assert_eq(store.load_session(), {})


func test_preset_save_list_load_delete() -> void:
	assert_true(store.save_preset("fast_eggs", {"bases": {"speed": 7.0}}))
	assert_true(store.save_preset("big-bag", {}))
	assert_eq(store.list_presets(), PackedStringArray(["big-bag", "fast_eggs"]))
	assert_eq(store.load_preset("fast_eggs")["bases"]["speed"], 7.0)
	store.delete_preset("big-bag")
	assert_eq(store.list_presets(), PackedStringArray(["fast_eggs"]))


func test_invalid_preset_names_are_rejected() -> void:
	assert_false(DevSessionStore.is_valid_preset_name(""))
	assert_false(DevSessionStore.is_valid_preset_name("../evil"))
	assert_false(DevSessionStore.is_valid_preset_name("with space"))
	assert_true(DevSessionStore.is_valid_preset_name("Test_1-a"))
	assert_false(store.save_preset("../evil", {}))
