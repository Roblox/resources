-- The shadow goes wherever the frame goes: individual corner radii, resize, rotation.
-- Left: one shadow. Right: two layers (tight contact + soft ambient). Loops every 16 s.
local Root = script.Parent.Parent
local Util = require(Root.Util)

local P = Util.Palette

-- { w, h, topLeft, topRight, bottomRight, bottomLeft, rotation }
local SHAPE = {
	{ 0, { 300, 300, 32, 32, 32, 32, 0 } },
	{ 2, { 300, 300, 32, 32, 32, 32, 0 } },
	{ 4, { 300, 300, 120, 16, 120, 16, 0 } },
	{ 6, { 300, 300, 120, 16, 120, 16, 0 } },
	{ 8, { 440, 230, 120, 16, 120, 16, -8 } },
	{ 10, { 440, 230, 120, 16, 120, 16, -8 } },
	{ 12, { 240, 340, 16, 80, 16, 80, 6 } },
	{ 14, { 240, 340, 16, 80, 16, 80, 6 } },
	{ 16, { 300, 300, 32, 32, 32, 32, 0 } },
}

local PHASES = {
	{ 0, "The same radius on every corner" },
	{ 2, "A different radius on each corner" },
	{ 6, "Resized and rotated" },
	{ 14, "The same radius on every corner" },
}

local function card(stage, x)
	local f = Util.frame(stage, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, 420),
		Size = UDim2.fromOffset(300, 300),
		BackgroundColor3 = P.Paper,
		BackgroundTransparency = 0,
	})
	return f, Util.corner(f, 32)
end

return {
	title = "Changing the frame",
	backdrop = "flat",
	period = 16,
	build = function(stage: Frame)
		local single, singleCorner = card(stage, 500)
		Util.shadow(single, { blur = 32, offset = Vector2.new(0, 12), transparency = 0.65 })

		local layered, layeredCorner = card(stage, 1100)
		Util.shadow(layered, { blur = 6, offset = Vector2.new(0, 2), transparency = 0.7, zIndex = -1 })
		Util.shadow(layered, { blur = 56, offset = Vector2.new(0, 28), transparency = 0.75, zIndex = -2 })

		for _, spec in { { 500, "One shadow" }, { 1100, "Two shadows" } } do
			Util.label(stage, spec[2], {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(spec[1], 700),
				FontFace = Util.Font.Bold,
				TextSize = 28,
			})
		end

		local cards = { { single, singleCorner }, { layered, layeredCorner } }
		return {
			update = function(_, t: number)
				local s = Util.track(SHAPE, t)
				for _, c in cards do
					c[1].Size = UDim2.fromOffset(s[1], s[2])
					c[1].Rotation = s[7]
					Util.setCorner(c[2], { s[3], s[4], s[5], s[6] })
				end
			end,
			caption = function(_, t: number)
				local text = PHASES[1][2]
				for _, phase in PHASES do
					if t % 16 >= phase[1] then
						text = phase[2]
					end
				end
				return text
			end,
		}
	end,
}
