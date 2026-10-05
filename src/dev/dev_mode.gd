extends Node
## Live tuning panel (docs/05-dev-mode.md). Panel implemented in M3.
## Only available in debug builds or exports with the "dev" feature tag.

var is_enabled: bool = false


func _ready() -> void:
	is_enabled = OS.is_debug_build() or OS.has_feature("dev")
