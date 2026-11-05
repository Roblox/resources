return {
	SCREEN_GUI_NAME = "EmoteMenu",
	DISPLAY_ORDER = 10,

	-- Wheel is sized from the smaller screen dimension so it stays square and on-screen.
	WHEEL_DIAMETER_SCALE = 0.55,
	MIN_WHEEL_DIAMETER = 260,
	MAX_WHEEL_DIAMETER = 520,

	SLOT_DIAMETER = 88,
	-- Slot-center distance from the wheel center, as a fraction of the wheel radius.
	RING_SCALE = 0.38,

	-- Pointer within this fraction of the wheel radius counts as neutral (nothing selected).
	CENTER_DEADZONE_SCALE = 0.3,
	THUMBSTICK_DEADZONE = 0.35,
	TOUCH_DRAG_DEADZONE = 24,

	BACKDROP_COLOR = Color3.fromRGB(0, 0, 0),
	BACKDROP_TRANSPARENCY = 0.5,

	SLOT_COLOR = Color3.fromRGB(35, 37, 43),
	SLOT_TRANSPARENCY = 0.15,
	SLOT_HIGHLIGHT_COLOR = Color3.fromRGB(255, 255, 255),
	SLOT_HIGHLIGHT_TRANSPARENCY = 0,

	SLOT_TEXT_COLOR = Color3.fromRGB(235, 235, 235),
	SLOT_HIGHLIGHT_TEXT_COLOR = Color3.fromRGB(20, 20, 20),
	SLOT_TEXT_SIZE = 18,

	CENTER_TEXT_COLOR = Color3.fromRGB(235, 235, 235),
	CENTER_TEXT_SIZE = 28,

	-- Enlargement applied to the highlighted slot.
	HIGHLIGHT_SCALE = 1.18,
	TWEEN_TIME = 0.12,

	CONFIRM_KEYCODES = { Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonR2 },
	NAVIGATE_THUMBSTICK = Enum.KeyCode.Thumbstick1,
}
