-- Conclusion: everything at once. The same menu gets twice as wide, tilts, then squeezes
-- onto a phone-shaped screen; shadows and gradients follow. Loops every 12 s.
local Root = script.Parent.Parent
local Util = require(Root.Util)
local ShopMenu = require(Root.ShopMenu)

-- { width, height, rotation }
local SHAPE = {
	{ 0, { 480, 640, 0 } },
	{ 1.5, { 480, 640, 0 } },
	{ 3, { 960, 640, 0 } },
	{ 4.5, { 960, 640, 0 } },
	{ 6, { 900, 600, -5 } },
	{ 7.5, { 900, 600, -5 } },
	{ 9, { 400, 780, 0 } },
	{ 10.5, { 400, 780, 0 } },
	{ 12, { 480, 640, 0 } },
}

local PHASES = {
	{ 0, "The shop menu at its usual size" },
	{ 1.5, "Twice as wide" },
	{ 4.5, "Rotated" },
	{ 7.5, "At phone size" },
	{ 10.5, "Back to its usual size" },
}

return {
	title = "The full menu",
	backdrop = "world",
	period = 12,
	build = function(stage: Frame)
		local menu = ShopMenu.new(stage, { position = UDim2.fromOffset(800, 450), width = 480, height = 640 })
		return {
			update = function(_, t: number)
				local s = Util.track(SHAPE, t)
				menu:setSize(s[1], s[2])
				menu.Root.Rotation = s[3]
				menu:update(t)
			end,
			caption = function(_, t: number)
				local text = PHASES[1][2]
				for _, phase in PHASES do
					if t % 12 >= phase[1] then
						text = phase[2]
					end
				end
				return text
			end,
		}
	end,
}
