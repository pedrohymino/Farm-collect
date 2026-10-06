class_name AnimalWander
extends Node3D
## Idle wandering inside a pen with the model's own animations (idle / walk / sometimes eat),
## plus a squash when the animal produces something.

const MOVE_SPEED: float = 0.6
const PAUSE_MIN: float = 0.8
const PAUSE_MAX: float = 2.5
const TURN_SHARPNESS: float = 8.0
const ARRIVE_DISTANCE: float = 0.05
const SQUASH_SCALE: Vector3 = Vector3(1.25, 0.7, 1.25)
const SQUASH_TIME: float = 0.12
const EAT_CHANCE: float = 0.35
const CROSSFADE_SEC: float = 0.2
const LOOPED_ANIMATIONS: Array[StringName] = [&"idle", &"walk", &"eat"]
const PLAYER_NODE_NAME: String = "AnimationPlayer"

var _bounds: Vector2 = Vector2.ONE
var _target: Vector3
var _pause: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _animation_player: AnimationPlayer
var _current: StringName = &""


func _ready() -> void:
	_rng.randomize()
	_target = position
	_pause = _rng.randf_range(0.0, PAUSE_MAX)
	_animation_player = find_child(PLAYER_NODE_NAME, true, false) as AnimationPlayer
	if _animation_player != null:
		for animation_name in LOOPED_ANIMATIONS:
			if _animation_player.has_animation(animation_name):
				_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_play(&"idle")


func set_bounds(half_extents: Vector2) -> void:
	_bounds = half_extents


func current_animation() -> StringName:
	return _current


func play_produce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", SQUASH_SCALE, SQUASH_TIME)
	tween.tween_property(self, "scale", Vector3.ONE, SQUASH_TIME * 2.0).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var to_target := _target - position
	if to_target.length() <= ARRIVE_DISTANCE:
		_pause = _rng.randf_range(PAUSE_MIN, PAUSE_MAX)
		_target = Vector3(
			_rng.randf_range(-_bounds.x, _bounds.x), 0.0, _rng.randf_range(-_bounds.y, _bounds.y)
		)
		_play(&"eat" if _rng.randf() < EAT_CHANCE else &"idle")
		return
	_play(&"walk")
	position += to_target.normalized() * minf(MOVE_SPEED * delta, to_target.length())
	var yaw := atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-TURN_SHARPNESS * delta))


func _play(animation_name: StringName) -> void:
	if _animation_player == null or animation_name == _current:
		return
	if not _animation_player.has_animation(animation_name):
		return
	_animation_player.play(animation_name, CROSSFADE_SEC)
	_current = animation_name
