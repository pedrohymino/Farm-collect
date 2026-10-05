extends Node
## Loads balance data (data/balance/*.json) at startup and reports every problem clearly.
## Content definitions (.tres) are added here as they are introduced (M2+).

const BALANCE_DIR: String = "res://data/balance"

var balance: BalanceData


func _init() -> void:
	reload_balance()


func reload_balance() -> void:
	balance = BalanceData.load_from_dir(BALANCE_DIR)
	for message in balance.errors:
		push_error("Balance data: " + message)


func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item_id: String in balance.items:
		ids.append(StringName(item_id))
	return ids


func item_base_price(item_id: StringName) -> float:
	return float(balance.items.get(String(item_id), {}).get("base_price", 0.0))


func item_production_seconds(item_id: StringName) -> float:
	return float(balance.items.get(String(item_id), {}).get("production_seconds", 0.0))
