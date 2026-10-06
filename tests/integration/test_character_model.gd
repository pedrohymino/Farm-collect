extends GutTest
## Kenney characters and animals actually animate (the model alone would just T-pose).

const CHARACTER: PackedScene = preload(
	"res://assets/models/kenney/mini-characters/character-female-f.glb"
)
const COW_SCENE: PackedScene = preload("res://assets/models/animals/cow.tscn")


func _character() -> CharacterModel:
	var model := CharacterModel.new()
	model.model_scene = CHARACTER
	add_child_autofree(model)
	return model


func test_starts_idle_with_loops_and_carry_variants() -> void:
	var model := _character()
	assert_eq(model.current_animation(), &"idle")
	for animation_name in [&"idle-carry", &"walk-carry", &"sprint-carry"]:
		assert_true(model.has_animation(animation_name), String(animation_name))


func test_follows_speed_and_carrying() -> void:
	var model := _character()
	model.set_motion(2.0, false)
	assert_eq(model.current_animation(), &"walk")
	model.set_motion(4.0, false)
	assert_eq(model.current_animation(), &"sprint")
	model.set_motion(4.0, true)
	assert_eq(model.current_animation(), &"sprint-carry")
	model.set_motion(0.0, true)
	assert_eq(model.current_animation(), &"idle-carry")


func test_swapping_the_model_keeps_it_animated() -> void:
	var model := _character()
	model.set_model(preload("res://assets/models/kenney/mini-characters/character-male-d.glb"))
	await wait_frames(2)
	model.set_motion(2.0, false)
	assert_eq(model.current_animation(), &"walk")


func test_animal_idles_and_walks() -> void:
	var cow := COW_SCENE.instantiate() as AnimalWander
	add_child_autofree(cow)
	assert_eq(cow.current_animation(), &"idle")
	cow.set_bounds(Vector2(2, 2))
	await wait_seconds(4.0)
	assert_true([&"idle", &"walk", &"eat"].has(cow.current_animation()))
