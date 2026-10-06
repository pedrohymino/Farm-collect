class_name BalanceData
extends RefCounted
## All tunable numbers, loaded from data/balance/*.json and validated.
## Gameplay never reads this directly: stats go through the Stats autoload.

const STATS_FILE: String = "stats.json"
const ITEMS_FILE: String = "items.json"
const PROGRESSION_FILE: String = "progression.json"
const PRODUCERS_FILE: String = "producers.json"
const UNLOCKS_FILE: String = "unlocks.json"
const UPGRADES_FILE: String = "upgrades.json"
const PASSIVES_FILE: String = "passives.json"
const ITEM_STAGES: Array[String] = ["raw", "processed"]
const SCOPED_ITEM_STATS: Array[String] = ["production.rate", "sell.price"]

var stats: Dictionary = {}
var items: Dictionary = {}
var progression: Dictionary = {}
var producers: Dictionary = {}
var unlocks: Dictionary = {}
var upgrades: Dictionary = {}
var passives: Dictionary = {}
var errors: PackedStringArray = PackedStringArray()


static func load_from_dir(dir_path: String) -> BalanceData:
	var data := BalanceData.new()
	data.stats = data._load_json(dir_path.path_join(STATS_FILE))
	data.items = data._load_json(dir_path.path_join(ITEMS_FILE))
	data.progression = data._load_json(dir_path.path_join(PROGRESSION_FILE))
	data.producers = data._load_json(dir_path.path_join(PRODUCERS_FILE))
	data.unlocks = data._load_json(dir_path.path_join(UNLOCKS_FILE))
	data.upgrades = data._load_json(dir_path.path_join(UPGRADES_FILE))
	data.passives = data._load_json(dir_path.path_join(PASSIVES_FILE))
	data.errors.append_array(validate_stats(data.stats))
	data.errors.append_array(validate_items(data.items))
	data.errors.append_array(validate_progression(data.progression))
	data.errors.append_array(validate_item_stats(data.items, data.stats))
	data.errors.append_array(validate_producers(data.producers, data.items))
	data.errors.append_array(UnlockRules.validate(data.unlocks, data.producers, data.stats))
	data.errors.append_array(UpgradeRules.validate(data.upgrades, data.stats))
	data.errors.append_array(PassiveRules.validate(data.passives, data.stats))
	return data


static func validate_stats(raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for stat_id: String in raw:
		var entry: Variant = raw[stat_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("stat '%s' must be an object" % stat_id)
		elif not _is_number(entry.get("base")):
			found.append("stat '%s' needs a numeric 'base'" % stat_id)
		elif float(entry.get("min", -INF)) > float(entry.get("max", INF)):
			found.append("stat '%s' has min > max" % stat_id)
	return found


static func validate_items(raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for item_id: String in raw:
		var entry: Variant = raw[item_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("item '%s' must be an object" % item_id)
		elif not _is_positive(entry.get("base_price")):
			found.append("item '%s' needs a positive 'base_price'" % item_id)
		elif not _is_positive(entry.get("production_seconds")):
			found.append("item '%s' needs a positive 'production_seconds'" % item_id)
		elif not ITEM_STAGES.has(entry.get("stage")):
			found.append("item '%s' has invalid 'stage' (expected %s)" % [item_id, ITEM_STAGES])
	return found


static func validate_progression(raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	if not _is_positive(raw.get("xp_base")):
		found.append("progression needs a positive 'xp_base'")
	if not _is_number(raw.get("xp_growth")) or float(raw.get("xp_growth")) < 1.0:
		found.append("progression needs 'xp_growth' >= 1")
	if not _is_number(raw.get("stars_per_level")) or float(raw.get("stars_per_level")) < 0.0:
		found.append("progression needs 'stars_per_level' >= 0")
	return found


## Every item must have its scoped stats (production.rate.<item>, sell.price.<item>).
static func validate_item_stats(items_raw: Dictionary, stats_raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for item_id: String in items_raw:
		for prefix in SCOPED_ITEM_STATS:
			var stat_id := "%s.%s" % [prefix, item_id]
			if not stats_raw.has(stat_id):
				found.append("item '%s' is missing stat '%s'" % [item_id, stat_id])
	return found


static func validate_producers(raw: Dictionary, items_raw: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for producer_id: String in raw:
		var entry: Variant = raw[producer_id]
		if typeof(entry) != TYPE_DICTIONARY:
			found.append("producer '%s' must be an object" % producer_id)
		elif not items_raw.has(entry.get("item", "")):
			found.append(
				"producer '%s' produces unknown item '%s'" % [producer_id, entry.get("item")]
			)
		elif not _is_positive(entry.get("base_units")) or not _is_number(entry.get("max_units")):
			found.append("producer '%s' needs positive 'base_units' and 'max_units'" % producer_id)
		elif float(entry["base_units"]) > float(entry["max_units"]):
			found.append("producer '%s' has base_units > max_units" % producer_id)
	return found


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT


static func _is_positive(value: Variant) -> bool:
	return _is_number(value) and float(value) > 0.0


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("missing balance file: %s" % path)
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append(
			(
				"invalid JSON in %s (line %d): %s"
				% [path, parser.get_error_line(), parser.get_error_message()]
			)
		)
		return {}
	if typeof(parser.data) != TYPE_DICTIONARY:
		errors.append("%s must contain a JSON object" % path)
		return {}
	return parser.data
