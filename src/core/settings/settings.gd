extends Node
## Live player settings (autoload "Settings"): loads them at startup, applies them to the
## engine (audio buses, language, graphics quality) and saves every change.

signal changed

const PATH: String = "user://settings.cfg"
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const SUN_GROUP: StringName = &"sun"

var data: SettingsData = SettingsData.new()

var _store: SettingsStore = SettingsStore.new(PATH)


func _ready() -> void:
	data = _store.load_settings()
	get_tree().node_added.connect(_on_node_added)
	apply()


## Replaces the settings, saves them and applies them everywhere.
func update(new_data: SettingsData) -> void:
	data = new_data.duplicate_data()
	_store.save_settings(data)
	apply()
	changed.emit()


func apply() -> void:
	_set_bus_volume(BUS_MASTER, data.master_volume)
	_set_bus_volume(BUS_MUSIC, data.music_volume)
	_set_bus_volume(BUS_SFX, data.sfx_volume)
	TranslationServer.set_locale(SettingsData.resolve_locale(data.language, OS.get_locale()))
	var profile := QualityProfile.for_level(data.quality)
	var root := get_tree().root
	root.msaa_3d = profile["msaa"]
	root.scaling_3d_scale = profile["render_scale"]
	for node in get_tree().get_nodes_in_group(SUN_GROUP):
		_apply_shadows(node, profile["shadows"])


func _set_bus_volume(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, SettingsData.volume_to_db(volume))
	AudioServer.set_bus_mute(index, volume <= SettingsData.MIN_AUDIBLE)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(SUN_GROUP):
		_apply_shadows(node, QualityProfile.for_level(data.quality)["shadows"])


func _apply_shadows(node: Node, enabled: bool) -> void:
	var light := node as DirectionalLight3D
	if light != null:
		light.shadow_enabled = enabled
