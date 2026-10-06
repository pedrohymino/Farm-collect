class_name Player
extends CharacterBody3D
## The farmer: moves relative to the camera and carries a mixed stack of items.
## Collecting, delivering and selling happen through zones (TransferZone, cashier spots).

const ACCELERATION: float = 40.0
const TURN_SHARPNESS: float = 14.0
const FACE_MIN_SPEED: float = 0.1
const MAX_LABEL_TIME: float = 0.8
const DUST_MIN_SPEED: float = 2.0

@export var persist_id: StringName = &"player"

var _max_label_timer: float = 0.0
var _dust: DustTrail

@onready var carry_visual: StackVisual = $Body/CarryVisual
@onready var _body: Node3D = $Body
@onready var _model: CharacterModel = $Body/Model
@onready var _max_label: Label3D = $MaxLabel


func _ready() -> void:
	add_to_group(&"player")
	add_to_group(&"carrier")
	add_to_group(&"cashier")
	add_to_group(&"persistent_station")
	carry_visual.bind(
		ItemContainer.new(ItemContainer.stat_capacity(Stats, &"player.carry_capacity"))
	)
	_max_label.visible = false
	_dust = DustTrail.new()
	add_child(_dust)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var camera := get_viewport().get_camera_3d()
	var yaw := camera.global_rotation.y if camera != null else 0.0
	var target := IsoInput.to_world(input, yaw) * Stats.get_value(&"player.move_speed")
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, ACCELERATION * delta)
	velocity = horizontal
	move_and_slide()

	if horizontal.length() > FACE_MIN_SPEED:
		var facing := atan2(horizontal.x, horizontal.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, facing, 1.0 - exp(-TURN_SHARPNESS * delta))
	_model.set_motion(horizontal.length(), not carry_visual.container.is_empty())
	carry_visual.owner_velocity = velocity
	_dust.emitting = horizontal.length() > DUST_MIN_SPEED
	_update_max_label(delta)


## Called by zones when the stack is full and more could be collected.
func show_full() -> void:
	_max_label_timer = MAX_LABEL_TIME
	_max_label.visible = true


func save_state() -> Dictionary:
	return {
		"carry": carry_visual.container.to_array(),
		"position": [global_position.x, global_position.z],
	}


func load_state(state: Dictionary) -> void:
	var carry: Variant = state.get("carry", [])
	if typeof(carry) == TYPE_ARRAY:
		carry_visual.container.load_array(carry)
	var saved_position: Variant = state.get("position")
	if typeof(saved_position) == TYPE_ARRAY and saved_position.size() == 2:
		global_position = Vector3(float(saved_position[0]), 0.0, float(saved_position[1]))


func _update_max_label(delta: float) -> void:
	if _max_label_timer <= 0.0:
		return
	_max_label_timer -= delta
	if _max_label_timer <= 0.0:
		_max_label.visible = false
	_dust = DustTrail.new()
	add_child(_dust)
