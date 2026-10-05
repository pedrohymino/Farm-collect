extends GutTest
## Dev panel driving the real Stats autoload (no session file: uses a temp store).

const CARRY := &"player.carry_capacity"
const YIELD := &"production.yield"

var panel: DevPanel
var dir_path: String


func before_each() -> void:
	dir_path = "user://test_dev_panel_%d" % Time.get_ticks_usec()
	panel = DevPanel.new(DevSessionStore.new(dir_path))
	add_child_autofree(panel)


func after_each() -> void:
	DevSessionStore.apply(Stats.registry, {}, ContentDB.balance.stats)
	Engine.time_scale = 1.0


func test_has_a_row_for_every_stat() -> void:
	for stat_id in Stats.stat_ids():
		assert_not_null(panel.row(stat_id), String(stat_id))


func test_multiplier_changes_live_value() -> void:
	panel.row(CARRY).set_multiplier(2.0)
	assert_eq(Stats.get_int(CARRY), 16)
	panel.row(YIELD).set_multiplier(3.0)
	assert_eq(Stats.get_value(YIELD), 3.0)


func test_fixed_value_overrides_formula() -> void:
	panel.row(CARRY).set_fixed(true, 50.0)
	assert_eq(Stats.get_int(CARRY), 50)
	panel.row(CARRY).set_fixed(false, 50.0)
	assert_eq(Stats.get_int(CARRY), 8)


func test_reset_restores_file_value() -> void:
	panel.row(CARRY).set_multiplier(4.0)
	panel.row(CARRY).set_base_value(20.0)
	panel.row(CARRY).reset()
	assert_eq(Stats.get_int(CARRY), 8)
	assert_eq(Stats.registry.dev_overrides(), {})


func test_bake_moves_override_into_base() -> void:
	panel.row(CARRY).set_multiplier(2.0)
	panel.row(CARRY).bake()
	assert_eq(Stats.registry.get_base(CARRY), 16.0)
	assert_eq(Stats.registry.dev_overrides(), {})
	var changes := BalanceWriter.changed_bases(ContentDB.balance.stats, Stats.registry)
	assert_eq(changes[0]["id"], String(CARRY))


func test_badge_shows_active_override_count() -> void:
	assert_eq(panel.overlay_text(), "")
	panel.row(CARRY).set_multiplier(2.0)
	panel.row(YIELD).set_multiplier(2.0)
	assert_string_contains(panel.overlay_text(), "2")


func test_search_filters_rows() -> void:
	panel.filter_stats("carry")
	assert_true(panel.row(CARRY).visible)
	assert_false(panel.row(YIELD).visible)
	panel.filter_stats("")
	assert_true(panel.row(YIELD).visible)


func test_toggle_opens_and_closes() -> void:
	assert_false(panel.is_open())
	panel.toggle()
	assert_true(panel.is_open())
