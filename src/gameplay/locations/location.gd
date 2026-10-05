class_name Location
extends Node3D
## A playable place (the farm; later the factory). Collects and restores the saved state
## of its stations: descendants in group "persistent_station" with `persist_id`,
## save_state() and load_state().

@export var location_id: StringName = &"farm"


func _ready() -> void:
	add_to_group(&"persistent_location")
	read_state()


func read_state() -> void:
	var state: Dictionary = GameState.data.locations.get(location_id, {})
	for station in _stations():
		var key := String(station.get(&"persist_id"))
		var station_state: Variant = state.get(key)
		if typeof(station_state) == TYPE_DICTIONARY:
			station.call(&"load_state", station_state)


func write_state() -> void:
	var state := {}
	for station in _stations():
		state[String(station.get(&"persist_id"))] = station.call(&"save_state")
	GameState.data.locations[location_id] = state


func _stations() -> Array[Node]:
	var stations: Array[Node] = []
	for node in get_tree().get_nodes_in_group(&"persistent_station"):
		if is_ancestor_of(node):
			stations.append(node)
	return stations
