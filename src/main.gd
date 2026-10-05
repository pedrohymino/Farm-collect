extends Node3D
## Entry point: loads the save (which also starts autosave), then builds the farm,
## so every station reads the loaded state in its _ready.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")


func _ready() -> void:
	SaveManager.load_game()
	add_child(FARM_SCENE.instantiate())
