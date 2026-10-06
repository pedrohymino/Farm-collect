extends GutTest
## M6 on the real farm: helpers, machines, unlock effects, trucks, money collector, offline.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const CUSTOMER_SCENE: PackedScene = preload("res://src/gameplay/npcs/customer.tscn")
const TO_COW_2: Array[StringName] = [
	&"chicken_3",
	&"area_field",
	&"wheat_field",
	&"wheat_counter",
	&"area_pasture",
	&"barn",
	&"milk_counter",
	&"cow_2",
]

var farm: Location
var player: Player


func before_each() -> void:
	GameState.new_game()
	farm = FARM_SCENE.instantiate()
	add_child_autofree(farm)
	(farm.get_node("CustomerSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	player = farm.get_node("Player")
	player.global_position = Vector3(0, 0, -3)
	await wait_physics_frames(2)


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()
	Offline.pending = 0.0


func _complete(ids: Array[StringName]) -> void:
	for unlock_id in ids:
		Unlocks.complete(unlock_id)


func _add_customer(counter: Counter, count: int) -> void:
	var customer := CUSTOMER_SCENE.instantiate() as Customer
	farm.add_child(customer)
	customer.global_position = counter.queue_slot_global(0)
	var exit: Array[Vector3] = [Vector3(30, 0, 30)]
	customer.setup(CustomerOrder.new(counter.item_id, count, 60.0), Color.WHITE, exit)
	counter.enqueue(customer)


func test_worker_cashier_sells_without_the_player() -> void:
	_complete(TO_COW_2)
	Unlocks.complete(&"cashier_egg")
	await wait_seconds(Location.REVEAL_TIME + 0.2)
	var counter := farm.get_node("EggCounter") as Counter
	counter.stock.push(&"egg")
	_add_customer(counter, 1)
	watch_signals(EventBus)
	await wait_seconds(Stats.get_value(&"counter.serve_time") + 0.5)
	assert_gt(counter.money_pile.stash.value, 0.0)
	assert_signal_emitted(EventBus, "automated_income")


func test_worker_carrier_brings_eggs_to_the_counter() -> void:
	_complete(TO_COW_2)
	_complete([&"cashier_egg", &"carrier_egg"])
	var coop := farm.get_node("Coop") as Producer
	for i in 4:
		coop.output.push(&"egg")
	Stats.set_dev_override(&"worker.move_speed", 1.0, 20.0)
	Stats.set_dev_override(&"worker.carry_capacity", 1.0, 4.0)
	var counter := farm.get_node("EggCounter") as Counter
	await wait_until(func() -> bool: return counter.stock.count(&"egg") >= 4, 8.0)
	assert_gte(counter.stock.count(&"egg"), 4)


func test_conveyor_moves_eggs_to_the_counter() -> void:
	_complete(TO_COW_2)
	_complete([&"cashier_egg", &"carrier_egg", &"egg_conveyor"])
	(farm.get_node("Workers/CarrierEgg") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var coop := farm.get_node("Coop") as Producer
	for i in 3:
		coop.output.push(&"egg")
	Stats.set_dev_override(&"machine.speed", 1.0, 5.0)
	var counter := farm.get_node("EggCounter") as Counter
	await wait_until(func() -> bool: return counter.stock.count(&"egg") >= 3, 6.0)
	assert_gte(counter.stock.count(&"egg"), 3)


func test_machine_unlock_effects_apply_and_survive_reload() -> void:
	var base := Stats.get_value(&"production.rate.milk")
	_complete(TO_COW_2)
	Unlocks.complete(&"milking_machine")
	assert_almost_eq(Stats.get_value(&"production.rate.milk"), base * 1.5, 0.0001)
	var saved := GameData.from_dict(GameState.data.to_dict())
	GameState.new_game()
	assert_almost_eq(Stats.get_value(&"production.rate.milk"), base, 0.0001)
	GameState.replace(saved)
	assert_almost_eq(Stats.get_value(&"production.rate.milk"), base * 1.5, 0.0001)


func test_truck_order_pays_bonus_when_filled() -> void:
	_complete(TO_COW_2)
	_complete([&"area_road", &"truck_bay"])
	await wait_seconds(Location.REVEAL_TIME + 0.2)
	var bay := farm.get_node("TruckBay") as TruckBay
	bay.arrive_now(true)
	assert_eq(bay.phase, TruckBay.Phase.PARKED)
	assert_false(bay.order.is_empty())
	Stats.set_dev_override(&"player.carry_capacity", 1.0, 200.0)
	for item_id: StringName in bay.order:
		for i in bay.order[item_id]:
			player.carry_visual.container.push(item_id)
	watch_signals(EventBus)
	player.global_position = (bay.get_node("DropZone") as Node3D).global_position
	await wait_seconds(4.0)
	assert_signal_emitted(EventBus, "truck_order_completed")
	assert_gt(bay.money_pile.stash.value, 0.0)
	assert_eq(bay.phase, TruckBay.Phase.LEAVING)


func test_money_collector_brings_pile_money_to_the_wallet() -> void:
	_complete(TO_COW_2)
	_complete([&"area_road", &"truck_bay", &"money_collector"])
	(farm.get_node("EggCounter") as Counter).money_pile.stash.add(50.0)
	await wait_until(func() -> bool: return Economy.balance(Wallet.MONEY) >= 50.0, 6.0)
	assert_almost_eq(Economy.balance(Wallet.MONEY), 50.0, 0.001)


func test_training_and_automation_branch_need_the_first_helper() -> void:
	assert_false(Progression.is_upgrade_visible(&"training"))
	Economy.earn(Wallet.STARS, 5.0)
	assert_false(Progression.can_buy_passive(&"automation_1"))
	_complete(TO_COW_2)
	Unlocks.complete(&"cashier_egg")
	assert_true(Progression.is_upgrade_visible(&"training"))
	assert_true(Progression.can_buy_passive(&"automation_1"))


func test_offline_earnings_from_saved_rate() -> void:
	GameState.data.income_rate = 1.0
	GameState.data.last_seen_unix = Time.get_unix_time_from_system() - 3600.0
	watch_signals(EventBus)
	EventBus.game_loaded.emit()
	var expected := 3600.0 * Stats.get_value(&"offline.efficiency")
	assert_almost_eq(Offline.pending, expected, 1.0)
	assert_signal_emitted(EventBus, "offline_earnings_ready")
	Offline.collect()
	assert_almost_eq(Economy.balance(Wallet.MONEY), expected, 1.0)


func test_offline_popup_shows_and_collects() -> void:
	var popup := OfflinePopup.new()
	add_child_autofree(popup)
	Offline.pending = 120.0
	EventBus.offline_earnings_ready.emit(120.0, 5400.0)
	assert_true(popup.visible)
	assert_string_contains(popup.format_duration(5400.0), "1")
	popup.collect()
	assert_false(popup.visible)
	assert_eq(Economy.balance(Wallet.MONEY), 120.0)
