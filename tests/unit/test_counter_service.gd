extends GutTest

const SERVE_TIME := 0.5

var stock: ItemContainer
var service: CounterService


func before_each() -> void:
	stock = ItemContainer.new(func() -> int: return 30, [&"egg"])
	service = CounterService.new(stock, &"egg")


func _order(count: int, patience: float = 20.0) -> CustomerOrder:
	return CustomerOrder.new(&"egg", count, patience)


func _fill(amount: int) -> void:
	for i in amount:
		stock.push(&"egg")


func test_join_returns_slot_and_respects_max_queue() -> void:
	assert_eq(service.join(_order(1), 2), 0)
	assert_eq(service.join(_order(1), 2), 1)
	assert_eq(service.join(_order(1), 2), -1)
	assert_eq(service.queue_size(), 2)


func test_serves_front_after_serve_time_when_ready_stocked_and_attended() -> void:
	var order := _order(2)
	service.join(order, 5)
	order.is_ready = true
	_fill(3)
	assert_null(service.tick(0.3, true, SERVE_TIME))
	var served := service.tick(0.3, true, SERVE_TIME)
	assert_eq(served, order)
	assert_eq(stock.size(), 1)
	assert_eq(service.queue_size(), 0)


func test_no_sale_without_cashier() -> void:
	var order := _order(1)
	service.join(order, 5)
	order.is_ready = true
	_fill(1)
	assert_null(service.tick(5.0, false, SERVE_TIME))
	assert_eq(stock.size(), 1)


func test_no_sale_until_customer_reaches_counter() -> void:
	service.join(_order(1), 5)
	_fill(1)
	assert_null(service.tick(5.0, true, SERVE_TIME))


func test_no_sale_without_enough_stock() -> void:
	var order := _order(3)
	service.join(order, 5)
	order.is_ready = true
	_fill(2)
	assert_null(service.tick(5.0, true, SERVE_TIME))


func test_progress_resets_when_cashier_leaves() -> void:
	var order := _order(1)
	service.join(order, 5)
	order.is_ready = true
	_fill(1)
	service.tick(0.4, true, SERVE_TIME)
	service.tick(0.1, false, SERVE_TIME)
	assert_null(service.tick(0.4, true, SERVE_TIME))


func test_queue_advances_after_sale() -> void:
	var first := _order(1)
	var second := _order(1)
	service.join(first, 5)
	service.join(second, 5)
	assert_eq(service.slot_of(second), 1)
	first.is_ready = true
	_fill(1)
	service.tick(1.0, true, SERVE_TIME)
	assert_eq(service.slot_of(second), 0)
	assert_eq(service.slot_of(first), -1)


func test_impatient_customers_leave() -> void:
	var patient := _order(1, 10.0)
	var impatient := _order(1, 2.0)
	service.join(patient, 5)
	service.join(impatient, 5)
	var gone := service.expire(3.0)
	assert_eq(gone, [impatient])
	assert_eq(service.queue_size(), 1)


func test_customer_being_served_does_not_lose_patience() -> void:
	var order := _order(1, 1.0)
	service.join(order, 5)
	order.is_ready = true
	_fill(1)
	service.tick(0.1, true, SERVE_TIME)
	assert_eq(service.expire(2.0), [])
