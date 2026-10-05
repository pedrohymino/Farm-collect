extends Node
## Saves and loads GameState.data (docs/04-arquitetura.md, section 8).
## Inactive until load_game() is called by the main scene, so tests and tools
## never read or overwrite the player's save.

const SAVE_DIR: String = "user://saves"
const SLOT: String = "slot_0"
const AUTOSAVE_INTERVAL_SEC: float = 30.0

var _store: SaveStore = SaveStore.new(SAVE_DIR, SLOT)
var _migrator: SaveMigrator = SaveMigrator.create_default()
var _is_active: bool = false
var _autosave_timer: Timer


func is_active() -> bool:
	return _is_active


func load_game() -> void:
	_is_active = true
	var result := _store.read()
	match result.status:
		SaveStore.ReadStatus.NONE:
			GameState.new_game()
		SaveStore.ReadStatus.CORRUPT:
			_start_fresh_after_failure(result.error)
		SaveStore.ReadStatus.OK:
			var migration := _migrator.migrate(result.payload)
			if migration.ok:
				GameState.replace(GameData.from_dict(migration.data))
			else:
				_start_fresh_after_failure(migration.error)
	_start_autosave()
	EventBus.game_loaded.emit()


func save_game() -> bool:
	if not _is_active:
		return false
	var saved := _store.write(build_payload())
	if saved:
		EventBus.game_saved.emit()
	return saved


## Current game as a save payload (also used by dev mode to export the save).
func build_payload() -> Dictionary:
	get_tree().call_group(&"persistent_location", &"write_state")
	return {
		"schema_version": SaveMigrator.CURRENT_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"data": GameState.data.to_dict(),
	}


## Dev mode: validates a payload and writes it as the current save. Caller reloads the scene.
func import_payload(payload: Dictionary) -> bool:
	if not _migrator.migrate(payload).ok:
		return false
	return _store.write(payload)


## Dev mode "reset save": deletes the save files and starts a new game in memory.
func delete_save() -> void:
	_store.delete_all()
	GameState.new_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


func _start_autosave() -> void:
	if _autosave_timer != null:
		return
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	_autosave_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_autosave_timer.timeout.connect(save_game)
	add_child(_autosave_timer)
	_autosave_timer.start()


func _start_fresh_after_failure(reason: String) -> void:
	var moved_to := _store.quarantine_main()
	push_error(
		"Save could not be loaded (%s). File kept at %s; starting new game." % [reason, moved_to]
	)
	GameState.new_game()
