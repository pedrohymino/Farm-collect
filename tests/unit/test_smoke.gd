extends GutTest
## Sanity checks for the project setup (M0).

const AUTOLOADS: Array[String] = [
	"EventBus",
	"ContentDB",
	"Stats",
	"GameState",
	"Economy",
	"SaveManager",
	"DevMode",
]

var _previous_locale: String


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_all_autoloads_are_registered() -> void:
	for autoload_name in AUTOLOADS:
		assert_not_null(get_node_or_null("/root/" + autoload_name), autoload_name + " missing")


func test_translates_to_portuguese() -> void:
	TranslationServer.set_locale("pt_BR")
	assert_eq(TranslationServer.translate("MENU_PLAY"), "Jogar")


func test_translates_to_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(TranslationServer.translate("MENU_PLAY"), "Play")


func test_dev_mode_enabled_in_debug_builds() -> void:
	var dev_mode: Node = get_node("/root/DevMode")
	assert_eq(dev_mode.is_enabled, OS.is_debug_build() or OS.has_feature("dev"))
