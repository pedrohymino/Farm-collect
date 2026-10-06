extends GutTest

var identity := func(key: String) -> String: return key


func test_percent_effects() -> void:
	var effect := {"stat": "player.move_speed", "type": "percent", "value": 0.06}
	assert_eq(EffectText.amount(effect), "+6%")
	assert_eq(EffectText.amount(effect, 3), "+18%")


func test_negative_percent() -> void:
	var effect := {"stat": "customer.spawn_interval", "type": "percent", "value": -0.06}
	assert_eq(EffectText.amount(effect), "-6%")


func test_flat_effects() -> void:
	assert_eq(
		EffectText.amount({"stat": "player.carry_capacity", "type": "flat", "value": 2}), "+2"
	)
	assert_eq(
		EffectText.amount({"stat": "production.yield", "type": "flat", "value": 0.25}), "+0.25"
	)


func test_flat_chance_is_shown_as_percentage() -> void:
	var effect := {"stat": "sell.tip_chance", "type": "flat", "value": 0.1}
	assert_eq(EffectText.amount(effect), "+10%")


func test_multiplier_effects() -> void:
	assert_eq(EffectText.amount({"stat": "x", "type": "multiplier", "value": 2.0}, 2), "×4")


func test_describe_lists_every_effect_with_stat_key() -> void:
	var effects := [
		{"stat": "player.pickup_rate", "type": "percent", "value": 0.1},
		{"stat": "player.drop_rate", "type": "percent", "value": 0.1},
	]
	assert_eq(
		EffectText.describe(effects, identity),
		"+10% STAT_PLAYER_PICKUP_RATE\n+10% STAT_PLAYER_DROP_RATE"
	)


func test_every_upgrade_and_passive_stat_has_a_translation() -> void:
	var effects: Array = []
	for entry: Dictionary in ContentDB.balance.upgrades.values():
		effects.append_array(entry["effects"])
	for entry: Dictionary in ContentDB.balance.passives.values():
		effects.append_array(entry["effects"])
	var previous_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("pt_BR")
	for effect: Dictionary in effects:
		var key := EffectText.stat_name_key(effect["stat"])
		assert_ne(TranslationServer.translate(key), key, key)
	TranslationServer.set_locale(previous_locale)
