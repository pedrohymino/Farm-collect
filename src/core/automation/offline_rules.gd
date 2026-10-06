class_name OfflineRules
extends RefCounted
## Money earned while the game was closed (docs/03-economia-e-balanceamento.md, section 8).
## earnings = automated income/s × min(time away, max_hours) × efficiency.

const SECONDS_PER_HOUR: float = 3600.0
## Shorter absences don't trigger the popup.
const MIN_AWAY_SEC: float = 60.0


static func earnings(rate: float, away_sec: float, max_hours: float, efficiency: float) -> float:
	if rate <= 0.0 or away_sec < MIN_AWAY_SEC:
		return 0.0
	var counted := minf(away_sec, max_hours * SECONDS_PER_HOUR)
	return rate * counted * clampf(efficiency, 0.0, 1.0)


## Time away from a saved timestamp; 0 if never saved or the clock went backwards.
static func away_seconds(last_seen_unix: float, now_unix: float) -> float:
	if last_seen_unix <= 0.0 or now_unix < last_seen_unix:
		return 0.0
	return now_unix - last_seen_unix
