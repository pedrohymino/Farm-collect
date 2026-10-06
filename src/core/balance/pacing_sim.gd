class_name PacingSim
extends RefCounted
## Economy flow model used to compare the unlock timeline with the pacing targets of
## docs/03-economia-e-balanceamento.md (section 7). Not the game: a deterministic
## 1-second-step simulation of a player who follows a simple buying policy.
##
## Real systems reused: StatRegistry, UnlockRules, UpgradeRules, PassiveRules, FarmLevelRules.
## Assumptions (all tunable below, documented in docs/03 section 7):
## - Items flow: production -> hauling -> counters (customers) and trucks.
## - The player hauls whatever is not automated, splitting time by value per second.
## - Each open counter gets customers every customer.spawn_interval; they buy buy_min..buy_max.
## - Pads are bought cheapest-first; upgrades only when they pay back within a few minutes.

const STEP_SEC: float = 1.0
const MAX_HOURS: float = 12.0
## Walk from the customer spawner to the first counter, so income starts a bit late.
const CUSTOMER_TRAVEL_SEC: float = 14.0
## Extra seconds per haul trip for the sell pad, picking up and turning around.
const HAUL_OVERHEAD_SEC: float = 1.0
## An upgrade is worth buying while it pays itself back within this many seconds; players
## grow more patient as the session gets longer (a quarter of the time played so far).
const MIN_PAYBACK_SEC: float = 240.0
const PAYBACK_PATIENCE: float = 0.25
## Meters from each producer to its counter (farm.tscn layout).
const HAUL_DISTANCE: Dictionary = {&"egg": 11.5, &"wheat": 10.4, &"milk": 8.8}
## Unlocks that open a counter, and the producer feeding it.
const COUNTER_UNLOCKS: Dictionary = {&"wheat": &"wheat_counter", &"milk": &"milk_counter"}
const PRODUCER_UNLOCKS: Dictionary = {&"wheat": &"wheat_field", &"milk": &"barn"}

var data: GameData = GameData.new()
var timeline: Array[Dictionary] = []  # {t, kind, id, rate (income per second at that time)}

var _balance: BalanceData
var _registry: StatRegistry = StatRegistry.new()
var _unlocks: UnlockRules
var _upgrades: UpgradeRules
var _passives: PassiveRules
var _levels: FarmLevelRules
var _time: float = 0.0
var _income_rate: float = 0.0


func _init(balance: BalanceData) -> void:
	_balance = balance
	_registry.load_defs(balance.stats)
	_unlocks = UnlockRules.new(balance.unlocks)
	_upgrades = UpgradeRules.new(balance.upgrades)
	_passives = PassiveRules.new(balance.passives)
	_levels = FarmLevelRules.new(balance.progression)


## Plays until every pad is bought or `limit_sec` pass. Returns the timeline.
func run(limit_sec: float = MAX_HOURS * 3600.0) -> Array[Dictionary]:
	while _time < limit_sec and _locked_count() > 0:
		_step()
	return timeline


## Per open item: items/s produced, hauled to the counter and asked for by customers.
func snapshot() -> Dictionary:
	var result := {}
	var supply := {}
	for item_id in _open_items():
		supply[item_id] = _supply_rate(item_id)
	var hauled := _haul(supply)
	var buy_min := _registry.get_value(&"customer.buy_min")
	var buy_max := maxf(_registry.get_value(&"customer.buy_max"), buy_min)
	var demand := (buy_min + buy_max) * 0.5 / _registry.get_value(&"customer.spawn_interval")
	for item_id: StringName in supply:
		result[item_id] = {"supply": supply[item_id], "hauled": hauled[item_id], "demand": demand}
	return result


func time_of(kind: String, id: StringName) -> float:
	for entry in timeline:
		if entry.kind == kind and entry.id == id:
			return entry.t
	return -1.0


func finished_at() -> float:
	return time_of("unlock", _last_unlock()) if _locked_count() == 0 else -1.0


func income_rate() -> float:
	return _income_rate


func seconds_to_first_sale() -> float:
	var interval := _registry.get_value(&"customer.spawn_interval")
	var first_customer := interval * 0.2 + CUSTOMER_TRAVEL_SEC
	var egg_ready := float(_balance.items["egg"]["production_seconds"]) * 0.5
	return maxf(first_customer, egg_ready + _trip_seconds(&"egg") * 0.5)


func _step() -> void:
	_income_rate = _compute_income_rate() if _time >= CUSTOMER_TRAVEL_SEC else 0.0
	var earned := _income_rate * STEP_SEC
	if earned > 0.0:
		data.wallet.add(Wallet.MONEY, earned)
		_levels.add_xp(data, earned * _registry.get_value(&"farm.xp_gain"))
	_time += STEP_SEC
	_buy_things()


func _buy_things() -> void:
	var bought := true
	while bought:
		bought = _buy_passive() or _buy_pad_or_upgrade()


