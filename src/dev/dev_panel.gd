class_name DevPanel
extends CanvasLayer
## In-game live tuning panel (docs/05-dev-mode.md). Every action goes through the same
## systems the game uses (Stats, Economy, SaveManager...). Also draws the "DEV ×N" badge.

const LAYER: int = 100
const PANEL_WIDTH: float = 1000.0
const MARGIN: int = 24
const OVERLAY_REFRESH_SEC: float = 0.25
const OVERLAY_COLOR: Color = Color("ffd166")
const PANEL_COLOR: Color = Color(0.09, 0.1, 0.13, 0.94)
const FAVORITE_STATS: Array[StringName] = [
	&"production.yield",
	&"player.carry_capacity",
	&"player.move_speed",
	&"sell.price",
	&"production.rate",
	&"customer.spawn_interval",
]
const MONEY_STEPS: Array[float] = [100.0, 10_000.0, 1_000_000.0]
const STAR_STEPS: Array[float] = [1.0, 10.0, 100.0]
const TIME_SCALE_MIN: float = 0.1
const TIME_SCALE_MAX: float = 10.0
const TIME_SCALE_PRESETS: Array[float] = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0]
const PORTRAIT_WINDOW: Vector2i = Vector2i(540, 1170)
const LANDSCAPE_WINDOW: Vector2i = Vector2i(1600, 900)

var _store: DevSessionStore
var _panel: PanelContainer
var _rows: Dictionary = {}  # StringName -> DevStatRow
var _overlay: Label
var _header_info: Label
var _status: Label
var _currency_labels: Dictionary = {}  # StringName -> Label
var _time_label: Label
var _time_slider: HSlider
var _item_picker: OptionButton
var _show_fps: bool = false
var _overlay_timer: float = 0.0


func _init(store: DevSessionStore) -> void:
	_store = store


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = DevUi.make_theme()
	root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(root)

	_overlay = DevUi.label("")
	_overlay.position = Vector2(MARGIN, MARGIN)
	_overlay.add_theme_color_override(&"font_color", OVERLAY_COLOR)
	_overlay.add_theme_constant_override(&"outline_size", 8)
	root.add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_WIDTH
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	_panel.add_theme_stylebox_override(&"panel", panel_style)
	_panel.visible = false
	root.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_child(DevUi.section(tr("DEV_TITLE")))
	_header_info = DevUi.label("", DevUi.SMALL_FONT_SIZE)
	_header_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_header_info)
	header.add_child(DevUi.button(tr("DEV_CLOSE"), toggle))
	box.add_child(header)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	_add_tab(tabs, tr("DEV_TAB_STATS"), _build_stats_tab())
	_add_tab(tabs, tr("DEV_TAB_ECONOMY"), _build_economy_tab())
	_add_tab(tabs, tr("DEV_TAB_TIME"), _build_time_tab())
	_add_tab(tabs, tr("DEV_TAB_WORLD"), _build_world_tab())
	_add_tab(tabs, tr("DEV_TAB_PROGRESSION"), DevProgressionTab.new(_set_status))
	_add_tab(tabs, tr("DEV_TAB_SAVE"), DevSaveTab.new(_store, _set_status))

	_status = DevUi.label("", DevUi.SMALL_FONT_SIZE)
	box.add_child(_status)

	Stats.stat_changed.connect(_on_stat_changed)
	EventBus.currency_changed.connect(_on_currency_changed.unbind(2))
	_on_currency_changed()
	_refresh_overlay()


func toggle() -> void:
	_panel.visible = not _panel.visible


func is_open() -> bool:
	return _panel.visible


func row(stat_id: StringName) -> DevStatRow:
	return _rows.get(stat_id)


func overlay_text() -> String:
	return _overlay.text


func filter_stats(query: String) -> void:
	var needle := query.strip_edges().to_lower()
	for stat_id: StringName in _rows:
		_rows[stat_id].visible = needle.is_empty() or String(stat_id).contains(needle)


func _process(delta: float) -> void:
	if not _show_fps:
		return
	_overlay_timer -= delta
	if _overlay_timer <= 0.0:
		_overlay_timer = OVERLAY_REFRESH_SEC
		_refresh_overlay()


func _add_tab(tabs: TabContainer, title: String, content: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, title)


func _build_stats_tab() -> Control:
	var box := VBoxContainer.new()
	var search := LineEdit.new()
	search.placeholder_text = tr("DEV_SEARCH")
	search.clear_button_enabled = true
	search.text_changed.connect(filter_stats)
	box.add_child(search)
	box.add_child(DevUi.button(tr("DEV_CLEAR_OVERRIDES"), _clear_overrides))
	var ordered: Array[StringName] = []
	for stat_id in FAVORITE_STATS:
		if Stats.registry.has_stat(stat_id):
			ordered.append(stat_id)
	for stat_id in Stats.stat_ids():
		if not ordered.has(stat_id):
			ordered.append(stat_id)
	for stat_id in ordered:
		var stat_row := DevStatRow.new(stat_id)
		_rows[stat_id] = stat_row
		box.add_child(stat_row)
	return box


func _build_economy_tab() -> Control:
	var box := VBoxContainer.new()
	_add_currency_controls(box, Wallet.MONEY, MONEY_STEPS)
	_add_currency_controls(box, Wallet.STARS, STAR_STEPS)
	return box


func _add_currency_controls(box: VBoxContainer, currency: StringName, steps: Array[float]) -> void:
	var balance_label := DevUi.section("")
	_currency_labels[currency] = balance_label
	box.add_child(balance_label)
	var buttons: Array[Control] = []
	for amount in steps:
		buttons.append(
			DevUi.button("+" + Economy.format(amount), Economy.earn.bind(currency, amount))
		)
	box.add_child(DevUi.flow(buttons))
	var amount_spin := DevUi.spin(0.0, 1e15, 1.0, 0.0)
	var set_button := DevUi.button(
		tr("DEV_SET"),
		func() -> void: GameState.data.wallet.set_balance(currency, amount_spin.value)
	)
	box.add_child(DevUi.flow([amount_spin, set_button]))


