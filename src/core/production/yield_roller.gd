class_name YieldRoller
extends RefCounted
## How many items one completed production cycle gives.
## yield_value 1.5 = always 1, plus 50% chance of 1 more. double_chance doubles the result.
## super_chance (passive "super harvest") multiplies it by super_multiplier.


static func roll(
	yield_value: float,
	double_chance: float,
	rng: RandomNumberGenerator,
	super_chance: float = 0.0,
	super_multiplier: int = 1
) -> int:
	var safe_yield := maxf(yield_value, 0.0)
	var amount := floori(safe_yield)
	if rng.randf() < safe_yield - amount:
		amount += 1
	if rng.randf() < double_chance:
		amount *= 2
	if super_chance > 0.0 and rng.randf() < super_chance:
		amount *= super_multiplier
	return amount
