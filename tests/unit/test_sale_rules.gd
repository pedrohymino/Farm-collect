extends GutTest


func test_unit_price_applies_multiplier() -> void:
	assert_almost_eq(SaleRules.unit_price(3.0, 1.5), 4.5, 0.0001)


func test_order_value_without_tip() -> void:
	assert_almost_eq(SaleRules.order_value(4.5, 2, false, 0.5), 9.0, 0.0001)


func test_order_value_with_tip_bonus() -> void:
	assert_almost_eq(SaleRules.order_value(4.0, 2, true, 0.5), 12.0, 0.0001)
