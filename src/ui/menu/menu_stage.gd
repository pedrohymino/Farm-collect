class_name MenuStage
extends Node3D
## The main-menu backdrop: a little farm diorama (farmer, cow, chicken, market, windmill, trees)
## under a slowly swaying camera. Pure decoration, built in code from the game's own models.

const FARMER: PackedScene = preload(
	"res://assets/models/kenney/mini-characters/character-female-f.glb"
)
const COW: PackedScene = preload("res://assets/models/animals/cow.tscn")
const CHICKEN: PackedScene = preload("res://assets/models/animals/chicken.tscn")
const MARKET: PackedScene = preload("res://assets/models/kaykit/hexagon/building_market_red.gltf")
const WINDMILL: PackedScene = preload(
	"res://assets/models/kaykit/hexagon/building_windmill_red.gltf"
)
const TENT: PackedScene = preload("res://assets/models/kenney/mini-forest/tent.glb")
const TREE: PackedScene = preload("res://assets/models/props/tree.tscn")
const BUSH: PackedScene = preload("res://assets/models/kaykit/forest/Bush_2_A_Color1.gltf")
const CRATE: PackedScene = preload("res://assets/models/kaykit/hexagon/crate_A_big.gltf")

const GROUND_COLOR: Color = Color("5fa83f")
const SKY_COLOR: Color = Color("87ceeb")
const FARMER_SCALE: float = 2.6
const CAMERA_POSITION: Vector3 = Vector3(0.0, 3.6, 10.5)
const CAMERA_TARGET: Vector3 = Vector3(0.0, 2.3, 0.0)
## Wide screens put the buttons over the lower part of the picture: look lower to lift the scene.
const LANDSCAPE_CAMERA_TARGET: Vector3 = Vector3(0.0, 0.8, 0.0)
const CAMERA_FOV: float = 50.0
const SWAY_AMPLITUDE: float = 0.6
const SWAY_SPEED: float = 0.25
const PEN_HALF_EXTENTS: Vector2 = Vector2(0.5, 0.35)

var _camera: Camera3D
var _time: float = 0.0


func _ready() -> void:
	_build_environment()
	_place(MARKET, Vector3(0.4, 0.0, -2.8), 2.0)
	_place(WINDMILL, Vector3(4.6, 0.0, -3.4), 3.4, -20.0)
	_place(TENT, Vector3(-3.6, 0.0, -1.0), 2.2, 25.0)
	_place(TREE, Vector3(-5.2, 0.0, -3.0), 1.9)
	_place(TREE, Vector3(6.4, 0.0, -0.2), 1.6)
	_place(BUSH, Vector3(-2.2, 0.0, -2.4), 4.0)
	_place(BUSH, Vector3(3.0, 0.0, -1.2), 3.4, 70.0)
	_place(CRATE, Vector3(2.0, 0.0, -1.6), 4.2, 30.0)
	var cow := _place(COW, Vector3(1.7, 0.0, 1.3), 1.5, -25.0)
	(cow as AnimalWander).set_bounds(PEN_HALF_EXTENTS)
	var chicken := _place(CHICKEN, Vector3(-0.6, 0.0, 2.3), 1.7, 20.0)
	(chicken as AnimalWander).set_bounds(PEN_HALF_EXTENTS)
	_add_farmer()


func _process(delta: float) -> void:
	_time += delta
	var sway := sin(_time * SWAY_SPEED * TAU) * SWAY_AMPLITUDE
	_camera.position = CAMERA_POSITION + Vector3(sway, 0.0, 0.0)
	var size := get_viewport().get_visible_rect().size
	var is_portrait := size.y > size.x
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if is_portrait else Camera3D.KEEP_HEIGHT
	_camera.look_at(CAMERA_TARGET if is_portrait else LANDSCAPE_CAMERA_TARGET)


func _place(
	scene: PackedScene, position_value: Vector3, scale_factor: float, yaw: float = 0.0
) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.position = position_value
	node.scale = Vector3.ONE * scale_factor
	node.rotation_degrees.y = yaw
	add_child(node)
	return node


func _add_farmer() -> void:
	var holder := Node3D.new()
	holder.position = Vector3(-1.5, 0.0, 1.2)
	holder.rotation_degrees.y = 18.0
	add_child(holder)
	var farmer := CharacterModel.new()
	farmer.model_scene = FARMER
	farmer.model_scale = FARMER_SCALE
	holder.add_child(farmer)


func _build_environment() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 40.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = GROUND_COLOR
	plane.material = material
	ground.mesh = plane
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.add_to_group(Settings.SUN_GROUP)
	add_child(sun)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = SKY_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.45
	world.environment = environment
	add_child(world)
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.position = CAMERA_POSITION
	add_child(_camera)
	_camera.look_at(CAMERA_TARGET)
