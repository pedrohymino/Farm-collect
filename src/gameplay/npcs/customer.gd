class_name Customer
extends Node3D
## Walks to its queue slot, waits, then walks away along its exit path.
## Rules (patience, serving) live in CounterService; this node only moves and shows mood.

const ARRIVE_DISTANCE: float = 0.05
const TURN_SHARPNESS: float = 10.0
const MOOD_HAPPY: Color = Color("5ee06b")
const MOOD_SAD: Color = Color("e5483b")
const MOOD_POP_TIME: float = 0.25

var order: CustomerOrder

var _target: Vector3
var _is_front: bool = false
var _leaving: bool = false
var _exit_path: Array[Vector3] = []

@onready var _body: Node3D = $Body
@onready var _model: CharacterModel = $Body/Model
@onready var _mood: MeshInstance3D = $Mood


## `variant` is the character model to wear (a Kenney .glb scene); null keeps the default one.
func setup(p_order: CustomerOrder, variant: PackedScene, exit_path: Array[Vector3]) -> void:
	order = p_order
	_exit_path = exit_path.duplicate()
	_target = global_position
	if variant != null:
		_model.set_model(variant)


func set_queue_target(target: Vector3, is_front: bool) -> void:
	if _leaving:
		return
	_target = target
	_is_front = is_front


func leave(happy: bool) -> void:
	_leaving = true
	order.is_ready = false
	_show_mood(happy)
	_advance_exit()


func _process(delta: float) -> void:
	var to_target := _target - global_position
	to_target.y = 0.0
	var step := Stats.get_value(&"customer.move_speed") * delta
	var arrived := to_target.length() <= maxf(step, ARRIVE_DISTANCE)
	if arrived:
		global_position = Vector3(_target.x, global_position.y, _target.z)
	else:
		global_position += to_target.normalized() * step
		_face(to_target, delta)
	_model.set_motion(0.0 if arrived else Stats.get_value(&"customer.move_speed"), false)

	if not _leaving:
		order.is_ready = _is_front and arrived
	elif arrived:
		_advance_exit()


func _advance_exit() -> void:
	if _exit_path.is_empty():
		queue_free()
		return
	_target = _exit_path.pop_front()


func _face(direction: Vector3, delta: float) -> void:
	var yaw := atan2(direction.x, direction.z)
	_body.rotation.y = lerp_angle(_body.rotation.y, yaw, 1.0 - exp(-TURN_SHARPNESS * delta))


func _show_mood(happy: bool) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = MOOD_HAPPY if happy else MOOD_SAD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mood.set_surface_override_material(0, material)
	_mood.visible = true
	_mood.scale = Vector3.ZERO
	create_tween().tween_property(_mood, "scale", Vector3.ONE, MOOD_POP_TIME).set_trans(
		Tween.TRANS_BACK
	)
