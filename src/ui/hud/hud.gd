extends CanvasLayer
## Top bar: farm level + XP bar, money (rolls and pulses on gains), stars + passive tree button.
## Also shows the "Level X!" banner.

const ROLL_TIME: float = 0.35
const PULSE_SCALE: float = 1.15
const PULSE_TIME: float = 0.15
const BAR_FONT_SIZE: int = 56
const LEVEL_FONT_SIZE: int = 44
const BADGE_SIZE: Vector2 = Vector2(84, 84)
const ICON_SIZE: Vector2 = Vector2(64, 44)
const XP_BAR_SIZE: Vector2 = Vector2(170, 26)
const PANEL_COLOR: Color = Color(0.1, 0.12, 0.15, 0.75)
const BANNER_FONT_SIZE: int = 120
const PAUSE_BUTTON_WIDTH: float = 96.0
const PAUSE_BUTTON_MARGIN: float = 32.0
const PAUSE_BUTTON_TOP: float = 150.0
const BANNER_TOP: float = 0.28
const BANNER_HOLD_SEC: float = 1.2
const BANNER_FADE_SEC: float = 0.4

var _shown_money: float = 0.0
var _roll_tween: Tween
var _pulse_tween: Tween
var _money_label: Label
var _money_panel: PanelContainer
var _stars_label: Label
var _tree_button: Button
var _level_label: Label
var _xp_bar: ProgressBar
var _banner: Label


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", 32)
	margin.add_theme_constant_override(&"margin_right", 32)
	margin.add_theme_constant_override(&"margin_top", 48)
	add_child(margin)
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(bar)
	bar.add_child(_build_level_box())
	bar.add_child(_spacer())
	_money_panel = _build_money_box()
	bar.add_child(_money_panel)
	bar.add_child(_spacer())
	bar.add_child(_build_stars_box())
	_build_banner()
	_build_pause_button()

	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.xp_changed.connect(_refresh_level.unbind(2))
	EventBus.level_up.connect(_show_level_up)
	GameState.data_replaced.connect(_refresh_all)
	_refresh_all()


func _refresh_all() -> void:
	_shown_money = Economy.balance(Wallet.MONEY)
	_render_money(_shown_money)
	_stars_label.text = Economy.format(Economy.balance(Wallet.STARS))
	_refresh_level()


func _on_currency_changed(currency: StringName, balance: float) -> void:
	if currency == Wallet.STARS:
		_stars_label.text = Economy.format(balance)
		return
	if currency != Wallet.MONEY:
		return
	if balance > _shown_money:
		_pulse()
	if _roll_tween != null:
		_roll_tween.kill()
	_roll_tween = create_tween()
	_roll_tween.tween_method(_render_money, _shown_money, balance, ROLL_TIME)


func _render_money(value: float) -> void:
	_shown_money = value
	_money_label.text = Economy.format(value)


func _refresh_level() -> void:
	_level_label.text = str(GameState.data.farm_level)
	_xp_bar.value = Progression.level_progress()


func _pulse() -> void:
	_money_panel.pivot_offset = _money_panel.size * 0.5
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_money_panel, "scale", Vector2.ONE * PULSE_SCALE, PULSE_TIME * 0.5)
	_pulse_tween.tween_property(_money_panel, "scale", Vector2.ONE, PULSE_TIME).set_trans(
		Tween.TRANS_BACK
	)


func _show_level_up(level: int) -> void:
	_refresh_level()
	_banner.text = tr("HUD_LEVEL_UP") % level
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(BANNER_HOLD_SEC)
	tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE_SEC)
	tween.tween_callback(func() -> void: _banner.visible = false)


func _build_level_box() -> PanelContainer:
	var panel := _dark_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	var badge := UiKit.swatch(UiKit.YELLOW, BADGE_SIZE)
	_level_label = _label("", LEVEL_FONT_SIZE)
	_level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(_level_label)
	row.add_child(badge)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = XP_BAR_SIZE
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.max_value = 1.0
	_xp_bar.step = 0.0
	_xp_bar.show_percentage = false
	_xp_bar.add_theme_stylebox_override(&"background", _bar_style(Color(0, 0, 0, 0.45)))
	_xp_bar.add_theme_stylebox_override(&"fill", _bar_style(UiKit.GREEN))
	row.add_child(_xp_bar)
	panel.add_child(row)
	return panel


func _build_money_box() -> PanelContainer:
	var panel := _dark_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	row.add_child(UiKit.swatch(UiKit.GREEN, ICON_SIZE))
	_money_label = _label("0", BAR_FONT_SIZE)
	_money_label.custom_minimum_size.x = 140.0
	row.add_child(_money_label)
	panel.add_child(row)
	return panel


func _build_stars_box() -> PanelContainer:
	var panel := _dark_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	row.add_child(UiKit.swatch(UiKit.YELLOW, Vector2(48, 48)))
	_stars_label = _label("0", BAR_FONT_SIZE)
	row.add_child(_stars_label)
	_tree_button = UiKit.button(
		tr("HUD_TREE"), UiKit.YELLOW.darkened(0.15), EventBus.passive_tree_requested.emit
	)
	_tree_button.add_theme_font_size_override(&"font_size", UiKit.SMALL_SIZE)
	row.add_child(_tree_button)
	panel.add_child(row)
	return panel


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _tree_button != null:
		_tree_button.text = tr("HUD_TREE")


func _build_pause_button() -> void:
	var button := UiKit.button(
		tr("HUD_PAUSE"), UiKit.GRAY.darkened(0.3), EventBus.pause_requested.emit
	)
	button.add_theme_font_size_override(&"font_size", UiKit.SMALL_SIZE)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -PAUSE_BUTTON_WIDTH - PAUSE_BUTTON_MARGIN
	button.offset_right = -PAUSE_BUTTON_MARGIN
	button.offset_top = PAUSE_BUTTON_TOP
	add_child(button)


func _build_banner() -> void:
	_banner = _label("", BANNER_FONT_SIZE)
	_banner.add_theme_color_override(&"font_color", UiKit.YELLOW)
	_banner.add_theme_constant_override(&"outline_size", 24)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = BANNER_TOP
	_banner.anchor_bottom = BANNER_TOP
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color(0.05, 0.05, 0.05))
	label.add_theme_constant_override(&"outline_size", 10)
	return label


func _dark_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(40)
	style.content_margin_left = 22.0
	style.content_margin_right = 26.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override(&"panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(13)
	return style


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer
