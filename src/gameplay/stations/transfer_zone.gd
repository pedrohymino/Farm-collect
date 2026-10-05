class_name TransferZone
extends Area3D
## While a carrier stands inside, moves items between it and a station pile at a
## stat-driven rate. Carriers are bodies in group "carrier" exposing `carry_visual: StackVisual`.

enum Mode { PICKUP, DROP }

@export var mode: Mode = Mode.PICKUP
@export var station_visual: StackVisual
@export var rate_stat: StringName = &"player.pickup_rate"
@export var marker: ZoneMarker

var _carriers: Dictionary = {}  # Node3D -> TransferTicker


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for carrier: Node3D in _carriers:
		var ticker: TransferTicker = _carriers[carrier]
		var allowed := ticker.consume(delta, Stats.get_value(rate_stat))
		for i in allowed:
			if not _move_one(carrier):
				ticker.reset()
				break


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
		_carriers[body] = TransferTicker.new()
		_update_marker()


func _on_body_exited(body: Node3D) -> void:
	if _carriers.erase(body):
		_update_marker()


func _update_marker() -> void:
	if marker != null:
		marker.set_active(not _carriers.is_empty())
