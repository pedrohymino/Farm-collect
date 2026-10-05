extends Node
## Global signal hub (docs/04-arquitetura.md, section 7).
## Gameplay emits; audio, juice, achievements and analytics listen.

@warning_ignore_start("unused_signal")
signal currency_changed(currency: StringName, balance: float)
signal currency_earned(currency: StringName, amount: float)
signal currency_spent(currency: StringName, amount: float)
signal game_loaded
signal game_saved
@warning_ignore_restore("unused_signal")
