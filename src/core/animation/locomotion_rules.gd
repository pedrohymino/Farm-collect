class_name LocomotionRules
extends RefCounted
## Which locomotion animation fits a movement speed, and how fast to play it so feet
## don't slide. Animations: idle / walk / sprint, plus "-carry" variants (arms holding a stack).

const IDLE_BELOW_SPEED: float = 0.15
const SPRINT_FROM_SPEED: float = 3.2
## Speed at which the animation's natural stride matches the ground (m/s, at game scale).
const WALK_REFERENCE_SPEED: float = 2.2
const SPRINT_REFERENCE_SPEED: float = 4.5
const MIN_PLAYBACK: float = 0.6
const MAX_PLAYBACK: float = 1.8
const CARRY_SUFFIX: String = "-carry"


static func animation_for(speed: float, carrying: bool) -> StringName:
	var base := &"idle"
	if speed >= SPRINT_FROM_SPEED:
		base = &"sprint"
	elif speed >= IDLE_BELOW_SPEED:
		base = &"walk"
	return StringName(String(base) + CARRY_SUFFIX) if carrying else base


static func playback_speed(speed: float) -> float:
	if speed < IDLE_BELOW_SPEED:
		return 1.0
	var reference := WALK_REFERENCE_SPEED if speed < SPRINT_FROM_SPEED else SPRINT_REFERENCE_SPEED
	return clampf(speed / reference, MIN_PLAYBACK, MAX_PLAYBACK)
