--!strict
-- Shrub scatter generator.
-- Casts rays downward from the top surface of the PM's editable bounds. For each ray
-- that hits ground (raycasts respect CanCollide, so non-collidable decorations don't
-- block), a randomly-picked Model from the Source folder is placed at the hit point —
-- provided it's at least MinSpacing studs from every previously-placed shrub in this
-- bake.
--
-- Requires the HAS_GUID plugin so this generator can rummage to its own PM for world
-- transform (raycasts have to be world-space; everything else is PM-local).

local CollectionService = game:GetService("CollectionService")

local defaultAttributes = {
	Source = "Mall.Shrubs",
	Seed = 1,
	Density = 0.7,
	MinSpacing = 6,
	GridStep = 4,
	-- Crease detection: a placement only succeeds if at least MinWalls of the cardinal
	-- horizontal raycasts (4 total) hit something within WallSearchDistance.
	WallSearchDistance = 6,
	MinWalls = 1,
	-- Ground-patch check: in addition to the center ray, four corner rays at this
	-- side-length around the candidate must all hit ground, and the Y spread of the
	-- five hits must stay within GroundFlatness studs (rejects edges and slopes).
	GroundPatchSize = 2,
	GroundFlatness = 0.5,
}

type GenerationFunctionParams<Attributes> = {
	Attributes: Attributes,
	Size: Vector3,
	Pause: (self: GenerationFunctionParams<Attributes>) -> (),
}

type GeneratorModuleDefinition<Attributes> = {
	Attributes: Attributes,
	OnGenerate: (parameters: GenerationFunctionParams<Attributes>, targetContainer: GeneratedFolder) -> (),
}

local function resolveSource(path: string): Instance?
	local segments = {}
	for segment in string.gmatch(path, "[^.]+") do
		table.insert(segments, segment)
	end
	if #segments == 0 then
		return nil
	end

	local roots = {
		game:GetService("Workspace"),
		game:GetService("ReplicatedFirst"),
		game:GetService("ReplicatedStorage"),
	}

	for _, root in roots do
		local current: Instance? = root
		for _, segment in segments do
			if not current then
				break
			end
			current = current:FindFirstChild(segment)
		end
		if current then
			return current
		end
	end
	return nil
end

local function rummageSelf(guid: string): ProceduralModel?
	for _, inst in CollectionService:GetTagged("HAS_GUID") do
		if inst:IsA("ProceduralModel") and inst:GetAttribute("Guid") == guid then
			return inst
		end
	end
	return nil
end

-- Emit a model's BaseParts flat into target at the given pivot-local CFrame.
local function emitModel(model: Instance, localCF: CFrame, target: Instance)
	local modelPivot = (model :: any):GetPivot()
	for _, src in model:GetDescendants() do
		if not src:IsA("BasePart") then
			continue
		end
		local relCF = modelPivot:ToObjectSpace(src.CFrame)
		local part = src:Clone()
		if not part:IsA("BasePart") then
			part:Destroy()
			continue
		end
		part.CFrame = localCF * relCF
		part.Anchored = true
		part.Parent = target
	end
end

