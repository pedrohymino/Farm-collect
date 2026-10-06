extends GutTest
## The shipped balance must keep the pacing targets of docs/03 (section 7).
## The simulation is a flow model, so each target gets a tolerance instead of an exact time.

const TOLERANCE: float = 1.5

var _balance: BalanceData
var _sim: PacingSim


func before_all() -> void:
	_balance = BalanceData.load_from_dir("res://data/balance")
	_sim = PacingSim.new(_balance)
	_sim.run()


func _assert_by(unlock_id: StringName, target_sec: float) -> void:
	var time := _sim.time_of("unlock", unlock_id)
	assert_gt(time, 0.0, "%s was never bought" % unlock_id)
	assert_lt(
		time, target_sec * TOLERANCE, "%s took %d s (target %d)" % [unlock_id, time, target_sec]
	)


func test_balance_data_is_valid() -> void:
	assert_eq(_balance.errors.size(), 0, str(_balance.errors))


func test_first_sale_is_quick() -> void:
	assert_lt(_sim.seconds_to_first_sale(), 20.0)


func test_early_pads_follow_the_targets() -> void:
	_assert_by(&"chicken_3", 45.0)
	_assert_by(&"upgrade_board", 120.0)
	_assert_by(&"area_field", 240.0)


func test_midgame_pads_follow_the_targets() -> void:
	_assert_by(&"barn", 600.0)
	_assert_by(&"cashier_egg", 900.0)
	_assert_by(&"truck_bay", 1800.0)


func test_complete_farm_takes_two_to_three_hours() -> void:
	var done := _sim.finished_at()
	assert_gt(done, 2.0 * 3600.0 * 0.75, "finished too early: %d s" % done)
	assert_lt(done, 3.0 * 3600.0, "finished too late: %d s" % done)


func test_every_unlock_is_reachable() -> void:
	for unlock_id in UnlockRules.new(_balance.unlocks).ids():
		assert_gt(_sim.time_of("unlock", unlock_id), 0.0, "%s unreachable" % unlock_id)


func test_no_long_silences_between_pads_early() -> void:
	var previous := 0.0
	for entry in _sim.timeline:
		if entry.kind != "unlock" or entry.t > 600.0:
			continue
		assert_lt(entry.t - previous, 150.0, "waited too long before %s" % entry.id)
		previous = entry.t
