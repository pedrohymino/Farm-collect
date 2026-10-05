class_name ItemDef
extends Resource
## Identity and visuals of an item.
## Numbers (price, production time) live in data/balance/items.json.

@export var id: StringName
@export var name_key: String
## Wrapper scene (assets/models/items/<id>.tscn); swapping art = swapping what it instances.
@export var visual_scene: PackedScene
## Height one item takes in a stack, in meters.
@export var stack_height: float = 0.25
