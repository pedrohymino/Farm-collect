extends GutTest

const YAW := PI / 4.0


func test_no_input_gives_no_direction() -> void:
	assert_eq(IsoInput.to_world(Vector2.ZERO, YAW), Vector3.ZERO)


func test_up_moves_away_from_camera() -> void:
	var dir := IsoInput.to_world(Vector2.UP, YAW)
	assert_almost_eq(dir.x, -sin(YAW), 0.0001)
	assert_almost_eq(dir.z, -cos(YAW), 0.0001)


func test_right_moves_along_camera_right() -> void:
	var dir := IsoInput.to_world(Vector2.RIGHT, YAW)
	assert_almost_eq(dir.x, cos(YAW), 0.0001)
	assert_almost_eq(dir.z, -sin(YAW), 0.0001)


func test_direction_is_horizontal_and_keeps_magnitude() -> void:
	var dir := IsoInput.to_world(Vector2(0.6, -0.8), YAW)
	assert_eq(dir.y, 0.0)
	assert_almost_eq(dir.length(), 1.0, 0.0001)
