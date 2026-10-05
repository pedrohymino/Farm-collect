extends GutTest


func test_no_cycle_before_interval() -> void:
	var cycle := ProductionCycle.new()
	assert_eq(cycle.advance(0.5, 1.0), 0)


func test_completes_cycle_and_keeps_remainder() -> void:
	var cycle := ProductionCycle.new()
	assert_eq(cycle.advance(1.25, 1.0), 1)
	assert_almost_eq(cycle.progress, 0.25, 0.0001)
	assert_eq(cycle.advance(0.75, 1.0), 1)


func test_large_delta_completes_multiple_cycles() -> void:
	var cycle := ProductionCycle.new()
	assert_eq(cycle.advance(3.5, 1.0), 3)


func test_start_offset_staggers_cycles() -> void:
	var cycle := ProductionCycle.new(0.5)
	assert_eq(cycle.advance(0.5, 1.0), 1)


func test_hold_makes_next_advance_complete_immediately() -> void:
	var cycle := ProductionCycle.new()
	cycle.hold(4.0)
	assert_eq(cycle.advance(0.01, 4.0), 1)


func test_ratio_reports_progress() -> void:
	var cycle := ProductionCycle.new()
	cycle.advance(1.0, 4.0)
	assert_almost_eq(cycle.ratio(4.0), 0.25, 0.0001)


func test_non_positive_interval_never_completes() -> void:
	var cycle := ProductionCycle.new()
	assert_eq(cycle.advance(10.0, 0.0), 0)
