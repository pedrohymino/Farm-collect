extends GutTest

var wallet: Wallet


func before_each() -> void:
	wallet = Wallet.new()


func test_starts_empty() -> void:
	assert_eq(wallet.get_balance(Wallet.MONEY), 0.0)
	assert_eq(wallet.get_balance(Wallet.STARS), 0.0)


func test_add_increases_balance_and_emits() -> void:
	watch_signals(wallet)
	assert_true(wallet.add(Wallet.MONEY, 25.0))
	assert_eq(wallet.get_balance(Wallet.MONEY), 25.0)
	assert_signal_emitted_with_parameters(wallet, "balance_changed", [Wallet.MONEY, 25.0])


func test_add_rejects_non_positive_amounts() -> void:
	assert_false(wallet.add(Wallet.MONEY, -5.0))
	assert_push_error("positive")
	assert_false(wallet.add(Wallet.MONEY, 0.0))
	assert_push_error("positive")
	assert_eq(wallet.get_balance(Wallet.MONEY), 0.0)


func test_spend_when_affordable() -> void:
	wallet.add(Wallet.MONEY, 50.0)
	assert_true(wallet.can_afford(Wallet.MONEY, 30.0))
	assert_true(wallet.spend(Wallet.MONEY, 30.0))
	assert_eq(wallet.get_balance(Wallet.MONEY), 20.0)


func test_spend_fails_without_changing_balance_when_insufficient() -> void:
	wallet.add(Wallet.MONEY, 10.0)
	assert_false(wallet.can_afford(Wallet.MONEY, 11.0))
	assert_false(wallet.spend(Wallet.MONEY, 11.0))
	assert_eq(wallet.get_balance(Wallet.MONEY), 10.0)


func test_set_balance_never_goes_negative() -> void:
	wallet.set_balance(Wallet.STARS, -3.0)
	assert_eq(wallet.get_balance(Wallet.STARS), 0.0)


func test_unknown_currency_is_rejected() -> void:
	assert_false(wallet.add(&"gems", 5.0))
	assert_push_error("Unknown currency")


func test_dict_round_trip() -> void:
	wallet.add(Wallet.MONEY, 120.5)
	wallet.add(Wallet.STARS, 3.0)
	var restored := Wallet.new()
	restored.load_dict(wallet.to_dict())
	assert_eq(restored.get_balance(Wallet.MONEY), 120.5)
	assert_eq(restored.get_balance(Wallet.STARS), 3.0)


func test_load_dict_ignores_invalid_values() -> void:
	wallet.load_dict({"money": "lots", "stars": -4, "gems": 10})
	assert_eq(wallet.get_balance(Wallet.MONEY), 0.0)
	assert_eq(wallet.get_balance(Wallet.STARS), 0.0)
