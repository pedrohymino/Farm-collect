class_name SettingsData
extends RefCounted
## Player settings (docs/02-game-design.md: volume, language, vibration, graphics quality).
## Pure data: from_dict() is tolerant and clamps, so a hand-edited file can never break the game.

enum Quality { LOW, MEDIUM, HIGH }

const LANGUAGES: Array[String] = ["auto", "en", "pt_BR"]
const DEFAULT_LANGUAGE: String = "en"
const SILENT_DB: float = -80.0
const MIN_AUDIBLE: float = 0.001

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var language: String = "auto"
var vibration: bool = true
var quality: Quality = Quality.MEDIUM


static func from_dict(raw: Dictionary) -> SettingsData:
	var data := SettingsData.new()
	data.master_volume = _volume(raw.get("master_volume"), data.master_volume)
	data.music_volume = _volume(raw.get("music_volume"), data.music_volume)
	data.sfx_volume = _volume(raw.get("sfx_volume"), data.sfx_volume)
	var language_value: Variant = raw.get("language")
	if typeof(language_value) == TYPE_STRING and LANGUAGES.has(language_value):
		data.language = language_value
	var vibration_value: Variant = raw.get("vibration")
	if typeof(vibration_value) == TYPE_BOOL:
		data.vibration = vibration_value
	var quality_value: Variant = raw.get("quality")
	if typeof(quality_value) == TYPE_INT or typeof(quality_value) == TYPE_FLOAT:
		data.quality = clampi(int(quality_value), Quality.LOW, Quality.HIGH) as Quality
	return data


func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"language": language,
		"vibration": vibration,
		"quality": int(quality),
	}


func duplicate_data() -> SettingsData:
	return SettingsData.from_dict(to_dict())


func is_equal_to(other: SettingsData) -> bool:
	return to_dict() == other.to_dict()


## 0..1 slider value to decibels; effectively zero is a full mute.
static func volume_to_db(volume: float) -> float:
	if volume <= MIN_AUDIBLE:
		return SILENT_DB
	return linear_to_db(clampf(volume, 0.0, 1.0))


## "auto" follows the system language (Portuguese or English); explicit choices are kept.
static func resolve_locale(language_setting: String, system_locale: String) -> String:
	if language_setting != "auto":
		return language_setting
	return "pt_BR" if system_locale.begins_with("pt") else DEFAULT_LANGUAGE


static func _volume(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return clampf(float(value), 0.0, 1.0)
	return fallback
