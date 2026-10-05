class_name Wallet
extends RefCounted
## Currency balances. Balances never go negative.

signal balance_changed(currency: StringName, balance: float)

const MONEY: StringName = &"money"
const STARS: StringName = &"stars"
const CURRENCIES: Array[StringName] = [MONEY, STARS]

var _balances: Dictionary = {MONEY: 0.0, STARS: 0.0}


func get_balance(currency: StringName) -> float:
	return _balances.get(currency, 0.0)


func can_afford(currency: StringName, amount: float) -> bool:
	return amount >= 0.0 and get_balance(currency) >= amount


func add(currency: StringName, amount: float) -> bool:
	if not _is_known(currency):
		return false
	if amount <= 0.0:
		push_error("Wallet.add needs a positive amount, got %f" % amount)
		return false
	_write_balance(currency, get_balance(currency) + amount)
	return true


## Spending 0 is allowed (free unlocks). Fails without changes when unaffordable.
func spend(currency: StringName, amount: float) -> bool:
	if not _is_known(currency):
		return false
	if amount < 0.0:
		push_error("Wallet.spend needs a non-negative amount, got %f" % amount)
		return false
	if not can_afford(currency, amount):
		return false
	_write_balance(currency, get_balance(currency) - amount)
	return true


## For dev mode and loading. Clamped to zero.
func set_balance(currency: StringName, amount: float) -> void:
	if _is_known(currency):
		_write_balance(currency, amount)


func to_dict() -> Dictionary:
	var raw := {}
	for currency in CURRENCIES:
		raw[String(currency)] = get_balance(currency)
	return raw


func load_dict(raw: Dictionary) -> void:
	for currency in CURRENCIES:
		var value: Variant = raw.get(String(currency), 0.0)
		var is_number := typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
		_write_balance(currency, float(value) if is_number else 0.0)


func _write_balance(currency: StringName, amount: float) -> void:
	_balances[currency] = maxf(amount, 0.0)
	balance_changed.emit(currency, _balances[currency])


func _is_known(currency: StringName) -> bool:
	if CURRENCIES.has(currency):
		return true
	push_error("Unknown currency: %s" % currency)
	return false
