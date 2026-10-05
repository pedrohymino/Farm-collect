extends GutTest
## Autoload wiring with the real balance data. No disk IO: SaveManager stays inactive.


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()


func test_content_db_loaded_without_errors() -> void:
	assert_eq(ContentDB.errors, PackedStringArray())
	assert_eq(ContentDB.item_base_price(&"egg"), 3.0)


func test_stats_are_fed_from_balance_data() -> void:
	assert_eq(Stats.get_int(&"player.carry_capacity"), 8)
	assert_eq(Stats.get_value(&"player.move_speed"), 4.0)


func test_stats_autoload_forwards_stat_changed() -> void:
	watch_signals(Stats)
	Stats.set_dev_override(&"player.carry_capacity", 2.0)
	assert_signal_emitted_with_parameters(Stats, "stat_changed", [&"player.carry_capacity", 16.0])


func test_economy_earn_and_spend_update_state_and_broadcast() -> void:
	watch_signals(EventBus)
	assert_true(Economy.earn(Wallet.MONEY, 40.0))
	assert_true(Economy.spend(Wallet.MONEY, 15.0))
	assert_eq(Economy.balance(Wallet.MONEY), 25.0)
	assert_signal_emitted_with_parameters(EventBus, "currency_earned", [Wallet.MONEY, 40.0])
	assert_signal_emitted_with_parameters(EventBus, "currency_spent", [Wallet.MONEY, 15.0])
	assert_signal_emitted_with_parameters(EventBus, "currency_changed", [Wallet.MONEY, 25.0])


func test_economy_rebinds_after_new_game() -> void:
	GameState.new_game()
	watch_signals(EventBus)
	Economy.earn(Wallet.MONEY, 5.0)
	assert_signal_emitted_with_parameters(EventBus, "currency_changed", [Wallet.MONEY, 5.0])


func test_save_manager_is_inactive_in_tests() -> void:
	assert_false(SaveManager.is_active())
	assert_false(SaveManager.save_game())
