extends Node
## Single source of every gameplay value (docs/04-arquitetura.md, section 3).
## Thin autoload wrapper around StatRegistry, fed by ContentDB.

signal stat_changed(stat_id: StringName, value: float)

var registry: StatRegistry = StatRegistry.new()


func _ready() -> void:
	registry.stat_changed.connect(stat_changed.emit)
	reload_defs()


func reload_defs() -> void:
	registry.load_defs(ContentDB.balance.stats)


func get_value(stat_id: StringName) -> float:
	return registry.get_value(stat_id)


func get_int(stat_id: StringName) -> int:
	return roundi(registry.get_value(stat_id))


func get_scoped(stat_id: StringName, scope: StringName) -> float:
	return registry.get_scoped(stat_id, scope)


func add_modifier(modifier: Modifier) -> void:
	registry.add_modifier(modifier)


func remove_modifiers_from(source_id: StringName) -> void:
	registry.remove_modifiers_from(source_id)


func set_base(stat_id: StringName, base: float) -> void:
	registry.set_base(stat_id, base)


func set_dev_override(
	stat_id: StringName, multiplier: float = 1.0, absolute: Variant = null
) -> void:
	registry.set_dev_override(stat_id, multiplier, absolute)


func clear_dev_override(stat_id: StringName) -> void:
	registry.clear_dev_override(stat_id)


func clear_all_dev_overrides() -> void:
	registry.clear_all_dev_overrides()


func breakdown(stat_id: StringName) -> Dictionary:
	return registry.breakdown(stat_id)


func stat_ids() -> Array[StringName]:
	return registry.stat_ids()
