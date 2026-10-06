class_name Worker
extends CharacterBody3D
## A farm helper walking a fixed route of stops (docs/02-game-design.md, section 4):
## CASHIER stands at a counter's cashier spot, CARRIER moves items from a pile to a counter,
## COLLECTOR walks between money piles. Zones react to it exactly as they do to the player.
## Moves kinematically on the WORKERS layer, so it never pushes or blocks the player.

enum Role { CASHIER, CARRIER, COLLECTOR }

const ARRIVE_DISTANCE: float = 0.15
const CARRIER_IDLE_SEC: float = 1.5
const COLLECTOR_IDLE_SEC: float = 0.4
const TURN_SHARPNESS: float = 10.0
const BOB_FREQUENCY: float = 13.0
const BOB_HEIGHT: float = 0.05

@export var role: Role = Role.CASHIER
## Route nodes (zones, piles or plain markers); positions are read every frame.
@export var stops: Array[NodePath] = []

var _brain: WorkerBrain
var _last_count: int = 0
var _walk_time: float = 0.0

@onready var carry_visual: StackVisual = $Body/CarryVisual
@onready var _body: Node3D = $Body
@onready var _model: Node3D = $Body/Model


func _ready() -> void:
	collision_layer = PhysicsLayers.WORKERS
	collision_mask = 0
	match role:
		Role.CASHIER:
			add_to_group(&"cashier")
		Role.CARRIER:
			add_to_group(&"carrier")
		Role.COLLECTOR:
			add_to_group(&"money_collector")
	carry_visual.bind(
		ItemContainer.new(ItemContainer.stat_capacity(Stats, &"worker.carry_capacity"))
	)
	var idle_limit := INF
	if role == Role.CARRIER:
		idle_limit = CARRIER_IDLE_SEC
	elif role == Role.COLLECTOR:
		idle_limit = COLLECTOR_IDLE_SEC
	_brain = WorkerBrain.new(stops.size(), idle_limit)


func current_stop() -> int:
	return _brain.stop_index


## Zones call this on carriers whose stack is full; helpers just keep going.
func show_full() -> void:
	pass


func _physics_process(delta: float) -> void:
	if stops.is_empty():
		return
	var arrived := _walk_to(_stop_position(_brain.stop_index), delta)
	var count := carry_visual.container.size()
	var made_progress := count != _last_count
	_last_count = count
	var work_done := false
	var can_leave := true
	if role == Role.CARRIER:
		if _brain.stop_index == 0:
			work_done = carry_visual.container.is_full()
			can_leave = count > 0
		else:
			work_done = count == 0
	_brain.update(delta, arrived, work_done and arrived, made_progress, can_leave)
	carry_visual.owner_velocity = Vector3.ZERO


func _walk_to(target: Vector3, delta: float) -> bool:
	var to_target := target - global_position
	to_target.y = 0.0
	var step := Stats.get_value(&"worker.move_speed") * delta
	if to_target.length() <= maxf(step, ARRIVE_DISTANCE):
		global_position = Vector3(target.x, global_position.y, target.z)
		_model.position.y = 0.0
		return true
	global_position += to_target.normalized() * step
	var yaw := atan2(to_target.x, to_target.z)
	_body.rotation.y = lerp_angle(_body.rotation.y, yaw, 1.0 - exp(-TURN_SHARPNESS * delta))
	_walk_time += delta
	_model.position.y = absf(sin(_walk_time * BOB_FREQUENCY)) * BOB_HEIGHT
	return false


func _stop_position(index: int) -> Vector3:
	var node := get_node_or_null(stops[index]) as Node3D
	return node.global_position if node != null else global_position
