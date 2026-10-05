class_name TransferTicker
extends RefCounted
## Turns a rate (items per second) into a number of transfers per frame.
## Starts "charged" so the first item moves the moment the carrier steps in.

## Absorbs float error from summing many small frame deltas.
const EPSILON: float = 1e-6

var _budget: float = 1.0


func consume(delta: float, rate: float) -> int:
	_budget += delta * maxf(rate, 0.0)
	var allowed := floori(_budget + EPSILON)
	_budget = maxf(_budget - allowed, 0.0)
	return allowed


## Call when the carrier leaves or nothing can move, so budget doesn't pile up.
func reset() -> void:
	_budget = 1.0
