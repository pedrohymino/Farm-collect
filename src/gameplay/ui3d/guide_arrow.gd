class_name GuideArrow
extends Node3D
## Onboarding without text: an arrow on the ground next to the player and a bouncing marker
## over the next objective, for each first-time action. Progress is saved (tutorial_step).

## Each step is done when this EventBus signal fires once; value = the signal's argument count.
const STEPS: Array[Dictionary] = [
	{"signal": &"item_collected", "args": 1},
	{"signal": &"item_delivered", "args": 1},
	{"signal": &"item_sold", "args": 3},
	{"signal": &"money_collected", "args": 1},
	{"signal": &"unlock_completed", "args": 1},
]
const HIDE_DISTANCE: float = 1.8
const GROUND_OFFSET: float = 1.2
const GROUND_HEIGHT: float = 0.05
const MARKER_HEIGHT: float = 2.4
const BOUNCE_HEIGHT: float = 0.35
const BOUNCE_SPEED: float = 4.0

@export var player: Node3D
## One target per entry in STEPS, in the same order.
@export var step_targets: Array[NodePath] = []

var _time: float = 0.0

@onready var _ground_arrow: Node3D = $GroundArrow
@onready var _marker: Node3D = $Marker


func _ready() -> void:
	add_to_group(&"guide_arrow")
	if current_step() >= STEPS.size():
		queue_free()
		return
	for index in STEPS.size():
		var step: Dictionary = STEPS[index]
		EventBus.connect(step["signal"], _on_step_signal.bind(index).unbind(step["args"]))


func current_step() -> int:
	return GameState.data.tutorial_step


func _process(delta: float) -> void:
	var target := _current_target()
	if target == null or player == null:
		_ground_arrow.visible = false
		_marker.visible = false
		return
	_time += delta
	var to_target := target.global_position - player.global_position
	to_target.y = 0.0
	_ground_arrow.visible = to_target.length() > HIDE_DISTANCE
	if _ground_arrow.visible:
		var direction := to_target.normalized()
		_ground_arrow.global_position = (
			player.global_position + direction * GROUND_OFFSET + Vector3.UP * GROUND_HEIGHT
		)
		_ground_arrow.rotation.y = atan2(direction.x, direction.z)
	_marker.visible = true
	_marker.global_position = (
		target.global_position
		+ Vector3.UP * (MARKER_HEIGHT + absf(sin(_time * BOUNCE_SPEED)) * BOUNCE_HEIGHT)
	)


func _current_target() -> Node3D:
	var step := current_step()
	if step >= step_targets.size():
		return null
	return get_node_or_null(step_targets[step]) as Node3D


func _on_step_signal(index: int) -> void:
	if index != current_step():
		return
	GameState.data.tutorial_step = index + 1
	EventBus.tutorial_step_changed.emit(GameState.data.tutorial_step)
	if GameState.data.tutorial_step >= STEPS.size():
		queue_free()
