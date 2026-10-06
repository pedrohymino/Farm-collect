extends GutTest
## Audio buses, music loop and haptics wiring.


func test_project_has_music_and_sfx_buses() -> void:
	assert_ne(AudioServer.get_bus_index(&"Music"), -1)
	assert_ne(AudioServer.get_bus_index(&"SFX"), -1)


func test_audio_director_routes_music_and_sfx() -> void:
	var director := AudioDirector.new()
	add_child_autofree(director)
	assert_eq(director.music_player().bus, &"Music")
	assert_true(director.music_player().playing)
	var sfx_players := director.get_children().filter(
		func(node: Node) -> bool: return node is AudioStreamPlayer and node.bus == &"SFX"
	)
	assert_eq(sfx_players.size(), AudioDirector.POOL_SIZE)


func test_haptics_disabled_on_desktop_and_throttled_when_enabled() -> void:
	var haptics := Haptics.new()
	add_child_autofree(haptics)
	assert_false(haptics.pulse(10, 0.5), "desktop: no vibration")
	haptics.enabled = true
	assert_true(haptics.pulse(10, 0.5))
	assert_false(haptics.pulse(10, 0.5), "throttled")
	assert_true(haptics.pulse(10, 0.5, true), "forced pulses skip the throttle")
