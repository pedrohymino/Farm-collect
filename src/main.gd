extends Node3D
## Entry point: loads the save (which also starts autosave).


func _ready() -> void:
	SaveManager.load_game()
