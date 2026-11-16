-- Companion place for "Why a Rounded Corner Is Never Just a Rounded Corner".
--
-- Controls:
--   1-6        jump to scene          Left/Right  previous/next step, then scene
--   Space      pause / resume         R           restart scene from t = 0 (for clean loops)
--   H          hide / show captions   B           toggle background blur (3D scenes)
-- On-screen ‹ › buttons do the same as Left/Right, for touch, and top-right buttons open the
-- shadow and gradient playgrounds. H hides them too, along with any scene button marked with the DemoChrome
-- attribute, so captures stay clean.
-- Scenes with `standalone = true` (the shadow playground) sit outside the numbered demo:
-- no caption bar or ‹ ›, no number key, and Left/Right skip them. Scenes open them by title.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Util = require(script.Util)
local Config = require(script.Config)
local World = require(script.World)

local P = Util.Palette

local scenes = {}
do
	local modules = script.Scenes:GetChildren()
	table.sort(modules, function(a, b)
		return a.Name < b.Name
	end)
	for _, m in modules do
		table.insert(scenes, require(m))
	end
end

-- Indices of the numbered demo scenes, in order.
local sequence = {}
for i, scene in scenes do
	if not scene.standalone then
		table.insert(sequence, i)
	end
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

local gui = Util.new("ScreenGui", {
	Name = "RoundedCornerDemo",
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.None,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})

local flatBackdrop = Util.frame(gui, {
	Name = "FlatBackdrop",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0,
	ZIndex = 0,
})
Util.gradient(flatBackdrop, { color = Util.colorSeq({ P.FlatTop, P.FlatBottom }), rotation = 90 })

local stageHost = Util.frame(gui, {
	Name = "Stage",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(Config.StageSize.X, Config.StageSize.Y),
	ZIndex = 1,
})
local stageScale = Util.new("UIScale", { Parent = stageHost })

local NAV_WIDTH = 44 * 2 + 8

-- The caption bar sits in a full-width row that centers it. Centered with AnchorPoint instead, the
-- bar can only grow to about half the screen before its text wraps.
local captionRow = Util.frame(gui, {
	Name = "CaptionRow",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, -24),
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 10,
})
Util.new("UIListLayout", { Parent = captionRow, HorizontalAlignment = Enum.HorizontalAlignment.Center })
local captionBar = Util.frame(captionRow, {
	Name = "Caption",
	Size = UDim2.fromOffset(0, 44),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = Color3.fromRGB(20, 22, 30),
	BackgroundTransparency = 0.25,
	ZIndex = 10,
	Visible = Config.ShowCaptions,
})
Util.corner(captionBar, 22)
Util.new("UIPadding", {
	Parent = captionBar,
	PaddingLeft = UDim.new(0, 22),
	PaddingRight = UDim.new(0, 22),
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
})
local captionText = Util.label(captionBar, "", {
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.XY,
	TextWrapped = true,
	TextSize = 20,
	TextColor3 = Color3.new(1, 1, 1),
	RichText = true,
	ZIndex = 11,
})
local captionWidth = Util.new("UISizeConstraint", { Parent = captionText })

-- Long captions wrap instead of running under the ‹ › buttons. When there isn't room beside the
-- buttons, the caption moves above them and uses the full width.
local function layoutCaption(screenWidth: number)
	local besideNav = screenWidth - 2 * (24 + NAV_WIDTH + 12)
	local aboveNav = besideNav < 480
	captionRow.Position = UDim2.new(0, 0, 1, aboveNav and -(24 + 44 + 12) or -24)
	local barWidth = aboveNav and screenWidth - 48 or besideNav
	-- The bar's left and right padding come off the text's width.
	captionWidth.MaxSize = Vector2.new(barWidth - 44, math.huge)
end

local warnings = {}
if not Util.HasShadow then
	table.insert(warnings, "UIShadow is unavailable in this build")
end
if not Util.HasGradientTypes then
	table.insert(warnings, "Enum.GradientType is unavailable in this build")
end
if #warnings > 0 then
	Util.label(gui, table.concat(warnings, ". ") .. ". See the README.", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(900, 30),
		TextColor3 = P.Red,
		ZIndex = 12,
	})
end

local world = World.new()

local current: { [string]: any }? = nil
local currentIndex = 0
local container: Frame? = nil
local t = 0
local paused = false
local hintUntil = os.clock() + 6

local loadScene

local ctx = {
	setTime = function(newTime: number)
		t = newTime
	end,
	-- Switch scenes from inside a scene: a scene number, or a scene's title.
	goTo = function(target: number | string)
		if type(target) == "string" then
			for i, scene in scenes do
				if scene.title == target then
					target = i
					break
				end
			end
		end
		if type(target) == "number" then
			task.defer(loadScene, target)
		end
	end,
}

-- Buttons always start visible, so touch users can navigate even when captions start hidden.
local showCaptions = Config.ShowCaptions
local showButtons = true
local nav: Frame
local playgroundButtons: Frame

