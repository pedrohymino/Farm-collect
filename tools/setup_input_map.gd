extends SceneTree
## Dev tool: (re)writes the input map into project.godot, so it is reproducible and diffable.
##   godot --headless --path . -s res://tools/setup_input_map.gd

const DEADZONE: float = 0.2


func _init() -> void:
	var actions := {
		"move_left":
		[_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)],
		"move_right":
		[_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)],
		"move_up":
		[_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)],
		"move_down":
		[_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)],
		"dev_toggle": [_key(KEY_F1), _key(KEY_QUOTELEFT)],
		"pause": [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)],
	}
	for action: String in actions:
		ProjectSettings.set_setting(
			"input/" + action, {"deadzone": DEADZONE, "events": actions[action]}
		)
	var error := ProjectSettings.save()
	print("input map saved: ", error == OK)
	quit()


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = code
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	return event
