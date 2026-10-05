extends GutTest
## The whole M2 loop on the real farm scene: collect -> deliver -> sell -> pick up money.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const CUSTOMER_SCENE: PackedScene = preload("res://src/gameplay/npcs/customer.tscn")
const SETTLE_FRAMES: int = 40

var farm: Location
var player: Player
var coop: Producer
var counter: Counter


func before_each() -> void:
	GameState.new_game()
	farm = FARM_SCENE.instantiate()
	add_child_autofree(farm)
	(farm.get_node("CustomerSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	player = farm.get_node("Player")
	coop = farm.get_node("Coop")
	counter = farm.get_node("EggCounter")
	await wait_physics_frames(2)


func after_each() -> void:
	GameState.new_game()


func _move_player_to(node_path: NodePath, base: Node) -> void:
	player.global_position = (base.get_node(node_path) as Node3D).global_position
	await wait_physics_frames(SETTLE_FRAMES)


func test_coop_starts_with_base_units() -> void:
	assert_eq(coop.unit_count(), ContentDB.producer_base_units(&"coop"))


func test_player_collects_from_coop_pile() -> void:
	for i in 4:
		coop.output.push(&"egg")
	await _move_player_to(^"PickupZone", coop)
	assert_gte(player.carry_visual.container.count(&"egg"), 4)


func test_collection_stops_at_carry_capacity() -> void:
	Stats.set_dev_override(&"player.carry_capacity", 1.0, 2.0)
	for i in 6:
		coop.output.push(&"egg")
	await _move_player_to(^"PickupZone", coop)
	assert_eq(player.carry_visual.container.size(), 2)
	Stats.clear_all_dev_overrides()


func test_player_delivers_only_matching_items_to_counter() -> void:
	player.carry_visual.container.push(&"egg")
	player.carry_visual.container.push(&"milk")
	player.carry_visual.container.push(&"egg")
	await _move_player_to(^"DropZone", counter)
	assert_eq(counter.stock.count(&"egg"), 2)
	assert_eq(player.carry_visual.container.items(), [&"milk"] as Array[StringName])


func test_full_loop_earns_money() -> void:
	for i in 3:
		counter.stock.push(&"egg")
	var customer := CUSTOMER_SCENE.instantiate() as Customer
	farm.add_child(customer)
	customer.global_position = counter.queue_slot_global(0)
	var exit: Array[Vector3] = [Vector3(30, 0, 30)]
	customer.setup(CustomerOrder.new(&"egg", 2, 60.0), Color.WHITE, exit)
	assert_true(counter.enqueue(customer))

	await _move_player_to(^"CashierSpot", counter)
	await wait_seconds(Stats.get_value(&"counter.serve_time") + 0.3)
	var expected := 2 * ContentDB.item_base_price(&"egg")
	assert_almost_eq(counter.money_pile.stash.value, expected, 0.001)
	assert_eq(counter.stock.size(), 1)

	await _move_player_to(^"MoneyPile", counter)
	assert_almost_eq(Economy.balance(Wallet.MONEY), expected, 0.001)
	assert_eq(counter.money_pile.stash.value, 0.0)


func test_location_state_round_trip() -> void:
	coop.output.push(&"egg")
	counter.stock.push(&"egg")
	counter.money_pile.stash.add(12.0)
	player.carry_visual.container.push(&"egg")
	farm.write_state()

	var reloaded := FARM_SCENE.instantiate() as Location
	add_child_autofree(reloaded)
	assert_eq((reloaded.get_node("Coop") as Producer).output.size(), 1)
	assert_eq((reloaded.get_node("EggCounter") as Counter).stock.size(), 1)
	assert_eq((reloaded.get_node("EggCounter") as Counter).money_pile.stash.value, 12.0)
	assert_eq((reloaded.get_node("Player") as Player).carry_visual.container.size(), 1)
