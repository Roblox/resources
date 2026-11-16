-- MEDIA — OPENING: the sword shop floating over gameplay. Loops seamlessly every 12 s.
local Root = script.Parent.Parent
local ShopMenu = require(Root.ShopMenu)

return {
	title = "Sword shop",
	caption = "The shop menu from the article, built with UICorner, UIShadow, and UIGradient",
	backdrop = "world",
	period = 12,
	build = function(stage: Frame)
		local menu = ShopMenu.new(stage, { position = UDim2.fromOffset(800, 450), width = 480, height = 640 })
		return {
			update = function(_, t: number)
				menu:update(t)
				menu.Root.Position = UDim2.fromOffset(800, 450 + math.sin(t * math.pi / 3) * 5)
			end,
		}
	end,
}
