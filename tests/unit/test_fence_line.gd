extends GutTest


func test_piece_count_accounts_for_the_shared_post() -> void:
	# pieces 2.0 long with 0.5 posts advance 1.5 each
	assert_eq(FenceLine.piece_count(3.0, 2.0, 0.5), 2)
	assert_eq(FenceLine.piece_count(6.0, 2.0, 0.5), 4)
	assert_eq(FenceLine.piece_count(0.3, 2.0, 0.5), 1)


func test_builds_one_multimesh_and_collision() -> void:
	var fence := FenceLine.new()
	fence.points = PackedVector2Array([Vector2(0, 0), Vector2(6, 0), Vector2(6, 4)])
	add_child_autofree(fence)
	var multimeshes := fence.find_children("*", "MultiMeshInstance3D", true, false)
	assert_eq(multimeshes.size(), 1)
	assert_gt((multimeshes[0] as MultiMeshInstance3D).multimesh.instance_count, 2)
	assert_eq(fence.find_children("*", "CollisionShape3D", true, false).size(), 2)


func test_closed_fence_adds_the_closing_segment() -> void:
	var fence := FenceLine.new()
	fence.points = PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 4), Vector2(0, 4)])
	fence.closed = true
	add_child_autofree(fence)
	assert_eq(fence.find_children("*", "CollisionShape3D", true, false).size(), 4)


func test_collision_can_be_disabled() -> void:
	var fence := FenceLine.new()
	fence.has_collision = false
	add_child_autofree(fence)
	assert_eq(fence.find_children("*", "CollisionShape3D", true, false).size(), 0)
