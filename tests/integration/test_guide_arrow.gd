extends GutTest
## Onboarding steps advance only in order, are saved, and the guide leaves when done.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")


func before_each() -> void:
	GameState.new_game()


func after_each() -> void:
	GameState.new_game()


func _spawn_farm() -> Location:
	var farm := FARM_SCENE.instantiate() as Location
	add_child_autofree(farm)
	(farm.get_node("CustomerSpawner") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	return farm


func test_steps_advance_in_order() -> void:
	_spawn_farm()
	assert_eq(GameState.data.tutorial_step, 0)
	EventBus.item_delivered.emit(&"egg")
	assert_eq(GameState.data.tutorial_step, 0)
	EventBus.item_collected.emit(&"egg")
	assert_eq(GameState.data.tutorial_step, 1)
	EventBus.item_delivered.emit(&"egg")
	EventBus.item_sold.emit(&"egg", 1, 3.0)
	assert_eq(GameState.data.tutorial_step, 3)


func test_guide_leaves_after_last_step() -> void:
	var farm := _spawn_farm()
	var guide := farm.get_node("Guide")
	EventBus.item_collected.emit(&"egg")
	EventBus.item_delivered.emit(&"egg")
	EventBus.item_sold.emit(&"egg", 1, 3.0)
	EventBus.money_collected.emit(3.0)
	EventBus.unlock_completed.emit(&"chicken_3")
	assert_eq(GameState.data.tutorial_step, GuideArrow.STEPS.size())
	await wait_frames(2)
	assert_false(is_instance_valid(guide))


func test_finished_onboarding_does_not_show_guide() -> void:
	GameState.data.tutorial_step = GuideArrow.STEPS.size()
	var farm := _spawn_farm()
	await wait_frames(2)
	assert_null(farm.get_node_or_null("Guide"))
