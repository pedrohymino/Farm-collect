class_name Counter
extends Node3D
## Sales counter: stock pile (filled through a DROP TransferZone), customer queue,
## cashier spot (someone in group "cashier" must stand there) and a money pile.

const SALE_TEXT_HEIGHT: float = 1.8
const SALE_TEXT_COLOR: Color = Color("7dff6b")
const VIP_TEXT_COLOR: Color = Color("ffd166")

@export var item_id: StringName = &"egg"
@export var persist_id: StringName = &"egg_counter"
## Customers line up from QueueStart along this direction.
@export var queue_direction: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var queue_spacing: float = 1.0
## Building shown instead of the plain table (a KayKit market in the item's color).
@export var storefront: PackedScene

var stock: ItemContainer
var service: CounterService

var _customers: Dictionary = {}  # CustomerOrder -> Customer
var _cashiers: int = 0
var _players_at_cashier: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var stock_visual: StackVisual = $StockVisual
@onready var money_pile: MoneyPile = $MoneyPile
@onready var _cashier_spot: Area3D = $CashierSpot
@onready var _cashier_marker: ZoneMarker = $CashierSpot/Marker
@onready var _queue_start: Marker3D = $QueueStart


func _ready() -> void:
	_install_storefront()
	add_to_group(&"persistent_station")
	add_to_group(&"counter")
	_rng.randomize()
	stock = ItemContainer.new(ItemContainer.stat_capacity(Stats, &"counter.capacity"), [item_id])
	stock_visual.bind(stock)
	service = CounterService.new(stock, item_id)
	_cashier_spot.collision_mask |= PhysicsLayers.WORKERS
	_cashier_spot.body_entered.connect(_on_cashier_entered)
	_cashier_spot.body_exited.connect(_on_cashier_exited)


func _install_storefront() -> void:
	if storefront == null:
		return
	var slot := $Table/Model as Node3D
	var building := storefront.instantiate() as Node3D
	building.transform = slot.transform
	slot.get_parent().add_child(building)
	slot.queue_free()


## False while the counter is still locked (disabled by its Location).
func is_open() -> bool:
	return can_process()


func has_queue_space() -> bool:
	return service.has_space(Stats.get_int(&"customer.max_queue"))


func enqueue(customer: Customer) -> bool:
	if service.join(customer.order, Stats.get_int(&"customer.max_queue")) < 0:
		return false
	_customers[customer.order] = customer
	return true


func queue_slot_global(slot: int) -> Vector3:
	return _queue_start.global_position + queue_direction.normalized() * queue_spacing * slot


func save_state() -> Dictionary:
	return {"stock": stock.to_array(), "money": money_pile.stash.value}


func load_state(state: Dictionary) -> void:
	var saved_stock: Variant = state.get("stock", [])
	if typeof(saved_stock) == TYPE_ARRAY:
		stock.load_array(saved_stock)
	money_pile.stash.load_value(state.get("money", 0.0))


func _process(delta: float) -> void:
	var served := service.tick(delta, _cashiers > 0, Stats.get_value(&"counter.serve_time"))
	if served != null:
		_complete_sale(served)
	for order in service.expire(delta):
		_release(order, false)
	for order in service.orders():
		var slot := service.slot_of(order)
		(_customers[order] as Customer).set_queue_target(queue_slot_global(slot), slot == 0)


func _complete_sale(order: CustomerOrder) -> void:
	var unit := SaleRules.unit_price(
		ContentDB.item_base_price(item_id), Stats.get_scoped(&"sell.price", item_id)
	)
	var tipped := _rng.randf() < Stats.get_value(&"sell.tip_chance")
	var value := SaleRules.order_value(
		unit, order.count, tipped, Stats.get_value(&"sell.tip_bonus")
	)
	var is_vip := _rng.randf() < Stats.get_value(&"sell.vip_chance")
	if is_vip:
		value *= Stats.get_value(&"sell.vip_multiplier")
	money_pile.stash.add(value)
	var customer: Customer = _customers[order]
	FloatingText.spawn(
		get_parent(),
		customer.global_position + Vector3.UP * SALE_TEXT_HEIGHT,
		tr("FX_MONEY_GAIN") % Economy.format(value),
		VIP_TEXT_COLOR if is_vip else SALE_TEXT_COLOR
	)
	EventBus.item_sold.emit(item_id, order.count, value)
	if _players_at_cashier == 0:
		EventBus.automated_income.emit(value)
	_release(order, true)


func _release(order: CustomerOrder, happy: bool) -> void:
	var customer: Customer = _customers[order]
	_customers.erase(order)
	customer.leave(happy)
	EventBus.customer_left.emit(happy)


func _on_cashier_entered(body: Node3D) -> void:
	if body.is_in_group(&"cashier"):
		_cashiers += 1
		if body.is_in_group(&"player"):
			_players_at_cashier += 1
		_cashier_marker.set_active(true)


func _on_cashier_exited(body: Node3D) -> void:
	if body.is_in_group(&"cashier"):
		_cashiers = maxi(_cashiers - 1, 0)
		if body.is_in_group(&"player"):
			_players_at_cashier = maxi(_players_at_cashier - 1, 0)
		_cashier_marker.set_active(_cashiers > 0)
