@tool
class_name FenceLine
extends Node3D
## Fence along local XZ points, built from the Kenney fence piece in ONE MultiMesh (1 draw call),
## with optional collision. Generated nodes are never saved into the scene.

const PIECE_SCENE: PackedScene = preload("res://assets/models/kenney/mini-forest/fence.glb")
## Kenney fence pieces are ~1.1 long; this makes them chunkier and ~0.8 m tall.
const PIECE_SCALE: float = 1.6
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

var _generated: Array[Node] = []
var _piece_mesh: Mesh
var _piece_local: Transform3D = Transform3D.IDENTITY


func _ready() -> void:
	_rebuild()


## Pieces needed to span `length`. Neighbors overlap by one post (`post_width`) so every
## joint shows a single post. At least one piece.
static func piece_count(length: float, piece_length: float, post_width: float) -> int:
	return maxi(roundi(length / maxf(piece_length - post_width, 0.01)), 1)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for node in _generated:
		node.queue_free()
	_generated.clear()
	if points.size() < 2:
		return
	_load_piece()
	var transforms: Array[Transform3D] = []
	var body := StaticBody3D.new() if has_collision else null
	if body != null:
		_add_generated(body)
	var model_length := _piece_mesh.get_aabb().size.x
	var post_width := _piece_mesh.get_aabb().size.z * PIECE_SCALE
	var piece_length := model_length * PIECE_SCALE
	for segment in _segments():
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var length := start.distance_to(end)
		var count := piece_count(length, piece_length, post_width)
		var direction := (end - start) / maxf(length, 0.001)
		var yaw := atan2(-direction.y, direction.x)
		var pitch := length / count
		# Each piece spans pitch + post_width, so its end posts coincide with its neighbors'.
		var stretch := (pitch + post_width) / model_length
		for i in count:
			var center := start + direction * pitch * (i + 0.5)
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3(stretch, PIECE_SCALE, PIECE_SCALE))
			transforms.append(Transform3D(basis, Vector3(center.x, 0.0, center.y)) * _piece_local)
		if body != null:
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(length, COLLISION_HEIGHT, COLLISION_THICKNESS)
			shape.shape = box
			var middle := (start + end) * 0.5
			shape.position = Vector3(middle.x, COLLISION_HEIGHT * 0.5, middle.y)
			shape.rotation.y = yaw
			body.add_child(shape)
	var instances := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _piece_mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	instances.multimesh = multimesh
	_add_generated(instances)


## Takes the mesh of the fence glb and centers it on X/Z so pieces tile around their origin.
func _load_piece() -> void:
	if _piece_mesh != null:
		return
	var root := PIECE_SCENE.instantiate() as Node3D
	var mesh_instance := root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_piece_mesh = mesh_instance.mesh
	var center := _piece_mesh.get_aabb().get_center()
	_piece_local = Transform3D(Basis.IDENTITY, Vector3(-center.x, 0.0, -center.z))
	root.free()


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
