extends SceneTree
## Dev tool: lists the animations of a model with length, loop mode and the bones they move.
##   godot --headless --path . -s res://tools/inspect_animations.gd --
##     res://path/model.glb [anim ...]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var scene := load(args[0]) as PackedScene
	var root := scene.instantiate()
	var wanted := args.slice(1)
	for player in root.find_children("*", "AnimationPlayer", true, false):
		var animation_player := player as AnimationPlayer
		for animation_name in animation_player.get_animation_list():
			if not wanted.is_empty() and not wanted.has(animation_name):
				continue
			var animation := animation_player.get_animation(animation_name)
			var bones := {}
			for track in animation.get_track_count():
				bones[String(animation.track_get_path(track)).get_slice(":", 1)] = true
			print(
				animation_name,
				" | ",
				snappedf(animation.length, 0.01),
				"s | loop=",
				animation.loop_mode,
				" | tracks=",
				animation.get_track_count(),
				" | bones=",
				bones.keys().slice(0, 12)
			)
	root.free()
	quit()
