class_name TransferZone
extends Area3D
## While a carrier stands inside, moves items between it and a station pile at a
## stat-driven rate. Carriers are bodies in group "carrier" exposing `carry_visual: StackVisual`.
## PICKUP zones also reach the player from player.magnet_radius away (passive "Magnet").

enum Mode { PICKUP, DROP }

## Approximate half-size of a zone, added to the magnet radius.
const ZONE_REACH: float = 0.9

@export var mode: Mode = Mode.PICKUP
@export var station_visual: StackVisual
@export var rate_stat: StringName = &"player.pickup_rate"
@export var marker: ZoneMarker

var _overlapping: Dictionary = {}  # Node3D -> true, from body signals
var _tickers: Dictionary = {}  # Node3D -> TransferTicker


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	var active := _active_carriers()
	for carrier: Node3D in _tickers.keys():
		if not active.has(carrier):
			_tickers.erase(carrier)
	for carrier in active:
		if not _tickers.has(carrier):
			_tickers[carrier] = TransferTicker.new()
		var ticker: TransferTicker = _tickers[carrier]
		for i in ticker.consume(delta, Stats.get_value(rate_stat)):
			if not _move_one(carrier):
				ticker.reset()
				break
	if marker != null:
		marker.set_active(not active.is_empty())


func _active_carriers() -> Array[Node3D]:
	var active: Array[Node3D] = []
	for carrier: Node3D in _overlapping:
		if is_instance_valid(carrier):
			active.append(carrier)
	if mode != Mode.PICKUP:
		return active
	var reach := Stats.get_value(&"player.magnet_radius")
	if reach <= 0.0:
		return active
	for node in get_tree().get_nodes_in_group(&"player"):
		var player := node as Node3D
		if player.is_in_group(&"carrier") and not active.has(player):
			var offset := player.global_position - global_position
			offset.y = 0.0
			if offset.length() <= ZONE_REACH + reach:
				active.append(player)
	return active


func _move_one(carrier: Node3D) -> bool:
	var carrier_visual: StackVisual = carrier.get(&"carry_visual")
	var from := station_visual if mode == Mode.PICKUP else carrier_visual
	var to := carrier_visual if mode == Mode.PICKUP else station_visual
	var index := ItemContainer.find_transfer_index(from.container, to.container)
	if index < 0:
		if mode == Mode.PICKUP and to.container.is_full() and not from.container.is_empty():
			carrier.call(&"show_full")
		return false
	var from_position := from.slot_global_position(index)
	var item_id := ItemContainer.transfer_at(from.container, to.container, index)
	to.fly_in_top(from_position)
	if mode == Mode.PICKUP:
		EventBus.item_collected.emit(item_id)
	else:
		EventBus.item_delivered.emit(item_id)
	return true


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"carrier"):
		_overlapping[body] = true


func _on_body_exited(body: Node3D) -> void:
	_overlapping.erase(body)
