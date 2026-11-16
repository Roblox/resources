-- Minimal 3D "gameplay" behind the menu: a low-poly campfire clearing with three blocky
-- friends running laps (one carrying a torch). Built client-side; owns the camera.
local Lighting = game:GetService("Lighting")
local Util = require(script.Parent.Util)

local World = {}
World.__index = World

local CENTER = Vector3.new(0, 0, 0)

local function part(parent, props)
	props.Parent = parent
	props.Anchored = true
	props.CanCollide = false
	props.CastShadow = props.CastShadow ~= false
	props.TopSurface = Enum.SurfaceType.Smooth
	props.BottomSurface = Enum.SurfaceType.Smooth
	props.Material = props.Material or Enum.Material.SmoothPlastic
	return Util.new("Part", props)
end

local function tree(parent, pos: Vector3, scale: number)
	part(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6 * scale, 1.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(pos + Vector3.new(0, 3 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 82, 52),
	})
	part(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 7 * scale,
		Position = pos + Vector3.new(0, 7.5 * scale, 0),
		Color = Color3.fromRGB(86, 160, 90),
	})
	part(parent, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 4.5 * scale,
		Position = pos + Vector3.new(1.2 * scale, 10.5 * scale, 0.6 * scale),
		Color = Color3.fromRGB(110, 184, 104),
	})
end

local function friend(parent, shirt: Color3, pants: Color3)
	local model = Instance.new("Model")
	model.Parent = parent
	local skin = Color3.fromRGB(255, 214, 160)
	local f = {
		model = model,
		torso = part(model, { Size = Vector3.new(2, 2, 1), Color = shirt }),
		head = part(model, { Size = Vector3.new(1.3, 1.3, 1.3), Color = skin }),
		armL = part(model, { Size = Vector3.new(0.9, 2, 0.9), Color = skin }),
		armR = part(model, { Size = Vector3.new(0.9, 2, 0.9), Color = skin }),
		legL = part(model, { Size = Vector3.new(0.95, 2, 0.95), Color = pants }),
		legR = part(model, { Size = Vector3.new(0.95, 2, 0.95), Color = pants }),
	}
	return f
end

local function poseFriend(f, root: CFrame, phase: number)
	local swing = math.sin(phase) * 0.9
	local bob = math.abs(math.sin(phase)) * 0.25
	root = root * CFrame.new(0, bob, 0)
	f.torso.CFrame = root * CFrame.new(0, 3, 0)
	f.head.CFrame = root * CFrame.new(0, 4.7, 0)
	local function limb(p, x, y, angle)
		p.CFrame = root * CFrame.new(x, y, 0) * CFrame.Angles(angle, 0, 0) * CFrame.new(0, -1, 0)
	end
	limb(f.armL, -1.45, 3.9, swing)
	limb(f.armR, 1.45, 3.9, -swing)
	limb(f.legL, -0.5, 2, -swing)
	limb(f.legR, 0.5, 2, swing)
end

