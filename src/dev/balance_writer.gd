class_name BalanceWriter
extends RefCounted
## Writes tuned stat bases back into data/balance/stats.json, keeping the file's format
## (one stat per line, blank line between prefix groups) so diffs stay small.

const KEY_ORDER: Array[String] = ["base", "min", "max", "integer"]
## Bases closer than this are considered unchanged.
const EPSILON: float = 1e-9


## [{id, old, new}] for every stat whose base in `registry` differs from `original_stats`.
static func changed_bases(original_stats: Dictionary, registry: StatRegistry) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	for stat_id: String in original_stats:
		if not registry.has_stat(StringName(stat_id)):
			continue
		var old_base := float(original_stats[stat_id].get("base", 0.0))
		var new_base := registry.get_base(StringName(stat_id))
		if absf(new_base - old_base) > EPSILON:
			changes.append({"id": stat_id, "old": old_base, "new": new_base})
	return changes


static func with_bases(original_stats: Dictionary, changes: Array[Dictionary]) -> Dictionary:
	var updated := original_stats.duplicate(true)
	for change in changes:
		if updated.has(change["id"]):
			updated[change["id"]]["base"] = change["new"]
	return updated


static func format_stats(raw: Dictionary) -> String:
	var lines := PackedStringArray()
	var previous_prefix := ""
	var ids: Array = raw.keys()
	for index in ids.size():
		var stat_id: String = ids[index]
		var prefix := stat_id.get_slice(".", 0)
		if index > 0 and prefix != previous_prefix:
			lines.append("")
		previous_prefix = prefix
		var separator := "," if index < ids.size() - 1 else ""
		lines.append('  "%s": %s%s' % [stat_id, _format_entry(raw[stat_id]), separator])
	return "{\n%s\n}\n" % "\n".join(lines)


static func write_stats(path: String, raw: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s: %s" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(format_stats(raw))
	file.close()
	return true


static func _format_entry(entry: Dictionary) -> String:
	var is_integer := bool(entry.get("integer", false))
	var parts := PackedStringArray()
	for key in KEY_ORDER:
		if not entry.has(key):
			continue
		var value: Variant = entry[key]
		var text: String
		if typeof(value) == TYPE_BOOL:
			text = "true" if value else "false"
		else:
			text = _format_number(float(value), is_integer)
		parts.append('"%s": %s' % [key, text])
	return "{ %s }" % ", ".join(parts)


static func _format_number(value: float, is_integer: bool) -> String:
	if is_integer:
		return str(roundi(value))
	if value == floorf(value):
		return "%.1f" % value
	return str(value)
