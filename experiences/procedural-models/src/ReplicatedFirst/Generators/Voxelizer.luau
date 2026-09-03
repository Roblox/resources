--!strict
-- Self-voxelizing bounds generator. Emits tiled pieces from a source set
-- (Mall.Concrete: Corner / VerticalEdge / TopEdge / VerticalFace / TopFace /
-- InteriorCorner / InteriorEdge) along the HOLLOW UNION SHELL of every
-- VOXEL_BOUNDS-tagged ProceduralModel.
--
-- Approach: build a boolean voxel grid for the union (overlapping solid PMs minus
-- Hole-tagged PMs) covering selfPM's OBB + 1-voxel skirt, then classify each owned
-- cell by its 4 horizontal cardinal neighbors + Y+1. Twelve patterns (4 outer
-- corners × 4 sides × 4 inner corners) plus a TopFace case; the Y+1-clear vs solid
-- split selects between top-cap pieces (Corner/TopEdge/InteriorCorner/TopFace) and
-- middle-of-stack pieces (VerticalEdge/VerticalFace/InteriorEdge). T-junctions and
-- holes drop out naturally — an abutting wall makes the inward axis solid, dropping
-- the cell from edge to face; a hole carves the union, exposing inner-corner
-- patterns wherever the cavity meets a remaining wall.
--
-- Same-orientation PMs share a world-anchored grid keyed by rotation, so their
-- voxels line up exactly. Priority resolves overlap ownership (tiebreak: Guid).

local CollectionService = game:GetService("CollectionService")

local BOUNDS_TAG = "VOXEL_BOUNDS"
local MAX_VOXELS = 50_000

type GenerationFunctionParams<Attributes> = {
	Attributes: Attributes,
	Size: Vector3,
	Pause: (self: GenerationFunctionParams<Attributes>) -> (),
}

type GeneratorModuleDefinition<Attributes> = {
	Attributes: Attributes,
	OnGenerate: (parameters: GenerationFunctionParams<Attributes>, targetContainer: GeneratedFolder) -> (),
}

local defaultAttributes = {
	Source = "Mall.Concrete",
	VoxelSize = 4,
	Priority = 0,
	Version = 1,
	Hole = false,
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

local function priorityKey(pm: ProceduralModel): (number, string)
	return pm:GetAttribute("Priority") or 0, pm:GetAttribute("Guid") or ""
end

local function beats(aP: number, aG: string, bP: number, bG: string): boolean
	if aP ~= bP then
		return aP > bP
	end
	return aG > bG
end

local function obbContains(worldP: Vector3, pm: ProceduralModel): boolean
	local localP = pm:GetPivot():PointToObjectSpace(worldP)
	local half = pm.Size * 0.5
	return math.abs(localP.X) <= half.X and math.abs(localP.Y) <= half.Y and math.abs(localP.Z) <= half.Z
end

local function worldAABB(pm: ProceduralModel): (Vector3, Vector3)
	local pivot = pm:GetPivot()
	local h = pm.Size * 0.5
	local minP = Vector3.new(math.huge, math.huge, math.huge)
	local maxP = -minP
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local corner = pivot * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)
				minP = Vector3.new(math.min(minP.X, corner.X), math.min(minP.Y, corner.Y), math.min(minP.Z, corner.Z))
				maxP = Vector3.new(math.max(maxP.X, corner.X), math.max(maxP.Y, corner.Y), math.max(maxP.Z, corner.Z))
			end
		end
	end
	return minP, maxP
end

local function aabbOverlap(aMin: Vector3, aMax: Vector3, bMin: Vector3, bMax: Vector3): boolean
	return aMax.X >= bMin.X
		and aMin.X <= bMax.X
		and aMax.Y >= bMin.Y
		and aMin.Y <= bMax.Y
		and aMax.Z >= bMin.Z
		and aMin.Z <= bMax.Z
end

