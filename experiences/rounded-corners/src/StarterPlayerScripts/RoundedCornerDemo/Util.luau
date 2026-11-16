-- Shared helpers for the "Why a Rounded Corner Is Never Just a Rounded Corner" companion place.
local Util = {}

Util.Font = {
	Regular = Font.fromEnum(Enum.Font.BuilderSans),
	Medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
	Black = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold),
	Mono = Font.fromEnum(Enum.Font.RobotoMono),
}

-- Feature detection. Properties are always reflected, so these only tell us the
-- class/enum exists, not that the renderer supports them yet (see README).
Util.HasShadow = pcall(function()
	Instance.new("UIShadow"):Destroy()
end)
Util.HasGradientTypes = pcall(function()
	local g = Instance.new("UIGradient")
	g.Type = Enum.GradientType.Conical
	g:Destroy()
end)

-- Current stage scale (design px -> screen px). Main keeps this updated.
Util.StageScale = 1

function Util.new(className: string, props: { [any]: any }?)
	local inst = Instance.new(className)
	local parent
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		elseif key == "Children" then
			for _, child in value do
				child.Parent = inst
			end
		else
			(inst :: any)[key] = value
		end
	end
	if inst:IsA("GuiObject") and not (props and props.BorderSizePixel) then
		inst.BorderSizePixel = 0
	end
	inst.Parent = parent
	return inst
end

function Util.frame(parent: Instance, props: { [any]: any }?)
	local p = props or {}
	p.Parent = parent
	if p.BackgroundColor3 == nil and p.BackgroundTransparency == nil then
		p.BackgroundTransparency = 1
	end
	return Util.new("Frame", p)
end

-- radius: number for all corners, or { tl, tr, br, bl } for individual corners.
function Util.corner(parent: Instance, radius)
	local c = Instance.new("UICorner")
	Util.setCorner(c, radius)
	c.Parent = parent
	return c
end

function Util.setCorner(c: UICorner, radius)
	if type(radius) == "table" then
		c.TopLeftRadius = UDim.new(0, radius[1])
		c.TopRightRadius = UDim.new(0, radius[2])
		c.BottomRightRadius = UDim.new(0, radius[3])
		c.BottomLeftRadius = UDim.new(0, radius[4])
	else
		c.CornerRadius = UDim.new(0, radius)
	end
end

