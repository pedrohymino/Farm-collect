class_name TruckOrderRules
extends RefCounted
## Truck orders: one or two of the items the farm can currently sell, sized by farm level,
## paid with a bonus over the counter price.
## count = round(order_size × (1 + order_growth × (level - 1))), split between the items.

const MAX_ITEM_TYPES: int = 2


## Returns {item_id: count}. `available_items` must not be empty.
static func generate(
	available_items: Array[StringName],
	farm_level: int,
	order_size: int,
	order_growth: float,
	rng: RandomNumberGenerator
) -> Dictionary:
	var pool := available_items.duplicate()
	var types := mini(rng.randi_range(1, MAX_ITEM_TYPES), pool.size())
	var total := maxi(roundi(order_size * (1.0 + order_growth * (farm_level - 1))), types)
	var order := {}
	for i in types:
		var item_id: StringName = pool.pop_at(rng.randi() % pool.size())
		var share := (
			total - _sum(order) if i == types - 1 else maxi(roundi(total / float(types)), 1)
		)
		order[item_id] = share
	return order


## Money paid when the order is complete: sum(count × unit price) × bonus.
static func reward(order: Dictionary, unit_prices: Dictionary, bonus: float) -> float:
	var total := 0.0
	for item_id: StringName in order:
		total += order[item_id] * float(unit_prices.get(item_id, 0.0))
	return total * bonus


## Items still missing, given what was delivered.
static func remaining(order: Dictionary, delivered: Dictionary) -> Dictionary:
	var missing := {}
	for item_id: StringName in order:
		var left: int = order[item_id] - int(delivered.get(item_id, 0))
		if left > 0:
			missing[item_id] = left
	return missing


static func _sum(order: Dictionary) -> int:
	var total := 0
	for item_id: StringName in order:
		total += order[item_id]
	return total
