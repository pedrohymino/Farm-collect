class_name CustomerSpawner
extends Marker3D
## Sends customers to counters with queue space, one every customer.spawn_interval per open counter.

## The first customer shows up quickly instead of waiting a full interval.
const FIRST_SPAWN_RATIO: float = 0.8

@export var customer_scene: PackedScene
## Customers walk through these nodes' positions, in order, after leaving the counter.
@export var exit_paths: Array[NodePath] = []
## Character models customers can wear; one is picked at random per customer.
@export var variants: Array[PackedScene] = []

var _cycle: ProductionCycle
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"customer_spawner")
	_rng.randomize()
	_cycle = ProductionCycle.new(FIRST_SPAWN_RATIO, Stats.get_value(&"customer.spawn_interval"))


func _process(delta: float) -> void:
	var interval := Stats.get_value(&"customer.spawn_interval")
	# customer.spawn_interval is per open counter: every counter brings its own customers.
	var streams := maxi(_open_counters(false).size(), 1)
	if _cycle.advance(delta * streams, interval) > 0 and not _try_spawn():
		_cycle.hold(interval)


## Spawns a customer right away (dev mode). Returns false if every queue is full.
func spawn_now() -> bool:
	return _try_spawn()


func _try_spawn() -> bool:
	var open := _open_counters(true)
	if open.is_empty():
		return false

	var counter := open[_rng.randi() % open.size()]
	var buy_min := Stats.get_int(&"customer.buy_min")
	var buy_max := maxi(Stats.get_int(&"customer.buy_max"), buy_min)
	var order := CustomerOrder.new(
		counter.item_id, _rng.randi_range(buy_min, buy_max), Stats.get_value(&"customer.patience")
	)
	var customer := customer_scene.instantiate() as Customer
	get_parent().add_child(customer)
	customer.global_position = global_position
	var exit_path: Array[Vector3] = []
	for path in exit_paths:
		exit_path.append((get_node(path) as Node3D).global_position)
	customer.setup(
		order,
		variants[_rng.randi() % variants.size()] if not variants.is_empty() else null,
		exit_path
	)
	counter.enqueue(customer)
	return true


## Open counters of this location; with `needs_queue_space`, only those that can take a customer.
func _open_counters(needs_queue_space: bool) -> Array[Counter]:
	var open: Array[Counter] = []
	for node in get_tree().get_nodes_in_group(&"counter"):
		var counter := node as Counter
		if counter == null or not get_parent().is_ancestor_of(counter) or not counter.is_open():
			continue
		if not needs_queue_space or counter.has_queue_space():
			open.append(counter)
	return open
