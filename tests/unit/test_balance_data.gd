extends GutTest


func test_project_balance_files_load_without_errors() -> void:
	var data := BalanceData.load_from_dir("res://data/balance")
	assert_eq(data.errors, PackedStringArray())
	assert_true(data.stats.has("player.carry_capacity"))
	assert_true(data.items.has("egg"))


func test_every_item_has_scoped_production_and_price_stats() -> void:
	var data := BalanceData.load_from_dir("res://data/balance")
	for item_id: String in data.items:
		assert_true(data.stats.has("production.rate." + item_id), item_id + " production stat")
		assert_true(data.stats.has("sell.price." + item_id), item_id + " price stat")


func test_validate_reports_bad_stat_definitions() -> void:
	var raw := {
		"ok": {"base": 1.0},
		"no_base": {"min": 0.0},
		"bad_range": {"base": 1.0, "min": 5.0, "max": 1.0},
		"not_a_dict": 3,
	}
	assert_eq(BalanceData.validate_stats(raw).size(), 3)


func test_validate_reports_bad_items() -> void:
	var raw := {
		"ok": {"base_price": 1.0, "production_seconds": 2.0, "stage": "raw"},
		"free": {"base_price": 0.0, "production_seconds": 2.0, "stage": "raw"},
		"weird_stage": {"base_price": 1.0, "production_seconds": 2.0, "stage": "cooked"},
	}
	assert_eq(BalanceData.validate_items(raw).size(), 2)


func test_missing_directory_is_an_error() -> void:
	var data := BalanceData.load_from_dir("res://data/does_not_exist")
	assert_gt(data.errors.size(), 0)


func test_validate_reports_bad_producers() -> void:
	var items := {"egg": {}}
	var raw := {
		"ok": {"item": "egg", "base_units": 2, "max_units": 6},
		"ghost": {"item": "unicorn", "base_units": 1, "max_units": 1},
		"zero": {"item": "egg", "base_units": 0, "max_units": 1},
		"inverted": {"item": "egg", "base_units": 5, "max_units": 1},
	}
	assert_eq(BalanceData.validate_producers(raw, items).size(), 3)
