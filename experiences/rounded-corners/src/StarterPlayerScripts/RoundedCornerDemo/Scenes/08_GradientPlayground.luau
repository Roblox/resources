-- Hands-on: change each UIGradient property with on-screen buttons (works with touch).
-- Starts from a freshly inserted UIGradient's defaults (Linear, white to white), so nothing
-- changes until you pick colors. Elliptical is left out until it ships.
local Root = script.Parent.Parent
local Util = require(Root.Util)
local Playground = require(Root.Playground)

local P = Util.Palette
local CARD_HEIGHT = 280

local TYPES = { "Linear", "Radial", "Conical" }

local COLORS = {
	{ label = "White, White (default)", seq = Util.colorSeq({ Color3.new(1, 1, 1), Color3.new(1, 1, 1) }) },
	{ label = "Orange, Pink, Purple", seq = Util.colorSeq({ P.Orange, P.Pink, P.Purple }) },
	{ label = "Purple, Cyan", seq = Util.colorSeq({ P.Purple, P.Cyan }) },
	-- First and last stops match, so Conical has no visible seam.
	{ label = "Orange to Cyan, looped", seq = Util.colorSeq({ P.Orange, P.Pink, P.Purple, P.Cyan, P.Orange }) },
}

local TRANSPARENCY = {
	{ label = "0 (default)", seq = NumberSequence.new(0) },
	{ label = "0 to 1", seq = NumberSequence.new(0, 1) },
}

local function label(choice)
	return type(choice) == "table" and choice.label or tostring(choice)
end
local function decimal(v)
	return string.format("%.2f", v)
end
local function whole(v)
	return tostring(v)
end
local function udim(v)
	return string.format("0, %d", v)
end
local function width(v)
	return string.format("{0, %d}, {0, %d}", v, CARD_HEIGHT)
end

return {
	title = "Gradient playground",
	-- Outside the numbered demo: reached from the top-right button, left via Back to the demo.
	standalone = true,
	backdrop = "flat",
	build = function(stage: Frame, ctx)
		return Playground.build(stage, ctx, {
			defaults = {
				gradientType = 1,
				color = 1,
				transparency = 1,
				rotation = 0,
				offsetX = 0,
				offsetY = 0,
				scale = 1,
				radius = 32,
				width = 400,
			},
			sections = {
				{
					title = "UIGradient",
					rows = {
						{ key = "gradientType", name = "Type", choices = TYPES, fmt = label },
						{ key = "color", name = "Color", choices = COLORS, fmt = label },
						{ key = "transparency", name = "Transparency", choices = TRANSPARENCY, fmt = label },
						{ key = "rotation", name = "Rotation", min = -180, max = 180, step = 15, fmt = whole },
						{ key = "offsetX", name = "Offset X", min = -0.5, max = 0.5, step = 0.05, fmt = decimal },
						{ key = "offsetY", name = "Offset Y", min = -0.5, max = 0.5, step = 0.05, fmt = decimal },
						{ key = "scale", name = "Scale", min = 0.25, max = 3, step = 0.25, fmt = decimal },
					},
				},
				{
					title = "Frame",
					rows = {
						{ key = "radius", name = "CornerRadius", min = 0, max = 140, step = 10, fmt = udim },
						{ key = "width", name = "Size", min = 200, max = 560, step = 40, fmt = width },
					},
				},
			},
			-- The shop menu's header gradient (see ShopMenu). Leaves the frame controls alone.
			presets = {
				{
					name = "ShopMenuPreset",
					label = "Load the sword shop header",
					values = {
						gradientType = 1,
						color = 2,
						transparency = 1,
						rotation = 20,
						offsetX = 0,
						offsetY = 0,
						scale = 1,
					},
				},
			},
			frame = { width = 400, height = CARD_HEIGHT, radius = 32 },
			-- No drop shadow on this frame: it would show through wherever Transparency fades the gradient.
			setup = function(card)
				return { gradient = Util.gradient(card, {}) }
			end,
			apply = function(state, card, corner, h)
				local g = h.gradient
				if Util.HasGradientTypes then
					g.Type = Enum.GradientType[TYPES[state.gradientType]];
					(g :: any).Scale = state.scale
				end
				g.Color = COLORS[state.color].seq
				g.Transparency = TRANSPARENCY[state.transparency].seq
				g.Rotation = state.rotation
				g.Offset = Vector2.new(state.offsetX, state.offsetY)
				corner.CornerRadius = UDim.new(0, state.radius)
				card.Size = UDim2.fromOffset(state.width, CARD_HEIGHT)
			end,
		})
	end,
}
