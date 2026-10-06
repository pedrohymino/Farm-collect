extends Node
## Global signal hub (docs/04-arquitetura.md, section 7).
## Gameplay emits; audio, juice, achievements and analytics listen.

@warning_ignore_start("unused_signal")
signal currency_changed(currency: StringName, balance: float)
signal currency_earned(currency: StringName, amount: float)
signal currency_spent(currency: StringName, amount: float)
signal game_loaded
signal game_saved

signal item_produced(item_id: StringName)
signal item_collected(item_id: StringName)
signal item_delivered(item_id: StringName)
signal item_sold(item_id: StringName, count: int, value: float)
signal money_collected(amount: float)
signal customer_left(happy: bool)

signal unlock_completed(unlock_id: StringName)
signal tutorial_step_changed(step: int)

signal xp_changed(xp: float, level: int)
signal level_up(level: int)
signal upgrade_purchased(upgrade_id: StringName, level: int)
signal passive_purchased(node_id: StringName)

signal upgrade_board_entered
signal upgrade_board_exited
signal passive_tree_requested

## A sale nobody had to be present for (worker cashier): feeds offline earnings.
signal automated_income(amount: float)
signal truck_order_completed(reward: float)
signal offline_earnings_ready(amount: float, away_seconds: float)
## Emitted right before the save payload is built, so systems can write their state.
signal before_save
@warning_ignore_restore("unused_signal")
