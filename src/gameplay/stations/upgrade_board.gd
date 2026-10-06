class_name UpgradeBoard
extends Area3D
## Standing here opens the upgrade menu (announced through EventBus, so the UI stays decoupled).

var _player_inside: bool = false

@onready var _marker: ZoneMarker = $Marker


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player") and not _player_inside:
		_player_inside = true
		_marker.set_active(true)
		EventBus.upgrade_board_entered.emit()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(&"player") and _player_inside:
		_player_inside = false
		_marker.set_active(false)
		EventBus.upgrade_board_exited.emit()