-- Walk a source piece's BaseParts and emit each at the given PM-local CFrame, with the
-- piece's source-pivot-relative offsets preserved.
local function emitPieceInstance(sourcePiece: Instance, cellLocalCF: CFrame, target: Instance)
	local sourcePivot = (sourcePiece :: any):GetPivot()
	for _, src in sourcePiece:GetDescendants() do
		if not src:IsA("BasePart") then
			continue
		end
		local relCF = sourcePivot:ToObjectSpace(src.CFrame)
		local part = src:Clone()
		if not part:IsA("BasePart") then
			part:Destroy()
			continue
		end
		part.CFrame = cellLocalCF * relCF
		part.Anchored = true
		part.Parent = target
	end
end

-- 4-cardinal + Y±1 pattern classifier. Returns (pieceName, rotationCFrame) or
-- (nil, identity) if no pattern matches.
local function classify(
	Solid: (number, number, number) -> boolean,
	Clear: (number, number, number) -> boolean,
	x: number,
	y: number,
	z: number
): (string?, CFrame)
	local topClear = Clear(x, y + 1, z)

	-- Outer corners. Outward direction is the diagonal between the two cleared
	-- cardinals; the rotation is named for that outward direction.
	if Clear(x + 1, y, z) and Solid(x - 1, y, z) and Solid(x, y, z + 1) and Clear(x, y, z - 1) then
		-- outward = (+x,-z)
		return (if topClear then "Corner" else "VerticalEdge"), CFrame.Angles(0, math.pi, 0)
	end
	if Solid(x + 1, y, z) and Clear(x - 1, y, z) and Solid(x, y, z + 1) and Clear(x, y, z - 1) then
		-- outward = (-x,-z)
		return (if topClear then "Corner" else "VerticalEdge"), CFrame.Angles(0, -math.pi / 2, 0)
	end
	if Clear(x + 1, y, z) and Solid(x - 1, y, z) and Clear(x, y, z + 1) and Solid(x, y, z - 1) then
		-- outward = (+x,+z)
		return (if topClear then "Corner" else "VerticalEdge"), CFrame.Angles(0, math.pi / 2, 0)
	end
	if Solid(x + 1, y, z) and Clear(x - 1, y, z) and Clear(x, y, z + 1) and Solid(x, y, z - 1) then
		-- outward = (-x,+z)
		return (if topClear then "Corner" else "VerticalEdge"), CFrame.identity
	end

	-- Sides. Outward direction is the single cleared cardinal.
	if Solid(x + 1, y, z) and Clear(x - 1, y, z) and Solid(x, y, z + 1) and Solid(x, y, z - 1) then
		-- outward = -x
		return (if topClear then "TopEdge" else "VerticalFace"), CFrame.identity
	end
	if Clear(x + 1, y, z) and Solid(x - 1, y, z) and Solid(x, y, z + 1) and Solid(x, y, z - 1) then
		-- outward = +x
		return (if topClear then "TopEdge" else "VerticalFace"), CFrame.Angles(0, math.pi, 0)
	end
	if Solid(x + 1, y, z) and Solid(x - 1, y, z) and Clear(x, y, z + 1) and Solid(x, y, z - 1) then
		-- outward = +z
		return (if topClear then "TopEdge" else "VerticalFace"), CFrame.Angles(0, math.pi / 2, 0)
	end
	if Solid(x + 1, y, z) and Solid(x - 1, y, z) and Solid(x, y, z + 1) and Clear(x, y, z - 1) then
		-- outward = -z
		return (if topClear then "TopEdge" else "VerticalFace"), CFrame.Angles(0, -math.pi / 2, 0)
	end

	-- Inner corners. Two adjacent cardinals are solid and the diagonal between
	-- them is clear — a 270° concave seam. The cavity opens toward the cleared
	-- diagonal; rotation is named for that direction (matching the outer-corner
	-- convention).
	if Solid(x + 1, y, z) and Clear(x + 1, y, z - 1) and Solid(x, y, z - 1) then
		-- cavity at (+x,-z)
		return (if topClear then "InteriorCorner" else "InteriorEdge"), CFrame.Angles(0, math.pi, 0)
	end
	if Solid(x - 1, y, z) and Clear(x - 1, y, z - 1) and Solid(x, y, z - 1) then
		-- cavity at (-x,-z)
		return (if topClear then "InteriorCorner" else "InteriorEdge"), CFrame.Angles(0, -math.pi / 2, 0)
	end
	if Solid(x + 1, y, z) and Clear(x + 1, y, z + 1) and Solid(x, y, z + 1) then
		-- cavity at (+x,+z)
		return (if topClear then "InteriorCorner" else "InteriorEdge"), CFrame.Angles(0, math.pi / 2, 0)
	end
	if Solid(x - 1, y, z) and Clear(x - 1, y, z + 1) and Solid(x, y, z + 1) then
		-- cavity at (-x,+z)
		return (if topClear then "InteriorCorner" else "InteriorEdge"), CFrame.identity
	end

	-- Top surface: all 4 cardinals solid and Y+1 clear. Includes a sub-check for
	-- the cavity-opening-lip case — a TopFace tile sitting at the OUTER lip of
	-- a hole has all cardinals solid (the slab continues) but a horizontal
	-- diagonal lands in the cavity, and that lip should be an InteriorCorner.
	if
		Clear(x, y + 1, z)
		and Solid(x + 1, y, z)
		and Solid(x - 1, y, z)
		and Solid(x, y, z + 1)
		and Solid(x, y, z - 1)
	then
		if Clear(x + 1, y, z + 1) then
			return "InteriorCorner", CFrame.Angles(0, math.pi / 2, 0)
		end
		if Clear(x - 1, y, z + 1) then
			return "InteriorCorner", CFrame.identity
		end
		if Clear(x + 1, y, z - 1) then
			return "InteriorCorner", CFrame.Angles(0, math.pi, 0)
		end
		if Clear(x - 1, y, z - 1) then
			return "InteriorCorner", CFrame.Angles(0, -math.pi / 2, 0)
		end
		return "TopFace", CFrame.identity
	end

	-- Bottom surface: all 4 cardinals solid, Y+1 solid, Y-1 clear. Cap the
	-- underside of an overhang with a TopFace flipped 180° on X.
	if
		Solid(x, y + 1, z)
		and Clear(x, y - 1, z)
		and Solid(x + 1, y, z)
		and Solid(x - 1, y, z)
		and Solid(x, y, z + 1)
		and Solid(x, y, z - 1)
	then
		return "TopFace", CFrame.Angles(math.pi, 0, 0)
	end

	return nil, CFrame.identity
