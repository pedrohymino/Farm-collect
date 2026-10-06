extends SceneTree
## Dev tool: prints size, material and animations of imported models.
##   godot --headless --path . -s res://tools/inspect_models.gd -- res://path/model.glb ...
## With no arguments, inspects every .glb under assets/models/kenney.


func _init() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		paths = _find_glbs("res://assets/models/kenney")
	for path in paths:
		_inspect(path)
	quit()


## Transform of `node` relative to `root`, from local transforms only (no scene tree needed).
func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		result = (current as Node3D).transform * result
		current = current.get_parent()
	return result


func _find_glbs(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	for entry in DirAccess.get_directories_at(dir_path):
		found.append_array(_find_glbs(dir_path.path_join(entry)))
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".glb"):
			found.append(dir_path.path_join(file_name))
	return found


func _inspect(path: String) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		print(path.get_file(), ": FAILED TO LOAD")
		return
	var root := scene.instantiate() as Node3D
	var bounds := AABB()
	var first := true
	var materials := {}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var world_box := _transform_to(root, mesh_instance) * mesh_instance.get_aabb()
		bounds = world_box if first else bounds.merge(world_box)
		first = false
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(surface)
			materials[material.resource_path if material else "none"] = true
	var animations := PackedStringArray()
	for player in root.find_children("*", "AnimationPlayer", true, false):
		animations.append_array((player as AnimationPlayer).get_animation_list())
	print(
		path.get_file().get_basename(),
		" size=",
		bounds.size.snapped(Vector3.ONE * 0.01),
		" bottom=",
		snappedf(bounds.position.y, 0.01),
		" materials=",
		materials.keys(),
		" anims=",
		animations.size()
	)
	root.queue_free()
