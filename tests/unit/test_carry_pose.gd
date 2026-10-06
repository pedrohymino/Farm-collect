extends GutTest

const SKELETON := "Model/Skeleton3D"


func _rotation_track(animation: Animation, bone: String, angles: Array[float]) -> void:
	var track := animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(track, NodePath("%s:%s" % [SKELETON, bone]))
	for index in angles.size():
		animation.rotation_track_insert_key(
			track, index * 0.25, Quaternion(Vector3.RIGHT, angles[index])
		)


func _walk() -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	_rotation_track(animation, "leg-left", [0.0, 0.5, 0.0])
	_rotation_track(animation, "arm-left", [0.2, -0.2, 0.2])
	_rotation_track(animation, "arm-right", [-0.2, 0.2, -0.2])
	return animation


func _holding() -> Animation:
	var animation := Animation.new()
	animation.length = 0.17
	_rotation_track(animation, "arm-left", [0.0, 1.2])
	_rotation_track(animation, "arm-right", [0.0, 1.1])
	return animation


func test_arm_tracks_are_recognised() -> void:
	assert_true(CarryPose.is_arm_track(NodePath("Model/Skeleton3D:arm-left")))
	assert_true(CarryPose.is_arm_track(NodePath("Model/Skeleton3D:arm-right")))
	assert_false(CarryPose.is_arm_track(NodePath("Model/Skeleton3D:leg-left")))


func test_variant_freezes_arms_in_holding_pose() -> void:
	var variant := CarryPose.build_variant(_walk(), _holding())
	var arm := variant.find_track(NodePath(SKELETON + ":arm-left"), Animation.TYPE_ROTATION_3D)
	assert_eq(variant.track_get_key_count(arm), 1)
	var pose: Quaternion = variant.track_get_key_value(arm, 0)
	assert_true(pose.is_equal_approx(Quaternion(Vector3.RIGHT, 1.2)))
	var other := variant.find_track(NodePath(SKELETON + ":arm-right"), Animation.TYPE_ROTATION_3D)
	var other_pose: Quaternion = variant.track_get_key_value(other, 0)
	assert_true(other_pose.is_equal_approx(Quaternion(Vector3.RIGHT, 1.1)))


func test_variant_keeps_leg_motion_and_loops() -> void:
	var variant := CarryPose.build_variant(_walk(), _holding())
	var leg := variant.find_track(NodePath(SKELETON + ":leg-left"), Animation.TYPE_ROTATION_3D)
	assert_eq(variant.track_get_key_count(leg), 3)
	assert_eq(variant.loop_mode, Animation.LOOP_LINEAR)


func test_base_animation_is_not_modified() -> void:
	var base := _walk()
	CarryPose.build_variant(base, _holding())
	var arm := base.find_track(NodePath(SKELETON + ":arm-left"), Animation.TYPE_ROTATION_3D)
	assert_eq(base.track_get_key_count(arm), 3)


func test_arm_without_holding_track_is_left_alone() -> void:
	var holding := Animation.new()
	var variant := CarryPose.build_variant(_walk(), holding)
	var arm := variant.find_track(NodePath(SKELETON + ":arm-left"), Animation.TYPE_ROTATION_3D)
	assert_eq(variant.track_get_key_count(arm), 3)
