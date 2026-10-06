class_name PassiveTreeGraph
extends Control
## Draws the links of the passive tree; node buttons are children placed by PassiveTreeScreen.

const LINE_WIDTH: float = 10.0
const OWNED_COLOR: Color = Color("ffd166")
const OPEN_COLOR: Color = Color(1, 1, 1, 0.55)
const LOCKED_COLOR: Color = Color(1, 1, 1, 0.18)

## [{"from": Vector2, "to": Vector2, "state": PassiveRules.NodeState}] in local coordinates.
var links: Array[Dictionary] = []


func set_links(new_links: Array[Dictionary]) -> void:
	links = new_links
	queue_redraw()


func _draw() -> void:
	for link in links:
		var color := LOCKED_COLOR
		match link["state"]:
			PassiveRules.NodeState.OWNED:
				color = OWNED_COLOR
			PassiveRules.NodeState.AVAILABLE:
				color = OPEN_COLOR
		draw_line(link["from"], link["to"], color, LINE_WIDTH, true)
