extends GutTest


func test_standing_still_is_idle() -> void:
	assert_eq(LocomotionRules.animation_for(0.0, false), &"idle")
	assert_eq(LocomotionRules.animation_for(0.1, false), &"idle")


func test_moderate_speed_walks_and_fast_sprints() -> void:
	assert_eq(LocomotionRules.animation_for(2.0, false), &"walk")
	assert_eq(LocomotionRules.animation_for(4.0, false), &"sprint")


func test_carrying_adds_suffix() -> void:
	assert_eq(LocomotionRules.animation_for(0.0, true), &"idle-carry")
	assert_eq(LocomotionRules.animation_for(2.0, true), &"walk-carry")
	assert_eq(LocomotionRules.animation_for(5.0, true), &"sprint-carry")


func test_playback_follows_speed_within_limits() -> void:
	assert_almost_eq(LocomotionRules.playback_speed(2.2), 1.0, 0.0001)
	assert_almost_eq(LocomotionRules.playback_speed(4.5), 1.0, 0.0001)
	assert_eq(LocomotionRules.playback_speed(3.0), LocomotionRules.playback_speed(3.0))
	assert_eq(LocomotionRules.playback_speed(0.0), 1.0)
	assert_eq(LocomotionRules.playback_speed(0.2), LocomotionRules.MIN_PLAYBACK)
	assert_eq(LocomotionRules.playback_speed(30.0), LocomotionRules.MAX_PLAYBACK)


func test_faster_walk_plays_faster() -> void:
	assert_gt(LocomotionRules.playback_speed(3.0), LocomotionRules.playback_speed(1.5))
