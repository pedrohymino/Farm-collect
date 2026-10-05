extends GutTest


func test_add_and_take_all() -> void:
	var stash := MoneyStash.new()
	stash.add(10.0)
	stash.add(2.5)
	assert_eq(stash.value, 12.5)
	assert_eq(stash.take_all(), 12.5)
	assert_eq(stash.value, 0.0)


func test_ignores_non_positive_amounts() -> void:
	var stash := MoneyStash.new()
	stash.add(-5.0)
	stash.add(0.0)
	assert_eq(stash.value, 0.0)


func test_emits_changed() -> void:
	var stash := MoneyStash.new()
	watch_signals(stash)
	stash.add(3.0)
	assert_signal_emitted_with_parameters(stash, "changed", [3.0])


func test_load_rejects_invalid_values() -> void:
	var stash := MoneyStash.new()
	stash.load_value("abc")
	assert_eq(stash.value, 0.0)
	stash.load_value(-3)
	assert_eq(stash.value, 0.0)
	stash.load_value(7)
	assert_eq(stash.value, 7.0)
