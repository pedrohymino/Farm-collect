class_name MoneyStash
extends RefCounted
## Money waiting to be picked up (the pile next to a counter).

signal changed(value: float)

var value: float = 0.0


func add(amount: float) -> void:
	if amount <= 0.0:
		return
	value += amount
	changed.emit(value)


func take_all() -> float:
	var taken := value
	value = 0.0
	changed.emit(value)
	return taken


func load_value(raw: Variant) -> void:
	var is_number := typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT
	value = maxf(float(raw), 0.0) if is_number else 0.0
	changed.emit(value)
