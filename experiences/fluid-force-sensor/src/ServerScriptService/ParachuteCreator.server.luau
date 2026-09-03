local PhysicsService = game:GetService("PhysicsService")
local aeroBlcok = game:GetService("ReplicatedStorage"):WaitForChild("AerodynamicBlcok")

local Ni = 4
local Nj = 8
local R = 10
local dR = 0.01
local Z = 4
local theta = math.pi / 180 * 50
local dtheta = theta / Nj
local dz = Z / Ni
local Offset = 5
local ANCHORED = false
local ropeLength = 40

local function distance(a, b)
	return (a.WorldPosition - b.WorldPosition).Magnitude
end

local function makeParachute(player, pos)
	local Base = Instance.new("Part")
	Base.Name = "Base"
	Base.Parent = game.Workspace
	Base.Material = Enum.Material.Fabric
	Base.Position = pos
	Base.Size = Vector3.new(0.2, 0.2, 0.2)
	Base.Anchored = ANCHORED

	local Prototype_part = aeroBlcok:Clone()
	Prototype_part.Anchored = ANCHORED
	Prototype_part.EnableFluidForces = true
	--Prototype_part.Strength=0.2

	--Prototype_part.ImplicitIntegration=true

	local density = 0.5
	local friction = 0.1
	local elasticity = 1
	local frictionWeight = 1
	local elasticityWeight = 1
	Prototype_part.CustomPhysicalProperties =
		PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
	Prototype_part.Material = Enum.Material.Fabric
	Prototype_part.CollisionGroup = "ParachuteCollisionGroup"

	local Prototype_spring = Instance.new("BallSocketConstraint") --Instance.new("SpringConstraint")
	local useSpring = true
	if useSpring then
		Prototype_spring = Instance.new("SpringConstraint")
		Prototype_spring.Coils = 2
		Prototype_spring.Radius = 0.1
		Prototype_spring.Thickness = 0.1
		Prototype_spring.Stiffness = 100
		Prototype_spring.Damping = 0.01
	end

	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 0, 0)
	att.Parent = Base
	att.Name = "att"

	for i = -Ni, Ni do
		for j = -Nj, Nj do
			local x = R * math.sin(j * dtheta)
			local y = R * math.cos(j * dtheta) + Offset
			local z = i * dz - dz / 2

			local Lx = R * dtheta
			local Ly = dR
			local Lz = dz

			local Ox = 0
			local Oy = 0
			local Oz = -180 / math.pi * j * dtheta

			local part = Prototype_part:Clone()
			part.Name = string.format("%d-%d", i, j)
			part.Parent = Base
			part.Color = Color3.fromRGB(35, 50, 0)

			part.Position = Vector3.new(x, y, z) + pos
			part.Size = Vector3.new(Lx, Ly, Lz)
			part.Orientation = Vector3.new(Ox, Oy, Oz)

			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(Lx / 2, 0, Lz / 2)
			a1.Parent = part
			a1.Name = "a1"

			local a2 = Instance.new("Attachment")
			a2.Position = Vector3.new(-Lx / 2, 0, Lz / 2)
			a2.Parent = part
			a2.Name = "a2"

			local a3 = Instance.new("Attachment")
			a3.Position = Vector3.new(-Lx / 2, 0, -Lz / 2)
			a3.Parent = part
			a3.Name = "a3"

			local a4 = Instance.new("Attachment")
			a4.Position = Vector3.new(Lx / 2, 0, -Lz / 2)
			a4.Parent = part
			a4.Name = "a4"

			if j > -Nj then
				local other = Base:FindFirstChild(string.format("%d-%d", i, j - 1))
				local s1 = Prototype_spring:Clone()
				s1.Attachment0 = a2
				s1.Attachment1 = other.a1
				s1.Parent = part
				if useSpring then
					s1.FreeLength = distance(a2, other.a1)
				end
				local s2 = Prototype_spring:Clone()
				s2.Attachment0 = a3
				s2.Attachment1 = other.a4
				s2.Parent = part
				if useSpring then
					s2.FreeLength = distance(a3, other.a4)
				end
			end

			if i > -Ni then
				local other = Base:FindFirstChild(string.format("%d-%d", i - 1, j))
				local s1 = Prototype_spring:Clone()
				s1.Attachment0 = a3
				s1.Attachment1 = other.a2
				s1.Parent = part
				if useSpring then
					s1.FreeLength = distance(a3, other.a2)
				end
				local s2 = Prototype_spring:Clone()
				s2.Attachment0 = a4
				s2.Attachment1 = other.a1
				s2.Parent = part
				if useSpring then
					s2.FreeLength = distance(a4, other.a1)
				end
			end

			if math.abs(j) == Nj then
				local am = Instance.new("Attachment")
				if j == Nj then
					am.Position = Vector3.new(Lx / 2, 0, 0)
				else
					am.Position = Vector3.new(-Lx / 2, 0, 0)
				end
				am.Parent = part
				am.Name = "am"
				local Rope = Instance.new("RopeConstraint")
				Rope.Attachment0 = am
				Rope.Attachment1 = Base.att
				Rope.Parent = part
				Rope.Visible = true
				Rope.Length = ropeLength
			end
		end
	end

	local Rode1 = Instance.new("RodConstraint")
	local b1 = Base:FindFirstChild(string.format("%d-%d", -Ni, -Nj)) --a3
	local b2 = Base:FindFirstChild(string.format("%d-%d", Ni, -Nj)) --a2
	local b3 = Base:FindFirstChild(string.format("%d-%d", Ni, Nj)) --a1
	local b4 = Base:FindFirstChild(string.format("%d-%d", -Ni, Nj)) --a4
	local b5 = Base:FindFirstChild(string.format("%d-%d", -Ni, 0)) --a1
	local b6 = Base:FindFirstChild(string.format("%d-%d", Ni, 0)) --a4

	local r1 = Instance.new("RodConstraint")
	r1.Parent = b1
	r1.Attachment0 = b1.a3
	r1.Attachment1 = b2.a2
	r1.Length = distance(r1.Attachment0, r1.Attachment1)

	local r2 = Instance.new("RodConstraint")
	r2.Parent = b1
	r2.Attachment0 = b1.a3
	r2.Attachment1 = b3.a1
	r2.Length = distance(r2.Attachment0, r2.Attachment1)

	local r3 = Instance.new("RodConstraint")
	r3.Parent = b1
	r3.Attachment0 = b1.a3
	r3.Attachment1 = b4.a4
	r3.Length = distance(r3.Attachment0, r3.Attachment1)

	local r4 = Instance.new("RodConstraint")
	r4.Parent = b2
	r4.Attachment0 = b2.a2
	r4.Attachment1 = b3.a1
	r4.Length = distance(r4.Attachment0, r4.Attachment1)

	local r5 = Instance.new("RodConstraint")
	r5.Parent = b2
	r5.Attachment0 = b2.a2
	r5.Attachment1 = b4.a1
	r5.Length = distance(r5.Attachment0, r5.Attachment1)

	local r6 = Instance.new("RodConstraint")
	r6.Parent = b3
	r6.Attachment0 = b3.a1
	r6.Attachment1 = b4.a2
	r6.Length = distance(r6.Attachment0, r6.Attachment1)

	local r7 = Instance.new("RodConstraint")
	r7.Parent = b5
	r7.Attachment0 = b5.a2
	r7.Attachment1 = b1.a1
	r7.Length = distance(r7.Attachment0, r7.Attachment1)

	local r8 = Instance.new("RodConstraint")
	r8.Parent = b5
	r8.Attachment0 = b5.a1
	r8.Attachment1 = b4.a2
	r8.Length = distance(r8.Attachment0, r8.Attachment1)

	local r9 = Instance.new("RodConstraint")
	r9.Parent = b6
	r9.Attachment0 = b6.a2
	r9.Attachment1 = b3.a1
	r9.Length = distance(r9.Attachment0, r9.Attachment1)

	local r10 = Instance.new("RodConstraint")
	r10.Parent = b5
	r10.Attachment0 = b6.a1
	r10.Attachment1 = b2.a2
	r10.Length = distance(r10.Attachment0, r10.Attachment1)
	return Base
