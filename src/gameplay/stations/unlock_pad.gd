class_name UnlockPad
extends Area3D
## Square on the ground that buys an unlock: standing on it drains money from the wallet
## into the unlock (always ~FILL_SECONDS for the full price). Visible only while available.

const FILL_SECONDS: float = 1.5
## Lowest drain speed, so very cheap pads still fill smoothly.
const MIN_DRAIN_PER_SEC: float = 5.0
const BILL_INTERVAL_SEC: float = 0.08
const PLAYER_BILL_HEIGHT: float = 1.0
const CAMERA_FOCUS_SEC: float = 1.6
const CONFETTI_HEIGHT: float = 0.3
## A body reported this soon after the pad appears was already standing on it.
const ARRIVAL_GRACE_FRAMES: int = 3

@export var unlock_id: StringName
@export var name_key: String
## Optional: the camera glances here when the unlock completes (new areas).
@export var camera_focus: Node3D

var _player: Node3D
var _bill_timer: float = 0.0
## Set when the pad appears under the player: they must step off and on again to pay,
## so finishing one pad never silently starts paying the next one at the same spot.
var _needs_reentry: bool = false
var _shown_at_frame: int = 0

@onready var _fill: MeshInstance3D = $Fill
@onready var _title: Label3D = $Title
@onready var _price: Label3D = $Price


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.unlock_completed.connect(_on_unlock_completed)
	Stats.stat_changed.connect(_on_stat_changed)
	_title.text = tr(name_key)
	refresh()


## Shows the pad only while its unlock can be bought.
func refresh() -> void:
	var available := Unlocks.is_available(unlock_id)
	if available and not visible:
		_shown_at_frame = Engine.get_physics_frames()
	visible = available
	set_deferred(&"monitoring", available)
	if not available:
		_player = null
	_update_progress()


func _physics_process(delta: float) -> void:
	if not visible or _player == null or _needs_reentry:
		return
	var rate := maxf(Unlocks.cost(unlock_id) / FILL_SECONDS, MIN_DRAIN_PER_SEC)
	var amount := minf(
		minf(rate * delta, Unlocks.remaining(unlock_id)), Economy.balance(Wallet.MONEY)
	)
	if amount <= 0.0 or not Economy.spend(Wallet.MONEY, amount):
		return
	_emit_bills(delta)
	Unlocks.pay(unlock_id, amount)
	_update_progress()


func _update_progress() -> void:
	var ratio := Unlocks.progress_ratio(unlock_id)
	_fill.visible = ratio > 0.0
	_fill.scale = Vector3(ratio, 1.0, ratio)
	_price.text = Economy.format(ceilf(Unlocks.remaining(unlock_id)))


func _emit_bills(delta: float) -> void:
	_bill_timer -= delta
	if _bill_timer > 0.0:
		return
	_bill_timer = BILL_INTERVAL_SEC
	var target := global_position
	BillFx.fly(
		self,
		_player.global_position + Vector3.UP * PLAYER_BILL_HEIGHT,
		func() -> Vector3: return target
	)


func _on_unlock_completed(completed_id: StringName) -> void:
	if completed_id == unlock_id:
		Confetti.burst(get_parent(), global_position + Vector3.UP * CONFETTI_HEIGHT)
		var camera := get_viewport().get_camera_3d() as FollowCamera
		if camera != null and camera_focus != null:
			camera.focus_on(camera_focus.global_position, CAMERA_FOCUS_SEC)
	refresh()


func _on_stat_changed(stat_id: StringName, _value: float) -> void:
	if stat_id == &"unlock.cost" and visible:
		_update_progress()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_player = body
		_needs_reentry = Engine.get_physics_frames() - _shown_at_frame <= ARRIVAL_GRACE_FRAMES


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		_needs_reentry = false
