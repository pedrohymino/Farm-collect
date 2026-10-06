class_name Location
extends Node3D
## A playable place (the farm; later the factory).
## - Saves/restores its stations: descendants in group "persistent_station" with
##   `persist_id`, save_state() and load_state().
## - Applies unlocks: descendants in group "unlock:<id>" exist only once <id> is unlocked;
##   descendants in "lock:<id>" (e.g. a fence in the way) disappear when it is unlocked.

const UNLOCK_GROUP_PREFIX: String = "unlock:"
const LOCK_GROUP_PREFIX: String = "lock:"
const REVEAL_TIME: float = 0.45
const HIDE_TIME: float = 0.25
const MIN_SCALE: float = 0.01

@export var location_id: StringName = &"farm"


func _ready() -> void:
	add_to_group(&"persistent_location")
	read_state()
	for unlock_id in Unlocks.rules.ids():
		var unlocked := Unlocks.is_unlocked(unlock_id)
		for node in _members(UNLOCK_GROUP_PREFIX + unlock_id):
			_set_active(node, unlocked)
		for node in _members(LOCK_GROUP_PREFIX + unlock_id):
			_set_active(node, not unlocked)
	EventBus.unlock_completed.connect(_on_unlock_completed)


func read_state() -> void:
	var state: Dictionary = GameState.data.locations.get(location_id, {})
	for station in _members(&"persistent_station"):
		var key := String(station.get(&"persist_id"))
		var station_state: Variant = state.get(key)
		if typeof(station_state) == TYPE_DICTIONARY:
			station.call(&"load_state", station_state)


func write_state() -> void:
	var state := {}
	for station in _members(&"persistent_station"):
		state[String(station.get(&"persist_id"))] = station.call(&"save_state")
	GameState.data.locations[location_id] = state


func _on_unlock_completed(unlock_id: StringName) -> void:
	for node in _members(UNLOCK_GROUP_PREFIX + unlock_id):
		_set_active(node, true)
		_reveal(node)
	for node in _members(LOCK_GROUP_PREFIX + unlock_id):
		_conceal(node)


func _reveal(node: Node) -> void:
	var node_3d := node as Node3D
	if node_3d == null:
		return
	var final_scale := node_3d.scale
	node_3d.scale = final_scale * MIN_SCALE
	node_3d.create_tween().tween_property(node_3d, "scale", final_scale, REVEAL_TIME).set_trans(
		Tween.TRANS_BACK
	)


func _conceal(node: Node) -> void:
	var node_3d := node as Node3D
	if node_3d == null:
		_set_active(node, false)
		return
	var final_scale := node_3d.scale
	var tween := node_3d.create_tween()
	tween.tween_property(node_3d, "scale", final_scale * MIN_SCALE, HIDE_TIME)
	tween.tween_callback(
		func() -> void:
			_set_active(node_3d, false)
			node_3d.scale = final_scale
	)


func _set_active(node: Node, active: bool) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if node is Node3D:
		(node as Node3D).visible = active


func _members(group: StringName) -> Array[Node]:
	var members: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group):
		if is_ancestor_of(node):
			members.append(node)
	return members