-- Caption bar and ‹ › follow H, and stay hidden in standalone scenes.
local function applyChrome()
	local scene = scenes[currentIndex]
	local inDemo = not (scene and scene.standalone)
	captionBar.Visible = showCaptions and inDemo
	if nav then
		nav.Visible = showButtons and inDemo
		playgroundButtons.Visible = showButtons and inDemo
	end
	if container then
		for _, d in container:GetDescendants() do
			if d:GetAttribute("DemoChrome") and d:IsA("GuiObject") then
				d.Visible = showButtons
			end
		end
	end
end

function loadScene(index: number)
	index = math.clamp(index, 1, #scenes)
	if container then
		container:Destroy()
	end
	currentIndex = index
	local scene = scenes[index]
	-- Standalone scenes (the playgrounds) lay themselves out for the real screen size instead of
	-- the fixed, uniformly scaled stage, so they stay usable in small windows and on phones.
	container = Util.frame(scene.standalone and gui or stageHost, {
		Name = scene.title,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})
	t = 0
	current = scene.build(container, ctx)
	if not scene.standalone then
		Util.rescaleShadows(container :: Frame)
	end
	applyChrome()
	flatBackdrop.Visible = scene.backdrop ~= "world"
end

local function updateLayout()
	local size = gui.AbsoluteSize
	local s = math.min(size.X / Config.StageSize.X, size.Y / Config.StageSize.Y)
	stageScale.Scale = s
	Util.StageScale = s
	Util.rescaleShadows(stageHost)
	layoutCaption(size.X)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout()

-- Previous/next step, then previous/next scene. Shared by the arrow keys and the ‹ › buttons.
local function go(direction: number)
	local position = table.find(sequence, currentIndex)
	if not position then
		return
	end
	local handled = current and current.step and current:step(t, direction)
	if not handled then
		loadScene(sequence[(position - 1 + direction) % #sequence + 1])
	end
end

nav = Util.frame(gui, {
	Name = "SceneNav",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -24),
	Size = UDim2.fromOffset(NAV_WIDTH, 44),
	ZIndex = 10,
})
for i, spec in { { "Previous", "‹", -1 }, { "Next", "›", 1 } } do
	local b = Util.button(nav, spec[2], {
		Name = spec[1],
		Position = UDim2.fromOffset((i - 1) * 52, 0),
		Size = UDim2.fromOffset(44, 44),
		TextSize = 30,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 22, 30),
		BackgroundTransparency = 0.25,
		CornerRadius = 22,
		ZIndex = 11,
	})
	b.Activated:Connect(function()
		go(spec[3])
	end)
end
playgroundButtons = Util.frame(gui, {
	Name = "Playgrounds",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -24, 0, 24),
	Size = UDim2.fromOffset(310, 52 * 2 + 12),
	ZIndex = 11,
})
for i, spec in
	{
		{ "ShadowPlayground", "Try the shadow playground", "Shadow playground" },
		{ "GradientPlayground", "Try the gradient playground", "Gradient playground" },
	}
do
	local b = Util.button(playgroundButtons, spec[2] .. "  →", {
		Name = spec[1],
		Position = UDim2.fromOffset(0, (i - 1) * 64),
		Size = UDim2.fromOffset(310, 52),
		TextSize = 20,
		BackgroundColor3 = P.Purple,
		TextColor3 = P.Paper,
		CornerRadius = 26,
		ZIndex = 11,
	})
	-- Outside the scaled stage, so the blur stays in screen px instead of following the stage scale.
	local s = Util.shadow(b, { offset = Vector2.new(0, 4), transparency = 0.6 })
	if s then
		s.BlurRadius = UDim.new(0, 14)
	end
	b.Activated:Connect(function()
		ctx.goTo(spec[3])
	end)
end
applyChrome()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local key = input.KeyCode
	local number = key.Value - Enum.KeyCode.One.Value + 1
	if number >= 1 and number <= 9 and number <= #sequence then
		loadScene(sequence[number])
	elseif key == Enum.KeyCode.Space then
		paused = not paused
	elseif key == Enum.KeyCode.R then
		t = 0
	elseif key == Enum.KeyCode.H then
		-- If anything is showing, hide it all for a clean capture; otherwise show it all.
		local show = not (showCaptions or showButtons)
		showCaptions, showButtons = show, show
		applyChrome()
	elseif key == Enum.KeyCode.B then
		world:setBlur(not world.DepthOfField.Enabled)
	elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.Right then
		go(key == Enum.KeyCode.Left and -1 or 1)
	elseif current and current.key then
		current:key(key)
	end
end)

loadScene(Config.StartScene)

RunService.RenderStepped:Connect(function(dt)
	if not paused then
		t += dt
	end
	local scene = scenes[currentIndex]
	-- The world shares the scene clock so 3D scenes restart (R) and pause in sync with the UI.
	world:update(scene.backdrop == "world" and t or 0)
	if current and current.update then
		current:update(t, dt)
	end

	local text = (current and current.caption and current:caption(t)) or scene.caption or ""
	local prefix =
		string.format("<b>%d/%d · %s</b>   ", table.find(sequence, currentIndex) or 0, #sequence, scene.title)
	if os.clock() < hintUntil then
		text = "1–6 scenes · ←/→ steps · Space pause"
	elseif paused then
		prefix ..= "⏸  "
	end
	captionText.Text = prefix .. text
end)
