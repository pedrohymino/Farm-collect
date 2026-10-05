extends GutTest


func test_new_game_defaults() -> void:
	var data := GameData.new()
	assert_eq(data.wallet.get_balance(Wallet.MONEY), 0.0)
	assert_eq(data.farm_level, 1)
	assert_eq(data.farm_xp, 0.0)
	assert_true(data.unlocked.is_empty())


func test_dict_round_trip_preserves_everything() -> void:
	var data := GameData.new()
	data.wallet.add(Wallet.MONEY, 99.0)
	data.unlock(&"chicken_3")
	data.unlock_progress[&"stand_upgrades"] = 12.0
	data.upgrade_levels[&"boots"] = 3
	data.passive_nodes[&"farmer_1"] = true
	data.farm_level = 4
	data.farm_xp = 17.5
	data.locations[&"farm"] = {"coop_output": ["egg", "egg"]}

	var restored := GameData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))

	assert_eq(restored.wallet.get_balance(Wallet.MONEY), 99.0)
	assert_true(restored.is_unlocked(&"chicken_3"))
	assert_eq(restored.unlock_progress[&"stand_upgrades"], 12.0)
	assert_eq(restored.upgrade_levels[&"boots"], 3)
	assert_true(restored.passive_nodes.has(&"farmer_1"))
	assert_eq(restored.farm_level, 4)
	assert_eq(restored.farm_xp, 17.5)
	assert_eq(restored.locations[&"farm"]["coop_output"], ["egg", "egg"])


func test_from_dict_tolerates_missing_and_wrong_types() -> void:
	var restored := GameData.from_dict(
		{"farm_level": "high", "unlocked": "nope", "upgrade_levels": {"boots": -2, "bag": 2.0}}
	)
	assert_eq(restored.farm_level, 1)
	assert_true(restored.unlocked.is_empty())
	assert_false(restored.upgrade_levels.has(&"boots"))
	assert_eq(restored.upgrade_levels[&"bag"], 2)
