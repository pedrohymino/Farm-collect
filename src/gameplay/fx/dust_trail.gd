class_name DustTrail
extends CPUParticles3D
## Little dust puffs behind someone running. The owner toggles `emitting` by speed.

const AMOUNT: int = 14
const LIFETIME: float = 0.5
const PUFF_RADIUS: float = 0.09
const PUFF_COLOR: Color = Color(0.86, 0.74, 0.55, 0.8)


func _init() -> void:
	amount = AMOUNT
	lifetime = LIFETIME
	emitting = false
	local_coords = false
	direction = Vector3.UP
	spread = 35.0
	gravity = Vector3(0.0, 0.6, 0.0)
	initial_velocity_min = 0.3
	initial_velocity_max = 0.8
	scale_amount_min = 0.6
	scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = curve
	var puff := SphereMesh.new()
	puff.radius = PUFF_RADIUS
	puff.height = PUFF_RADIUS * 2.0
	puff.radial_segments = 6
	puff.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = PUFF_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = material
	mesh = puff