func _buy_passive() -> bool:
	var stars := data.wallet.get_balance(Wallet.STARS)
	var best := &""
	for node_id in _passives.ids():
		if _passives.can_unlock(node_id, data) and _passives.cost(node_id) <= stars:
			if best.is_empty() or _passives.cost(node_id) < _passives.cost(best):
				best = node_id
	if best.is_empty():
		return false
	data.wallet.spend(Wallet.STARS, _passives.cost(best))
	data.passive_nodes[best] = true
	_add_modifiers(_passives.modifiers(best))
	_log("passive", best)
	return true


func _buy_pad_or_upgrade() -> bool:
	var money := data.wallet.get_balance(Wallet.MONEY)
	var pad := _cheapest_pad()
	var pad_cost := _pad_cost(pad) if not pad.is_empty() else INF
	if not pad.is_empty() and pad_cost <= money:
		data.wallet.spend(Wallet.MONEY, pad_cost)
		data.unlock(pad)
		_add_modifiers(_unlocks.modifiers(pad))
		_log("unlock", pad)
		return true
	var upgrade := _best_upgrade(money)
	if upgrade.is_empty():
		return false
	data.wallet.spend(Wallet.MONEY, _upgrade_cost(upgrade))
	_set_upgrade_level(upgrade, int(data.upgrade_levels.get(upgrade, 0)) + 1)
	_log("upgrade", upgrade)
	return true


func _cheapest_pad() -> StringName:
	var available := _unlocks.available_ids(data)
	return available[0] if not available.is_empty() else &""


## The affordable upgrade with the shortest payback, if the player finds it short enough.
func _best_upgrade(money: float) -> StringName:
	if not data.is_unlocked(&"upgrade_board"):
		return &""
	var best := &""
	var best_payback := maxf(MIN_PAYBACK_SEC, _time * PAYBACK_PATIENCE)
	var base_rate := _compute_income_rate()
	for upgrade_id in _upgrades.ids():
		var level := int(data.upgrade_levels.get(upgrade_id, 0))
		var cost := _upgrade_cost(upgrade_id)
		if _upgrades.is_maxed(upgrade_id, level) or cost > money:
			continue
		if not _upgrades.is_visible(upgrade_id, data):
			continue
		_set_upgrade_level(upgrade_id, level + 1)
		var gain := _compute_income_rate() - base_rate
		_set_upgrade_level(upgrade_id, level)
		if gain > 0.0 and cost / gain < best_payback:
			best = upgrade_id
			best_payback = cost / gain
	return best


func _set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	data.upgrade_levels[upgrade_id] = level
	_registry.remove_modifiers_from(_upgrades.source_id(upgrade_id))
	_add_modifiers(_upgrades.modifiers(upgrade_id, level))


func _pad_cost(pad: StringName) -> float:
	return _unlocks.base_cost(pad) * _registry.get_value(&"unlock.cost")


func _upgrade_cost(upgrade_id: StringName) -> float:
	var level := int(data.upgrade_levels.get(upgrade_id, 0))
	return _upgrades.cost(upgrade_id, level, _registry.get_value(&"upgrade.cost"))


func _locked_count() -> int:
	var count := 0
	for unlock_id in _unlocks.ids():
		if not data.is_unlocked(unlock_id):
			count += 1
	return count


func _last_unlock() -> StringName:
	for i in range(timeline.size() - 1, -1, -1):
		if timeline[i].kind == "unlock":
			return timeline[i].id
	return &""


func _add_modifiers(modifiers: Array[Modifier]) -> void:
	for modifier in modifiers:
		_registry.add_modifier(modifier)


func _log(kind: String, id: StringName) -> void:
	timeline.append({"t": _time, "kind": kind, "id": id, "rate": _income_rate})


# --- income model -------------------------------------------------------------------------


func _compute_income_rate() -> float:
	var items := _open_items()
	var supply := {}
	for item_id in items:
		supply[item_id] = _supply_rate(item_id)
	var hauled := _haul(supply)
	var income := 0.0
	var truck_rate := _truck_rate_per_item(items.size())
	for item_id in items:
		var to_truck := minf(hauled[item_id], truck_rate)
		hauled[item_id] -= to_truck
		income += to_truck * _unit_price(item_id) * _registry.get_value(&"truck.bonus")
	var sales := _customer_sales(hauled)
	for item_id in sales:
		income += sales[item_id] * _unit_price(item_id) * _order_multiplier()
	return income


## Items with an open counter (the egg counter exists from the start).
func _open_items() -> Array[StringName]:
	var items: Array[StringName] = [&"egg"]
	for item_id: StringName in COUNTER_UNLOCKS:
		if data.is_unlocked(COUNTER_UNLOCKS[item_id]) and _units(item_id) > 0:
			items.append(item_id)
	return items


