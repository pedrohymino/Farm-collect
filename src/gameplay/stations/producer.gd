class_name Producer
extends Node3D
## A pen of producing units (chickens, cows). Each unit runs its own ProductionCycle and
## drops items on the output pile, which carriers empty through a TransferZone.

## Height above a unit where produced items start their flight.
const DROP_HEIGHT: float = 0.4

@export var producer_id: StringName = &"coop"
@export var persist_id: StringName = &"coop"
@export var unit_scene: PackedScene
## Half-size (local XZ) of the area units wander in.
@export var pen_half_extents: Vector2 = Vector2(1.5, 1.1)

var output: ItemContainer
var item_id: StringName

var _units: Array[Node3D] = []
var _cycles: Array[ProductionCycle] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var output_visual: StackVisual = $OutputVisual
@onready var _units_root: Node3D = $Units


func _ready() -> void:
	add_to_group(&"persistent_station")
	add_to_group(&"producer")
	_rng.randomize()
	item_id = ContentDB.producer_item(producer_id)
	output = ItemContainer.new(
		ItemContainer.stat_capacity(Stats, &"production.output_capacity"), [item_id]
	)
	output_visual.bind(output)
	_refresh_units()
	EventBus.unlock_completed.connect(_refresh_units.unbind(1))


func unit_count() -> int:
	return _units.size()


func set_unit_count(count: int) -> void:
	var target := clampi(count, 0, ContentDB.producer_max_units(producer_id))
	while _units.size() < target:
		_add_unit()


## Base units from producers.json plus what completed unlocks add.
func _refresh_units() -> void:
	set_unit_count(ContentDB.producer_base_units(producer_id) + Unlocks.units_bonus(producer_id))


func save_state() -> Dictionary:
	return {"output": output.to_array()}


func load_state(state: Dictionary) -> void:
	var saved: Variant = state.get("output", [])
	if typeof(saved) == TYPE_ARRAY:
		output.load_array(saved)


func _process(delta: float) -> void:
	var interval := _interval()
	for index in _cycles.size():
		if output.is_full():
			_cycles[index].hold(interval)
			continue
		for i in _cycles[index].advance(delta, interval):
			_produce(index)


func _interval() -> float:
	var rate := Stats.get_scoped(&"production.rate", item_id)
	return ContentDB.item_production_seconds(item_id) / rate


func _produce(unit_index: int) -> void:
	var amount := YieldRoller.roll(
		Stats.get_value(&"production.yield"),
		Stats.get_value(&"production.double_chance"),
		_rng,
		Stats.get_value(&"production.super_chance"),
		Stats.get_int(&"production.super_multiplier")
	)
	var unit := _units[unit_index]
	var from := unit.global_position + Vector3.UP * DROP_HEIGHT
	for i in amount:
		if not output.push(item_id):
			return
		output_visual.fly_in_top(from)
		EventBus.item_produced.emit(item_id)
	if amount > 0 and unit.has_method(&"play_produce"):
		unit.call(&"play_produce")


func _add_unit() -> void:
	var unit := unit_scene.instantiate() as Node3D
	_units_root.add_child(unit)
	unit.position = Vector3(
		_rng.randf_range(-pen_half_extents.x, pen_half_extents.x),
		0.0,
		_rng.randf_range(-pen_half_extents.y, pen_half_extents.y)
	)
	if unit.has_method(&"set_bounds"):
		unit.call(&"set_bounds", pen_half_extents)
	_units.append(unit)
	_cycles.append(ProductionCycle.new(_rng.randf(), _interval()))
