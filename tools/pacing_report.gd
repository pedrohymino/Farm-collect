extends SceneTree
## Prints the simulated unlock timeline next to the pacing targets of docs/03 (section 7).
## Run: godot --headless -s tools/pacing_report.gd [-- --balance=<dir>]

const MILESTONES: Array[Dictionary] = [
	{"label": "First sale", "id": &"", "target": 20.0},
	{"label": "First pad (chicken_3)", "id": &"chicken_3", "target": 45.0},
	{"label": "Upgrade board", "id": &"upgrade_board", "target": 120.0},
	{"label": "Open the Field", "id": &"area_field", "target": 240.0},
	{"label": "First cow (barn)", "id": &"barn", "target": 600.0},
	{"label": "First helper (cashier_egg)", "id": &"cashier_egg", "target": 900.0},
	{"label": "Trucks (truck_bay)", "id": &"truck_bay", "target": 1800.0},
]
const COMPLETE_MIN: float = 7200.0
const COMPLETE_MAX: float = 10800.0
## Longest acceptable wait between two pad purchases, by minute of play. Late pads are big
## goals; the infinite upgrades and the passive tree fill the time in between.
const GAP_LIMITS: Array[Dictionary] = [
	{"until": 600.0, "max_gap": 150.0},
	{"until": 1800.0, "max_gap": 360.0},
	{"until": 7200.0, "max_gap": 1800.0},
]
## Longest acceptable wait between any two purchases (pads, upgrades or skills).
const MAX_PURCHASE_GAP: float = 300.0


func _init() -> void:
	var balance := BalanceData.load_from_dir(_balance_dir())
	for error in balance.errors:
		print("BALANCE ERROR: ", error)
	var sim := PacingSim.new(balance)
	sim.run()
	print("\n== Pacing report (simulated, see docs/03 section 7) ==")
	for milestone: Dictionary in MILESTONES:
		var time := (
			sim.seconds_to_first_sale()
			if milestone.id == &""
			else sim.time_of("unlock", milestone.id)
		)
		var verdict := "ok" if time >= 0.0 and time <= milestone.target * 1.5 else "CHECK"
		print(
			(
				"%-28s %9s   target %-9s %s"
				% [milestone.label, _clock(time), _clock(milestone.target), verdict]
			)
		)
	var done := sim.finished_at()
	var complete_verdict := (
		"ok" if done >= COMPLETE_MIN * 0.75 and done <= COMPLETE_MAX else "CHECK"
	)
	print(
		(
			"%-28s %9s   target %s-%s %s"
			% [
				"Farm complete",
				_clock(done),
				_clock(COMPLETE_MIN),
				_clock(COMPLETE_MAX),
				complete_verdict
			]
		)
	)
	print("Farm level at the end: %d" % sim.data.farm_level)
	print("\n== Pad timeline ==")
	for entry in sim.timeline:
		if entry.kind == "unlock":
			print("%9s  %-16s income %s/s" % [_clock(entry.t), entry.id, "%.2f" % entry.rate])
	_print_gaps(sim)
	_print_purchase_gaps(sim)
	_print_bottlenecks(balance)
	quit()


## `-- --balance=<dir>` simulates another balance folder (for experiments).
func _balance_dir() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--balance="):
			return argument.trim_prefix("--balance=")
	return "res://data/balance"


## Which limit binds (production, hauling or customers) at a few moments of the game.
func _print_bottlenecks(balance: BalanceData) -> void:
	print("\n== Items/s: produced / hauled / asked by customers ==")
	for minutes in [15, 30, 60, 120]:
		var sim := PacingSim.new(balance)
		sim.run(minutes * 60.0)
		var parts: PackedStringArray = []
		var flows := sim.snapshot()
		for item_id: StringName in flows:
			var flow: Dictionary = flows[item_id]
			parts.append("%s %.2f/%.2f/%.2f" % [item_id, flow.supply, flow.hauled, flow.demand])
		print("%4d min  income %.1f/s  %s" % [minutes, sim.income_rate(), "   ".join(parts)])


func _print_gaps(sim: PacingSim) -> void:
	print("\n== Waits between pads longer than the limit ==")
	var previous := 0.0
	var problems := 0
	for entry in sim.timeline:
		if entry.kind != "unlock":
			continue
		var gap: float = entry.t - previous
		var limit := _gap_limit(entry.t)
		if gap > limit:
			problems += 1
			print(
				(
					"%9s  waited %s before %s (limit %s)"
					% [_clock(entry.t), _clock(gap), entry.id, _clock(limit)]
				)
			)
		previous = entry.t
	if problems == 0:
		print("none")


## The player always has something to buy: long silences between any two purchases are flagged.
func _print_purchase_gaps(sim: PacingSim) -> void:
	print("\n== Waits between any two purchases over %s ==" % _clock(MAX_PURCHASE_GAP))
	var previous := 0.0
	var found := 0
	for entry in sim.timeline:
		var gap: float = entry.t - previous
		if gap > MAX_PURCHASE_GAP:
			found += 1
			print(
				"%9s  waited %s before %s %s" % [_clock(entry.t), _clock(gap), entry.kind, entry.id]
			)
		previous = entry.t
	if found == 0:
		print("none")


func _gap_limit(time: float) -> float:
	for rule: Dictionary in GAP_LIMITS:
		if time <= rule.until:
			return rule.max_gap
	return INF


func _clock(seconds: float) -> String:
	if seconds < 0.0:
		return "never"
	var total := int(seconds)
	if total >= 3600:
		return "%dh%02dm" % [total / 3600, (total % 3600) / 60]
	return "%dm%02ds" % [total / 60, total % 60]
