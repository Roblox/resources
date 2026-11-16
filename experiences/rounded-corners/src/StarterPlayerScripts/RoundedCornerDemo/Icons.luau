-- Flat item icons built only from Frames, UICorner and UIGradient, so the demo needs no
-- uploaded art and every icon is itself a small showcase of the features in the article.
-- Each builder returns a transparent 64x64 container.
local Util = require(script.Parent.Util)

local Icons = {}

local function box(parent, x, y, w, h, color, radius)
	local f = Util.frame(parent, {
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
	})
	if radius then
		Util.corner(f, radius)
	end
	return f
end

local function container(parent)
	return Util.frame(parent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(64, 64),
	})
end

function Icons.sword(parent, bladeColor: Color3?)
	local root = container(parent)
	local holder = Util.frame(root, { Size = UDim2.fromScale(1, 1), Rotation = 45 })
	local blade = box(holder, 27, 0, 10, 40, Color3.new(1, 1, 1), { 5, 5, 0, 0 })
	Util.gradient(blade, {
		color = Util.colorSeq({ Color3.new(1, 1, 1), bladeColor or Color3.fromRGB(176, 188, 206) }),
		rotation = 0,
	})
	box(holder, 30, 4, 3, 34, Color3.fromRGB(255, 255, 255), 2).BackgroundTransparency = 0.4
	local guard = box(holder, 17, 40, 30, 7, Util.Palette.Gold, 4)
	Util.gradient(guard, {
		color = Util.colorSeq({ Color3.fromRGB(255, 226, 140), Color3.fromRGB(214, 140, 30) }),
		rotation = 90,
	})
	box(holder, 29, 47, 6, 10, Color3.fromRGB(120, 72, 40), 2)
	local pommel = box(holder, 27, 55, 10, 10, Util.Palette.Gold, 5)
	Util.gradient(pommel, {
		type = "Radial",
		color = Util.colorSeq({ Color3.fromRGB(255, 240, 180), Color3.fromRGB(214, 140, 30) }),
		offset = Vector2.new(-0.2, -0.2),
	})
	return root
end

function Icons.shield(parent, colorA: Color3, colorB: Color3)
	local root = container(parent)
	-- Individual corner radii give the classic heater-shield silhouette.
	local outer = box(root, 9, 4, 46, 56, Color3.new(1, 1, 1), { 10, 10, 24, 24 })
	Util.gradient(outer, {
		color = Util.colorSeq({ Color3.fromRGB(230, 236, 245), Color3.fromRGB(150, 160, 178) }),
		rotation = 90,
	})
	local inner = box(outer, 5, 5, 36, 46, Color3.new(1, 1, 1), { 7, 7, 19, 19 })
	Util.gradient(inner, { color = Util.colorSeq({ colorA, colorB }), rotation = 60 })
	box(inner, 15, 0, 6, 46, Color3.new(1, 1, 1), 0).BackgroundTransparency = 0.75
	return root
end

function Icons.potion(parent, liquid: Color3)
	local root = container(parent)
	box(root, 23, 4, 18, 8, Color3.fromRGB(176, 120, 70), 3)
	local neck = box(root, 25, 10, 14, 14, Color3.fromRGB(220, 232, 245), 3)
	neck.BackgroundTransparency = 0.2
	local body = box(root, 10, 18, 44, 44, liquid, 22)
	Util.gradient(body, {
		type = "Radial",
		color = Util.colorSeq({ Color3.new(1, 1, 1), liquid, liquid:Lerp(Color3.new(0, 0, 0), 0.45) }),
		offset = Vector2.new(-0.18, -0.18),
	})
	local shine = box(body, 9, 8, 10, 10, Color3.new(1, 1, 1), 5)
	shine.BackgroundTransparency = 0.35
	return root
end

function Icons.gem(parent, colorA: Color3, colorB: Color3)
	local root = container(parent)
	local gem = box(root, 14, 14, 36, 36, Color3.new(1, 1, 1), 6)
	gem.Rotation = 45
	-- Alternating conical stops read as cut facets.
	Util.gradient(gem, {
		type = "Conical",
		color = Util.colorSeq({ colorA, colorB, colorA, colorB, colorA, colorB, colorA, colorB, colorA }),
	})
	local table_ = box(gem, 11, 11, 14, 14, Color3.new(1, 1, 1), 3)
	table_.BackgroundTransparency = 0.55
	return root
end

function Icons.coin(parent, size: number)
	local c = Util.frame(parent, {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Util.Palette.Gold,
		BackgroundTransparency = 0,
	})
	Util.corner(c, size)
	Util.gradient(c, {
		type = "Radial",
		color = Util.colorSeq({
			Color3.fromRGB(255, 244, 196),
			Color3.fromRGB(255, 196, 61),
			Color3.fromRGB(205, 128, 20),
		}),
		offset = Vector2.new(-0.15, -0.2),
	})
	Util.stroke(c, 1.5, Color3.fromRGB(160, 96, 10), 0.3)
	return c
end

return Icons