func _build_time_tab() -> Control:
	var box := VBoxContainer.new()
	_time_label = DevUi.section("")
	box.add_child(_time_label)
	_time_slider = HSlider.new()
	_time_slider.min_value = TIME_SCALE_MIN
	_time_slider.max_value = TIME_SCALE_MAX
	_time_slider.step = 0.05
	_time_slider.value = Engine.time_scale
	_time_slider.value_changed.connect(_set_time_scale)
	box.add_child(_time_slider)
	var presets: Array[Control] = []
	for scale in TIME_SCALE_PRESETS:
		presets.append(
			DevUi.button(DevUi.num(scale) + "×", func() -> void: _time_slider.value = scale)
		)
	box.add_child(DevUi.flow(presets))
	box.add_child(
		DevUi.toggle(tr("DEV_PAUSE"), func(paused: bool) -> void: get_tree().paused = paused)
	)
	_set_time_scale(Engine.time_scale)
	return box


func _build_world_tab() -> Control:
	var box := VBoxContainer.new()
	_item_picker = OptionButton.new()
	for item_id in ContentDB.item_ids():
		var item_def := ContentDB.item_def(item_id)
		_item_picker.add_item(tr(item_def.name_key) if item_def != null else String(item_id))
		_item_picker.set_item_metadata(_item_picker.item_count - 1, item_id)
	box.add_child(DevUi.flow([DevUi.label(tr("DEV_ITEM")), _item_picker]))
	box.add_child(DevUi.button(tr("DEV_FILL_CARRY"), _fill_player_stack))
	box.add_child(DevUi.button(tr("DEV_EMPTY_CARRY"), _empty_player_stack))
	box.add_child(DevUi.button(tr("DEV_FILL_PRODUCERS"), _fill_producers))
	box.add_child(DevUi.button(tr("DEV_FILL_COUNTERS"), _fill_counters))
	box.add_child(
		DevUi.button(
			tr("DEV_RIPEN_FIELDS"),
			func() -> void: get_tree().call_group(&"crop_field", &"ripen_all")
		)
	)
	box.add_child(DevUi.button(tr("DEV_SPAWN_CUSTOMER"), _spawn_customer))
	box.add_child(DevUi.toggle(tr("DEV_SHOW_FPS"), _set_show_fps))
	box.add_child(DevUi.button(tr("DEV_TOGGLE_ORIENTATION"), _toggle_orientation))
	return box


func _on_stat_changed(stat_id: StringName, _value: float) -> void:
	if _rows.has(stat_id):
		_rows[stat_id].refresh()
	_refresh_overlay()


func _on_currency_changed() -> void:
	if _currency_labels.has(Wallet.MONEY):
		_currency_labels[Wallet.MONEY].text = (
			tr("DEV_MONEY") % Economy.format(Economy.balance(Wallet.MONEY))
		)
		_currency_labels[Wallet.STARS].text = (
			tr("DEV_STARS") % Economy.format(Economy.balance(Wallet.STARS))
		)


func _refresh_overlay() -> void:
	var count := Stats.registry.dev_overrides().size()
	var lines := PackedStringArray()
	if count > 0:
		lines.append(tr("DEV_BADGE") % count)
	if _show_fps:
		(
			lines
			. append(
				(
					tr("DEV_FPS")
					% [
						Performance.get_monitor(Performance.TIME_FPS),
						Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					]
				)
			)
		)
	_overlay.text = "\n".join(lines)
	_header_info.text = tr("DEV_OVERRIDES_ACTIVE") % count


func _set_status(message: String) -> void:
	_status.text = message


func _clear_overrides() -> void:
	Stats.clear_all_dev_overrides()
	_set_status(tr("DEV_DONE"))


func _set_time_scale(value: float) -> void:
	Engine.time_scale = value
	_time_label.text = tr("DEV_TIME_SCALE") % DevUi.num(value)


func _set_show_fps(enabled: bool) -> void:
	_show_fps = enabled
	_refresh_overlay()


func _selected_item() -> StringName:
	if _item_picker.selected < 0:
		return &""
	return _item_picker.get_item_metadata(_item_picker.selected)


func _fill_player_stack() -> void:
	for player in get_tree().get_nodes_in_group(&"player"):
		_fill((player as Player).carry_visual.container, _selected_item())


func _empty_player_stack() -> void:
	for player in get_tree().get_nodes_in_group(&"player"):
		(player as Player).carry_visual.container.clear()


func _fill_producers() -> void:
	for node in get_tree().get_nodes_in_group(&"producer"):
		var producer := node as Producer
		_fill(producer.output, producer.item_id)


func _fill_counters() -> void:
	for node in get_tree().get_nodes_in_group(&"counter"):
		var counter := node as Counter
		_fill(counter.stock, counter.item_id)


func _fill(container: ItemContainer, item_id: StringName) -> void:
	if item_id.is_empty():
		return
	for i in container.free_space():
		if not container.push(item_id):
			break


func _spawn_customer() -> void:
	var spawned := false
	for spawner in get_tree().get_nodes_in_group(&"customer_spawner"):
		spawned = (spawner as CustomerSpawner).spawn_now() or spawned
	_set_status(tr("DEV_DONE") if spawned else tr("DEV_FAILED"))


func _toggle_orientation() -> void:
	var window := get_window()
	window.size = PORTRAIT_WINDOW if window.size.x > window.size.y else LANDSCAPE_WINDOW