function World.new()
	local self = setmetatable({}, World)
	local folder = Instance.new("Folder")
	folder.Name = "RoundedCornerDemoWorld"
	folder.Parent = workspace
	self.Folder = folder

	part(folder, {
		Size = Vector3.new(400, 1, 400),
		Position = CENTER - Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(122, 170, 98),
		CastShadow = false,
	})
	part(folder, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 36, 36),
		CFrame = CFrame.new(CENTER + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(214, 190, 140),
		CastShadow = false,
	})

	-- Campfire: stone ring, crossed logs, fire, light.
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		part(folder, {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.3,
			Position = CENTER + Vector3.new(math.cos(a) * 2.6, 0.4, math.sin(a) * 2.6),
			Color = Color3.fromRGB(140, 140, 150),
		})
	end
	for i = 0, 2 do
		part(folder, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4, 0.7, 0.7),
			CFrame = CFrame.new(CENTER + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, i * math.pi / 3, math.rad(20)),
			Color = Color3.fromRGB(110, 70, 40),
		})
	end
	local emitter = part(folder, { Size = Vector3.one, Position = CENTER + Vector3.new(0, 1, 0), Transparency = 1 })
	Util.new("Fire", {
		Parent = emitter,
		Size = 7,
		Heat = 14,
		Color = Color3.fromRGB(255, 140, 40),
		SecondaryColor = Color3.fromRGB(255, 60, 20),
	})
	Util.new(
		"Smoke",
		{ Parent = emitter, Opacity = 0.08, RiseVelocity = 6, Size = 4, Color = Color3.fromRGB(80, 80, 80) }
	)
	Util.new("PointLight", { Parent = emitter, Color = Color3.fromRGB(255, 150, 70), Range = 24, Brightness = 3 })

	local rng = Random.new(7)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local r = rng:NextNumber(30, 60)
		tree(folder, CENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), rng:NextNumber(0.9, 1.5))
	end
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(20, 45)
		part(folder, {
			Size = Vector3.new(rng:NextNumber(2, 4), rng:NextNumber(1, 2.5), rng:NextNumber(2, 4)),
			CFrame = CFrame.new(CENTER + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)) * CFrame.Angles(0, a, 0.2),
			Color = Color3.fromRGB(150, 150, 160),
		})
	end

	-- Lap speeds are multiples of 2π/12 so the world loops in 12 s, like the menu scenes.
	local lap = math.pi * 2 / 12
	self.Friends = {
		{
			f = friend(folder, Color3.fromRGB(59, 130, 246), Color3.fromRGB(40, 50, 80)),
			radius = 11,
			speed = lap,
			offset = 0,
		},
		{
			f = friend(folder, Color3.fromRGB(244, 63, 94), Color3.fromRGB(60, 40, 50)),
			radius = 11,
			speed = lap,
			offset = 0.9,
		},
		{
			f = friend(folder, Color3.fromRGB(250, 204, 21), Color3.fromRGB(70, 60, 40)),
			radius = 14.5,
			speed = -lap,
			offset = 2.5,
		},
	}
	-- The one "setting things on fire".
	Util.new("Fire", { Parent = self.Friends[2].f.armR, Size = 2.5, Heat = 6 })

	self.saved = {
		ClockTime = Lighting.ClockTime,
		Brightness = Lighting.Brightness,
	}
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.2
	self.Atmosphere =
		Util.new("Atmosphere", { Parent = Lighting, Density = 0.32, Haze = 1.2, Color = Color3.fromRGB(255, 220, 190) })
	-- Soft background blur so the UI reads as the subject. Toggle with B.
	self.DepthOfField = Util.new("DepthOfFieldEffect", {
		Parent = Lighting,
		FarIntensity = 0.45,
		NearIntensity = 0.3,
		FocusDistance = 12,
		InFocusRadius = 6,
	})
	self.Bloom = Util.new("BloomEffect", { Parent = Lighting, Intensity = 0.4, Size = 30, Threshold = 1.4 })
	return self
end

function World:update(t: number)
	for _, runner in self.Friends do
		local a = t * runner.speed + runner.offset
		local pos = CENTER + Vector3.new(math.cos(a) * runner.radius, 0, math.sin(a) * runner.radius)
		local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * math.sign(runner.speed)
		poseFriend(runner.f, CFrame.lookAt(pos, pos + tangent), t * 3 * math.pi + runner.offset)
	end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local orbit = 0.6 + math.sin(t * math.pi * 2 / 12) * 0.12
	local eye = CENTER + Vector3.new(math.cos(orbit) * 34, 15, math.sin(orbit) * 34)
	camera.CFrame = CFrame.lookAt(eye, CENTER + Vector3.new(0, 2, 0))
	camera.FieldOfView = 50
end

function World:setBlur(enabled: boolean)
	self.DepthOfField.Enabled = enabled
end

return World
