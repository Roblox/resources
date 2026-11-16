-- Hands-on: change each UIShadow property with on-screen buttons (works with touch).
-- Starts from a freshly inserted UIShadow's defaults, so the article's tutorial steps line up.
local Root = script.Parent.Parent
local Util = require(Root.Util)
local Playground = require(Root.Playground)

local CARD_HEIGHT = 240

local function udim(v)
	return string.format("0, %d", v)
end
local function offsetY(v)
	return string.format("{0, 0}, {0, %d}", v)
end
local function both(v)
	return string.format("{0, %d}, {0, %d}", v, v)
end
local function decimal(v)
	return string.format("%.2f", v)
end
local function width(v)
	return string.format("{0, %d}, {0, %d}", v, CARD_HEIGHT)
end
local function whole(v)
	return tostring(v)
end

return {
	title = "Shadow playground",
	-- Outside the numbered demo: reached from the top-right button, left via Back to the demo.
	standalone = true,
	backdrop = "flat",
	build = function(stage: Frame, ctx)
		return Playground.build(stage, ctx, {
			defaults = {
				blur1 = 0,
				offset1 = 0,
				transparency1 = 0,
				spread1 = 0,
				layer2 = false,
				blur2 = 64,
				offset2 = 28,
				transparency2 = 0.5,
				radius = 32,
				width = 360,
				rotation = 0,
			},
			sections = {
				{
					title = "UIShadow",
					rows = {
						{ key = "blur1", name = "BlurRadius", min = 0, max = 64, step = 4, fmt = udim },
						{ key = "offset1", name = "Offset", min = 0, max = 40, step = 2, fmt = offsetY },
						{ key = "transparency1", name = "Transparency", min = 0, max = 1, step = 0.05, fmt = decimal },
						{ key = "spread1", name = "Spread", min = 0, max = 24, step = 2, fmt = both },
					},
				},
				{
					title = "Second UIShadow (ZIndex -2)",
					toggle = "layer2",
					rows = {
						{ key = "blur2", name = "BlurRadius", min = 0, max = 128, step = 8, fmt = udim },
						{ key = "offset2", name = "Offset", min = 0, max = 60, step = 4, fmt = offsetY },
						{ key = "transparency2", name = "Transparency", min = 0, max = 1, step = 0.05, fmt = decimal },
					},
				},
				{
					title = "Frame",
					rows = {
						{ key = "radius", name = "CornerRadius", min = 0, max = 120, step = 8, fmt = udim },
						{ key = "width", name = "Size", min = 200, max = 560, step = 40, fmt = width },
						{ key = "rotation", name = "Rotation", min = -30, max = 30, step = 5, fmt = whole },
					},
				},
			},
			-- The shop menu's two layers (see ShopMenu). Leaves the frame controls alone.
			presets = {
				{
					name = "ShopMenuPreset",
					label = "Load the sword shop shadows",
					values = {
						blur1 = 8,
						offset1 = 4,
						transparency1 = 0.55,
						spread1 = 0,
						layer2 = true,
						blur2 = 64,
						offset2 = 28,
						transparency2 = 0.5,
					},
				},
			},
			frame = { width = 360, height = CARD_HEIGHT, radius = 32 },
			setup = function(card)
				return {
					shadow1 = Util.shadow(card, { blur = 0, offset = Vector2.zero, transparency = 0, zIndex = -1 }),
					shadow2 = Util.shadow(
						card,
						{ blur = 64, offset = Vector2.new(0, 28), transparency = 0.5, zIndex = -2 }
					),
				}
			end,
			apply = function(state, card, corner, h, view)
				if h.shadow1 and h.shadow2 then
					view.setBlur(h.shadow1, state.blur1)
					h.shadow1.Offset = UDim2.fromOffset(0, state.offset1)
					h.shadow1.Transparency = state.transparency1
					h.shadow1.Spread = UDim2.fromOffset(state.spread1, state.spread1)
					h.shadow2.Enabled = state.layer2
					view.setBlur(h.shadow2, state.blur2)
					h.shadow2.Offset = UDim2.fromOffset(0, state.offset2)
					h.shadow2.Transparency = state.transparency2
				end
				corner.CornerRadius = UDim.new(0, state.radius)
				card.Size = UDim2.fromOffset(state.width, CARD_HEIGHT)
				card.Rotation = state.rotation
			end,
		})
	end,
}
