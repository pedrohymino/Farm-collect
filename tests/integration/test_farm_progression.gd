extends GutTest
## M5 effects inside the real farm: magnet pickup, VIP customers, the upgrade board.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const CUSTOMER_SCENE: PackedScene = preload("res://src/gameplay/npcs/customer.tscn")

var farm: Location
var player: Player


func before_each() -> void:
	GameState.new_game()
	farm = FARM_SCENE.instantiate()
	add_child_autofree(farm)
	(farm.get_node("CustomerSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	player = farm.get_node("Player")
	await wait_physics_frames(2)


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()


func test_magnet_collects_from_outside_the_zone() -> void:
	var coop := farm.get_node("Coop") as Producer
	for i in 3:
		coop.output.push(&"egg")
	var zone := coop.get_node("PickupZone") as Node3D
	player.global_position = zone.global_position + Vector3(2.0, 0.0, 0.0)
	await wait_physics_frames(30)
	assert_eq(player.carry_visual.container.size(), 0, "no magnet yet")
	Stats.set_dev_override(&"player.magnet_radius", 1.0, 2.0)
	await wait_physics_frames(30)
	assert_gte(player.carry_visual.container.count(&"egg"), 3)


func test_vip_customer_pays_multiplied() -> void:
	Stats.set_dev_override(&"sell.vip_chance", 1.0, 1.0)
	var counter := farm.get_node("EggCounter") as Counter
	counter.stock.push(&"egg")
	var customer := CUSTOMER_SCENE.instantiate() as Customer
	farm.add_child(customer)
	customer.global_position = counter.queue_slot_global(0)
	var exit: Array[Vector3] = [Vector3(30, 0, 30)]
	customer.setup(CustomerOrder.new(&"egg", 1, 60.0), null, exit)
	counter.enqueue(customer)
	player.global_position = (counter.get_node("CashierSpot") as Node3D).global_position
	await wait_seconds(Stats.get_value(&"counter.serve_time") + 0.4)
	var expected := ContentDB.item_base_price(&"egg") * Stats.get_value(&"sell.vip_multiplier")
	assert_almost_eq(counter.money_pile.stash.value, expected, 0.001)


func test_upgrade_board_appears_after_unlock_and_announces_the_player() -> void:
	var station := farm.get_node("UpgradeStation") as Node3D
	assert_false(station.visible)
	Unlocks.complete(&"chicken_3")
	Unlocks.complete(&"upgrade_board")
	assert_true(station.visible)
	watch_signals(EventBus)
	await wait_seconds(Location.REVEAL_TIME + 0.2)
	player.global_position = (station.get_node("Zone") as Node3D).global_position
	await wait_physics_frames(10)
	assert_signal_emitted(EventBus, "upgrade_board_entered")
