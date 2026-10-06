extends GutTest

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 1234


func test_integer_yield_without_double_chance() -> void:
	assert_eq(YieldRoller.roll(1.0, 0.0, rng), 1)
	assert_eq(YieldRoller.roll(3.0, 0.0, rng), 3)


func test_full_double_chance_doubles() -> void:
	assert_eq(YieldRoller.roll(2.0, 1.0, rng), 4)


func test_fractional_yield_averages_out() -> void:
	var total := 0
	for i in 10_000:
		total += YieldRoller.roll(1.5, 0.0, rng)
	assert_almost_eq(total / 10_000.0, 1.5, 0.03)


func test_double_chance_averages_out() -> void:
	var total := 0
	for i in 10_000:
		total += YieldRoller.roll(1.0, 0.25, rng)
	assert_almost_eq(total / 10_000.0, 1.25, 0.03)


func test_yield_below_one_still_gives_at_least_zero() -> void:
	assert_gte(YieldRoller.roll(0.0, 0.0, rng), 0)


func test_super_harvest_multiplies_result() -> void:
	assert_eq(YieldRoller.roll(1.0, 0.0, rng, 1.0, 10), 10)


func test_super_harvest_disabled_by_default() -> void:
	for i in 100:
		assert_lte(YieldRoller.roll(1.0, 0.0, rng), 1)
