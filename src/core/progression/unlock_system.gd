extends Node
## Unlocks on the live game (autoload "Unlocks"): availability, costs scaled by the
## unlock.cost stat, payments into pads and completion events. Rules live in UnlockRules.

var rules: UnlockRules


func _ready() -> void:
	reload()


func reload() -> void:
	rules = UnlockRules.new(ContentDB.balance.unlocks)


func is_unlocked(unlock_id: StringName) -> bool:
	return GameState.data.is_unlocked(unlock_id)


func is_available(unlock_id: StringName) -> bool:
	return rules.is_available(unlock_id, GameState.data)


func cost(unlock_id: StringName) -> float:
	return rules.base_cost(unlock_id) * Stats.get_value(&"unlock.cost")


func remaining(unlock_id: StringName) -> float:
	return rules.remaining(unlock_id, cost(unlock_id), GameState.data)


func progress_ratio(unlock_id: StringName) -> float:
	var total := cost(unlock_id)
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - remaining(unlock_id) / total, 0.0, 1.0)


## Puts money already taken from the wallet into an unlock; completes it when fully paid.
func pay(unlock_id: StringName, amount: float) -> void:
	if rules.pay(unlock_id, amount, cost(unlock_id), GameState.data):
		EventBus.unlock_completed.emit(unlock_id)


## Completes an unlock without paying (dev mode, free unlocks).
func complete(unlock_id: StringName) -> void:
	if not rules.has(unlock_id) or is_unlocked(unlock_id):
		return
	GameState.data.unlock(unlock_id)
	EventBus.unlock_completed.emit(unlock_id)


func units_bonus(target: StringName) -> int:
	return rules.units_bonus(target, GameState.data)


func available_ids() -> Array[StringName]:
	return rules.available_ids(GameState.data)
