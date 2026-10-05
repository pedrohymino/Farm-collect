extends Node3D
## Entry point: loads the save (which also starts autosave), turns on dev mode in debug
## builds, then builds the farm, so every station reads the loaded state in its _ready.

const FARM_SCENE: PackedScene = preload("res://src/gameplay/locations/farm/farm.tscn")


func _ready() -> void:
	SaveManager.load_game()
	DevMode.activate()
	add_child(FARM_SCENE.instantiate())
