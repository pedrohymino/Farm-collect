extends Node3D
## Dev tool: shows models side by side to judge scale and style.
##   godot --path . --write-movie out.png --quit-after 8 res://tools/showcase_models.tscn --
##     path[@scale[@yaw]] ...
## Models stand in a row on a green ground, labelled with their file name.

const SPACING: float = 2.4
const CAMERA_HEIGHT: float = 3.2
const CAMERA_BACK: float = 6.5
const GROUND_COLOR: Color = Color("5fa83f")


func _ready() -> void:
	var entries := OS.get_cmdline_user_args()
	var count := entries.size()
	_build_environment(count)
	for index in count:
		var parts := entries[index].split("@")
		var scene := load(parts[0]) as PackedScene
		if scene == null:
			push_error("cannot load " + parts[0])
			continue
		var model := scene.instantiate() as Node3D
		var scale_factor := float(parts[1]) if parts.size() > 1 else 1.0
		model.scale = Vector3.ONE * scale_factor
		model.rotation_degrees.y = float(parts[2]) if parts.size() > 2 else 0.0
		model.position.x = (index - (count - 1) * 0.5) * SPACING
		add_child(model)
		var label := Label3D.new()
		label.text = parts[0].get_file().get_basename()
		label.font_size = 48
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(model.position.x, 0.12, 1.0)
		add_child(label)


func _build_environment(count: int) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(maxf(count * SPACING + 4.0, 12.0), 8.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = GROUND_COLOR
	plane.material = material
	ground.mesh = plane
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("87ceeb")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.45
	world.environment = environment
	add_child(world)
	var camera := Camera3D.new()
	camera.fov = 40.0
	camera.position = Vector3(0, CAMERA_HEIGHT + count * 0.3, CAMERA_BACK + count * 1.6)
	camera.rotation_degrees = Vector3(-18, 0, 0)
	add_child(camera)
