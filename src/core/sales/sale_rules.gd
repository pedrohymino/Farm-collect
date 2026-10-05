class_name SaleRules
extends RefCounted
## Pricing math. Inputs come from ContentDB (base price) and Stats (multipliers, tip).


static func unit_price(base_price: float, price_multiplier: float) -> float:
	return base_price * price_multiplier


static func order_value(unit: float, count: int, tipped: bool, tip_bonus: float) -> float:
	var value := unit * count
	if tipped:
		value *= 1.0 + tip_bonus
	return value
