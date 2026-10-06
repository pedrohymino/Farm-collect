class_name Confetti
extends CPUParticles3D
## One-shot burst of colorful paper bits (unlocks, level ups).

const AMOUNT: int = 48
const LIFETIME: float = 1.4
const PIECE_SIZE: Vector3 = Vector3(0.12, 0.02, 0.08)
const SPEED_MIN: float = 4.0
const SPEED_MAX: float = 7.0
const SPREAD_DEGREES: float = 50.0
const COLORS: Array[Color] = [
	Color("e5483b"), Color("f7c531"), Color("3fd3f2"), Color("5ee06b"), Color("b06be0")
]


static func burst(parent: Node, global_pos: Vector3) -> void:
	var particles := Confetti.new()
	parent.add_child(particles)
	particles.global_position = global_pos
	particles.emitting = true


func _init() -> void:
	one_shot = true
	explosiveness = 0.9
	amount = AMOUNT
	lifetime = LIFETIME
	direction = Vector3.UP
	spread = SPREAD_DEGREES
	initial_velocity_min = SPEED_MIN
	initial_velocity_max = SPEED_MAX
	angular_velocity_min = -360.0
	angular_velocity_max = 360.0
	var piece := BoxMesh.new()
	piece.size = PIECE_SIZE
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	piece.material = material
	mesh = piece
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	ramp.offsets = PackedFloat32Array()
	ramp.colors = PackedColorArray()
	for index in COLORS.size():
		ramp.add_point(index / float(COLORS.size()), COLORS[index])
	color_initial_ramp = ramp
	finished.connect(queue_free)
