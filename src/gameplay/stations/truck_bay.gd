class_name TruckBay
extends Node3D
## Loading dock: a truck drives in, asks for a load (TruckOrderRules), the player drops items
## into its bed through a DROP zone, and when complete it pays a bonus into the money pile
## and drives off. The next truck comes after truck.interval seconds.

enum Phase { WAITING, ARRIVING, PARKED, LEAVING }

const DRIVE_SPEED: float = 9.0
const ARRIVE_DISTANCE: float = 0.05
const REWARD_TEXT_HEIGHT: float = 3.0
const REWARD_TEXT_COLOR: Color = Color("ffd166")

@export var persist_id: StringName = &"truck_bay"
@export var truck_scene: PackedScene
@export var enter_point: Marker3D
@export var park_point: Marker3D
@export var exit_point: Marker3D

var phase: Phase = Phase.WAITING
var order: Dictionary = {}  # StringName -> int

var _bed: ItemContainer
var _truck: Node3D
var _cooldown: ProductionCycle
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var bed_visual: StackVisual = $BedVisual
@onready var money_pile: MoneyPile = $MoneyPile
@onready var _order_label: Label3D = $OrderLabel


func _ready() -> void:
	add_to_group(&"persistent_station")
	add_to_group(&"truck_bay")
	_rng.randomize()
	_bed = ItemContainer.new(_order_total, [])
	_bed.set_accepts([])
	_bed.item_added.connect(_on_item_added.unbind(2))
	bed_visual.bind(_bed)
	_cooldown = ProductionCycle.new(0.0, Stats.get_value(&"truck.interval"))
	_order_label.visible = false


## Dev mode / tests: skips the wait (and the drive in, with skip_drive).
func arrive_now(skip_drive: bool = false) -> void:
	if phase == Phase.WAITING:
		_start_order()
	if skip_drive and phase == Phase.ARRIVING:
		_truck.global_position = park_point.global_position
		phase = Phase.PARKED
		_refresh_order()


func delivered(item_id: StringName) -> int:
	return _bed.count(item_id)


func save_state() -> Dictionary:
	if phase != Phase.PARKED:
		return {}
	var saved_order := {}
	for item_id: StringName in order:
		saved_order[String(item_id)] = order[item_id]
	return {"order": saved_order, "bed": _bed.to_array()}


func load_state(state: Dictionary) -> void:
	var saved_order: Variant = state.get("order")
	if typeof(saved_order) != TYPE_DICTIONARY or saved_order.is_empty():
		return
	order.clear()
	for item_id: String in saved_order:
		order[StringName(item_id)] = int(saved_order[item_id])
	_spawn_truck(park_point.global_position)
	phase = Phase.PARKED
	_bed.load_array(state.get("bed", []))
	_refresh_order()


func _process(delta: float) -> void:
	match phase:
		Phase.WAITING:
			if _cooldown.advance(delta, Stats.get_value(&"truck.interval")) > 0:
				_start_order()
		Phase.ARRIVING:
			if _drive_to(park_point.global_position, delta):
				phase = Phase.PARKED
				_refresh_order()
		Phase.LEAVING:
			if _drive_to(exit_point.global_position, delta):
				_truck.queue_free()
				_truck = null
				phase = Phase.WAITING


func _start_order() -> void:
	var items := _sellable_items()
	if items.is_empty():
		return
	order = TruckOrderRules.generate(
		items,
		GameState.data.farm_level,
		Stats.get_int(&"truck.order_size"),
		Stats.get_value(&"truck.order_growth"),
		_rng
	)
	_bed.load_array([])
	_spawn_truck(enter_point.global_position)
	phase = Phase.ARRIVING


func _on_item_added() -> void:
	_refresh_order()
	# Deferred: the bed visual handles this same signal after us; finishing (and emptying
	# the bed) right now would pull the item out from under it.
	_check_complete.call_deferred()


func _check_complete() -> void:
	if phase == Phase.PARKED and TruckOrderRules.remaining(order, _delivered_map()).is_empty():
		_complete_order()


func _complete_order() -> void:
	var prices := {}
	for item_id: StringName in order:
		prices[item_id] = SaleRules.unit_price(
			ContentDB.item_base_price(item_id), Stats.get_scoped(&"sell.price", item_id)
		)
	var reward := TruckOrderRules.reward(order, prices, Stats.get_value(&"truck.bonus"))
	money_pile.stash.add(reward)
	FloatingText.spawn(
		self,
		park_point.global_position + Vector3.UP * REWARD_TEXT_HEIGHT,
		tr("FX_MONEY_GAIN") % Economy.format(reward),
		REWARD_TEXT_COLOR
	)
	EventBus.truck_order_completed.emit(reward)
	order.clear()
	_bed.load_array([])
	_refresh_order()
	phase = Phase.LEAVING


func _refresh_order() -> void:
	var missing := TruckOrderRules.remaining(order, _delivered_map())
	var accepts: Array[StringName] = []
	accepts.assign(missing.keys())
	_bed.set_accepts(accepts if phase == Phase.PARKED else ([] as Array[StringName]))
	var lines := PackedStringArray()
	for item_id: StringName in order:
		var item_def := ContentDB.item_def(item_id)
		var item_name := tr(item_def.name_key) if item_def != null else String(item_id)
		lines.append(tr("TRUCK_LINE") % [item_name, _bed.count(item_id), order[item_id]])
	_order_label.text = "\n".join(lines)
	_order_label.visible = phase == Phase.PARKED and not order.is_empty()


func _delivered_map() -> Dictionary:
	var delivered_items := {}
	for item_id: StringName in order:
		delivered_items[item_id] = _bed.count(item_id)
	return delivered_items


func _order_total() -> int:
	var total := 0
	for item_id: StringName in order:
		total += order[item_id]
	return total


## Items whose counters are open: the farm can make and sell them.
func _sellable_items() -> Array[StringName]:
	var items: Array[StringName] = []
	for node in get_tree().get_nodes_in_group(&"counter"):
		var counter := node as Counter
		if counter.is_open() and not items.has(counter.item_id):
			items.append(counter.item_id)
	return items


func _spawn_truck(at: Vector3) -> void:
	if _truck == null:
		_truck = truck_scene.instantiate() as Node3D
		_truck.top_level = true
		add_child(_truck)
	_truck.global_position = at


func _drive_to(target: Vector3, delta: float) -> bool:
	var to_target := target - _truck.global_position
	var step := DRIVE_SPEED * delta
	if to_target.length() <= maxf(step, ARRIVE_DISTANCE):
		_truck.global_position = target
		return true
	_truck.global_position += to_target.normalized() * step
	return false
