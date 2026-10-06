extends GutTest

var rules: FarmLevelRules
var data: GameData


func before_each() -> void:
	rules = FarmLevelRules.new({"xp_base": 50.0, "xp_growth": 1.5, "stars_per_level": 1})
	data = GameData.new()


func test_xp_curve() -> void:
	assert_eq(rules.xp_to_next(1), 50.0)
	assert_eq(rules.xp_to_next(2), 75.0)
	assert_eq(rules.xp_to_next(3), 112.5)


func test_xp_below_threshold_does_not_level() -> void:
	assert_eq(rules.add_xp(data, 30.0), 0)
	assert_eq(data.farm_xp, 30.0)
	assert_eq(data.farm_level, 1)


func test_level_up_carries_remainder_and_gives_stars() -> void:
	assert_eq(rules.add_xp(data, 60.0), 1)
	assert_eq(data.farm_level, 2)
	assert_eq(data.farm_xp, 10.0)
	assert_eq(data.wallet.get_balance(Wallet.STARS), 1.0)


func test_big_gain_levels_several_times() -> void:
	assert_eq(rules.add_xp(data, 50.0 + 75.0 + 112.5 + 1.0), 3)
	assert_eq(data.farm_level, 4)
	assert_almost_eq(data.farm_xp, 1.0, 0.0001)
	assert_eq(data.wallet.get_balance(Wallet.STARS), 3.0)


func test_progress_ratio() -> void:
	rules.add_xp(data, 25.0)
	assert_almost_eq(rules.progress_ratio(data), 0.5, 0.0001)


func test_non_positive_xp_is_ignored() -> void:
	assert_eq(rules.add_xp(data, -10.0), 0)
	assert_eq(data.farm_xp, 0.0)
