class_name FloatingText
extends Label3D
## "+$12"-style text that rises and fades above something.

const RISE: float = 1.2
const LIFETIME: float = 0.9
const FONT_SIZE: int = 96
const OUTLINE_SIZE: int = 24
const PIXEL_SIZE: float = 0.004


static func spawn(parent: Node, global_pos: Vector3, message: String, color: Color) -> void:
	var label := FloatingText.new()
	label.text = message
	label.modulate = color
	label.outline_modulate = Color(0.1, 0.1, 0.1, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = FONT_SIZE
	label.outline_size = OUTLINE_SIZE
	label.pixel_size = PIXEL_SIZE
	label.no_depth_test = true
	parent.add_child(label)
	label.global_position = global_pos
	label._animate()


func _animate() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + RISE, LIFETIME).set_trans(
		Tween.TRANS_CUBIC
	)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)
	tween.chain().tween_callback(queue_free)
