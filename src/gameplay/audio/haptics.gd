class_name Haptics
extends Node
## Phone vibration for key moments (docs/02-game-design.md, section 9). Does nothing on PC.
## Listens to EventBus like AudioDirector; rapid collects are throttled.

const COLLECT_MS: int = 8
const SALE_MS: int = 18
const UNLOCK_MS: int = 60
const MIN_INTERVAL_SEC: float = 0.06
const AMPLITUDE_LIGHT: float = 0.3
const AMPLITUDE_STRONG: float = 0.8

var enabled: bool = true
var _last_pulse_sec: float = -INF


func _ready() -> void:
	enabled = OS.has_feature("mobile")
	EventBus.item_collected.connect(
		func(_item_id: StringName) -> void: pulse(COLLECT_MS, AMPLITUDE_LIGHT)
	)
	EventBus.item_sold.connect(
		func(_item_id: StringName, _count: int, _value: float) -> void:
			pulse(SALE_MS, AMPLITUDE_LIGHT)
	)
	EventBus.unlock_completed.connect(
		func(_unlock_id: StringName) -> void: pulse(UNLOCK_MS, AMPLITUDE_STRONG, true)
	)
	EventBus.level_up.connect(func(_level: int) -> void: pulse(UNLOCK_MS, AMPLITUDE_STRONG, true))


## Returns true if the device was asked to vibrate (enabled and not throttled).
func pulse(duration_ms: int, amplitude: float, force: bool = false) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if not enabled or not Settings.data.vibration:
		return false
	if not force and now - _last_pulse_sec < MIN_INTERVAL_SEC:
		return false
	_last_pulse_sec = now
	Input.vibrate_handheld(duration_ms, amplitude)
	return true