end

-- Make a new tool and handle and put it in the player's Backpack
local function makeTool(player)
	-- Create tool
	local tool = Instance.new("Tool")
	tool.Parent = player:WaitForChild("Backpack")
	--print(player.Character.Humanoid.TargetPoint)
	--Create tool handle
	local pos = player.Character:GetPrimaryPartCFrame().p
	local handle = makeParachute(player, pos)
	handle.Parent = tool
	handle.Name = "Handle"
	-- Enable and equip tool
	tool.Enabled = true
	tool.Name = "Parachute"
	tool.Equipped:Connect(function()
		onEquipped(player)
	end)
	player.Character:FindFirstChild("Humanoid"):EquipTool(tool)
end

function onEquipped(player)
	print("Parachute activation")
	local pos = player.Character:GetPrimaryPartCFrame().p
	local scale = 4
	for i = -Ni, Ni do
		for j = -Nj, Nj do
			local part = player.Character.Parachute.Handle:FindFirstChild(string.format("%d-%d", i, j))
			local x = R * math.sin(j * dtheta) / scale
			local y = R * math.cos(j * dtheta) / scale + Offset
			local z = (i * dz - dz / 2) / scale

			local Ox = 0
			local Oy = 0
			local Oz = -180 / math.pi * j * dtheta

			part.Position = Vector3.new(x, y, z) + pos
			part.Orientation = Vector3.new(Ox, Oy, Oz)
		end
	end
end

local makePara: RemoteFunction = game.ReplicatedStorage:FindFirstChild("MakeParachute")
makePara.OnServerInvoke = makeTool
