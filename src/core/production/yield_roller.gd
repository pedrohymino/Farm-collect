class_name YieldRoller
extends RefCounted
## How many items one completed production cycle gives.
## yield_value 1.5 = always 1, plus 50% chance of 1 more. double_chance doubles the result.


static func roll(yield_value: float, double_chance: float, rng: RandomNumberGenerator) -> int:
	var safe_yield := maxf(yield_value, 0.0)
	var amount := floori(safe_yield)
	if rng.randf() < safe_yield - amount:
		amount += 1
	if rng.randf() < double_chance:
		amount *= 2
	return amount
