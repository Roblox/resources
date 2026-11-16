-- MEDIA — THREE KINDS OF GRADIENT: linear, radial and conical on the same shape, animating
-- direction, center and angle. Loops every 8 s.
local Root = script.Parent.Parent
local Util = require(Root.Util)

local P = Util.Palette
local PERIOD = 8

return {
	title = "Gradient types",
	caption = "Three UIGradients with the same colors: Linear, Radial, and Conical",
	backdrop = "flat",
	period = PERIOD,
	build = function(stage: Frame)
		-- First and last stops match so the conical seam is invisible.
		local colors = Util.colorSeq({ P.Orange, P.Pink, P.Purple, P.Cyan, P.Orange })
		local specs = {
			{ x = 400, type = "Linear", title = "Linear", subtitle = "Position along a line" },
			{ x = 800, type = "Radial", title = "Radial", subtitle = "Distance from the center" },
			{ x = 1200, type = "Conical", title = "Conical", subtitle = "Angle around the center" },
		}
		local gradients = {}
		for _, spec in specs do
			local f = Util.frame(stage, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(spec.x, 400),
				Size = UDim2.fromOffset(300, 300),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0,
			})
			Util.corner(f, 44)
			Util.shadow(f, { blur = 28, offset = Vector2.new(0, 12), transparency = 0.75 })
			gradients[spec.type] = Util.gradient(f, { type = spec.type, color = colors })
			Util.label(stage, spec.title, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(spec.x, 600),
				FontFace = Util.Font.Bold,
				TextSize = 30,
			})
			Util.label(stage, spec.subtitle, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(spec.x, 638),
				TextSize = 21,
				TextColor3 = P.SubInk,
			})
		end
		if not Util.HasGradientTypes then
			Util.label(stage, "Enum.GradientType is missing in this build", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(800, 160),
				Size = UDim2.fromOffset(900, 30),
				TextColor3 = P.Red,
			})
		end

		return {
			update = function(_, t: number)
				local angle = (t / PERIOD) * 360
				gradients.Linear.Rotation = angle
				local a = (t / PERIOD) * math.pi * 2
				gradients.Radial.Offset = Vector2.new(math.cos(a), math.sin(a)) * 0.22
				gradients.Conical.Rotation = angle
			end,
		}
	end,
}
