extends Node
## Holds the live GameData (currencies, unlocks, upgrades, passives, farm XP, location state).
## Replaced as a whole on load or new game; listeners should rebind on data_replaced.

signal data_replaced

var data: GameData = GameData.new()


func replace(new_data: GameData) -> void:
	data = new_data
	data_replaced.emit()


func new_game() -> void:
	replace(GameData.new())
