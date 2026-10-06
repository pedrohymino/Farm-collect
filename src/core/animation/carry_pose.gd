class_name CarryPose
extends RefCounted
## Builds "carrying" versions of locomotion animations: legs, torso and head keep moving,
## the arms freeze in the holding pose (the last key of a short "holding" animation).

const ARM_TRACK_SUFFIXES: Array[String] = [":arm-left", ":arm-right"]


static func is_arm_track(path: NodePath) -> bool:
	var text := String(path)
	for suffix in ARM_TRACK_SUFFIXES:
		if text.ends_with(suffix):
			return true
	return false


## `base` keeps its own tracks except the arms, which hold the final pose of `holding`.
static func build_variant(base: Animation, holding: Animation) -> Animation:
	var variant := base.duplicate() as Animation
	for track in variant.get_track_count():
		var path := variant.track_get_path(track)
		if not is_arm_track(path):
			continue
		var held_track := holding.find_track(path, variant.track_get_type(track))
		var held_keys := holding.track_get_key_count(held_track) if held_track >= 0 else 0
		if held_keys == 0:
			continue
		var pose: Variant = holding.track_get_key_value(held_track, held_keys - 1)
		while variant.track_get_key_count(track) > 0:
			variant.track_remove_key(track, 0)
		variant.track_insert_key(track, 0.0, pose)
	variant.loop_mode = Animation.LOOP_LINEAR
	return variant
