class_name ZoneMarker
extends MeshInstance3D
## Flat colored square on the ground showing an interaction zone; pulses while in use.

const PULSE_SPEED: float = 8.0
const PULSE_AMOUNT: float = 0.06
const ACTIVE_SCALE: float = 1.08
const SHARPNESS: float = 12.0

var _active: bool = false
var _time: float = 0.0


func set_active(active: bool) -> void:
	_active = active


func _process(delta: float) -> void:
	_time += delta
	var target := 1.0
	if _active:
		target = ACTIVE_SCALE + sin(_time * PULSE_SPEED) * PULSE_AMOUNT
	var current := lerpf(scale.x, target, 1.0 - exp(-SHARPNESS * delta))
	scale = Vector3(current, 1.0, current)
