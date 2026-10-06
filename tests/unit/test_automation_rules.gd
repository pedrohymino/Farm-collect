extends GutTest
## WorkerBrain, TruckOrderRules, IncomeMeter and OfflineRules.

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 42


func test_brain_works_after_arriving_and_moves_on_when_done() -> void:
	var brain := WorkerBrain.new(2, 1.0)
	brain.update(0.1, false, false, false, true)
	assert_eq(brain.state, WorkerBrain.State.MOVING)
	brain.update(0.1, true, false, false, true)
	assert_eq(brain.state, WorkerBrain.State.WORKING)
	brain.update(0.1, true, true, true, true)
	assert_eq(brain.state, WorkerBrain.State.MOVING)
	assert_eq(brain.stop_index, 1)


func test_brain_gives_up_when_idle_only_if_allowed() -> void:
	var brain := WorkerBrain.new(2, 1.0)
	brain.update(0.1, true, false, false, true)
	brain.update(2.0, true, false, false, false)
	assert_eq(brain.stop_index, 0, "not allowed to leave yet")
	brain.update(2.0, true, false, false, true)
	assert_eq(brain.stop_index, 1)


func test_brain_progress_resets_idle_timer() -> void:
	var brain := WorkerBrain.new(2, 1.0)
	brain.update(0.1, true, false, false, true)
	brain.update(0.8, true, false, false, true)
	brain.update(0.8, true, false, true, true)
	brain.update(0.8, true, false, false, true)
	assert_eq(brain.stop_index, 0)


func test_cashier_brain_never_leaves() -> void:
	var brain := WorkerBrain.new(1, INF)
	brain.update(0.1, true, false, false, true)
	brain.update(1000.0, true, false, false, true)
	assert_eq(brain.state, WorkerBrain.State.WORKING)


func test_order_size_grows_with_level() -> void:
	var items: Array[StringName] = [&"egg"]
	assert_eq(TruckOrderRules.generate(items, 1, 12, 0.15, rng), {&"egg": 12})
	assert_eq(TruckOrderRules.generate(items, 5, 12, 0.15, rng), {&"egg": 19})


func test_order_uses_at_most_two_available_items_and_keeps_total() -> void:
	var items: Array[StringName] = [&"egg", &"milk", &"wheat"]
	for i in 20:
		var order := TruckOrderRules.generate(items, 1, 12, 0.0, rng)
		assert_lte(order.size(), 2)
		var total := 0
		for item_id: StringName in order:
			assert_true(items.has(item_id))
			total += order[item_id]
		assert_eq(total, 12)


func test_reward_applies_prices_and_bonus() -> void:
	var order := {&"egg": 10, &"milk": 2}
	assert_eq(TruckOrderRules.reward(order, {&"egg": 3.0, &"milk": 8.0}, 1.5), 69.0)


func test_remaining_items() -> void:
	var order := {&"egg": 10, &"milk": 2}
	assert_eq(TruckOrderRules.remaining(order, {&"egg": 4, &"milk": 2}), {&"egg": 6})


func test_income_meter_rate_over_window() -> void:
	var meter := IncomeMeter.new(0.0)
	meter.record(60.0, 30.0)
	meter.record(60.0, 90.0)
	assert_almost_eq(meter.rate(120.0), 1.0, 0.0001)


func test_income_meter_uses_minimum_span_early() -> void:
	var meter := IncomeMeter.new(0.0)
	meter.record(30.0, 1.0)
	assert_almost_eq(meter.rate(2.0), 0.5, 0.0001)


func test_income_meter_forgets_old_samples() -> void:
	var meter := IncomeMeter.new(0.0)
	meter.record(300.0, 10.0)
	assert_eq(meter.rate(400.0), 0.0)


func test_offline_earnings_cap_and_efficiency() -> void:
	assert_eq(OfflineRules.earnings(2.0, 3600.0, 2.0, 0.25), 1800.0)
	assert_eq(OfflineRules.earnings(2.0, 100000.0, 2.0, 0.25), 3600.0)
	assert_eq(OfflineRules.earnings(2.0, 30.0, 2.0, 1.0), 0.0)
	assert_eq(OfflineRules.earnings(0.0, 3600.0, 2.0, 1.0), 0.0)


func test_away_seconds_guards_bad_clocks() -> void:
	assert_eq(OfflineRules.away_seconds(1000.0, 1600.0), 600.0)
	assert_eq(OfflineRules.away_seconds(1000.0, 900.0), 0.0)
	assert_eq(OfflineRules.away_seconds(0.0, 1600.0), 0.0)
