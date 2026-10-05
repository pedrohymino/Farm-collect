class_name IsoInput
extends RefCounted
## Converts 2D input (up = screen up) into a world direction for a camera rotated by `yaw`.


static func to_world(input: Vector2, yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)
