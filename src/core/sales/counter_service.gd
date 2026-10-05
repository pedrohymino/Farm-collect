class_name CounterService
extends RefCounted
## Queue and serving rules of one sales counter (no visuals, no money).
## A sale needs: front customer at the counter, someone at the cashier spot,
## enough stock, and serve_time seconds of uninterrupted attention.

var stock: ItemContainer
var item_id: StringName

var _queue: Array[CustomerOrder] = []
var _serve_progress: float = 0.0


func _init(p_stock: ItemContainer, p_item_id: StringName) -> void:
	stock = p_stock
	item_id = p_item_id


func queue_size() -> int:
	return _queue.size()


func has_space(max_queue: int) -> bool:
	return _queue.size() < max_queue


## Returns the queue slot (0 = at the counter), or -1 if the queue is full.
func join(order: CustomerOrder, max_queue: int) -> int:
	if not has_space(max_queue):
		return -1
	_queue.append(order)
	return _queue.size() - 1


func slot_of(order: CustomerOrder) -> int:
	return _queue.find(order)


func orders() -> Array[CustomerOrder]:
	return _queue.duplicate()


func serve_ratio(serve_time: float) -> float:
	if serve_time <= 0.0:
		return 0.0
	return clampf(_serve_progress / serve_time, 0.0, 1.0)


## Advances serving. Returns the order that was just served (its items already
## removed from stock), or null.
func tick(delta: float, cashier_present: bool, serve_time: float) -> CustomerOrder:
	if not _can_serve_front(cashier_present):
		_serve_progress = 0.0
		return null
	_serve_progress += delta
	if _serve_progress < serve_time:
		return null
	_serve_progress = 0.0
	var served: CustomerOrder = _queue.pop_front()
	for i in served.count:
		stock.pop_matching([item_id])
	return served


## Drains patience; returns orders whose customers gave up (removed from the queue).
## The customer currently being served keeps their patience.
func expire(delta: float) -> Array[CustomerOrder]:
	var gone: Array[CustomerOrder] = []
	for index in range(_queue.size() - 1, -1, -1):
		if index == 0 and _serve_progress > 0.0:
			continue
		var order := _queue[index]
		order.patience -= delta
		if order.patience <= 0.0:
			_queue.remove_at(index)
			gone.push_front(order)
	return gone


func _can_serve_front(cashier_present: bool) -> bool:
	if _queue.is_empty() or not cashier_present:
		return false
	var front := _queue[0]
	return front.is_ready and stock.count(item_id) >= front.count
