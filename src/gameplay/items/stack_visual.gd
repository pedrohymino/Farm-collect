class_name StackVisual
extends Node3D
## Draws an ItemContainer as a pile: one column (player stack) or a grid (station piles).
## Pure presentation: listens to the container and never changes it.

const FLY_TIME: float = 0.28
const FLY_ARC_HEIGHT: float = 1.0
const POP_SCALE: float = 1.3
const POP_TIME: float = 0.18
const RELAYOUT_TIME: float = 0.12
const SWAY_MAX: float = 0.5
const SWAY_SHARPNESS: float = 8.0
const META_ITEM: StringName = &"item_id"
const META_FLYING: StringName = &"flying"
const META_TWEEN: StringName = &"layout_tween"

@export var columns: int = 1
@export var rows: int = 1
## Distance between grid cells on X (columns) and Z (rows).
@export var cell_spacing: Vector2 = Vector2(0.3, 0.3)
## How much a column leans against the owner's movement (player stack). 0 disables.
@export var sway_strength: float = 0.0

var container: ItemContainer
## World velocity of whatever carries this stack, set by it every frame (drives sway).
var owner_velocity: Vector3 = Vector3.ZERO

var _nodes: Array[Node3D] = []
var _sway: Vector3 = Vector3.ZERO
var _heights: Dictionary = {}  # StringName -> float


func bind(p_container: ItemContainer) -> void:
	if container != null:
		container.item_added.disconnect(_on_item_added)
		container.item_removed.disconnect(_on_item_removed)
		container.contents_reset.disconnect(_rebuild)
	container = p_container
	container.item_added.connect(_on_item_added)
	container.item_removed.connect(_on_item_removed)
	container.contents_reset.connect(_rebuild)
	_rebuild()


func slot_position(index: int) -> Vector3:
	var per_layer := maxi(columns * rows, 1)
	var cell := index % per_layer
	var column := cell % columns
	var row := floori(cell / float(columns))
	var x := (column - (columns - 1) * 0.5) * cell_spacing.x
	var z := (row - (rows - 1) * 0.5) * cell_spacing.y
	var y := 0.0
	var below := index - per_layer
	while below >= 0:
		y += _height_at(below)
		below -= per_layer
	return Vector3(x, y, z)


func slot_global_position(index: int) -> Vector3:
	return to_global(slot_position(index))


## Where the next item would land.
func next_slot_global_position() -> Vector3:
	return to_global(slot_position(_nodes.size()))


## Animates the top item flying in from a world position (call right after it was added).
func fly_in_top(from_global: Vector3) -> void:
	if _nodes.is_empty():
		return
	var node := _nodes.back() as Node3D
	var start := to_local(from_global)
	node.set_meta(META_FLYING, true)
	node.position = start
	var tween := node.create_tween()
	tween.tween_method(_fly_step.bind(node, start), 0.0, 1.0, FLY_TIME)
	tween.tween_callback(_land.bind(node))


func _process(delta: float) -> void:
	if sway_strength <= 0.0 or _nodes.is_empty():
		return
	var local_velocity := global_basis.inverse() * owner_velocity
	var target := Vector3(-local_velocity.x, 0.0, -local_velocity.z) * sway_strength
	target = target.limit_length(SWAY_MAX)
	_sway = _sway.lerp(target, 1.0 - exp(-SWAY_SHARPNESS * delta))
	var top_height := maxf(slot_position(_nodes.size() - 1).y, 0.001)
	for index in _nodes.size():
		var node := _nodes[index]
		if node.has_meta(META_FLYING):
			continue
		var base := slot_position(index)
		var lean := pow(base.y / top_height, 2.0)
		node.position = base + _sway * lean


func _on_item_added(item_id: StringName, index: int) -> void:
	var node := _spawn(item_id)
	_nodes.insert(index, node)
	node.position = slot_position(index)
	_pop(node)
	if index < _nodes.size() - 1:
		_relayout()


func _on_item_removed(_item_id: StringName, index: int) -> void:
	var node := _nodes[index]
	_nodes.remove_at(index)
	node.queue_free()
	_relayout()


func _rebuild() -> void:
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	var item_ids := container.items()
	for index in item_ids.size():
		var node := _spawn(item_ids[index])
		_nodes.append(node)
		node.position = slot_position(index)


func _spawn(item_id: StringName) -> Node3D:
	var item_def := ContentDB.item_def(item_id)
	var node: Node3D
	if item_def != null and item_def.visual_scene != null:
		node = item_def.visual_scene.instantiate() as Node3D
	else:
		node = Node3D.new()
	node.set_meta(META_ITEM, item_id)
	add_child(node)
	return node


func _height_at(index: int) -> float:
	if index >= _nodes.size():
		return 0.0
	var item_id: StringName = _nodes[index].get_meta(META_ITEM)
	if not _heights.has(item_id):
		var item_def := ContentDB.item_def(item_id)
		_heights[item_id] = item_def.stack_height if item_def != null else 0.0
	return _heights[item_id]


func _relayout() -> void:
	if sway_strength > 0.0:
		return  # _process places column items every frame
	for index in _nodes.size():
		var node := _nodes[index]
		if node.has_meta(META_FLYING):
			continue
		if node.has_meta(META_TWEEN):
			(node.get_meta(META_TWEEN) as Tween).kill()
		var tween := node.create_tween()
		tween.tween_property(node, "position", slot_position(index), RELAYOUT_TIME)
		node.set_meta(META_TWEEN, tween)


func _fly_step(t: float, node: Node3D, start: Vector3) -> void:
	var index := _nodes.find(node)
	if index < 0:
		return
	var end := slot_position(index)
	node.position = start.lerp(end, t) + Vector3.UP * FLY_ARC_HEIGHT * 4.0 * t * (1.0 - t)


func _land(node: Node3D) -> void:
	node.remove_meta(META_FLYING)
	var index := _nodes.find(node)
	if index >= 0:
		node.position = slot_position(index)
	_pop(node)


func _pop(node: Node3D) -> void:
	node.scale = Vector3.ONE * POP_SCALE
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3.ONE, POP_TIME).set_trans(Tween.TRANS_BACK)
