class_name ItemContainer
extends RefCounted
## Ordered stack of item ids (index 0 = bottom) with a live capacity.
## Everything that holds items uses this: player, producer piles, counters, workers, trucks.

signal item_added(item_id: StringName, index: int)
signal item_removed(item_id: StringName, index: int)
## Emitted after load_array() replaces the contents; visuals should rebuild.
signal contents_reset

const NONE: StringName = &""

var _items: Array[StringName] = []
var _capacity: Callable
var _accepts: Array[StringName] = []


## capacity: Callable returning int, read every time (so stat changes apply instantly).
## accepts: allowed item ids; empty means any item.
func _init(capacity: Callable, accepts: Array[StringName] = []) -> void:
	_capacity = capacity
	_accepts = accepts.duplicate()


## Capacity Callable bound to a stat of anything with get_value()
## (the Stats autoload or a StatRegistry).
static func stat_capacity(stat_source: Object, stat_id: StringName) -> Callable:
	return func() -> int: return int(stat_source.get_value(stat_id))


## Moves the topmost item of `from` that matches `filter` and that `to` accepts.
## Returns the moved item id, or NONE if nothing could move.
static func transfer_one(
	from: ItemContainer, to: ItemContainer, filter: Array[StringName] = []
) -> StringName:
	var index := find_transfer_index(from, to, filter)
	if index < 0:
		return NONE
	return transfer_at(from, to, index)


## Index (in `from`) of the item transfer_one would move, or -1. Lets visuals know
## where the item leaves from before it moves.
static func find_transfer_index(
	from: ItemContainer, to: ItemContainer, filter: Array[StringName] = []
) -> int:
	if to.is_full():
		return -1
	for index in range(from._items.size() - 1, -1, -1):
		var item_id := from._items[index]
		if (filter.is_empty() or filter.has(item_id)) and to.accepts(item_id):
			return index
	return -1


## Moves the item at `index` of `from` to the top of `to`. Caller must have checked
## it is transferable (see find_transfer_index).
static func transfer_at(from: ItemContainer, to: ItemContainer, index: int) -> StringName:
	var item_id := from._remove_at(index)
	to.push(item_id)
	return item_id


func capacity() -> int:
	return maxi(int(_capacity.call()), 0)


func size() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()


func is_full() -> bool:
	return _items.size() >= capacity()


func free_space() -> int:
	return maxi(capacity() - _items.size(), 0)


func accepts(item_id: StringName) -> bool:
	return _accepts.is_empty() or _accepts.has(item_id)


func can_accept(item_id: StringName) -> bool:
	return accepts(item_id) and not is_full()


func push(item_id: StringName) -> bool:
	if not can_accept(item_id):
		return false
	_items.append(item_id)
	item_added.emit(item_id, _items.size() - 1)
	return true


func pop_top() -> StringName:
	if _items.is_empty():
		return NONE
	return _remove_at(_items.size() - 1)


## Removes the topmost item whose id is in `filter` (any item if empty).
func pop_matching(filter: Array[StringName] = []) -> StringName:
	for index in range(_items.size() - 1, -1, -1):
		if filter.is_empty() or filter.has(_items[index]):
			return _remove_at(index)
	return NONE


func count(item_id: StringName) -> int:
	return _items.count(item_id)


func items() -> Array[StringName]:
	return _items.duplicate()


func clear() -> void:
	while not _items.is_empty():
		pop_top()


func to_array() -> Array:
	var raw: Array = []
	for item_id in _items:
		raw.append(String(item_id))
	return raw


## Restores saved contents. Ignores capacity (never deletes saved items) but skips
## invalid entries and items this container does not accept.
func load_array(raw: Array) -> void:
	_items.clear()
	for entry: Variant in raw:
		if typeof(entry) != TYPE_STRING and typeof(entry) != TYPE_STRING_NAME:
			continue
		var item_id := StringName(entry)
		if accepts(item_id):
			_items.append(item_id)
	contents_reset.emit()


func _remove_at(index: int) -> StringName:
	var item_id := _items[index]
	_items.remove_at(index)
	item_removed.emit(item_id, index)
	return item_id
