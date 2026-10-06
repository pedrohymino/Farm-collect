extends GutTest
## Main menu, pause menu, settings panel and save notices. Settings and saves are redirected
## to temporary files so the tests never touch the player's own files.

var _original_settings_store: SettingsStore
var _original_settings: SettingsData
var _original_save_store: SaveStore
var _original_locale: String
var _settings_path: String
var _save_dir: String


func before_each() -> void:
	_original_settings_store = Settings._store
	_original_settings = Settings.data.duplicate_data()
	_original_save_store = SaveManager._store
	_original_locale = TranslationServer.get_locale()
	_settings_path = "user://test_menu_settings_%d.cfg" % Time.get_ticks_usec()
	_save_dir = "user://test_menu_saves_%d" % Time.get_ticks_usec()
	Settings._store = SettingsStore.new(_settings_path)
	Settings.update(SettingsData.new())
	SaveManager._store = SaveStore.new(_save_dir, "slot_0")
	TranslationServer.set_locale("en")


func after_each() -> void:
	get_tree().paused = false
	Settings._store = _original_settings_store
	Settings.update(_original_settings)
	SaveManager._store = _original_save_store
	TranslationServer.set_locale(_original_locale)
	if FileAccess.file_exists(_settings_path):
		DirAccess.remove_absolute(_settings_path)
	var dir := DirAccess.open(_save_dir)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(_save_dir)


func _add_settings_panel() -> SettingsPanel:
	var panel := SettingsPanel.new()
	add_child_autofree(panel)
	return panel


func test_slider_changes_apply_and_save() -> void:
	var panel := _add_settings_panel()
	panel.slider("music_volume").value = 0.3
	assert_almost_eq(Settings.data.music_volume, 0.3, 0.001)
	var saved := SettingsStore.new(_settings_path).load_settings()
	assert_almost_eq(saved.music_volume, 0.3, 0.001)


func test_language_and_quality_choices_apply() -> void:
	var panel := _add_settings_panel()
	panel.language_option().item_selected.emit(2)
	panel.quality_option().item_selected.emit(0)
	assert_eq(Settings.data.language, "pt_BR")
	assert_eq(TranslationServer.get_locale(), "pt_BR")
	assert_eq(Settings.data.quality, SettingsData.Quality.LOW)


func test_vibration_toggle_updates_setting_and_label() -> void:
	var panel := _add_settings_panel()
	assert_string_contains(panel.vibration_toggle().text, tr("SETTINGS_ON"))
	panel.vibration_toggle().button_pressed = false
	assert_false(Settings.data.vibration)
	assert_string_contains(panel.vibration_toggle().text, tr("SETTINGS_OFF"))


func test_panel_follows_settings_changed_elsewhere() -> void:
	var panel := _add_settings_panel()
	var data := Settings.data.duplicate_data()
	data.sfx_volume = 0.4
	Settings.update(data)
	assert_almost_eq(panel.slider("sfx_volume").value, 0.4, 0.001)


func test_reset_progress_needs_a_second_tap() -> void:
	var panel := _add_settings_panel()
	panel.press_reset()
	assert_true(panel.is_reset_armed())


func test_automatic_language_goes_back_to_the_system_language() -> void:
	var data := Settings.data.duplicate_data()
	data.language = "pt_BR"
	Settings.update(data)
	assert_eq(TranslationServer.get_locale(), "pt_BR")
	data.language = "auto"
	Settings.update(data)
	var expected := SettingsData.resolve_locale("auto", OS.get_locale())
	assert_eq(TranslationServer.get_locale(), expected)


func test_open_menus_follow_a_language_change() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open()
	var data := Settings.data.duplicate_data()
	data.language = "pt_BR"
	Settings.update(data)
	await wait_physics_frames(2)
	assert_true(menu.is_open(), "still open after the rebuild")
	assert_true(_has_text(menu, "Voltar ao jogo"), "resume button speaks Portuguese")
	data.language = "en"
	Settings.update(data)
	await wait_physics_frames(2)
	assert_true(_has_text(menu, "Resume"))


func test_main_menu_button_failing_to_save_keeps_the_player_in_the_game() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open()
	DirAccess.make_dir_recursive_absolute(_save_dir)
	SaveManager._is_active = true
	DirAccess.make_dir_recursive_absolute(_save_dir.path_join("slot_0.tmp"))
	menu._to_main_menu()
	SaveManager._is_active = false
	assert_push_error("Cannot write save")
	assert_true(menu.is_open(), "stays in the pause menu")


func _has_text(node: Node, text: String) -> bool:
	if node is Button and (node as Button).text == text:
		return true
	for child in node.get_children():
		if not child.is_queued_for_deletion() and _has_text(child, text):
			return true
	return false


func test_vibration_off_silences_haptics() -> void:
	var haptics := Haptics.new()
	add_child_autofree(haptics)
	haptics.enabled = true
	var data := Settings.data.duplicate_data()
	data.vibration = false
	Settings.update(data)
	assert_false(haptics.pulse(10, 0.5, true))
	data.vibration = true
	Settings.update(data)
	assert_true(haptics.pulse(10, 0.5, true))


func test_pause_menu_pauses_and_resumes_the_game() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open()
	assert_true(menu.is_open())
	assert_true(get_tree().paused)
	menu.close()
	assert_false(menu.is_open())
	assert_false(get_tree().paused)


func test_pause_request_toggles_the_menu() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	EventBus.pause_requested.emit()
	assert_true(menu.is_open())
	EventBus.pause_requested.emit()
	assert_false(menu.is_open())


func test_pause_menu_can_open_on_settings() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	menu.open_settings()
	assert_true(menu.is_open())
	assert_true(menu.is_settings_visible())


func test_toast_shows_save_problems_and_failures() -> void:
	var toast := NoticeToast.new()
	add_child_autofree(toast)
	assert_false(toast.is_showing())
	EventBus.save_failed.emit()
	assert_true(toast.is_showing())
	assert_eq(toast.current_text(), tr("NOTICE_SAVE_FAILED"))
	EventBus.save_problem.emit(&"restored_from_backup")
	assert_eq(toast.current_text(), tr("NOTICE_SAVE_RESTORED"))
	EventBus.save_problem.emit(&"corrupt_reset")
	assert_eq(toast.current_text(), tr("NOTICE_SAVE_RESET"))


func test_main_menu_offers_play_or_continue() -> void:
	var fresh := MainMenu.new()
	add_child_autofree(fresh)
	assert_eq(fresh.play_button_text(), tr("MENU_PLAY"))
	DirAccess.make_dir_recursive_absolute(_save_dir)
	var file := FileAccess.open(_save_dir.path_join("slot_0.json"), FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	var returning := MainMenu.new()
	add_child_autofree(returning)
	assert_eq(returning.play_button_text(), tr("MENU_CONTINUE"))
