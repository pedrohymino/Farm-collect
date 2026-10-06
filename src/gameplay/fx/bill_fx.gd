class_name BillFx
extends RefCounted
## Money bills flying through the air (collecting a pile, paying into an unlock pad).

const BILL_SIZE: Vector3 = Vector3(0.38, 0.07, 0.2)
const BILL_COLOR: Color = Color("3dba4e")
const FLY_TIME: float = 0.3
const ARC_HEIGHT: float = 0.8

static var _mesh: BoxMesh


static func mesh() -> BoxMesh:
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = BILL_SIZE
		var material := StandardMaterial3D.new()
		material.albedo_color = BILL_COLOR
		_mesh.material = material
	return _mesh


## Flies a bill from `start` to wherever `end_provider` (Callable -> Vector3) says, then frees it.
## The bill is a top-level child of `parent`, so it is freed with it.
static func fly(parent: Node, start: Vector3, end_provider: Callable) -> void:
	var bill := MeshInstance3D.new()
	bill.mesh = mesh()
	bill.top_level = true
	parent.add_child(bill)
	bill.global_position = start
	var tween := bill.create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var end: Vector3 = end_provider.call()
			bill.global_position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * ARC_HEIGHT,
		0.0,
		1.0,
		FLY_TIME
	)
	tween.tween_callback(bill.queue_free)
