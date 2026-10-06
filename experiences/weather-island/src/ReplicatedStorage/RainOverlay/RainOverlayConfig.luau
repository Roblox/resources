--!strict
-- Anything you can see (colors, streak thickness, gradients, how strong the
-- tint is, the ScreenGui's DisplayOrder) is in the GUI. This config is just
-- timing and motion.

local RainOverlayConfig = {
	StartEnabled = true,

	-- Seconds to cross-fade between clear and full rain. Entering shelter
	-- should feel like the sound dropping away, not a light switch.
	FadeDuration = 1.25,

	-- Streaks fall this much slower at zero intensity, so a fade also reads
	-- as the storm easing off rather than just going transparent.
	MinSpeedScale = 0.55,

	-- Template sizes and layer speeds are authored for this viewport height.
	-- Both scale with the actual viewport so the rain keeps the same apparent
	-- thickness and fall rate across display resolutions.
	ReferenceViewportHeight = 720,

	-- Degrees the rain leans from vertical. Positive leans right.
	WindAngle = 12,
	-- The lean drifts this many degrees either side of WindAngle...
	WindVariance = 4.5,
	-- ...on a cycle this many seconds long, which looks like a passing gust.
	WindPeriod = 9,

	-- Parallax bands, ordered back to front. Template names a child of
	-- ui.StreakTemplates, which decides how each band looks. The numbers here
	-- decide how many there are and how they move. Speed is pixels per second
	-- at ReferenceViewportHeight, and LengthScale multiplies the template's
	-- length so streaks in a band aren't all identical.
	Layers = {
		{
			Template = "Far",
			Count = 90,
			Speed = { 900, 1250 },
			LengthScale = { 0.75, 1.3 },
		},
		{
			Template = "Mid",
			Count = 55,
			Speed = { 1350, 1750 },
			LengthScale = { 0.75, 1.3 },
		},
		{
			Template = "Near",
			Count = 28,
			Speed = { 1900, 2450 },
			LengthScale = { 0.75, 1.3 },
		},
	},

	-- Keyboard shortcut for flipping the overlay while testing. Remove
	-- before publishing.
	ToggleKey = Enum.KeyCode.R,
}

return RainOverlayConfig
