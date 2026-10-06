class_name Sparkle
extends CPUParticles3D
## Small golden glints floating up from something valuable (money piles). Owner toggles `emitting`.

const AMOUNT: int = 6
const LIFETIME: float = 1.1
const GLINT_SIZE: float = 0.07
const GLINT_COLOR: Color = Color(1.0, 0.92, 0.45)
const AREA_HALF_SIZE: Vector3 = Vector3(0.4, 0.1, 0.3)


func _init() -> void:
	amount = AMOUNT
	lifetime = LIFETIME
	emitting = false
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = AREA_HALF_SIZE
	direction = Vector3.UP
	spread = 10.0
	gravity = Vector3.ZERO
	initial_velocity_min = 0.3
	initial_velocity_max = 0.6
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = curve
	var glint := QuadMesh.new()
	glint.size = Vector2.ONE * GLINT_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = GLINT_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glint.material = material
	mesh = glint
