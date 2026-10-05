extends Node
## Earning and spending currencies on the live wallet, broadcasting through EventBus.

var _bound_wallet: Wallet


func _ready() -> void:
	GameState.data_replaced.connect(_bind_wallet)
	_bind_wallet()


func balance(currency: StringName) -> float:
	return GameState.data.wallet.get_balance(currency)


func can_afford(currency: StringName, amount: float) -> bool:
	return GameState.data.wallet.can_afford(currency, amount)


func earn(currency: StringName, amount: float) -> bool:
	if not GameState.data.wallet.add(currency, amount):
		return false
	EventBus.currency_earned.emit(currency, amount)
	return true


func spend(currency: StringName, amount: float) -> bool:
	if not GameState.data.wallet.spend(currency, amount):
		return false
	EventBus.currency_spent.emit(currency, amount)
	return true


func format(value: float) -> String:
	return NumberFormat.format(value)


func _bind_wallet() -> void:
	if _bound_wallet != null and _bound_wallet.balance_changed.is_connected(_on_balance_changed):
		_bound_wallet.balance_changed.disconnect(_on_balance_changed)
	_bound_wallet = GameState.data.wallet
	_bound_wallet.balance_changed.connect(_on_balance_changed)
	for currency in Wallet.CURRENCIES:
		EventBus.currency_changed.emit(currency, _bound_wallet.get_balance(currency))


func _on_balance_changed(currency: StringName, new_balance: float) -> void:
	EventBus.currency_changed.emit(currency, new_balance)
