@tool
class_name FenceLine
extends Node3D
## Low-poly fence (posts + rails + optional collision) along local XZ points.
## Built at runtime and in the editor; generated nodes are never saved into the scene.

const POST_SIZE: Vector3 = Vector3(0.14, 0.75, 0.14)
const POST_SPACING: float = 1.0
const RAIL_HEIGHTS: Array[float] = [0.28, 0.55]
const RAIL_SIZE: Vector2 = Vector2(0.06, 0.09)
const COLLISION_HEIGHT: float = 1.2
const COLLISION_THICKNESS: float = 0.3

@export var points: PackedVector2Array = PackedVector2Array([Vector2(-2, 0), Vector2(2, 0)]):
	set(value):
		points = value
		_rebuild()
@export var closed: bool = false:
	set(value):
		closed = value
		_rebuild()
@export var has_collision: bool = true:
	set(value):
		has_collision = value
		_rebuild()
@export var color: Color = Color("b5713a"):
	set(value):
		color = value
		_rebuild()

var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for node in _generated:
		node.queue_free()
	_generated.clear()
	if points.size() < 2:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var post_transforms: Array[Transform3D] = []
	var body := StaticBody3D.new() if has_collision else null
	if body != null:
		_add_generated(body)

	for segment in _segments():
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var length := start.distance_to(end)
		var steps := maxi(ceili(length / POST_SPACING), 1)
		for i in steps + 1:
			var p := start.lerp(end, i / float(steps))
			post_transforms.append(Transform3D(Basis(), Vector3(p.x, POST_SIZE.y * 0.5, p.y)))
		var center := (start + end) * 0.5
		var yaw := atan2(end.x - start.x, end.y - start.y)
		for height in RAIL_HEIGHTS:
			var rail := MeshInstance3D.new()
			var rail_mesh := BoxMesh.new()
			rail_mesh.size = Vector3(RAIL_SIZE.x, RAIL_SIZE.y, length)
			rail_mesh.material = material
			rail.mesh = rail_mesh
			rail.position = Vector3(center.x, height, center.y)
			rail.rotation.y = yaw
			_add_generated(rail)
		if body != null:
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(COLLISION_THICKNESS, COLLISION_HEIGHT, length)
			shape.shape = box
			shape.position = Vector3(center.x, COLLISION_HEIGHT * 0.5, center.y)
			shape.rotation.y = yaw
			body.add_child(shape)

	var posts := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var post_mesh := BoxMesh.new()
	post_mesh.size = POST_SIZE
	post_mesh.material = material
	multimesh.mesh = post_mesh
	multimesh.instance_count = post_transforms.size()
	for i in post_transforms.size():
		multimesh.set_instance_transform(i, post_transforms[i])
	posts.multimesh = multimesh
	_add_generated(posts)


func _segments() -> Array:
	var segments := []
	for i in points.size() - 1:
		segments.append([points[i], points[i + 1]])
	if closed and points.size() > 2:
		segments.append([points[points.size() - 1], points[0]])
	return segments


func _add_generated(node: Node) -> void:
	add_child(node)
	_generated.append(node)
