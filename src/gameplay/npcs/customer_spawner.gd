class_name CustomerSpawner
extends Marker3D
## Sends customers to counters with queue space, at the rate of customer.spawn_interval.

## The first customer shows up quickly instead of waiting a full interval.
const FIRST_SPAWN_RATIO: float = 0.8

@export var customer_scene: PackedScene
## Customers walk through these nodes' positions, in order, after leaving the counter.
@export var exit_paths: Array[NodePath] = []
@export var shirt_colors: PackedColorArray = PackedColorArray(
	[Color("e5483b"), Color("f7c531"), Color("3fa7f2"), Color("b06be0"), Color("ff8f3f")]
)

var _cycle: ProductionCycle
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_cycle = ProductionCycle.new(FIRST_SPAWN_RATIO, Stats.get_value(&"customer.spawn_interval"))


func _process(delta: float) -> void:
	var interval := Stats.get_value(&"customer.spawn_interval")
	if _cycle.advance(delta, interval) > 0 and not _try_spawn():
		_cycle.hold(interval)


func _try_spawn() -> bool:
	var open: Array[Counter] = []
	for node in get_tree().get_nodes_in_group(&"counter"):
		var counter := node as Counter
		if counter != null and get_parent().is_ancestor_of(counter) and counter.has_queue_space():
			open.append(counter)
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
	customer.setup(order, shirt_colors[_rng.randi() % shirt_colors.size()], exit_path)
	counter.enqueue(customer)
	return true
