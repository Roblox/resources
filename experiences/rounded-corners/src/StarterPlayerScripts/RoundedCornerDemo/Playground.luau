-- Shared layout for the hands-on playground scenes: a preview frame, a panel of −/+ rows,
-- preset and Reset buttons, and Back to the demo. Buttons use .Activated, so they work with
-- touch. Values are shown the way Studio's Properties window shows them.
--
-- Responsive: the playground fills the screen instead of the demo's fixed stage. Wide windows
-- put the preview beside the controls; tall or narrow ones stack the preview above them. Controls
-- stay full size and scroll when they don't fit; only the preview frame scales to fit.
--
-- config = {
--   defaults = { key = value },
--   sections = { { title, toggle = key?, rows = { row } } },
--     row = { key, name, fmt, min, max, step }      -- number, clamped
--         | { key, name, fmt, choices = { ... } }   -- index into choices, wraps around
--   presets = { { name, label, values = { key = value } } },
--   frame = { width, height, radius },
--   setup = function(card): handles                     -- create the modifiers once
--   apply = function(state, card, corner, handles, view) -- push state onto them
-- }
-- view.setBlur(shadow, blur) sets a UIShadow's blur in preview px; use it instead of setting
-- BlurRadius directly, because the preview's UIScale doesn't scale BlurRadius.
local GuiService = game:GetService("GuiService")

local Util = require(script.Parent.Util)

local P = Util.Palette

local MARGIN = 16
-- On very wide screens, the preview and controls stay together in a centered column.
local MAX_CONTENT_WIDTH = 1440
local BUTTON = 44 -- Minimum touch target.
local ROW_HEIGHT = 52
-- Room around the preview frame for most of its shadow. The softest shadows can fade a little
-- past the preview area, which keeps the frame itself large.
local PREVIEW_PADDING = Vector2.new(40, 80)
-- The preview frame can grow past its real size when there's room, so it doesn't look lost
-- next to the controls.
local MAX_PREVIEW_SCALE = 2

local Playground = {}

-- Chrome sits outside any UIScale, so its shadow blur is set in screen px.
local function chromeShadow(parent: GuiObject, blur: number, offsetY: number, transparency: number)
	local s = Util.shadow(parent, { offset = Vector2.new(0, offsetY), transparency = transparency })
	if s then
		s:SetAttribute("DesignBlur", nil)
		s.BlurRadius = UDim.new(0, blur)
	end
end

