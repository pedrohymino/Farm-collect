extends Node
## Upgrades (money), passive tree (stars) and farm XP/levels on the live game.
## Upgrades and passives only register stat modifiers (source "upgrade:<id>" / "passive:<id>");
## they are re-applied from GameData whenever the game is loaded or replaced.

var upgrades: UpgradeRules
var passives: PassiveRules
var farm_level: FarmLevelRules


func _ready() -> void:
	reload()
	GameState.data_replaced.connect(apply_all)
	EventBus.item_sold.connect(_on_item_sold)


func reload() -> void:
	upgrades = UpgradeRules.new(ContentDB.balance.upgrades)
	passives = PassiveRules.new(ContentDB.balance.passives)
	farm_level = FarmLevelRules.new(ContentDB.balance.progression)
	apply_all()


## Rebuilds every upgrade/passive modifier from the saved levels and nodes.
func apply_all() -> void:
	for upgrade_id in upgrades.ids():
		_apply_upgrade(upgrade_id)
	for node_id in passives.ids():
		Stats.remove_modifiers_from(passives.source_id(node_id))
		if GameState.data.passive_nodes.has(node_id):
			_add_modifiers(passives.modifiers(node_id))


func upgrade_level(upgrade_id: StringName) -> int:
	return int(GameState.data.upgrade_levels.get(upgrade_id, 0))


func upgrade_cost(upgrade_id: StringName) -> float:
	return upgrades.cost(upgrade_id, upgrade_level(upgrade_id), Stats.get_value(&"upgrade.cost"))


func is_upgrade_visible(upgrade_id: StringName) -> bool:
	return upgrades.is_visible(upgrade_id, GameState.data)


func can_buy_upgrade(upgrade_id: StringName) -> bool:
	return (
		upgrades.has(upgrade_id)
		and is_upgrade_visible(upgrade_id)
		and not upgrades.is_maxed(upgrade_id, upgrade_level(upgrade_id))
		and Economy.can_afford(Wallet.MONEY, upgrade_cost(upgrade_id))
	)


func buy_upgrade(upgrade_id: StringName) -> bool:
	if not can_buy_upgrade(upgrade_id) or not Economy.spend(Wallet.MONEY, upgrade_cost(upgrade_id)):
		return false
	var level := upgrade_level(upgrade_id) + 1
	GameState.data.upgrade_levels[upgrade_id] = level
	_apply_upgrade(upgrade_id)
	EventBus.upgrade_purchased.emit(upgrade_id, level)
	return true


func set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	GameState.data.upgrade_levels[upgrade_id] = maxi(level, 0)
	_apply_upgrade(upgrade_id)


func passive_state(node_id: StringName) -> PassiveRules.NodeState:
	return passives.state(node_id, GameState.data)


func can_buy_passive(node_id: StringName) -> bool:
	return (
		passives.can_unlock(node_id, GameState.data)
		and Economy.can_afford(Wallet.STARS, passives.cost(node_id))
	)


func buy_passive(node_id: StringName) -> bool:
	if not can_buy_passive(node_id) or not Economy.spend(Wallet.STARS, passives.cost(node_id)):
		return false
	GameState.data.passive_nodes[node_id] = true
	_add_modifiers(passives.modifiers(node_id))
	EventBus.passive_purchased.emit(node_id)
	return true


## Dev mode: removes every upgrade level and passive node (no refund).
func reset_all() -> void:
	GameState.data.upgrade_levels.clear()
	GameState.data.passive_nodes.clear()
	apply_all()


func xp_to_next() -> float:
	return farm_level.xp_to_next(GameState.data.farm_level)


func level_progress() -> float:
	return farm_level.progress_ratio(GameState.data)


func add_xp(amount: float) -> void:
	var gained := farm_level.add_xp(GameState.data, amount)
	EventBus.xp_changed.emit(GameState.data.farm_xp, GameState.data.farm_level)
	for i in gained:
		EventBus.level_up.emit(GameState.data.farm_level - gained + 1 + i)


func _apply_upgrade(upgrade_id: StringName) -> void:
	Stats.remove_modifiers_from(upgrades.source_id(upgrade_id))
	_add_modifiers(upgrades.modifiers(upgrade_id, upgrade_level(upgrade_id)))


func _add_modifiers(modifiers: Array[Modifier]) -> void:
	for modifier in modifiers:
		Stats.add_modifier(modifier)


func _on_item_sold(_item_id: StringName, _count: int, value: float) -> void:
	add_xp(value * Stats.get_value(&"farm.xp_gain"))
