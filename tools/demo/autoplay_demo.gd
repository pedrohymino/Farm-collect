extends Node
## Dev tool: plays the core loop by itself (fresh game, no save) so it can be recorded:
##   godot --write-movie out.png --fixed-fps 30 --quit-after 900 res://tools/demo/autoplay_demo.tscn
## Drives the player through the real input actions, like a person would.
## User args (after `--`): --dev-panel (panel open), --all-unlocked (every unlock done),
## --overview (camera pulled back to show the whole farm), --show-upgrades (upgrade menu open),
## --show-tree (passive tree open with a few skills bought).

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")
const ARRIVE_DISTANCE: float = 0.3
const WAIT_AT_CASHIER_SEC: float = 4.0
const WAIT_AT_PICKUP_SEC: float = 2.0
const OVERVIEW_DISTANCE: float = 42.0
const SHOWCASE_MONEY: float = 500.0
const SHOWCASE_STARS: float = 6.0

var _player: Player
var _route: Array[Dictionary] = []
var _step: int = 0
var _wait: float = 0.0


func _ready() -> void:
	GameState.new_game()
	var args := OS.get_cmdline_user_args()
	if args.has("--all-unlocked"):
		for unlock_id in Unlocks.rules.ids():
			GameState.data.unlock(unlock_id)
		GameState.data.tutorial_step = GuideArrow.STEPS.size()
	if args.has("--dev-panel"):
		DevMode.activate()
		DevMode.toggle()
	var farm := FARM_SCENE.instantiate() as Location
	add_child(farm)
	_player = farm.get_node("Player")
	if args.has("--show-upgrades"):
		Economy.earn(Wallet.MONEY, SHOWCASE_MONEY)
		Progression.set_upgrade_level(&"backpack", 3)
		EventBus.upgrade_board_entered.emit.call_deferred()
	if args.has("--show-tree"):
		Economy.earn(Wallet.STARS, SHOWCASE_STARS)
		for node_id: StringName in [&"farmer_1", &"farmer_2", &"production_1"]:
			Progression.buy_passive(node_id)
		EventBus.passive_tree_requested.emit.call_deferred()
	if args.has("--overview"):
		(farm.get_node("Camera") as FollowCamera).distance = OVERVIEW_DISTANCE
	var coop := farm.get_node("Coop")
	var counter := farm.get_node("EggCounter")
	_route = [
		{"node": coop.get_node("PickupZone"), "wait": WAIT_AT_PICKUP_SEC},
		{"node": counter.get_node("DropZone"), "wait": 1.0},
		{"node": counter.get_node("CashierSpot"), "wait": WAIT_AT_CASHIER_SEC},
		{"node": counter.get_node("MoneyPile"), "wait": 0.5},
	]


func _physics_process(delta: float) -> void:
	var target: Node3D = _route[_step]["node"]
	var to_target := target.global_position - _player.global_position
	to_target.y = 0.0
	if to_target.length() > ARRIVE_DISTANCE:
		_steer(to_target.normalized())
		return
	_steer(Vector3.ZERO)
	_wait += delta
	if _wait >= float(_route[_step]["wait"]):
		_wait = 0.0
		_step = (_step + 1) % _route.size()


## Inverse of IsoInput.to_world: world direction -> input actions.
func _steer(direction: Vector3) -> void:
	var yaw := get_viewport().get_camera_3d().global_rotation.y
	var local := direction.rotated(Vector3.UP, -yaw)
	_press(&"move_right", &"move_left", local.x)
	_press(&"move_down", &"move_up", local.z)


func _press(positive: StringName, negative: StringName, value: float) -> void:
	Input.action_release(positive)
	Input.action_release(negative)
	if value > 0.01:
		Input.action_press(positive, value)
	elif value < -0.01:
		Input.action_press(negative, -value)
