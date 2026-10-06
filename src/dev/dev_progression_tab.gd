class_name DevProgressionTab
extends VBoxContainer
## Dev panel tab: unlocks and onboarding shortcuts.

const XP_STEPS: Array[float] = [100.0, 1000.0, 10000.0]

var _report: Callable
var _count_label: Label


## report: Callable(String) that shows a status message in the panel.
func _init(report: Callable) -> void:
	_report = report
	_count_label = DevUi.section("")
	add_child(_count_label)
	add_child(DevUi.button(tr("DEV_UNLOCK_NEXT"), _unlock_next))
	add_child(DevUi.button(tr("DEV_UNLOCK_ALL"), _unlock_all))
	add_child(DevUi.button(tr("DEV_RESET_UNLOCKS"), _reset_unlocks))
	add_child(DevUi.button(tr("DEV_SKIP_TUTORIAL"), _skip_tutorial))
	add_child(DevUi.section(tr("DEV_LEVEL")))
	var xp_buttons: Array[Control] = []
	for amount in XP_STEPS:
		xp_buttons.append(
			DevUi.button(tr("DEV_ADD_XP") % DevUi.num(amount), Progression.add_xp.bind(amount))
		)
	add_child(DevUi.flow(xp_buttons))
	add_child(
		DevUi.button(
			tr("DEV_LEVEL_UP"), func() -> void: Progression.add_xp(Progression.xp_to_next())
		)
	)
	add_child(DevUi.button(tr("DEV_RESET_PROGRESSION"), _reset_progression))
	EventBus.unlock_completed.connect(_refresh_count.unbind(1))
	_refresh_count()


func unlock_next() -> bool:
	var available := Unlocks.available_ids()
	if available.is_empty():
		return false
	Unlocks.complete(available[0])
	return true


func _unlock_next() -> void:
	_report.call(tr("DEV_DONE") if unlock_next() else tr("DEV_FAILED"))


func _unlock_all() -> void:
	while unlock_next():
		pass
	_report.call(tr("DEV_DONE"))


func _reset_unlocks() -> void:
	GameState.data.unlocked.clear()
	GameState.data.unlock_progress.clear()
	SaveManager.save_game()
	get_tree().reload_current_scene()


func _skip_tutorial() -> void:
	GameState.data.tutorial_step = GuideArrow.STEPS.size()
	EventBus.tutorial_step_changed.emit(GameState.data.tutorial_step)
	get_tree().call_group(&"guide_arrow", &"queue_free")
	_report.call(tr("DEV_DONE"))


func _reset_progression() -> void:
	Progression.reset_all()
	_report.call(tr("DEV_DONE"))


func _refresh_count() -> void:
	_count_label.text = (
		tr("DEV_UNLOCKED_COUNT") % [GameState.data.unlocked.size(), Unlocks.rules.ids().size()]
	)
