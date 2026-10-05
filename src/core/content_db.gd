extends Node
## Loads balance data (data/balance/*.json) and content definitions (data/content/**.tres)
## at startup and reports every problem clearly.

const BALANCE_DIR: String = "res://data/balance"
const ITEMS_DIR: String = "res://data/content/items"

var balance: BalanceData
var errors: PackedStringArray = PackedStringArray()

var _item_defs: Dictionary = {}  # StringName -> ItemDef


func _init() -> void:
	reload()


func reload() -> void:
	balance = BalanceData.load_from_dir(BALANCE_DIR)
	_item_defs = load_item_defs(ITEMS_DIR)
	errors = balance.errors.duplicate()
	errors.append_array(validate_item_defs(_item_defs, balance.items))
	for message in errors:
		push_error("Content: " + message)


static func load_item_defs(dir_path: String) -> Dictionary:
	var defs := {}
	if not DirAccess.dir_exists_absolute(dir_path):
		return defs
	# list_directory handles exported (remapped) resources, unlike DirAccess.get_files().
	for file_name in ResourceLoader.list_directory(dir_path):
		if not file_name.ends_with(".tres"):
			continue
		var item_def := load(dir_path.path_join(file_name)) as ItemDef
		if item_def != null:
			defs[item_def.id] = item_def
	return defs


## Every balance item needs an ItemDef with visuals, and vice versa.
static func validate_item_defs(defs: Dictionary, items_raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for item_id: String in items_raw:
		var item_def: ItemDef = defs.get(StringName(item_id))
		if item_def == null:
			found.append("item '%s' has no ItemDef in data/content/items" % item_id)
		elif item_def.visual_scene == null:
			found.append("ItemDef '%s' has no visual_scene" % item_id)
	for item_id: StringName in defs:
		if not items_raw.has(String(item_id)):
			found.append("ItemDef '%s' has no entry in items.json" % item_id)
	return found


func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item_id: String in balance.items:
		ids.append(StringName(item_id))
	return ids


func item_def(item_id: StringName) -> ItemDef:
	var found: ItemDef = _item_defs.get(item_id)
	if found == null:
		push_error("Unknown item: %s" % item_id)
	return found


func item_base_price(item_id: StringName) -> float:
	return float(balance.items.get(String(item_id), {}).get("base_price", 0.0))


func item_production_seconds(item_id: StringName) -> float:
	return float(balance.items.get(String(item_id), {}).get("production_seconds", 0.0))


func producer_item(producer_id: StringName) -> StringName:
	return StringName(_producer(producer_id).get("item", ""))


func producer_base_units(producer_id: StringName) -> int:
	return int(_producer(producer_id).get("base_units", 0))


func producer_max_units(producer_id: StringName) -> int:
	return int(_producer(producer_id).get("max_units", 0))


func _producer(producer_id: StringName) -> Dictionary:
	var entry: Variant = balance.producers.get(String(producer_id))
	if typeof(entry) != TYPE_DICTIONARY:
		push_error("Unknown producer: %s" % producer_id)
		return {}
	return entry