local Generator: GeneratorModuleDefinition<typeof(defaultAttributes)> = {
	Attributes = defaultAttributes,

	OnGenerate = function(parameters, targetContainer)
		local source = resolveSource(parameters.Attributes.Source)
		if not source then
			warn(`[Shrubs] could not resolve Source: {parameters.Attributes.Source}`)
			return
		end
		local models = source:GetChildren()
		if #models == 0 then
			warn(`[Shrubs] Source folder is empty`)
			return
		end

		local guid = (parameters.Attributes :: any).Guid
		local selfPM = guid and rummageSelf(guid)
		if not selfPM then
			warn(`[Shrubs] tag the PM with HAS_GUID — raycasts need the PM's world transform`)
			return
		end

		local size = parameters.Size
		local halfX, halfY, halfZ = size.X / 2, size.Y / 2, size.Z / 2
		local pivot = selfPM:GetPivot()

		local rng = Random.new(parameters.Attributes.Seed)

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { selfPM }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.RespectCanCollide = true

		local rayLength = size.Y * 2
		local placed: { Vector3 } = {}

		local gridStep = parameters.Attributes.GridStep
		local minSpacing = parameters.Attributes.MinSpacing
		local density = parameters.Attributes.Density
		local minSpacingSq = minSpacing * minSpacing
		local wallSearch = parameters.Attributes.WallSearchDistance
		local minWalls = parameters.Attributes.MinWalls
		local patchHalf = parameters.Attributes.GroundPatchSize / 2
		local groundFlatness = parameters.Attributes.GroundFlatness

		-- 4 cardinal horizontal directions in PM-local frame (so rotated PMs work).
		local localCardinals = {
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1),
		}

		-- Corner offsets for the patch check, in PM-local frame.
		local patchCorners = {
			Vector3.new(-patchHalf, 0, -patchHalf),
			Vector3.new(patchHalf, 0, -patchHalf),
			Vector3.new(-patchHalf, 0, patchHalf),
			Vector3.new(patchHalf, 0, patchHalf),
		}

		local x = -halfX + gridStep / 2
		while x < halfX do
			local z = -halfZ + gridStep / 2
			while z < halfZ do
				if rng:NextNumber() < density then
					local jx = x + rng:NextNumber(-gridStep / 2, gridStep / 2)
					local jz = z + rng:NextNumber(-gridStep / 2, gridStep / 2)
					local worldOrigin = pivot * Vector3.new(jx, halfY, jz)
					local worldDir = pivot:VectorToWorldSpace(Vector3.new(0, -rayLength, 0))
					local hit = workspace:Raycast(worldOrigin, worldDir, rayParams)
					if hit then
						-- Patch check: 4 corner rays must all hit, and the Y spread
						-- across the 5 hits (center + 4 corners) must be within
						-- groundFlatness.
						local minY = hit.Position.Y
						local maxY = hit.Position.Y
						local patchOk = true
						for _, off in patchCorners do
							local cornerOrigin = worldOrigin + pivot:VectorToWorldSpace(off)
							local cornerHit = workspace:Raycast(cornerOrigin, worldDir, rayParams)
							if not cornerHit then
								patchOk = false
								break
							end
							if cornerHit.Position.Y > maxY then
								maxY = cornerHit.Position.Y
							end
							if cornerHit.Position.Y < minY then
								minY = cornerHit.Position.Y
							end
						end
						if patchOk and (maxY - minY) <= groundFlatness then
							local localHit = pivot:PointToObjectSpace(hit.Position)
							local clear = true
							for _, p in placed do
								local d = p - localHit
								if d.X * d.X + d.Y * d.Y + d.Z * d.Z < minSpacingSq then
									clear = false
									break
								end
							end
							if clear then
								-- Crease check: cardinal horizontal rays from just above the
								-- hit point. Cast slightly above ground so we don't hit the
								-- ground itself when it slopes up.
								local wallOrigin = hit.Position + Vector3.new(0, 1, 0)
								local wallHits = 0
								for _, localDir in localCardinals do
									local wallDir = pivot:VectorToWorldSpace(localDir * wallSearch)
									if workspace:Raycast(wallOrigin, wallDir, rayParams) then
										wallHits += 1
									end
								end
								if wallHits >= minWalls then
									local model = models[rng:NextInteger(1, #models)]
									local yRot = CFrame.fromEulerAngles(0, rng:NextNumber() * math.pi * 2, 0)
									emitModel(model, CFrame.new(localHit) * yRot, targetContainer)
									table.insert(placed, localHit)
								end
								parameters:Pause()
							end
						end
					end
				end
				z += gridStep
			end
			x += gridStep
		end
	end,
}

return Generator
