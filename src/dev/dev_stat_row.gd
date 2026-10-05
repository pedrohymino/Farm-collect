class_name DevStatRow
extends PanelContainer
## One stat in the dev panel: final value, dev multiplier / fixed value, base, reset,
## "apply to base" and a one-line breakdown of where the value comes from.

const MULTIPLIER_MAX: float = 1000.0
const VALUE_LIMIT: float = 1e12
const STEP: float = 0.01
const DECIMALS: int = 3
const OVERRIDE_TINT: Color = Color(1.0, 0.85, 0.5)

var stat_id: StringName

var _final_label: Label
var _breakdown_label: Label
var _multiplier: SpinBox
var _fixed: CheckBox
var _fixed_value: SpinBox
var _base: SpinBox
var _updating: bool = false


func _init(p_stat_id: StringName) -> void:
	stat_id = p_stat_id
	var box := VBoxContainer.new()
	add_child(box)

	var header := HBoxContainer.new()
	var name_label := DevUi.label(String(stat_id))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	_final_label = DevUi.label("")
	header.add_child(name_label)
	header.add_child(_final_label)
	box.add_child(header)

	_multiplier = DevUi.spin(0.0, MULTIPLIER_MAX, STEP, 1.0)
	_multiplier.value_changed.connect(_on_override_input.unbind(1))
	_fixed = CheckBox.new()
	_fixed.text = tr("DEV_FIXED")
	_fixed.toggled.connect(_on_override_input.unbind(1))
	_fixed_value = DevUi.spin(-VALUE_LIMIT, VALUE_LIMIT, STEP, 0.0)
	_fixed_value.value_changed.connect(_on_override_input.unbind(1))
	_base = DevUi.spin(-VALUE_LIMIT, VALUE_LIMIT, STEP, 0.0)
	_base.value_changed.connect(_on_base_input)
	(
		box
		. add_child(
			(
				DevUi
				. flow(
					[
						DevUi.label(tr("DEV_MULTIPLIER")),
						_multiplier,
						_fixed,
						_fixed_value,
						DevUi.label(tr("DEV_BASE")),
						_base,
						DevUi.button(tr("DEV_RESET"), reset),
						DevUi.button(tr("DEV_BAKE"), bake),
					]
				)
			)
		)
	)

	_breakdown_label = DevUi.label("", DevUi.SMALL_FONT_SIZE)
	_breakdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_breakdown_label.add_theme_color_override(&"font_color", DevUi.MUTED_COLOR)
	box.add_child(_breakdown_label)
	refresh()


static func format_value(value: float, is_integer: bool) -> String:
	if is_integer:
		return str(roundi(value))
	return String.num(value, DECIMALS)


func refresh() -> void:
	var info := Stats.breakdown(stat_id)
	var dev: Dictionary = info["dev"]
	var is_integer: bool = info["is_integer"]
	_updating = true
	_final_label.text = format_value(info["final"], is_integer)
	_base.value = info["base"]
	_multiplier.value = dev.get("multiplier", 1.0)
	_fixed.button_pressed = dev.get("absolute") != null
	_fixed_value.value = dev["absolute"] if dev.get("absolute") != null else info["final"]
	_breakdown_label.text = (
		tr("DEV_BREAKDOWN")
		% [
			format_value(info["base"], is_integer),
			_modifiers_text(info["modifiers"], dev),
			format_value(info["final"], is_integer),
		]
	)
	self_modulate = OVERRIDE_TINT if not dev.is_empty() else Color.WHITE
	_updating = false


func set_multiplier(value: float) -> void:
	_multiplier.value = value


func set_fixed(enabled: bool, value: float) -> void:
	_fixed_value.value = value
	_fixed.button_pressed = enabled


func set_base_value(value: float) -> void:
	_base.value = value


## Clears the override and restores the base from the balance file.
func reset() -> void:
	Stats.clear_dev_override(stat_id)
	var original: Dictionary = ContentDB.balance.stats.get(String(stat_id), {})
	Stats.set_base(stat_id, float(original.get("base", Stats.registry.get_base(stat_id))))


## Turns the current override into the base value, then clears the override.
func bake() -> void:
	var info := Stats.breakdown(stat_id)
	var dev: Dictionary = info["dev"]
	if dev.is_empty():
		return
	var new_base: float = info["base"] * float(dev["multiplier"])
	if dev["absolute"] != null:
		new_base = float(dev["absolute"])
	Stats.clear_dev_override(stat_id)
	Stats.set_base(stat_id, new_base)


func _on_override_input() -> void:
	if _updating:
		return
	var absolute: Variant = _fixed_value.value if _fixed.button_pressed else null
	if is_equal_approx(_multiplier.value, 1.0) and absolute == null:
		Stats.clear_dev_override(stat_id)
	else:
		Stats.set_dev_override(stat_id, _multiplier.value, absolute)


func _on_base_input(value: float) -> void:
	if not _updating:
		Stats.set_base(stat_id, value)


func _modifiers_text(modifiers: Array, dev: Dictionary) -> String:
	var parts := PackedStringArray()
	for modifier: Dictionary in modifiers:
		var value: float = modifier["value"]
		var amount: String
		match modifier["type"]:
			Modifier.Type.FLAT:
				amount = DevUi.signed_num(value)
			Modifier.Type.PERCENT:
				amount = DevUi.signed_num(value * 100.0) + "%"
			_:
				amount = "×" + DevUi.num(value)
		parts.append("%s %s" % [modifier["source_id"], amount])
	if not dev.is_empty():
		var dev_amount := "×" + DevUi.num(float(dev["multiplier"]))
		if dev["absolute"] != null:
			dev_amount = "=" + DevUi.num(float(dev["absolute"]))
		parts.append("%s %s" % [tr("DEV_OVERRIDE_TAG"), dev_amount])
	if parts.is_empty():
		return tr("DEV_NO_MODIFIERS")
	return ", ".join(parts)
