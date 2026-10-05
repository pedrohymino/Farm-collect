class_name ProductionCycle
extends RefCounted
## Timer for one producing unit (an animal, a crop bed, a machine).
## The interval is passed on every advance so stat changes apply instantly.

var progress: float = 0.0


## start_ratio staggers units so they don't all produce on the same frame.
func _init(start_ratio: float = 0.0, interval: float = 1.0) -> void:
	progress = clampf(start_ratio, 0.0, 1.0) * interval


## Returns how many cycles completed during `delta`.
func advance(delta: float, interval: float) -> int:
	if interval <= 0.0:
		return 0
	progress += delta
	var completed := floori(progress / interval)
	progress -= completed * interval
	return completed


## Keeps the unit "ready": used when the output is full, so it produces as soon as there is room.
func hold(interval: float) -> void:
	progress = interval


func ratio(interval: float) -> float:
	if interval <= 0.0:
		return 0.0
	return clampf(progress / interval, 0.0, 1.0)
