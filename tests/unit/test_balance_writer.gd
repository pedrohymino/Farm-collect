extends GutTest

const STATS_PATH := "res://data/balance/stats.json"

var original: Dictionary


func before_each() -> void:
	original = {
		"player.speed": {"base": 4.0, "min": 1.0},
		"player.carry": {"base": 8, "min": 1, "integer": true},
		"sell.price": {"base": 1.0, "min": 0.1},
	}


func _registry() -> StatRegistry:
	var registry := StatRegistry.new()
	registry.load_defs(original)
	return registry


func test_no_changes_when_bases_match() -> void:
	assert_eq(BalanceWriter.changed_bases(original, _registry()), [])


func test_detects_changed_bases_only() -> void:
	var registry := _registry()
	registry.set_base(&"player.carry", 12.0)
	registry.set_dev_override(&"player.speed", 3.0)
	var changes := BalanceWriter.changed_bases(original, registry)
	assert_eq(changes.size(), 1)
	assert_eq(changes[0]["id"], "player.carry")
	assert_eq(changes[0]["old"], 8.0)
	assert_eq(changes[0]["new"], 12.0)


func test_with_bases_returns_updated_copy() -> void:
	var updated := BalanceWriter.with_bases(
		original, [{"id": "sell.price", "old": 1.0, "new": 1.5}]
	)
	assert_eq(updated["sell.price"]["base"], 1.5)
	assert_eq(original["sell.price"]["base"], 1.0)


func test_format_keeps_integers_and_floats_readable() -> void:
	var text := BalanceWriter.format_stats(original)
	assert_string_contains(text, '"player.carry": { "base": 8, "min": 1, "integer": true }')
	assert_string_contains(text, '"player.speed": { "base": 4.0, "min": 1.0 }')


func test_format_separates_prefix_groups_with_blank_line() -> void:
	var text := BalanceWriter.format_stats(original)
	assert_string_contains(text, '"min": 1, "integer": true },\n\n  "sell.price"')


func test_project_stats_file_round_trips_exactly() -> void:
	var text := FileAccess.get_file_as_string(STATS_PATH)
	var parsed: Dictionary = JSON.parse_string(text)
	assert_eq(BalanceWriter.format_stats(parsed), text)


func test_write_then_load_persists_new_base() -> void:
	var path := "user://test_stats_%d.json" % Time.get_ticks_usec()
	var updated := BalanceWriter.with_bases(
		original, [{"id": "player.carry", "old": 8.0, "new": 20.0}]
	)
	assert_true(BalanceWriter.write_stats(path, updated))
	var reloaded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(reloaded["player.carry"]["base"], 20.0)
	DirAccess.remove_absolute(path)
