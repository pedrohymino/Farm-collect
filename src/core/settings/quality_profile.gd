class_name QualityProfile
extends RefCounted
## What each graphics quality level changes. Kept as data so it is testable and easy to tune.

const RENDER_SCALE_LOW: float = 0.75


## Returns {"shadows": bool, "msaa": Viewport.MSAA, "render_scale": float}.
static func for_level(level: SettingsData.Quality) -> Dictionary:
	match level:
		SettingsData.Quality.LOW:
			return {
				"shadows": false, "msaa": Viewport.MSAA_DISABLED, "render_scale": RENDER_SCALE_LOW
			}
		SettingsData.Quality.HIGH:
			return {"shadows": true, "msaa": Viewport.MSAA_2X, "render_scale": 1.0}
	return {"shadows": true, "msaa": Viewport.MSAA_DISABLED, "render_scale": 1.0}
