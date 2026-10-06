class_name CropField
extends Node3D
## Crop beds that grow by themselves; carriers harvest ripe beds just by walking over them.
## Bed count = producer base units + unlock bonuses (producers.json / unlocks.json).

const COLUMNS: int = 3
const BED_SPACING: float = 1.1
const BED_SIZE: float = 0.95
const BED_HEIGHT: float = 0.08
const HARVEST_RADIUS: float = 0.6
const DROP_HEIGHT: float = 0.4
const SPROUT_SCALE: float = 0.15
const RIPE_POP_SCALE: float = 1.25
const POP_TIME: float = 0.15
const SOIL_COLOR: Color = Color("8a5a2b")
const GROWING_COLOR: Color = Color("6fbf45")
const RIPE_COLOR: Color = Color("f2c335")

@export var producer_id: StringName = &"field"

var item_id: StringName

## {plant: Node3D (pivot at soil level), mesh: MeshInstance3D, cycle: ProductionCycle, ripe: bool}
var _beds: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _soil_mesh: BoxMesh
var _plant_mesh: CylinderMesh
var _growing_material: StandardMaterial3D
var _ripe_material: StandardMaterial3D

@onready var _beds_root: Node3D = $Beds


func _ready() -> void:
	add_to_group(&"crop_field")
	_rng.randomize()
	item_id = ContentDB.producer_item(producer_id)
	_build_shared_resources()
	_refresh_units()
	EventBus.unlock_completed.connect(_refresh_units.unbind(1))


func bed_count() -> int:
	return _beds.size()


func ripe_count() -> int:
	return _beds.filter(func(bed: Dictionary) -> bool: return bed["ripe"]).size()


func bed_global_position(index: int) -> Vector3:
	return _beds_root.to_global(_bed_position(index))


## Dev mode / tests: makes every bed harvestable now.
func ripen_all() -> void:
	for bed in _beds:
		_set_ripe(bed, true)


func _process(delta: float) -> void:
	var interval := _interval()
	for bed in _beds:
		if bed["ripe"]:
			continue
		var cycle: ProductionCycle = bed["cycle"]
		if cycle.advance(delta, interval) > 0:
			_set_ripe(bed, true)
		else:
			(bed["plant"] as Node3D).scale.y = lerpf(SPROUT_SCALE, 1.0, cycle.ratio(interval))


func _physics_process(_delta: float) -> void:
	for carrier in get_tree().get_nodes_in_group(&"carrier"):
		var carrier_node := carrier as Node3D
		for index in _beds.size():
			if _beds[index]["ripe"] and _is_near(carrier_node, index):
				_harvest(index, carrier_node)


func _harvest(index: int, carrier: Node3D) -> void:
	var visual: StackVisual = carrier.get(&"carry_visual")
	var amount := YieldRoller.roll(
		Stats.get_value(&"production.yield"), Stats.get_value(&"production.double_chance"), _rng
	)
	var harvested := 0
	for i in amount:
		if not visual.container.push(item_id):
			break
		visual.fly_in_top(bed_global_position(index) + Vector3.UP * DROP_HEIGHT)
		EventBus.item_collected.emit(item_id)
		harvested += 1
	if harvested == 0 and amount > 0:
		carrier.call(&"show_full")
		return
	var bed := _beds[index]
	(bed["cycle"] as ProductionCycle).progress = 0.0
	_set_ripe(bed, false)


func _is_near(carrier: Node3D, index: int) -> bool:
	var offset := carrier.global_position - bed_global_position(index)
	offset.y = 0.0
	return offset.length() <= HARVEST_RADIUS


func _interval() -> float:
	return (
		ContentDB.item_production_seconds(item_id) / Stats.get_scoped(&"production.rate", item_id)
	)


func _refresh_units() -> void:
	var target := clampi(
		ContentDB.producer_base_units(producer_id) + Unlocks.units_bonus(producer_id),
		0,
		ContentDB.producer_max_units(producer_id)
	)
	while _beds.size() < target:
		_add_bed()


func _add_bed() -> void:
	var index := _beds.size()
	var soil := MeshInstance3D.new()
	soil.mesh = _soil_mesh
	soil.position = _bed_position(index) + Vector3.UP * BED_HEIGHT * 0.5
	_beds_root.add_child(soil)
	var plant := Node3D.new()
	plant.position = Vector3(0.0, BED_HEIGHT * 0.5, 0.0)
	soil.add_child(plant)
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = _plant_mesh
	mesh_node.position.y = _plant_mesh.height * 0.5
	plant.add_child(mesh_node)
	var bed := {
		"plant": plant,
		"mesh": mesh_node,
		"cycle": ProductionCycle.new(_rng.randf(), _interval()),
		"ripe": false,
	}
	_beds.append(bed)
	_set_ripe(bed, false)


func _bed_position(index: int) -> Vector3:
	var column := index % COLUMNS
	var row := floori(index / float(COLUMNS))
	return Vector3((column - (COLUMNS - 1) * 0.5) * BED_SPACING, 0.0, row * BED_SPACING)


func _set_ripe(bed: Dictionary, ripe: bool) -> void:
	bed["ripe"] = ripe
	var plant: Node3D = bed["plant"]
	(bed["mesh"] as MeshInstance3D).set_surface_override_material(
		0, _ripe_material if ripe else _growing_material
	)
	if ripe:
		plant.scale = Vector3.ONE * RIPE_POP_SCALE
		plant.create_tween().tween_property(plant, "scale", Vector3.ONE, POP_TIME).set_trans(
			Tween.TRANS_BACK
		)
	else:
		plant.scale = Vector3(1.0, SPROUT_SCALE, 1.0)


func _build_shared_resources() -> void:
	_soil_mesh = BoxMesh.new()
	_soil_mesh.size = Vector3(BED_SIZE, BED_HEIGHT, BED_SIZE)
	var soil_material := StandardMaterial3D.new()
	soil_material.albedo_color = SOIL_COLOR
	_soil_mesh.material = soil_material
	_plant_mesh = CylinderMesh.new()
	_plant_mesh.top_radius = 0.36
	_plant_mesh.bottom_radius = 0.28
	_plant_mesh.height = 0.6
	_plant_mesh.radial_segments = 8
	_growing_material = StandardMaterial3D.new()
	_growing_material.albedo_color = GROWING_COLOR
	_ripe_material = StandardMaterial3D.new()
	_ripe_material.albedo_color = RIPE_COLOR
