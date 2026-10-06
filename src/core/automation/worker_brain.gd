class_name WorkerBrain
extends RefCounted
## Decides what a helper does next: walk to the current stop, work there, move on.
## The node reports each frame whether it arrived, whether the job at this stop is done,
## whether it made progress, and whether it is allowed to leave unfinished.

enum State { MOVING, WORKING }

var state: State = State.MOVING
var stop_index: int = 0

var _stop_count: int
## Seconds without progress before giving up on an unfinished stop (INF = never: cashiers).
var _idle_limit: float
var _idle: float = 0.0


func _init(stop_count: int, idle_limit: float) -> void:
	_stop_count = maxi(stop_count, 1)
	_idle_limit = idle_limit


func update(
	delta: float, arrived: bool, work_done: bool, made_progress: bool, can_leave: bool
) -> void:
	if state == State.MOVING:
		if arrived:
			state = State.WORKING
			_idle = 0.0
		return
	_idle = 0.0 if made_progress else _idle + delta
	if work_done or (can_leave and _idle >= _idle_limit):
		stop_index = (stop_index + 1) % _stop_count
		state = State.MOVING
		_idle = 0.0
