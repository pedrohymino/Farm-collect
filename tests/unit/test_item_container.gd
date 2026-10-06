extends GutTest


func _container(capacity: int, accepts: Array[StringName] = []) -> ItemContainer:
	return ItemContainer.new(func() -> int: return capacity, accepts)


func test_push_until_full() -> void:
	var c := _container(2)
	assert_true(c.push(&"egg"))
	assert_true(c.push(&"milk"))
	assert_true(c.is_full())
	assert_false(c.push(&"egg"))
	assert_eq(c.size(), 2)


func test_filter_rejects_other_item_types() -> void:
	var c := _container(10, [&"egg"])
	assert_false(c.can_accept(&"milk"))
	assert_false(c.push(&"milk"))
	assert_true(c.push(&"egg"))


func test_capacity_is_read_live() -> void:
	var capacity: Array[int] = [1]
	var c := ItemContainer.new(func() -> int: return capacity[0])
	c.push(&"egg")
	assert_true(c.is_full())
	capacity[0] = 3
	assert_false(c.is_full())
	assert_eq(c.free_space(), 2)


func test_lowering_capacity_keeps_existing_items() -> void:
	var capacity: Array[int] = [3]
	var c := ItemContainer.new(func() -> int: return capacity[0])
	c.push(&"egg")
	c.push(&"egg")
	capacity[0] = 1
	assert_eq(c.size(), 2)
	assert_true(c.is_full())
	assert_eq(c.free_space(), 0)


func test_pop_top_returns_last_pushed() -> void:
	var c := _container(5)
	c.push(&"egg")
	c.push(&"milk")
	assert_eq(c.pop_top(), &"milk")
	assert_eq(c.pop_top(), &"egg")
	assert_eq(c.pop_top(), &"")


func test_pop_matching_takes_topmost_matching_item() -> void:
	var c := _container(5)
	c.push(&"egg")
	c.push(&"milk")
	c.push(&"wheat")
	assert_eq(c.pop_matching([&"egg"]), &"egg")
	assert_eq(c.items(), [&"milk", &"wheat"])
	assert_eq(c.pop_matching([&"egg"]), &"")


func test_count_by_item() -> void:
	var c := _container(5)
	c.push(&"egg")
	c.push(&"milk")
	c.push(&"egg")
	assert_eq(c.count(&"egg"), 2)
	assert_eq(c.count(&"wheat"), 0)


func test_emits_signals_with_index() -> void:
	var c := _container(5)
	watch_signals(c)
	c.push(&"egg")
	c.push(&"milk")
	c.pop_matching([&"egg"])
	assert_signal_emitted_with_parameters(c, "item_added", [&"milk", 1])
	assert_signal_emitted_with_parameters(c, "item_removed", [&"egg", 0])


func test_items_returns_a_copy() -> void:
	var c := _container(5)
	c.push(&"egg")
	var snapshot := c.items()
	snapshot.append(&"milk")
	assert_eq(c.size(), 1)


func test_transfer_one_moves_topmost_acceptable_item() -> void:
	var player := _container(5)
	var counter := _container(5, [&"egg"])
	player.push(&"egg")
	player.push(&"milk")
	assert_eq(ItemContainer.transfer_one(player, counter), &"egg")
	assert_eq(player.items(), [&"milk"])
	assert_eq(counter.items(), [&"egg"])


func test_transfer_one_does_nothing_when_target_full_or_no_match() -> void:
	var from := _container(5)
	var to := _container(1, [&"egg"])
	from.push(&"milk")
	assert_eq(ItemContainer.transfer_one(from, to), &"")
	from.push(&"egg")
	to.push(&"egg")
	assert_eq(ItemContainer.transfer_one(from, to), &"")
	assert_eq(from.size(), 2)


func test_serialization_round_trip() -> void:
	var c := _container(5)
	c.push(&"egg")
	c.push(&"milk")
	var restored := _container(5)
	restored.load_array(c.to_array())
	assert_eq(restored.items(), [&"egg", &"milk"])


func test_load_array_skips_items_not_accepted() -> void:
	var c := _container(5, [&"egg"])
	c.load_array(["egg", "milk", 42, "egg"])
	assert_eq(c.items(), [&"egg", &"egg"])


func test_find_transfer_index_points_at_topmost_acceptable_item() -> void:
	var from := _container(5)
	var to := _container(5, [&"egg"])
	from.push(&"egg")
	from.push(&"egg")
	from.push(&"milk")
	assert_eq(ItemContainer.find_transfer_index(from, to), 1)
	assert_eq(ItemContainer.find_transfer_index(from, _container(0)), -1)


func test_stat_capacity_reads_from_stat_source() -> void:
	var registry := StatRegistry.new()
	registry.load_defs({"cap": {"base": 2, "integer": true}})
	var c := ItemContainer.new(ItemContainer.stat_capacity(registry, &"cap"))
	assert_eq(c.capacity(), 2)
	registry.set_base(&"cap", 4.0)
	assert_eq(c.capacity(), 4)


func test_set_accepts_changes_filter() -> void:
	var c := _container(5, [&"egg"])
	c.set_accepts([&"milk"] as Array[StringName])
	assert_false(c.accepts(&"egg"))
	assert_true(c.push(&"milk"))
