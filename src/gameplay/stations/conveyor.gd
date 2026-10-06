class_name Conveyor
extends Node3D
## Machine that carries items from a pile to a counter's stock along a belt; the items
## visibly ride it. Throughput = machine.conveyor_rate × machine.speed items per second.

const BELT_SPEED: float = 2.0
const RIDE_HEIGHT: float = 0.12
const BELT_WIDTH: float = 0.5
const BELT_THICKNESS: float = 0.08
const BELT_COLOR: Color = Color("4a4f57")

@export var source_visual: StackVisual
@export var target_visual: StackVisual
@export var start_point: Marker3D
@export var end_point: Marker3D

var _ticker: TransferTicker = TransferTicker.new()
var _riding: Array[Dictionary] = []  # {"node": Node3D, "item": StringName, "t": float}


func _ready() -> void:
	_build_belt()


func riding_count() -> int:
	return _riding.size()


func _physics_process(delta: float) -> void:
	var speed := Stats.get_value(&"machine.speed")
	for i in _ticker.consume(delta, Stats.get_value(&"machine.conveyor_rate") * speed):
		if not _launch():
			_ticker.reset()
			break
	var start := start_point.global_position
	var end := end_point.global_position
	var step := BELT_SPEED * speed * delta / maxf(start.distance_to(end), 0.01)
	for ride in _riding.duplicate():
		ride["t"] = minf(float(ride["t"]) + step, 1.0)
		(ride["node"] as Node3D).global_position = (
			start.lerp(end, ride["t"]) + Vector3.UP * RIDE_HEIGHT
		)
		if ride["t"] >= 1.0:
			_arrive(ride)


func _launch() -> bool:
	var source := source_visual.container
	var target := target_visual.container
	if target.free_space() - _riding.size() <= 0:
		return false
	var index := ItemContainer.find_transfer_index(source, target)
	if index < 0:
		return false
	var item_id := source.items()[index]
	source.pop_matching([item_id])
	var item_def := ContentDB.item_def(item_id)
	var node: Node3D = item_def.visual_scene.instantiate() if item_def != null else Node3D.new()
	node.top_level = true
	add_child(node)
	node.global_position = start_point.global_position
	_riding.append({"node": node, "item": item_id, "t": 0.0})
	return true


func _arrive(ride: Dictionary) -> void:
	_riding.erase(ride)
	(ride["node"] as Node3D).queue_free()
	if target_visual.container.push(ride["item"]):
		target_visual.fly_in_top(end_point.global_position)


func _build_belt() -> void:
	var start := start_point.global_position
	var end := end_point.global_position
	var belt := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(BELT_WIDTH, BELT_THICKNESS, start.distance_to(end))
	var material := StandardMaterial3D.new()
	material.albedo_color = BELT_COLOR
	mesh.material = material
	belt.mesh = mesh
	belt.top_level = true
	add_child(belt)
	belt.global_position = (start + end) * 0.5
	belt.look_at(end, Vector3.UP)
