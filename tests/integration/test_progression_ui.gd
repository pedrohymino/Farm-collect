extends GutTest
## Upgrade menu and passive tree screens driving the real Progression autoload.

var menu: UpgradeMenu
var tree: PassiveTreeScreen


func before_each() -> void:
	GameState.new_game()
	menu = UpgradeMenu.new()
	add_child_autofree(menu)
	tree = PassiveTreeScreen.new()
	add_child_autofree(tree)


func after_each() -> void:
	GameState.new_game()


func test_menu_opens_and_closes_with_the_board_events() -> void:
	assert_false(menu.is_open())
	EventBus.upgrade_board_entered.emit()
	assert_true(menu.is_open())
	EventBus.upgrade_board_exited.emit()
	assert_false(menu.is_open())


func test_buy_button_is_disabled_without_money() -> void:
	assert_true(menu.buy_button(&"backpack").disabled)
	Economy.earn(Wallet.MONEY, 1000.0)
	assert_false(menu.buy_button(&"backpack").disabled)


func test_pressing_buy_purchases_the_upgrade() -> void:
	Economy.earn(Wallet.MONEY, 1000.0)
	menu.buy_button(&"backpack").pressed.emit()
	assert_eq(Progression.upgrade_level(&"backpack"), 1)


func test_tree_has_a_button_per_node_and_opens_on_request() -> void:
	for node_id in Progression.passives.ids():
		assert_not_null(tree.node_button(node_id), String(node_id))
	assert_false(tree.visible)
	EventBus.passive_tree_requested.emit()
	assert_true(tree.visible)


func test_selecting_and_buying_a_node() -> void:
	Economy.earn(Wallet.STARS, 1.0)
	tree.select(&"farmer_1")
	assert_true(tree.buy_selected())
	assert_eq(Progression.passive_state(&"farmer_1"), PassiveRules.NodeState.OWNED)
	tree.select(&"farmer_3")
	assert_false(tree.buy_selected())


func test_key_nodes_have_names() -> void:
	assert_ne(tree.passive_name(&"farmer_key"), "PASSIVE_FARMER_KEY")
	assert_string_contains(tree.passive_name(&"farmer_2"), "II")


func test_locked_branch_root_explains_it_needs_the_first_helper() -> void:
	var previous_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("pt_BR")
	assert_string_contains(tree.lock_text(&"automation_1"), "Caixa")
	TranslationServer.set_locale(previous_locale)
	assert_eq(tree.lock_text(&"farmer_1"), "")
	assert_ne(tree.lock_text(&"farmer_2"), "")


func test_branch_opens_after_the_first_helper() -> void:
	Economy.earn(Wallet.STARS, 5.0)
	assert_false(Progression.can_buy_passive(&"automation_1"))
	Unlocks.complete(&"cashier_egg")
	assert_true(Progression.can_buy_passive(&"automation_1"))
	assert_eq(tree.lock_text(&"automation_1"), "")
