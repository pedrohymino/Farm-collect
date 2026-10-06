class_name IncomeMeter
extends RefCounted
## Average automated income per second over a sliding window (feeds offline earnings).

const WINDOW_SEC: float = 300.0
## Never divide by less than this, so one early sale doesn't look like a huge rate.
const MIN_SPAN_SEC: float = 60.0

var _samples: Array[Vector2] = []  # (time, amount)
var _started_at: float


func _init(start_time: float) -> void:
	_started_at = start_time


func record(amount: float, time: float) -> void:
	if amount > 0.0:
		_samples.append(Vector2(time, amount))
	_trim(time)


func rate(now: float) -> float:
	_trim(now)
	var total := 0.0
	for sample in _samples:
		total += sample.y
	var span := clampf(now - _started_at, MIN_SPAN_SEC, WINDOW_SEC)
	return total / span


func _trim(now: float) -> void:
	while not _samples.is_empty() and now - _samples[0].x > WINDOW_SEC:
		_samples.pop_front()
