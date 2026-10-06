class_name FarmLevelRules
extends RefCounted
## Farm XP and levels (data/balance/progression.json). XP comes from sales; each level
## gives stars for the passive tree. xp_to_next(level) = xp_base × xp_growth^(level - 1).

var _xp_base: float
var _xp_growth: float
var _stars_per_level: float


func _init(progression: Dictionary) -> void:
	_xp_base = float(progression.get("xp_base", 50.0))
	_xp_growth = float(progression.get("xp_growth", 1.35))
	_stars_per_level = float(progression.get("stars_per_level", 1))


func xp_to_next(level: int) -> float:
	return _xp_base * pow(_xp_growth, level - 1)


func progress_ratio(data: GameData) -> float:
	return clampf(data.farm_xp / xp_to_next(data.farm_level), 0.0, 1.0)


## Adds XP, applying every level-up it causes (stars go to the wallet). Returns levels gained.
func add_xp(data: GameData, amount: float) -> int:
	if amount <= 0.0:
		return 0
	data.farm_xp += amount
	var gained := 0
	while data.farm_xp >= xp_to_next(data.farm_level):
		data.farm_xp -= xp_to_next(data.farm_level)
		data.farm_level += 1
		gained += 1
	if gained > 0 and _stars_per_level > 0.0:
		data.wallet.add(Wallet.STARS, _stars_per_level * gained)
	return gained
