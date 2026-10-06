extends GutTest
## Unlock pads, area expansion, wheat field and barn on the real farm scene.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const TO_WHEAT_COUNTER: Array[StringName] = [
	&"chicken_3", &"area_field", &"wheat_field", &"wheat_counter"
]
const TO_BARN: Array[StringName] = [
	&"chicken_3", &"area_field", &"wheat_field", &"wheat_counter", &"area_pasture", &"barn"
]

var farm: Location
var player: Player


func before_each() -> void:
	GameState.new_game()
	farm = _spawn_farm()
	player = farm.get_node("Player")
	await wait_physics_frames(2)


func after_each() -> void:
	GameState.new_game()
	Stats.clear_all_dev_overrides()


func _spawn_farm() -> Location:
	var instance := FARM_SCENE.instantiate() as Location
	add_child_autofree(instance)
	(instance.get_node("CustomerSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	return instance


func _is_active(location: Location, path: NodePath) -> bool:
	var node := location.get_node(path) as Node3D
	return node.visible and node.can_process()


func _complete(ids: Array[StringName]) -> void:
	for unlock_id in ids:
		Unlocks.complete(unlock_id)


func test_locked_content_starts_hidden() -> void:
	for path: NodePath in [
		^"WheatField", ^"WheatCounter", ^"Barn", ^"MilkCounter", ^"Fences/Field"
	]:
		assert_false(_is_active(farm, path), str(path))
	assert_true(_is_active(farm, ^"Fences/East"))


func test_only_pads_with_met_requirements_are_visible() -> void:
	assert_true((farm.get_node("Pads/Chicken3") as Node3D).visible)
	assert_false((farm.get_node("Pads/Chicken4") as Node3D).visible)
	assert_false((farm.get_node("Pads/AreaField") as Node3D).visible)


func test_standing_on_pad_buys_the_unlock() -> void:
	Economy.earn(Wallet.MONEY, 100.0)
	player.global_position = (farm.get_node("Pads/Chicken3") as Node3D).global_position
	await wait_seconds(UnlockPad.FILL_SECONDS + 0.5)
	assert_true(Unlocks.is_unlocked(&"chicken_3"))
	assert_eq((farm.get_node("Coop") as Producer).unit_count(), 3)
	assert_almost_eq(Economy.balance(Wallet.MONEY), 85.0, 0.01)
	assert_false((farm.get_node("Pads/Chicken3") as Node3D).visible)
	assert_true((farm.get_node("Pads/Chicken4") as Node3D).visible)
	assert_true((farm.get_node("Pads/AreaField") as Node3D).visible)


func test_partial_payment_is_kept() -> void:
	Economy.earn(Wallet.MONEY, 5.0)
	player.global_position = (farm.get_node("Pads/Chicken3") as Node3D).global_position
	await wait_seconds(1.0)
	assert_false(Unlocks.is_unlocked(&"chicken_3"))
	assert_almost_eq(Unlocks.remaining(&"chicken_3"), 10.0, 0.01)
	assert_almost_eq(Economy.balance(Wallet.MONEY), 0.0, 0.01)


func test_area_unlock_swaps_fences_and_reveals_ground() -> void:
	_complete([&"chicken_3", &"area_field"])
	await wait_seconds(Location.HIDE_TIME + 0.2)
	assert_false(_is_active(farm, ^"Fences/East"))
	assert_true(_is_active(farm, ^"Fences/Field"))
	assert_true(_is_active(farm, ^"YardField"))


func test_wheat_is_harvested_by_walking_over_ripe_beds() -> void:
	_complete([&"chicken_3", &"area_field", &"wheat_field"])
	var field := farm.get_node("WheatField") as CropField
	assert_eq(field.bed_count(), ContentDB.producer_base_units(&"field"))
	field.ripen_all()
	player.global_position = field.bed_global_position(0)
	await wait_physics_frames(5)
	assert_gte(player.carry_visual.container.count(&"wheat"), 1)
	assert_lt(field.ripe_count(), field.bed_count())


func test_bed_unlock_adds_beds() -> void:
	_complete(TO_WHEAT_COUNTER)
	Unlocks.complete(&"wheat_beds_2")
	assert_eq((farm.get_node("WheatField") as CropField).bed_count(), 12)


func test_barn_produces_milk_once_unlocked() -> void:
	_complete(TO_BARN)
	var barn := farm.get_node("Barn") as Producer
	assert_eq(barn.unit_count(), 1)
	Stats.set_dev_override(&"production.rate", 50.0)
	await wait_seconds(0.6)
	assert_gt(barn.output.count(&"milk"), 0)


func test_unlocked_counter_opens_for_customers() -> void:
	assert_false((farm.get_node("WheatCounter") as Counter).is_open())
	_complete(TO_WHEAT_COUNTER)
	assert_true((farm.get_node("WheatCounter") as Counter).is_open())


func test_reloaded_farm_rebuilds_unlocked_state() -> void:
	_complete(TO_WHEAT_COUNTER)
	farm.write_state()
	var reloaded := _spawn_farm()
	assert_true(_is_active(reloaded, ^"WheatField"))
	assert_true(_is_active(reloaded, ^"WheatCounter"))
	assert_false(_is_active(reloaded, ^"Fences/East"))
	assert_false((reloaded.get_node("Pads/WheatCounter") as Node3D).visible)
	assert_eq((reloaded.get_node("Coop") as Producer).unit_count(), 3)
