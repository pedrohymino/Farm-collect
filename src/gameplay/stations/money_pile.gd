class_name MoneyPile
extends Area3D
## Money waiting next to a counter. The player picks up all of it by standing on it.

## How much money one visible bill stands for (visual density only).
const BILL_VALUE: float = 5.0
const MAX_VISIBLE_BILLS: int = 40
const GRID_COLUMNS: int = 2
const GRID_ROWS: int = 2
const BILL_GAP: float = 0.04
const MAX_FLYING_BILLS: int = 12
const FLY_TARGET_HEIGHT: float = 1.0

var stash: MoneyStash = MoneyStash.new()

var _bills: Array[MeshInstance3D] = []
var _collector: Node3D = null


func _ready() -> void:
	stash.changed.connect(_refresh_bills)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if _collector != null and stash.value > 0.0:
		_collect()


func _collect() -> void:
	var starts: Array[Vector3] = []
	for bill in _bills.slice(maxi(_bills.size() - MAX_FLYING_BILLS, 0)):
		starts.append(bill.global_position)
	var amount := stash.take_all()
	Economy.earn(Wallet.MONEY, amount)
	EventBus.money_collected.emit(amount)
	for start in starts:
		_fly_bill(start)


func _fly_bill(start: Vector3) -> void:
	var target := _collector
	var fallback := start
	BillFx.fly(
		self,
		start,
		func() -> Vector3:
			if is_instance_valid(target):
				return target.global_position + Vector3.UP * FLY_TARGET_HEIGHT
			return fallback
	)


func _refresh_bills(value: float) -> void:
	var wanted := mini(ceili(value / BILL_VALUE), MAX_VISIBLE_BILLS)
	while _bills.size() > wanted:
		_bills.pop_back().queue_free()
	while _bills.size() < wanted:
		var bill := MeshInstance3D.new()
		bill.mesh = BillFx.mesh()
		add_child(bill)
		bill.position = _bill_position(_bills.size())
		_bills.append(bill)


func _bill_position(index: int) -> Vector3:
	var per_layer := GRID_COLUMNS * GRID_ROWS
	var cell := index % per_layer
	var layer := floori(index / float(per_layer))
	var x := (cell % GRID_COLUMNS - (GRID_COLUMNS - 1) * 0.5) * (BillFx.BILL_SIZE.x + BILL_GAP)
	var z := (
		(floori(cell / float(GRID_COLUMNS)) - (GRID_ROWS - 1) * 0.5)
		* (BillFx.BILL_SIZE.z + BILL_GAP)
	)
	return Vector3(x, BillFx.BILL_SIZE.y * (layer + 0.5), z)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_collector = body


func _on_body_exited(body: Node3D) -> void:
	if body == _collector:
		_collector = null
