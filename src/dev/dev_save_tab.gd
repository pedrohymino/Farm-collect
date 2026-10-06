class_name DevSaveTab
extends VBoxContainer
## Dev panel tab: save actions, tuning presets and balance-file tools.

const STATS_FILE: String = "res://data/balance/stats.json"

var _store: DevSessionStore
var _report: Callable
var _preset_name: LineEdit
var _preset_list: OptionButton


## report: Callable(String) that shows a status message in the panel.
func _init(store: DevSessionStore, report: Callable) -> void:
	_store = store
	_report = report

	add_child(DevUi.section(tr("DEV_TAB_SAVE")))
	add_child(DevUi.button(tr("DEV_SAVE_NOW"), _save_now))
	add_child(DevUi.button(tr("DEV_RELOAD_SAVE"), _reload_scene))
	add_child(DevUi.button(tr("DEV_RESET_SAVE"), _reset_save))
	add_child(DevUi.button(tr("DEV_EXPORT_SAVE"), _export_save))
	add_child(DevUi.button(tr("DEV_IMPORT_SAVE"), _import_save))

	add_child(DevUi.section(tr("DEV_PRESETS")))
	_preset_name = LineEdit.new()
	_preset_name.placeholder_text = tr("DEV_PRESET_NAME")
	_preset_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_row := HBoxContainer.new()
	name_row.add_child(_preset_name)
	name_row.add_child(DevUi.button(tr("DEV_PRESET_SAVE"), _save_preset))
	add_child(name_row)
	_preset_list = OptionButton.new()
	_preset_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list_row := HBoxContainer.new()
	list_row.add_child(_preset_list)
	list_row.add_child(DevUi.button(tr("DEV_PRESET_LOAD"), _load_preset))
	list_row.add_child(DevUi.button(tr("DEV_PRESET_DELETE"), _delete_preset))
	add_child(list_row)
	_refresh_presets()

	add_child(DevUi.section(tr("DEV_BALANCE")))
	add_child(DevUi.button(tr("DEV_RELOAD_BALANCE"), _reload_balance))
	var write_button := DevUi.button(tr("DEV_WRITE_BALANCE"), _write_balance)
	write_button.disabled = not OS.has_feature("editor")
	write_button.tooltip_text = tr("DEV_WRITE_BALANCE_EDITOR_ONLY")
	add_child(write_button)


func _save_now() -> void:
	_report.call(tr("DEV_DONE") if SaveManager.save_game() else tr("DEV_FAILED"))


func _reload_scene() -> void:
	get_tree().reload_current_scene()


func _reset_save() -> void:
	_confirm(
		tr("DEV_RESET_SAVE_CONFIRM"),
		func() -> void:
			SaveManager.delete_save()
			_reload_scene()
	)


func _export_save() -> void:
	DisplayServer.clipboard_set(JSON.stringify(SaveManager.build_payload(), "\t"))
	_report.call(tr("DEV_DONE"))


func _import_save() -> void:
	var parsed: Variant = JSON.parse_string(DisplayServer.clipboard_get())
	if typeof(parsed) == TYPE_DICTIONARY and SaveManager.import_payload(parsed):
		_reload_scene()
	else:
		_report.call(tr("DEV_IMPORT_FAILED"))


func _save_preset() -> void:
	var preset_name := _preset_name.text.strip_edges()
	if not DevSessionStore.is_valid_preset_name(preset_name):
		_report.call(tr("DEV_PRESET_INVALID"))
		return
	var data := DevSessionStore.capture(Stats.registry, ContentDB.balance.stats)
	_report.call(tr("DEV_DONE") if _store.save_preset(preset_name, data) else tr("DEV_FAILED"))
	_refresh_presets()


func _load_preset() -> void:
	var preset_name := _selected_preset()
	if preset_name.is_empty():
		return
	DevSessionStore.apply(Stats.registry, _store.load_preset(preset_name), ContentDB.balance.stats)
	_report.call(tr("DEV_DONE"))


func _delete_preset() -> void:
	var preset_name := _selected_preset()
	if preset_name.is_empty():
		return
	_store.delete_preset(preset_name)
	_refresh_presets()
	_report.call(tr("DEV_DONE"))


func _refresh_presets() -> void:
	_preset_list.clear()
	for preset_name in _store.list_presets():
		_preset_list.add_item(preset_name)


func _selected_preset() -> String:
	if _preset_list.selected < 0:
		return ""
	return _preset_list.get_item_text(_preset_list.selected)


func _reload_balance() -> void:
	ContentDB.reload()
	Stats.reload_defs()
	Unlocks.reload()
	Progression.reload()
	_report.call(tr("DEV_DONE"))


func _write_balance() -> void:
	if not OS.has_feature("editor"):
		_report.call(tr("DEV_WRITE_BALANCE_EDITOR_ONLY"))
		return
	var changes := BalanceWriter.changed_bases(ContentDB.balance.stats, Stats.registry)
	if changes.is_empty():
		_report.call(tr("DEV_WRITE_BALANCE_NONE"))
		return
	var lines := PackedStringArray()
	for change in changes:
		lines.append(
			"%s: %s → %s" % [change["id"], DevUi.num(change["old"]), DevUi.num(change["new"])]
		)
	_confirm(
		tr("DEV_WRITE_BALANCE_CONFIRM") + "\n\n" + "\n".join(lines),
		func() -> void:
			var updated := BalanceWriter.with_bases(ContentDB.balance.stats, changes)
			var written := BalanceWriter.write_stats(
				ProjectSettings.globalize_path(STATS_FILE), updated
			)
			if written:
				_reload_balance()
			else:
				_report.call(tr("DEV_FAILED"))
	)


func _confirm(text: String, on_confirmed: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.theme = DevUi.make_theme()
	dialog.dialog_text = text
	dialog.confirmed.connect(on_confirmed)
	dialog.visibility_changed.connect(
		func() -> void:
			if not dialog.visible:
				dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()