func _units(item_id: StringName) -> int:
	var producer_id := _producer_for(item_id)
	var producer: Dictionary = _balance.producers[producer_id]
	if PRODUCER_UNLOCKS.has(item_id) and not data.is_unlocked(PRODUCER_UNLOCKS[item_id]):
		return 0
	var total := int(producer["base_units"]) + _unlocks.units_bonus(producer_id, data)
	return mini(total, int(producer["max_units"]))


func _producer_for(item_id: StringName) -> StringName:
	for producer_id: String in _balance.producers:
		if _balance.producers[producer_id]["item"] == String(item_id):
			return StringName(producer_id)
	return &""


func _supply_rate(item_id: StringName) -> float:
	var seconds := float(_balance.items[String(item_id)]["production_seconds"])
	var rate := _registry.get_scoped(&"production.rate", item_id)
	var yield_mean := (
		_registry.get_value(&"production.yield")
		* (1.0 + _registry.get_value(&"production.double_chance"))
		* (
			1.0
			+ (
				_registry.get_value(&"production.super_chance")
				* (_registry.get_value(&"production.super_multiplier") - 1.0)
			)
		)
	)
	return _units(item_id) * rate / seconds * yield_mean


## Items per second that actually reach their counter: automated hauling first, then the
## player, who spends his time on the items that pay best per second of walking.
func _haul(supply: Dictionary) -> Dictionary:
	var hauled := {}
	var left := {}
	for item_id: StringName in supply:
		var auto := minf(supply[item_id], _auto_haul_rate(item_id))
		hauled[item_id] = auto
		left[item_id] = supply[item_id] - auto
	var order: Array = left.keys()
	order.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			return _unit_price(a) * _player_haul_rate(a) > _unit_price(b) * _player_haul_rate(b)
	)
	var time_left := 1.0
	for item_id: StringName in order:
		var cap := _player_haul_rate(item_id)
		var share := minf(left[item_id] / cap, time_left)
		hauled[item_id] += share * cap
		time_left -= share
	return hauled


func _auto_haul_rate(item_id: StringName) -> float:
	if item_id != &"egg" or not data.is_unlocked(&"carrier_egg"):
		return 0.0
	var worker_carry := _registry.get_value(&"worker.carry_capacity")
	var worker_speed := _registry.get_value(&"worker.move_speed")
	var rate := worker_carry / _trip_time(&"egg", worker_carry, worker_speed)
	if data.is_unlocked(&"egg_conveyor"):
		rate += (
			_registry.get_value(&"machine.conveyor_rate") * _registry.get_value(&"machine.speed")
		)
	return rate


func _player_haul_rate(item_id: StringName) -> float:
	var carry := _registry.get_value(&"player.carry_capacity")
	return carry / _trip_time(item_id, carry, _registry.get_value(&"player.move_speed"))


func _trip_seconds(item_id: StringName) -> float:
	var carry := _registry.get_value(&"player.carry_capacity")
	return _trip_time(item_id, carry, _registry.get_value(&"player.move_speed"))


func _trip_time(item_id: StringName, carry: float, speed: float) -> float:
	var pickup := _registry.get_value(&"player.pickup_rate")
	var drop := _registry.get_value(&"player.drop_rate")
	return (
		2.0 * float(HAUL_DISTANCE[item_id]) / speed
		+ carry / pickup
		+ carry / drop
		+ HAUL_OVERHEAD_SEC
	)


## Items per second customers buy at each counter: every open counter has its own stream of
## customers (customer.spawn_interval is per counter), capped by what reaches it.
func _customer_sales(available: Dictionary) -> Dictionary:
	var buy_min := _registry.get_value(&"customer.buy_min")
	var buy_max := maxf(_registry.get_value(&"customer.buy_max"), buy_min)
	var demand := (buy_min + buy_max) * 0.5 / _registry.get_value(&"customer.spawn_interval")
	var sales := {}
	for item_id: StringName in available:
		sales[item_id] = minf(demand, available[item_id])
	return sales


func _truck_rate_per_item(item_count: int) -> float:
	if not data.is_unlocked(&"truck_bay") or item_count == 0:
		return 0.0
	var size := _registry.get_value(&"truck.order_size")
	var growth := _registry.get_value(&"truck.order_growth")
	var order := size * (1.0 + growth * (data.farm_level - 1))
	return order / _registry.get_value(&"truck.interval") / item_count


func _unit_price(item_id: StringName) -> float:
	var base := float(_balance.items[String(item_id)]["base_price"])
	return base * _registry.get_scoped(&"sell.price", item_id)


func _order_multiplier() -> float:
	var tip := (
		1.0 + _registry.get_value(&"sell.tip_chance") * _registry.get_value(&"sell.tip_bonus")
	)
	var vip := (
		1.0
		+ (
			_registry.get_value(&"sell.vip_chance")
			* (_registry.get_value(&"sell.vip_multiplier") - 1.0)
		)
	)
	return tip * vip
