extends CanvasLayer
## Top bar with the money counter, which rolls up/down and pulses on gains.

const ROLL_TIME: float = 0.35
const PULSE_SCALE: float = 1.15
const PULSE_TIME: float = 0.15

var _shown_money: float = 0.0
var _roll_tween: Tween
var _pulse_tween: Tween

@onready var _money_label: Label = %MoneyLabel
@onready var _money_panel: Control = %MoneyPanel


func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	_shown_money = Economy.balance(Wallet.MONEY)
	_render_money(_shown_money)


func _on_currency_changed(currency: StringName, balance: float) -> void:
	if currency != Wallet.MONEY:
		return
	if balance > _shown_money:
		_pulse()
	if _roll_tween != null:
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_method(_render_money, _shown_money, balance, ROLL_TIME)


func _render_money(value: float) -> void:
	_shown_money = value
	_money_label.text = Economy.format(value)


func _pulse() -> void:
	_money_panel.pivot_offset = _money_panel.size * 0.5
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_money_panel, "scale", Vector2.ONE * PULSE_SCALE, PULSE_TIME * 0.5)
	_pulse_tween.tween_property(_money_panel, "scale", Vector2.ONE, PULSE_TIME).set_trans(
		Tween.TRANS_BACK
	)
