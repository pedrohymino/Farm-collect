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


func test_after_the_last_step_the_guide_points_at_the_next_goal() -> void:
	var farm := _spawn_farm()
	var guide := farm.get_node("Guide") as GuideArrow
	assert_false(guide.is_goal_mode())
	EventBus.item_collected.emit(&"egg")
	EventBus.item_delivered.emit(&"egg")
	EventBus.item_sold.emit(&"egg", 1, 3.0)
	EventBus.money_collected.emit(3.0)
	EventBus.unlock_completed.emit(&"chicken_3")
	assert_eq(GameState.data.tutorial_step, GuideArrow.STEPS.size())
	await wait_frames(2)
	assert_true(is_instance_valid(guide))
	assert_true(guide.is_goal_mode())


func test_next_goal_is_the_cheapest_visible_pad() -> void:
	GameState.data.tutorial_step = GuideArrow.STEPS.size()
	var farm := _spawn_farm()
	var guide := farm.get_node("Guide") as GuideArrow
	await wait_frames(2)
	assert_eq(guide.next_goal_pad().unlock_id, &"chicken_3")
	Unlocks.complete(&"chicken_3")
	await wait_frames(2)
	var expected := guide.next_goal_pad()
	for node in get_tree().get_nodes_in_group(&"unlock_pad"):
		var pad := node as UnlockPad
		if pad.visible:
			assert_lte(Unlocks.remaining(expected.unlock_id), Unlocks.remaining(pad.unlock_id))
	assert_ne(expected.unlock_id, &"chicken_3")


func test_marker_is_visible_in_goal_mode() -> void:
	GameState.data.tutorial_step = GuideArrow.STEPS.size()
	var farm := _spawn_farm()
	await wait_frames(3)
	assert_true((farm.get_node("Guide/Marker") as Node3D).visible)
