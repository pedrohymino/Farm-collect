class_name FollowCamera
extends Camera3D
## Isometric-style perspective camera that smoothly follows a target.
## Keeps the narrow screen dimension constant, so portrait shows more of the farm vertically.

@export var target: Node3D
@export var yaw_degrees: float = 45.0
@export var pitch_degrees: float = 50.0
@export var distance: float = 15.0
@export var follow_sharpness: float = 6.0


func _ready() -> void:
	rotation = Vector3(deg_to_rad(-pitch_degrees), deg_to_rad(yaw_degrees), 0.0)
	get_viewport().size_changed.connect(_update_aspect)
	_update_aspect()
	if target != null:
		global_position = _desired_position()


func _process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(
		_desired_position(), 1.0 - exp(-follow_sharpness * delta)
	)


func _desired_position() -> Vector3:
	return target.global_position + global_basis.z * distance


func _update_aspect() -> void:
	var size := get_viewport().get_visible_rect().size
	keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