end

local Generator: GeneratorModuleDefinition<typeof(defaultAttributes)> = {
	Attributes = defaultAttributes,

	OnGenerate = function(parameters, targetContainer)
		local source = resolveSource(parameters.Attributes.Source)
		if not source then
			warn(`[Voxelizer] could not resolve Source: {parameters.Attributes.Source}`)
			return
		end

		-- Hole PMs are pure carve-outs: they subtract their volume from the union but
		-- don't emit pieces themselves.
		if parameters.Attributes.Hole then
			return
		end

		local guid = (parameters.Attributes :: any).Guid
		local selfPM = guid and rummageSelf(guid)
		if not selfPM then
			return
		end

		local voxelSize = parameters.Attributes.VoxelSize
		local myPriority, myGuid = priorityKey(selfPM)

		-- Split AABB neighbours into solid bounds and holes. The union is
		-- (selfPM ∪ solids) \ holes.
		local selfMin, selfMax = worldAABB(selfPM)
		local solidNeighbors = {}
		local holeNeighbors = {}
		local outranking = {}
		for _, pm in CollectionService:GetTagged(BOUNDS_TAG) do
			if pm ~= selfPM and pm:IsA("ProceduralModel") then
				local nMin, nMax = worldAABB(pm)
				if aabbOverlap(selfMin, selfMax, nMin, nMax) then
					if pm:GetAttribute("Hole") then
						table.insert(holeNeighbors, pm)
					else
						table.insert(solidNeighbors, pm)
						local nP, nG = priorityKey(pm)
						if beats(nP, nG, myPriority, myGuid) then
							table.insert(outranking, pm)
						end
					end
				end
			end
		end

		local size = parameters.Size
		local half = size * 0.5
		local pivot = selfPM:GetPivot()
		local pivotRotation = pivot - pivot.Position
		local gridCenter = pivotRotation:PointToObjectSpace(pivot.Position)

		local iMinX = math.floor((gridCenter.X - half.X) / voxelSize)
		local iMaxX = math.floor((gridCenter.X + half.X) / voxelSize)
		local iMinY = math.floor((gridCenter.Y - half.Y) / voxelSize)
		local iMaxY = math.floor((gridCenter.Y + half.Y) / voxelSize)
		local iMinZ = math.floor((gridCenter.Z - half.Z) / voxelSize)
		local iMaxZ = math.floor((gridCenter.Z + half.Z) / voxelSize)

		-- Build the voxel grid over selfPM's OBB + 1-voxel skirt so the classifier's
		-- neighbor lookups at the boundary don't fall off the edge of the table.
		local voxels: { [Vector3]: boolean } = {}
		for ix = iMinX - 1, iMaxX + 1 do
			for iy = iMinY - 1, iMaxY + 1 do
				for iz = iMinZ - 1, iMaxZ + 1 do
					local cellCenter =
						Vector3.new((ix + 0.5) * voxelSize, (iy + 0.5) * voxelSize, (iz + 0.5) * voxelSize)
					local cellWorld = pivotRotation:PointToWorldSpace(cellCenter)
					local inUnion = false
					if obbContains(cellWorld, selfPM) then
						inUnion = true
					else
						for _, other in solidNeighbors do
							if obbContains(cellWorld, other) then
								inUnion = true
								break
							end
						end
					end
					if inUnion then
						for _, hole in holeNeighbors do
							if obbContains(cellWorld, hole) then
								inUnion = false
								break
							end
						end
					end
					if inUnion then
						voxels[Vector3.new(ix, iy, iz)] = true
					end
				end
				parameters:Pause()
			end
		end

		local function Solid(x: number, y: number, z: number): boolean
			return voxels[Vector3.new(x, y, z)] == true
		end
		local function Clear(x: number, y: number, z: number): boolean
			return voxels[Vector3.new(x, y, z)] ~= true
		end

		local emitted = 0
		local truncated = false

		for ix = iMinX, iMaxX do
			for iy = iMinY, iMaxY do
				for iz = iMinZ, iMaxZ do
					parameters:Pause()
					if emitted >= MAX_VOXELS then
						truncated = true
						break
					end

					if not Solid(ix, iy, iz) then
						continue
					end

					-- Ownership: cell center must be in selfPM's OBB and no
					-- priority-outranking neighbor's OBB contains it.
					local cellCenter =
						Vector3.new((ix + 0.5) * voxelSize, (iy + 0.5) * voxelSize, (iz + 0.5) * voxelSize)
					local offset = cellCenter - gridCenter
					if math.abs(offset.X) > half.X or math.abs(offset.Y) > half.Y or math.abs(offset.Z) > half.Z then
						continue
					end

					if #outranking > 0 then
						local cellWorld = pivotRotation:PointToWorldSpace(cellCenter)
						local stolen = false
						for _, n in outranking do
							if obbContains(cellWorld, n) then
								stolen = true
								break
							end
						end
						if stolen then
							continue
						end
					end

					-- Interior skip: all 6 cardinal neighbors solid → not on the shell.
					if
						Solid(ix + 1, iy, iz)
						and Solid(ix - 1, iy, iz)
						and Solid(ix, iy + 1, iz)
						and Solid(ix, iy - 1, iz)
						and Solid(ix, iy, iz + 1)
						and Solid(ix, iy, iz - 1)
					then
						continue
					end

					local pieceName, rot = classify(Solid, Clear, ix, iy, iz)
					if pieceName then
						local piece = source:FindFirstChild(pieceName)
						if piece then
							local cellLocalCF = CFrame.new(offset) * rot
							emitPieceInstance(piece, cellLocalCF, targetContainer)
							emitted += 1
						end
					end
				end
				if truncated then
					break
				end
			end
			if truncated then
				break
			end
		end

		if truncated then
			warn(`[Voxelizer] {selfPM.Name} truncated at {MAX_VOXELS} pieces`)
		end

		-- End-of-bake clear: wipe the previous bake's stale children right before
		-- returning, so the engine's reparent of targetContainer happens in the same
		-- tick and the user never sees an empty Generated folder.
		local existingGenerated = selfPM:FindFirstChild("Generated")
		if existingGenerated then
			existingGenerated:ClearAllChildren()
		end
	end,
}

return Generator
