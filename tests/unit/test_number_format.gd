extends GutTest


func test_small_numbers_are_floored_integers() -> void:
	assert_eq(NumberFormat.format(0.0), "0")
	assert_eq(NumberFormat.format(12.9), "12")
	assert_eq(NumberFormat.format(999.99), "999")


func test_thousands_use_k_with_one_decimal() -> void:
	assert_eq(NumberFormat.format(1000.0), "1K")
	assert_eq(NumberFormat.format(1200.0), "1.2K")
	assert_eq(NumberFormat.format(12_550.0), "12.5K")


func test_hundreds_of_a_unit_have_no_decimals() -> void:
	assert_eq(NumberFormat.format(123_456.0), "123K")


func test_never_rounds_up() -> void:
	assert_eq(NumberFormat.format(1999.0), "1.9K")
	assert_eq(NumberFormat.format(999_999.0), "999K")


func test_named_suffixes() -> void:
	assert_eq(NumberFormat.format(3.4e6), "3.4M")
	assert_eq(NumberFormat.format(5.6e9), "5.6B")
	assert_eq(NumberFormat.format(7.8e12), "7.8T")


func test_letter_suffixes_after_trillions() -> void:
	assert_eq(NumberFormat.format(1e15), "1aa")
	assert_eq(NumberFormat.format(2.5e18), "2.5ab")
	assert_eq(NumberFormat.format(1e15 * pow(1000.0, 26)), "1ba")


func test_negative_numbers_keep_sign() -> void:
	assert_eq(NumberFormat.format(-1500.0), "-1.5K")
