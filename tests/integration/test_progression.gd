extends GutTest
## Progression autoload with real balance data: upgrades, passives and farm level.


func before_each() -> void:
	GameState.new_game()


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()


func test_new_game_has_no_progression_modifiers() -> void:
	assert_eq(Stats.get_int(&"player.carry_capacity"), 8)


func test_buying_upgrade_spends_money_and_applies_effect() -> void:
	Economy.earn(Wallet.MONEY, 100.0)
	var cost := Progression.upgrade_cost(&"backpack")
	watch_signals(EventBus)
	assert_true(Progression.buy_upgrade(&"backpack"))
	assert_eq(Progression.upgrade_level(&"backpack"), 1)
	assert_almost_eq(Economy.balance(Wallet.MONEY), 100.0 - cost, 0.001)
	assert_eq(Stats.get_int(&"player.carry_capacity"), 10)
	assert_signal_emitted_with_parameters(EventBus, "upgrade_purchased", [&"backpack", 1])
	assert_gt(Progression.upgrade_cost(&"backpack"), cost)


func test_cannot_buy_upgrade_without_money() -> void:
	assert_false(Progression.buy_upgrade(&"backpack"))
	assert_eq(Progression.upgrade_level(&"backpack"), 0)


func test_upgrade_respects_max_level() -> void:
	Progression.set_upgrade_level(&"advertising", Progression.upgrades.max_level(&"advertising"))
	Economy.earn(Wallet.MONEY, 1e12)
	assert_false(Progression.buy_upgrade(&"advertising"))


func test_passive_needs_stars_and_a_neighbor() -> void:
	assert_false(Progression.buy_passive(&"farmer_1"))
	Economy.earn(Wallet.STARS, 10.0)
	assert_false(Progression.buy_passive(&"farmer_2"))
	assert_true(Progression.buy_passive(&"farmer_1"))
	assert_true(Progression.buy_passive(&"farmer_2"))
	assert_eq(Economy.balance(Wallet.STARS), 8.0)
	assert_eq(Stats.get_int(&"player.carry_capacity"), 10)


func test_loading_a_save_reapplies_modifiers() -> void:
	var saved := GameData.new()
	saved.upgrade_levels[&"backpack"] = 2
	saved.passive_nodes[&"farmer_2"] = true
	GameState.replace(saved)
	assert_eq(Stats.get_int(&"player.carry_capacity"), 14)
	GameState.new_game()
	assert_eq(Stats.get_int(&"player.carry_capacity"), 8)


func test_sales_give_xp_and_level_up_gives_stars() -> void:
	watch_signals(EventBus)
	var needed := Progression.xp_to_next()
	EventBus.item_sold.emit(&"egg", 1, needed + 1.0)
	assert_eq(GameState.data.farm_level, 2)
	assert_eq(Economy.balance(Wallet.STARS), 1.0)
	assert_signal_emitted_with_parameters(EventBus, "level_up", [2])