function Util.stroke(parent: Instance, thickness: number, color: Color3, transparency: number?)
	return Util.new("UIStroke", {
		Parent = parent,
		Thickness = thickness,
		Color = color,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- UIShadow's BlurRadius offset is not multiplied by ancestor UIScale (Offset and Spread are),
-- so blur is authored in design px and rescaled here whenever the stage scale changes.
function Util.shadow(parent: Instance, opts: { [string]: any })
	if not Util.HasShadow then
		return nil
	end
	local s = Instance.new("UIShadow")
	s.Color = opts.color or Color3.new(0, 0, 0)
	s.Transparency = opts.transparency or 0.6
	local offset = opts.offset or Vector2.zero
	s.Offset = UDim2.fromOffset(offset.X, offset.Y)
	local spread = opts.spread or 0
	s.Spread = UDim2.fromOffset(spread, spread)
	s.ZIndex = opts.zIndex or -1
	s:SetAttribute("DesignBlur", opts.blur or 16)
	s.BlurRadius = UDim.new(0, (opts.blur or 16) * Util.StageScale)
	s.Parent = parent
	return s
end

function Util.setShadowBlur(s: Instance?, blur: number)
	if s then
		s:SetAttribute("DesignBlur", blur);
		(s :: any).BlurRadius = UDim.new(0, blur * Util.StageScale)
	end
end

function Util.rescaleShadows(root: Instance)
	for _, d in root:GetDescendants() do
		local blur = d:GetAttribute("DesignBlur")
		if blur and d.ClassName == "UIShadow" then
			(d :: any).BlurRadius = UDim.new(0, blur * Util.StageScale)
		end
	end
end

-- colors: array of Color3 spaced evenly, or array of { t, Color3 }.
function Util.colorSeq(colors)
	local keys = {}
	for i, c in colors do
		if typeof(c) == "Color3" then
			table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
		else
			table.insert(keys, ColorSequenceKeypoint.new(c[1], c[2]))
		end
	end
	return ColorSequence.new(keys)
end

function Util.numSeq(points)
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

-- gradientType: "Linear" | "Radial" | "Conical" | "Elliptical"
function Util.gradient(parent: Instance, opts: { [string]: any })
	local g = Instance.new("UIGradient")
	g.Color = opts.color or Util.colorSeq({ Color3.new(1, 1, 1), Color3.new(1, 1, 1) })
	if opts.transparency then
		g.Transparency = opts.transparency
	end
	g.Rotation = opts.rotation or 0
	g.Offset = opts.offset or Vector2.zero
	if opts.type and Util.HasGradientTypes then
		g.Type = Enum.GradientType[opts.type]
	end
	if opts.scale and Util.HasGradientTypes then
		(g :: any).Scale = opts.scale
	end
	g.Parent = parent
	return g
end

function Util.label(parent: Instance, text: string, props: { [any]: any }?)
	local p = props or {}
	p.Parent = parent
	p.Text = text
	p.BackgroundTransparency = 1
	p.FontFace = p.FontFace or Util.Font.Medium
	p.TextSize = p.TextSize or 22
	p.TextColor3 = p.TextColor3 or Color3.fromRGB(40, 44, 56)
	p.Size = p.Size or UDim2.fromOffset(400, 30)
	return Util.new("TextLabel", p)
end

-- A rounded TextButton. Connect to .Activated so it works with mouse, touch, and gamepad.
function Util.button(parent: Instance, text: string, props: { [any]: any }?)
	local p = props or {}
	local radius = p.CornerRadius or 10
	p.CornerRadius = nil
	p.Parent = parent
	p.Text = text
	p.FontFace = p.FontFace or Util.Font.Bold
	p.TextSize = p.TextSize or 24
	p.TextColor3 = p.TextColor3 or Util.Palette.Ink
	p.BackgroundColor3 = p.BackgroundColor3 or Util.Palette.FlatBottom
	p.AutoButtonColor = true
	local b = Util.new("TextButton", p)
	Util.corner(b, radius)
	return b
end

-- A straight line segment drawn as a rotated Frame. Points are in the parent's offset space.
function Util.line(parent: Instance, a: Vector2, b: Vector2, thickness: number, color: Color3)
	local f = Util.new("Frame", {
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
	})
	Util.setLine(f, a, b, thickness)
	return f
end

function Util.setLine(f: Frame, a: Vector2, b: Vector2, thickness: number)
	local d = b - a
	local mid = (a + b) / 2
	f.Position = UDim2.fromOffset(mid.X, mid.Y)
	f.Size = UDim2.fromOffset(d.Magnitude + thickness * 0.5, thickness)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
end

function Util.dot(parent: Instance, p: Vector2, size: number, color: Color3)
	local f = Util.new("Frame", {
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color,
	})
	Util.corner(f, size)
	return f
end

function Util.clamp01(x: number)
	return math.clamp(x, 0, 1)
end

function Util.smooth(x: number)
	x = Util.clamp01(x)
	return x * x * (3 - 2 * x)
end

function Util.lerp(a, b, t: number)
	return a + (b - a) * t
end

-- Evaluates a looping keyframe track. keys: array of { time, value } where value is a
-- number or an array of numbers; the last key's time is the loop length. Smoothstep between keys.
function Util.track(keys, t: number)
	local length = keys[#keys][1]
	t = t % length
	for i = 1, #keys - 1 do
		local k0, k1 = keys[i], keys[i + 1]
		if t <= k1[1] then
			local u = Util.smooth((t - k0[1]) / math.max(k1[1] - k0[1], 1e-6))
			if type(k0[2]) == "table" then
				local out = {}
				for j = 1, #k0[2] do
					out[j] = Util.lerp(k0[2][j], k1[2][j], u)
				end
				return out
			end
			return Util.lerp(k0[2], k1[2], u)
		end
	end
	return keys[#keys][2]
end

-- Complementary error function (Abramowitz & Stegun 7.1.26), used for the Gaussian edge LUT.
function Util.erfc(x: number)
	local z = math.abs(x)
	local t = 1 / (1 + 0.3275911 * z)
	local poly = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))))
	local r = poly * math.exp(-z * z)
	return x >= 0 and r or 2 - r
end

Util.Palette = {
	Ink = Color3.fromRGB(32, 36, 48),
	SubInk = Color3.fromRGB(104, 112, 130),
	Paper = Color3.fromRGB(255, 255, 255),
	FlatTop = Color3.fromRGB(240, 242, 247),
	FlatBottom = Color3.fromRGB(222, 226, 235),
	Panel = Color3.fromRGB(30, 34, 48),
	PanelDeep = Color3.fromRGB(22, 25, 36),
	Card = Color3.fromRGB(40, 46, 64),
	Orange = Color3.fromRGB(255, 138, 61),
	Pink = Color3.fromRGB(255, 79, 139),
	Purple = Color3.fromRGB(124, 92, 246),
	Cyan = Color3.fromRGB(34, 211, 238),
	Gold = Color3.fromRGB(255, 196, 61),
	Green = Color3.fromRGB(52, 211, 120),
	Blue = Color3.fromRGB(59, 130, 246),
	Red = Color3.fromRGB(244, 63, 94),
}

return Util