function Playground.build(root: Frame, ctx, config)
	local state = table.clone(config.defaults)

	local back = Util.button(root, "←  Back to the demo", {
		Name = "BackToDemo",
		Size = UDim2.fromOffset(220, BUTTON),
		TextSize = 18,
		BackgroundColor3 = P.Paper,
		CornerRadius = BUTTON / 2,
	})
	back:SetAttribute("DemoChrome", true)
	chromeShadow(back, 10, 2, 0.8)
	back.Activated:Connect(function()
		ctx.goTo(1)
	end)

	-- Preview: the frame is laid out in design px inside a holder that scales to fit.
	local widest = config.frame.width
	for _, section in config.sections do
		for _, spec in section.rows do
			if spec.key == "width" and spec.max then
				widest = spec.max
			end
		end
	end
	-- Sized for the widest frame, so the scale doesn't jump as the frame's width changes.
	local design = Vector2.new(widest, config.frame.height) + PREVIEW_PADDING
	local preview = Util.frame(root, { Name = "Preview" })
	local holder = Util.frame(preview, {
		Name = "Holder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(design.X, design.Y),
	})
	local previewScale = Util.new("UIScale", { Parent = holder })
	local card = Util.frame(holder, {
		Name = "Frame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(config.frame.width, config.frame.height),
		BackgroundColor3 = P.Paper,
		BackgroundTransparency = 0,
	})
	local corner = Util.corner(card, config.frame.radius)
	Util.label(card, "Frame", {
		Size = UDim2.fromScale(1, 1),
		FontFace = Util.Font.Bold,
		TextSize = 28,
		TextColor3 = P.SubInk,
	})
	local handles = config.setup(card)

	local view = {}
	function view.setBlur(s: Instance?, blur: number)
		if s then
			s:SetAttribute("DesignBlur", blur);
			(s :: any).BlurRadius = UDim.new(0, blur * previewScale.Scale)
		end
	end
	local function rescaleBlur()
		for _, d in card:GetChildren() do
			local blur = d:GetAttribute("DesignBlur")
			if blur and d:IsA("UIShadow") then
				d.BlurRadius = UDim.new(0, blur * previewScale.Scale)
			end
		end
	end

	-- Controls: a white panel inside a scrolling frame, so every row stays full size.
	local scroll = Util.new("ScrollingFrame", {
		Name = "ControlsScroll",
		Parent = root,
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = P.SubInk,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	})
	-- Room for the panel's shadow and the scroll bar.
	Util.new("UIPadding", {
		Parent = scroll,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 14),
	})
	local panel = Util.frame(scroll, {
		Name = "Controls",
		-- A ScrollingFrame child's scale ignores UIPadding, so take the 8 + 14 px padding off here.
		Size = UDim2.new(1, -22, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = P.Paper,
		BackgroundTransparency = 0,
	})
	Util.corner(panel, 20)
	chromeShadow(panel, 18, 6, 0.85)
	Util.new("UIPadding", {
		Parent = panel,
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
	})
	Util.new("UIListLayout", { Parent = panel, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	local refreshers = {}
	local function apply()
		config.apply(state, card, corner, handles, view)
		for _, refresh in refreshers do
			refresh()
		end
	end

	for _, section in config.sections do
		local header =
			Util.frame(panel, { Name = section.title, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = nextOrder() })
		Util.label(header, section.title, {
			Size = UDim2.new(1, -110, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			FontFace = Util.Font.Bold,
			TextSize = 18,
		})
		local sectionRows = {}
		if section.toggle then
			local toggle = Util.button(header, "", {
				Name = "Toggle",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(100, 36),
				TextSize = 16,
			})
			toggle.Activated:Connect(function()
				state[section.toggle] = not state[section.toggle]
				apply()
			end)
			table.insert(refreshers, function()
				local on = state[section.toggle]
				toggle.Text = on and "Remove" or "Add"
				for _, r in sectionRows do
					r.Visible = on
				end
			end)
		end
		for _, spec in section.rows do
			local row =
				Util.frame(panel, { Name = spec.key, Size = UDim2.new(1, 0, 0, ROW_HEIGHT), LayoutOrder = nextOrder() })
			table.insert(sectionRows, row)
			-- Name above value, so rows fit a phone's width.
			local textWidth = -(BUTTON * 2 + 16)
			Util.label(row, spec.name, {
				Position = UDim2.fromOffset(0, 6),
				Size = UDim2.new(1, textWidth, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Util.Font.Mono,
				TextSize = 14,
				TextColor3 = P.SubInk,
			})
			local value = Util.label(row, "", {
				Position = UDim2.fromOffset(0, 25),
				Size = UDim2.new(1, textWidth, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Util.Font.Mono,
				TextSize = 16,
				TextColor3 = P.Purple,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local function change(direction: number)
				if spec.choices then
					state[spec.key] = (state[spec.key] - 1 + direction) % #spec.choices + 1
				else
					local v = math.clamp(state[spec.key] + spec.step * direction, spec.min, spec.max)
					state[spec.key] = math.round(v * 100) / 100
				end
				apply()
			end
			local minus = Util.button(row, "−", {
				Name = "Minus",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -(BUTTON + 8), 0.5, 0),
				Size = UDim2.fromOffset(BUTTON, BUTTON),
			})
			local plus = Util.button(row, "+", {
				Name = "Plus",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(BUTTON, BUTTON),
			})
			minus.Activated:Connect(function()
				change(-1)
			end)
			plus.Activated:Connect(function()
				change(1)
			end)
			table.insert(refreshers, function()
				local v = state[spec.key]
				value.Text = spec.fmt(spec.choices and spec.choices[v] or v)
			end)
		end
	end

	-- Preset and Reset sit side by side in a wide panel and stack in a narrow one.
	local actions =
		Util.frame(panel, { Name = "Actions", Size = UDim2.new(1, 0, 0, BUTTON), LayoutOrder = nextOrder() })
	local actionButtons = {}
	for _, preset in config.presets do
		local b = Util.button(actions, preset.label, {
			Name = preset.name,
			TextSize = 17,
			BackgroundColor3 = P.Purple,
			TextColor3 = P.Paper,
		})
		b.Activated:Connect(function()
			for key, v in preset.values do
				state[key] = v
			end
			apply()
		end)
		table.insert(actionButtons, { button = b, weight = 3 })
	end
	local reset = Util.button(actions, "Reset", { Name = "Reset", TextSize = 17 })
	reset.Activated:Connect(function()
		state = table.clone(config.defaults)
		apply()
	end)
	table.insert(actionButtons, { button = reset, weight = 2 })

	local function layoutActions(innerWidth: number)
		local gap = 8
		if innerWidth >= 420 then
			local total = 0
			for _, a in actionButtons do
				total += a.weight
			end
			local x = 0
			for i, a in actionButtons do
				local share = a.weight / total
				a.button.Position = UDim2.new(x, i == 1 and 0 or gap / 2, 0, 0)
				a.button.Size = UDim2.new(share, -gap / 2, 0, BUTTON)
				x += share
			end
			actions.Size = UDim2.new(1, 0, 0, BUTTON)
		else
			for i, a in actionButtons do
				a.button.Position = UDim2.fromOffset(0, (i - 1) * (BUTTON + gap))
				a.button.Size = UDim2.new(1, 0, 0, BUTTON)
			end
			actions.Size = UDim2.new(1, 0, 0, #actionButtons * (BUTTON + gap) - gap)
		end
	end

	local function layout()
		local w, h = root.AbsoluteSize.X, root.AbsoluteSize.Y
		if w <= 0 or h <= 0 then
			return
		end
		-- Keep the back button clear of the Roblox menu buttons in the top bar.
		local inset = GuiService.TopbarInset
		local backX = inset.Width > 0 and inset.Min.X + 8 or MARGIN
		local backY = inset.Height > 0 and math.max(4, (inset.Height - BUTTON) / 2) or MARGIN
		if backX + back.Size.X.Offset + MARGIN > w then
			-- No room beside the Roblox buttons on a narrow screen: drop below the top bar.
			backX = MARGIN
			backY = inset.Height + 8
		end
		back.Position = UDim2.fromOffset(backX, backY)
		local top = math.max(backY + BUTTON, inset.Height) + 12

		-- Side by side once there's room for a good-size frame beside the controls, unless the
		-- window is strongly portrait. Below 900 px, stacking gives the frame more room, except in
		-- short landscape windows like a sideways phone, where there's no height to stack into.
		local wide = (w >= 900 and w >= h * 0.75) or (w >= 680 and w >= h * 1.3)
		local contentWidth = math.min(w, MAX_CONTENT_WIDTH)
		local left = math.floor((w - contentWidth) / 2)
		local previewSize
		if wide then
			-- Rows need about 300 px, so the preview gets the rest of the row.
			local controlsWidth = math.clamp(math.floor(contentWidth * 0.3), 340, 420)
			scroll.Position = UDim2.fromOffset(left + contentWidth - controlsWidth - MARGIN, top - 8)
			scroll.Size = UDim2.fromOffset(controlsWidth, h - top - MARGIN + 8)
			previewSize = Vector2.new(contentWidth - controlsWidth - MARGIN * 3, h - top - MARGIN)
		else
			local previewHeight = math.clamp(math.floor(h * 0.42), 200, 440)
			previewSize = Vector2.new(contentWidth - MARGIN * 2, previewHeight)
			scroll.Position = UDim2.fromOffset(left + MARGIN - 8, top + previewHeight + 4)
			scroll.Size =
				UDim2.fromOffset(contentWidth - MARGIN * 2 + 16, math.max(h - top - previewHeight - 4, BUTTON * 3))
		end
		preview.Position = UDim2.fromOffset(left + MARGIN, top)
		preview.Size = UDim2.fromOffset(previewSize.X, previewSize.Y)
		previewScale.Scale = math.min(MAX_PREVIEW_SCALE, previewSize.X / design.X, previewSize.Y / design.Y)
		rescaleBlur()
		-- Scroll padding (22) and panel padding (36) come off the panel's inner width.
		layoutActions(scroll.Size.X.Offset - 22 - 36)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	local topbarChanged = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout)
	root.Destroying:Once(function()
		topbarChanged:Disconnect()
	end)

	-- Scripted control for recording the article's clips: Fire({ key = value }, reset?).
	local setState = Util.new("BindableEvent", { Name = "SetState", Parent = root })
	setState.Event:Connect(function(values, fromDefaults)
		if fromDefaults then
			state = table.clone(config.defaults)
		end
		for key, v in values do
			state[key] = v
		end
		apply()
	end)

	layout()
	apply()
	return {}
end

return Playground
