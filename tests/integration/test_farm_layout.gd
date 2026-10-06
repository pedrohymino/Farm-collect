extends GutTest
## Layout invariants of the real farm: players must never get trapped.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")


func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon)


func test_no_unlock_pad_is_inside_a_closed_fence() -> void:
	GameState.new_game()
	var farm := FARM_SCENE.instantiate() as Location
	add_child_autofree(farm)
	await wait_physics_frames(2)
	var pads_checked := 0
	var closed_fences: Array[FenceLine] = []
	for node in farm.find_children("*", "Node3D", true, false):
		var fence := node as FenceLine
		if fence != null and fence.closed:
			closed_fences.append(fence)
	for pad_node in farm.find_children("*", "Area3D", true, false):
		var pad := pad_node as UnlockPad
		if pad == null:
			continue
		pads_checked += 1
		for fence in closed_fences:
			var polygon := PackedVector2Array()
			for local_point in fence.points:
				var world := fence.to_global(Vector3(local_point.x, 0.0, local_point.y))
				polygon.append(Vector2(world.x, world.z))
			var inside := _point_in_polygon(
				Vector2(pad.global_position.x, pad.global_position.z), polygon
			)
			assert_false(inside, "%s is inside the closed fence %s" % [pad.name, fence.get_path()])
	assert_gt(pads_checked, 5, "the farm has unlock pads to check")
	GameState.new_game()


func test_every_pen_has_a_gate() -> void:
	GameState.new_game()
	var farm := FARM_SCENE.instantiate() as Location
	add_child_autofree(farm)
	await wait_physics_frames(2)
	for node in farm.find_children("*", "Node3D", true, false):
		var fence := node as FenceLine
		if fence != null and fence.name == &"Pen":
			assert_false(fence.closed, "%s is a closed ring" % fence.get_path())
	GameState.new_game()
