class_name CharacterModel
extends Node3D
## A Kenney mini-character with locomotion animation. Holds the imported model as its child,
## builds the "-carry" animation variants once, and plays idle / walk / sprint (or the carry
## versions) according to the speed its owner reports each frame.

const CROSSFADE_SEC: float = 0.15
const LOOPED_ANIMATIONS: Array[StringName] = [&"idle", &"walk", &"sprint"]
const HOLDING_ANIMATION: StringName = &"holding-both"
const PLAYER_NODE_NAME: String = "AnimationPlayer"

@export var model_scene: PackedScene
## Kenney characters are ~0.7 units tall; this scales them to game size (~1.05 m).
@export var model_scale: float = 1.5

var _player: AnimationPlayer
var _model: Node3D
var _current: StringName = &""


func _ready() -> void:
	if model_scene != null and _model == null:
		_build()


## Swaps the character. Safe to call before or after the node enters the tree.
func set_model(scene: PackedScene) -> void:
	model_scene = scene
	if is_inside_tree():
		_build()


func current_animation() -> StringName:
	return _current


func has_animation(animation_name: StringName) -> bool:
	return _player != null and _player.has_animation(animation_name)


## Call every frame with the real ground speed (m/s) and whether a stack is being carried.
func set_motion(speed: float, carrying: bool) -> void:
	if _player == null:
		return
	var wanted := LocomotionRules.animation_for(speed, carrying)
	if wanted != _current and _player.has_animation(wanted):
		_player.play(wanted, CROSSFADE_SEC)
		_current = wanted
	_player.speed_scale = LocomotionRules.playback_speed(speed)


func _build() -> void:
	if _model != null:
		_model.queue_free()
		_model = null
		_player = null
		_current = &""
	_model = model_scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * model_scale
	add_child(_model)
	_player = _model.find_child(PLAYER_NODE_NAME, true, false) as AnimationPlayer
	if _player == null:
		return
	_prepare_animations()
	set_motion(0.0, false)


func _prepare_animations() -> void:
	var library := _player.get_animation_library(&"")
	for animation_name in LOOPED_ANIMATIONS:
		library.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	if not library.has_animation(HOLDING_ANIMATION):
		return
	var holding := library.get_animation(HOLDING_ANIMATION)
	for animation_name in LOOPED_ANIMATIONS:
		var carry_name := StringName(String(animation_name) + LocomotionRules.CARRY_SUFFIX)
		if not library.has_animation(carry_name):
			library.add_animation(
				carry_name, CarryPose.build_variant(library.get_animation(animation_name), holding)
			)
