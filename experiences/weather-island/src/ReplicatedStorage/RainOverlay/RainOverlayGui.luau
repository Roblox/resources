--!strict
-- Assembles the rain overlay from the authored GUI in RainOverlay/ui.
--
-- Color, thickness, the gradient, and tint all live in the template files.
-- The container is larger than the viewport so that it can rotate and still
-- cover the screen.

local RainOverlayConfig = require(script.Parent.RainOverlayConfig)

local uiFolder = script.Parent.ui
local overlayTemplate: ScreenGui = uiFolder.Overlay
local streakTemplates: Folder = uiFolder.StreakTemplates

local RainOverlayGui = {}

export type Streak = {
	frame: Frame,
	-- Position inside the rotated container, in pixels.
	x: number,
	y: number,
	-- Authored dimensions and speed at ReferenceViewportHeight.
	baseWidth: number,
	baseLength: number,
	baseSpeed: number,
	-- Dimensions and speed after viewport scaling.
	length: number,
	speed: number,
	-- The authored transparency, i.e. how this streak looks at full intensity.
	baseTransparency: number,
}

export type Parts = {
	root: Frame,
	tint: Frame,
	-- Authored transparency of the tint wash at full intensity.
	tintTransparency: number,
	container: Frame,
	-- How much wider the container is than the viewport, read off the model.
	containerScale: number,
	streaks: { Streak },
}

local function randomBetween(range: { number }): number
	return range[1] + math.random() * (range[2] - range[1])
end

function RainOverlayGui.build(): (ScreenGui, Parts)
	local gui = overlayTemplate:Clone()
	local root: Frame = gui.Root
	local tint: Frame = root.Tint
	local container: Frame = root.Streaks

	local streaks: { Streak } = {}
	for _, layer in RainOverlayConfig.Layers do
		local found = streakTemplates:FindFirstChild(layer.Template)
		assert(found, "ui.StreakTemplates has no frame named " .. layer.Template)
		local template = found :: Frame
		local authoredSize = template.Size

		for _ = 1, layer.Count do
			-- Jitter only the length. Uniform streaks read as banding, but
			-- everything else stays exactly as authored.
			local baseLength = authoredSize.Y.Offset * randomBetween(layer.LengthScale)
			local baseSpeed = randomBetween(layer.Speed)

			local frame = template:Clone()
			frame.Size = UDim2.fromOffset(authoredSize.X.Offset, baseLength)
			frame.BackgroundTransparency = 1
			frame.Parent = container

			table.insert(streaks, {
				frame = frame,
				x = 0,
				y = 0,
				baseWidth = authoredSize.X.Offset,
				baseLength = baseLength,
				baseSpeed = baseSpeed,
				length = baseLength,
				speed = baseSpeed,
				baseTransparency = template.BackgroundTransparency,
			})
		end
	end

	local tintTransparency = tint.BackgroundTransparency
	tint.BackgroundTransparency = 1

	return gui,
		{
			root = root,
			tint = tint,
			tintTransparency = tintTransparency,
			container = container,
			containerScale = container.Size.X.Scale,
			streaks = streaks,
		}
end

return RainOverlayGui
