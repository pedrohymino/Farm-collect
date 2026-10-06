extends GutTest
## customer.spawn_interval is per open counter: opening more counters brings more customers.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const SPAWN_INTERVAL_SEC: float = 0.5
## Short enough that no queue fills up (max 5 customers per counter).
const OBSERVE_FRAMES: int = 70
const SETTLE_FRAMES: int = 2
const SECOND_COUNTER_UNLOCKS: Array[StringName] = [
	&"chicken_3", &"area_field", &"wheat_field", &"wheat_counter"
]


func before_each() -> void:
	GameState.new_game()
	Stats.set_dev_override(&"customer.spawn_interval", 1.0, SPAWN_INTERVAL_SEC)
	Stats.set_dev_override(&"customer.patience", 1.0, 1000.0)


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()


func _customers_in_fresh_farm(unlock_ids: Array[StringName]) -> int:
	GameState.new_game()
	for unlock_id in unlock_ids:
		Unlocks.complete(unlock_id)
	var farm: Location = FARM_SCENE.instantiate()
	add_child(farm)
	await wait_physics_frames(SETTLE_FRAMES + OBSERVE_FRAMES)
	var count := 0
	for child in farm.get_children():
		if child is Customer:
			count += 1
	farm.queue_free()
	await wait_physics_frames(SETTLE_FRAMES)
	return count


func test_more_open_counters_bring_more_customers() -> void:
	var with_one_counter := await _customers_in_fresh_farm([])
	var with_two_counters := await _customers_in_fresh_farm(SECOND_COUNTER_UNLOCKS)
	assert_gt(with_one_counter, 0)
	assert_gt(with_two_counters, with_one_counter)
