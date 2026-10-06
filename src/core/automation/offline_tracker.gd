extends Node
## Offline earnings (autoload "Offline"): measures automated income while playing, stores the
## rate and timestamp on save, and on load offers the money earned while the game was closed.

var meter: IncomeMeter
## Earnings waiting for the player to collect (popup).
var pending: float = 0.0


func _ready() -> void:
	meter = IncomeMeter.new(_now())
	EventBus.automated_income.connect(func(amount: float) -> void: meter.record(amount, _now()))
	EventBus.before_save.connect(_write_to_save)
	EventBus.game_loaded.connect(_on_game_loaded)


## Computes what `away_seconds` of absence is worth and announces it. Returns the amount.
func compute_pending(away_seconds: float) -> float:
	pending = OfflineRules.earnings(
		GameState.data.income_rate,
		away_seconds,
		Stats.get_value(&"offline.max_hours"),
		Stats.get_value(&"offline.efficiency")
	)
	if pending > 0.0:
		EventBus.offline_earnings_ready.emit(pending, away_seconds)
	return pending


func collect() -> float:
	var amount := pending
	pending = 0.0
	if amount > 0.0:
		Economy.earn(Wallet.MONEY, amount)
	return amount


func _write_to_save() -> void:
	GameState.data.income_rate = meter.rate(_now())
	GameState.data.last_seen_unix = Time.get_unix_time_from_system()


func _on_game_loaded() -> void:
	meter = IncomeMeter.new(_now())
	var away := OfflineRules.away_seconds(
		GameState.data.last_seen_unix, Time.get_unix_time_from_system()
	)
	compute_pending(away)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
