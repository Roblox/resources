--!strict
-- Tuneable settings for the dialog system.

local DialogConfig = {
	-- Typewriter speed in characters per second.
	TextSpeed = 35,

	-- If true, freezes the player's character while dialog is open.
	FreezePlayer = true,

	-- How far the player can move (in studs) from the NPC before dialog auto-ends.
	-- Set to 0 or nil to disable. Not applicable if FreezePlayer is true.
	MaxInteractionDistance = 25,

	-- Volume for mood sound.
	SoundEffectVolume = 1,

	-- ProximityPrompt configuration applied to every tagged NPC.
	Prompt = {
		ActionText = "Talk",
		HoldDuration = 0,
		MaxActivationDistance = 10,
		RequiresLineOfSight = false,
	},

	-- Camera shake applied (client-local) on screens with mood set to shake = true.
	-- Default values are mild.
	Shake = {
		Magnitude = 2.2,
		Roughness = 11,
		FadeIn = 0.1,
		FadeOut = 0.9,
	},

	-- Visual layout for the dialog ScreenGui.
	UI = {
		PanelSize = UDim2.fromOffset(900, 240),
		PanelAnchor = Vector2.new(0.5, 1),
		PanelPosition = UDim2.new(0.5, 0, 1, -240),
		ImageSize = UDim2.fromOffset(300, 300),
		-- How far the portrait pokes out past the panel's top and left edges (px).
		ImageOverflowTop = 80,
		ImageOverflowLeft = 20,
		BackgroundColor = Color3.fromRGB(20, 22, 30),
		BackgroundTransparency = 0.1,
		AccentColor = Color3.fromRGB(120, 180, 255),
		TextColor = Color3.fromRGB(240, 240, 245),
		ButtonColor = Color3.fromRGB(40, 44, 56),
		ButtonHoverColor = Color3.fromRGB(60, 68, 88),
		CornerRadius = UDim.new(0, 12),
		TextSize = 32,
	},
}

return DialogConfig
