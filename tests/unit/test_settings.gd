extends GutTest

var path: String


func before_each() -> void:
	path = "user://test_settings_%d.cfg" % Time.get_ticks_usec()


func after_each() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_defaults() -> void:
	var data := SettingsData.new()
	assert_eq(data.master_volume, 1.0)
	assert_eq(data.language, "auto")
	assert_true(data.vibration)
	assert_eq(data.quality, SettingsData.Quality.MEDIUM)


func test_from_dict_clamps_and_ignores_garbage() -> void:
	var data := (
		SettingsData
		. from_dict(
			{
				"master_volume": 7.0,
				"music_volume": -3,
				"sfx_volume": "loud",
				"language": "klingon",
				"vibration": "yes",
				"quality": 99,
			}
		)
	)
	assert_eq(data.master_volume, 1.0)
	assert_eq(data.music_volume, 0.0)
	assert_eq(data.sfx_volume, 1.0)
	assert_eq(data.language, "auto")
	assert_true(data.vibration)
	assert_eq(data.quality, SettingsData.Quality.HIGH)


func test_dict_round_trip() -> void:
	var data := SettingsData.new()
	data.master_volume = 0.4
	data.language = "pt_BR"
	data.vibration = false
	data.quality = SettingsData.Quality.LOW
	assert_true(SettingsData.from_dict(data.to_dict()).is_equal_to(data))
	assert_false(data.is_equal_to(SettingsData.new()))


func test_duplicate_is_independent() -> void:
	var data := SettingsData.new()
	var copy := data.duplicate_data()
	copy.master_volume = 0.1
	assert_eq(data.master_volume, 1.0)


func test_volume_to_db() -> void:
	assert_eq(SettingsData.volume_to_db(0.0), SettingsData.SILENT_DB)
	assert_almost_eq(SettingsData.volume_to_db(1.0), 0.0, 0.0001)
	assert_lt(SettingsData.volume_to_db(0.5), 0.0)
	assert_gt(SettingsData.volume_to_db(0.5), SettingsData.volume_to_db(0.1))


func test_resolve_locale() -> void:
	assert_eq(SettingsData.resolve_locale("auto", "pt_BR"), "pt_BR")
	assert_eq(SettingsData.resolve_locale("auto", "pt_PT"), "pt_BR")
	assert_eq(SettingsData.resolve_locale("auto", "de_DE"), "en")
	assert_eq(SettingsData.resolve_locale("en", "pt_BR"), "en")
	assert_eq(SettingsData.resolve_locale("pt_BR", "en_US"), "pt_BR")


func test_store_round_trip_and_defaults_when_missing() -> void:
	var store := SettingsStore.new(path)
	assert_true(store.load_settings().is_equal_to(SettingsData.new()))
	var data := SettingsData.new()
	data.sfx_volume = 0.25
	data.quality = SettingsData.Quality.HIGH
	assert_true(store.save_settings(data))
	assert_true(store.load_settings().is_equal_to(data))


func test_store_survives_a_damaged_file() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[settings\nmaster_volume = = =")
	file.close()
	var loaded := SettingsStore.new(path).load_settings()
	assert_engine_error("ConfigFile parse error")
	assert_true(loaded.is_equal_to(SettingsData.new()))


func test_quality_profiles_get_cheaper_downwards() -> void:
	var low := QualityProfile.for_level(SettingsData.Quality.LOW)
	var medium := QualityProfile.for_level(SettingsData.Quality.MEDIUM)
	var high := QualityProfile.for_level(SettingsData.Quality.HIGH)
	assert_false(low["shadows"])
	assert_true(medium["shadows"])
	assert_lt(low["render_scale"], medium["render_scale"])
	assert_gt(high["msaa"], medium["msaa"])
