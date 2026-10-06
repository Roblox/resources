--!strict
-- Screen-space rain. A full-screen overlay fakes the downpour in 2D, so it costs
-- the same whether the player is standing in a courtyard or on an empty island,
-- and each client decides for itself whether it is raining.
--
-- The overlay itself is authored in RainOverlay/ui and edited in Studio. This
-- module parents a copy to PlayerGui, animates the streaks, and toggles Enabled.
--
-- Call RainOverlay.start() once on the client, then toggle it as the player moves
-- between open ground and cover with RainOverlay.setEnabled(false) when they
-- step inside and RainOverlay.setEnabled(true) when they step back out.
--
-- If the player has Reduce Motion turned on, the streaks are hidden and only
-- the tint fades in and out.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local RainOverlayConfig = require(script.RainOverlayConfig)
local RainOverlayGui = require(script.RainOverlayGui)

local player = Players.LocalPlayer
assert(player, "RainOverlay must run on the client")

local RainOverlay = {}

local gui: ScreenGui
local parts: RainOverlayGui.Parts

local started = false
local enabled = RainOverlayConfig.StartEnabled
-- Ceiling on how hard it rains, 0..1. Separate from `enabled` so a caller can
-- dial the storm down for partial cover without losing the on/off switch.
local ceiling = 1
-- What is actually on screen this frame, eased towards the target.
local intensity = 0
local appliedIntensity = -1
local windPhase = 0
local renderConnection: RBXScriptConnection? = nil
local layoutSize = Vector2.zero
local reducedMotion = GuiService.ReducedMotionEnabled

local function targetIntensity(): number
	return if enabled then ceiling else 0
end

local function containerSize(): Vector2
	local size = parts.container.AbsoluteSize
	local camera = workspace.CurrentCamera
	if (size.X < 1 or size.Y < 1) and camera then
		-- AbsoluteSize is still zero on the frame the GUI is parented.
		size = camera.ViewportSize * parts.containerScale
	end
	return size
end

local function refreshLayout(forceScatter: boolean?): Vector2
	local size = containerSize()
	if size.X < 1 or size.Y < 1 then
		return size
	end
	if not forceScatter and size == layoutSize then
		return size
	end

	local previousSize = layoutSize
	local shouldScatter = forceScatter or previousSize.X < 1 or previousSize.Y < 1
	local viewportHeight = size.Y / math.max(parts.containerScale, 1e-6)
	local visualScale = viewportHeight / math.max(RainOverlayConfig.ReferenceViewportHeight, 1)

	for _, streak in parts.streaks do
		streak.length = streak.baseLength * visualScale
		streak.speed = streak.baseSpeed * visualScale
		-- Scaling the 1 px templates down on short viewports would leave them
		-- thinner than a pixel, where they break up or vanish.
		streak.frame.Size = UDim2.fromOffset(math.max(streak.baseWidth * visualScale, 1), streak.length)

		if shouldScatter then
			streak.x = math.random() * size.X
			streak.y = math.random() * size.Y
		else
			streak.x *= size.X / previousSize.X
			streak.y *= size.Y / previousSize.Y
		end
		streak.frame.Position = UDim2.fromOffset(streak.x, streak.y)
	end
	layoutSize = size
	return size
end

local function applyIntensity()
	if intensity == appliedIntensity then
		return
	end
	appliedIntensity = intensity

	-- Ease each authored transparency towards fully invisible.
	parts.tint.BackgroundTransparency = 1 - (1 - parts.tintTransparency) * intensity
	for _, streak in parts.streaks do
		streak.frame.BackgroundTransparency = 1 - (1 - streak.baseTransparency) * intensity
	end
end

local function disconnectRender()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

local function step(deltaTime: number)
	local target = targetIntensity()

	if intensity ~= target then
		local delta = deltaTime / math.max(RainOverlayConfig.FadeDuration, 0.01)
		intensity = if target > intensity
			then math.min(intensity + delta, target)
			else math.max(intensity - delta, target)
		applyIntensity()
	end

	if target <= 0 and intensity <= 0 then
		-- Fully sheltered. Drop the loop entirely rather than animating
		-- streaks nobody can see. This also handles a zero target before the
		-- first rendered frame.
		disconnectRender()
		gui.Enabled = false
		return
	end

	if reducedMotion then
		-- Keep the tint as a non-moving weather cue. Once its fade settles,
		-- there is nothing left that needs a per-frame update.
		if intensity == target then
			disconnectRender()
		end
		return
	end

	-- Lean the container rather than each streak.
	windPhase += deltaTime
	local gust = math.sin(windPhase * (2 * math.pi) / RainOverlayConfig.WindPeriod)
	parts.container.Rotation = RainOverlayConfig.WindAngle + RainOverlayConfig.WindVariance * gust

	local size = refreshLayout()
	if size.X < 1 or size.Y < 1 then
		return
	end
	local speedScale = RainOverlayConfig.MinSpeedScale + (1 - RainOverlayConfig.MinSpeedScale) * intensity
	for _, streak in parts.streaks do
		streak.y += streak.speed * speedScale * deltaTime
		if streak.y > size.Y then
			streak.x = math.random() * size.X
			-- Stagger re-entry so the pool doesn't settle into visible rows.
			streak.y = -streak.length - math.random() * size.Y * 0.35
		end
		streak.frame.Position = UDim2.fromOffset(streak.x, streak.y)
	end
end

local function startRender()
	if renderConnection then
		return
	end
	if intensity <= 0 and not reducedMotion then
		-- Coming back from hidden, where the pool froze mid-fall.
		refreshLayout(true)
	else
		refreshLayout()
	end
	parts.container.Visible = not reducedMotion
	gui.Enabled = true
	renderConnection = RunService.RenderStepped:Connect(step)
end

local function syncRender()
	local target = targetIntensity()
	if target <= 0 and intensity <= 0 then
		disconnectRender()
		gui.Enabled = false
	elseif reducedMotion and intensity == target then
		disconnectRender()
		gui.Enabled = true
	else
		startRender()
	end
end

-- Turn the storm on or off for this player. Safe to call before start().
function RainOverlay.setEnabled(value: boolean)
	enabled = value
	if started then
		syncRender()
	end
end

function RainOverlay.isEnabled(): boolean
	return enabled
end

-- Cap how hard it rains, 0..1, for cover that only partly shields the player
-- such as a porch or a tree canopy.
function RainOverlay.setIntensity(value: number)
	ceiling = math.clamp(value, 0, 1)
	if started then
		syncRender()
	end
end

function RainOverlay.start()
	if started then
		return
	end
	started = true

	local playerGui = player:WaitForChild("PlayerGui")
	gui, parts = RainOverlayGui.build()
	gui.Parent = playerGui
	refreshLayout(true)
	parts.container.Visible = not reducedMotion

	parts.container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		refreshLayout()
	end)
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		reducedMotion = GuiService.ReducedMotionEnabled
		parts.container.Visible = not reducedMotion
		if not reducedMotion and targetIntensity() > 0 then
			refreshLayout(true)
		end
		syncRender()
	end)

	local toggleKey = RainOverlayConfig.ToggleKey
	if toggleKey then
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == toggleKey then
				RainOverlay.setEnabled(not enabled)
			end
		end)
	end

	syncRender()
end

return RainOverlay
