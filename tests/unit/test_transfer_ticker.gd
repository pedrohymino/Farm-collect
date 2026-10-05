extends GutTest


func test_first_transfer_is_immediate() -> void:
	var ticker := TransferTicker.new()
	assert_eq(ticker.consume(0.0, 8.0), 1)


func test_rate_limits_transfers_per_second() -> void:
	var ticker := TransferTicker.new()
	ticker.consume(0.0, 10.0)
	var total := 0
	for i in 60:
		total += ticker.consume(1.0 / 60.0, 10.0)
	assert_eq(total, 10)


func test_large_delta_allows_many_transfers() -> void:
	var ticker := TransferTicker.new()
	ticker.consume(0.0, 4.0)
	assert_eq(ticker.consume(1.0, 4.0), 4)


func test_reset_makes_next_transfer_immediate_again() -> void:
	var ticker := TransferTicker.new()
	ticker.consume(0.0, 2.0)
	assert_eq(ticker.consume(0.1, 2.0), 0)
	ticker.reset()
	assert_eq(ticker.consume(0.0, 2.0), 1)
