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
@warning_ignore_restore("unused_signal")
