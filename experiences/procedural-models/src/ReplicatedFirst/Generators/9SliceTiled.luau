--!strict
-- 3D 9-slice generator, tiled variant.
-- Same source-piece scheme as 9Slice — Corner / VerticalEdge / TopEdge / VerticalFace /
-- TopFace — but edges are placed as a row of cu-sized tiles and faces as a grid, rather
-- than a single stretched copy. PM Size is internally snapped to integer multiples of
-- the corner unit per axis (minimum 2 corner units).
--
-- BaseParts are flattened directly into targetContainer. CFrames are pivot-local; the
-- engine post-multiplies by the PM's pivot on reparent.

local defaultAttributes = {
	Source = "Mall.Concrete",
	Tint = true,
	Color = Color3.fromRGB(220, 220, 220),
	Material = "SmoothPlastic",
	MaterialVariant = "",
}

-- Source-orientation corrections, applied in source-local frame. Tweak per piece category
-- if your source authoring convention doesn't match this generator's assumed natural
-- orientation. See 9Slice.luau for assumptions.
local SOURCE_FIX: { [string]: CFrame } = {
	Corner = CFrame.identity,
	VerticalEdge = CFrame.identity,
	TopEdgeAlongX = CFrame.fromEulerAngles(0, math.rad(90), 0),
	TopEdgeAlongZ = CFrame.fromEulerAngles(0, -math.rad(90), 0),
	WallFaceZ = CFrame.fromEulerAngles(0, math.pi / 2, 0),
	WallFaceX = CFrame.fromEulerAngles(0, math.pi / 2, 0),
	TopFace = CFrame.identity,
}

local function resolveMaterial(name: string): Enum.Material
	for _, item in Enum.Material:GetEnumItems() do
		if item.Name == name then
			return item
		end
	end
	return Enum.Material.SmoothPlastic
end

type GenerationFunctionParams<Attributes> = {
	Attributes: Attributes,
	Size: Vector3,
	Pause: (self: GenerationFunctionParams<Attributes>) -> (),
}

type GeneratorModuleDefinition<Attributes> = {
	Attributes: Attributes,
	OnGenerate: (parameters: GenerationFunctionParams<Attributes>, targetContainer: GeneratedFolder) -> (),
}

-- Resolve a dot-separated path by cascading through Workspace, ReplicatedFirst, then
-- ReplicatedStorage. First location that contains the full path wins.
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

type Skin = { tint: boolean, color: Color3, material: Enum.Material, materialVariant: string }

-- Emit copies of every BasePart in sourcePiece at the given placement. No stretching is
-- applied (every tile is exactly the source's natural size); `fix` rotates the piece in
-- source-local frame to align authoring with this generator's assumed natural orientation.
local function emitPiece(sourcePiece: Instance, placementCF: CFrame, fix: CFrame, skin: Skin, target: Instance)
	local sourceRef = sourcePiece:GetPivot()

	for _, src in sourcePiece:GetDescendants() do
		if not src:IsA("BasePart") then
			continue
		end

		local relCF = sourceRef:ToObjectSpace(src.CFrame)
		local partInPlacement = fix * relCF

		local part = src:Clone()
		if not part:IsA("BasePart") then
			part:Destroy()
			continue
		end
		part.CFrame = placementCF * partInPlacement
		part.Anchored = true
		if skin.tint then
			part.Color = skin.color
			part.Material = skin.material
			if skin.materialVariant ~= "" then
				part.MaterialVariant = skin.materialVariant
			end
		end
		part.Parent = target
	end
end

-- Rotation that takes a top-row piece to its bottom-row counterpart: 180° around the
-- piece's horizontal outward direction (in world). Preserves outward, flips vertical.
-- Pieces with no horizontal outward (top/bottom faces) just flip around world X.
local function flipBottom(horizontalOutward: Vector3): CFrame
	if horizontalOutward.Magnitude < 0.001 then
		return CFrame.Angles(math.pi, 0, 0)
	end
	return CFrame.fromAxisAngle(horizontalOutward.Unit, math.pi)
end

type Placement = { name: string, fixKey: string, cf: CFrame }

-- Snap a dimension to the nearest integer multiple of cu, with a minimum of 2*cu.
local function snapDim(value: number, cu: number): number
	return math.max(2 * cu, math.floor(value / cu + 0.5) * cu)
end

local function buildPlacements(size: Vector3, cu: Vector3): { Placement }
	size = Vector3.new(snapDim(size.X, cu.X), snapDim(size.Y, cu.Y), snapDim(size.Z, cu.Z))

	local hW, hH, hD = size.X / 2, size.Y / 2, size.Z / 2
	local cuX2, cuY2, cuZ2 = cu.X / 2, cu.Y / 2, cu.Z / 2

	-- Number of tiles along each axis in the "interior" between the corners.
	local nX = math.floor((size.X - 2 * cu.X) / cu.X + 0.5)
	local nY = math.floor((size.Y - 2 * cu.Y) / cu.Y + 0.5)
	local nZ = math.floor((size.Z - 2 * cu.Z) / cu.Z + 0.5)

	-- The four (x,z) corner columns with their Y rotation (same as 9Slice).
	local columns = {
		{ sx = 1, sz = 1, yRot = math.pi / 2 },
		{ sx = -1, sz = 1, yRot = 0 },
		{ sx = -1, sz = -1, yRot = -math.pi / 2 },
		{ sx = 1, sz = -1, yRot = math.pi },
	}

	-- Center of tile i (0-indexed) along an axis: tile 0 begins at -half + cu/2, then each
	-- subsequent tile shifts by cu.
	local function tileCenter(half: number, cuAxis: number, i: number): number
		return -half + cuAxis + (i + 0.5) * cuAxis
	end

	local p: { Placement } = {}

	-- 8 Corners (unchanged from 9Slice).
	for _, col in columns do
		for _, sy in { -1, 1 } do
			local pos = Vector3.new(col.sx * (hW - cuX2), sy * (hH - cuY2), col.sz * (hD - cuZ2))
			local rot = CFrame.Angles(0, col.yRot, 0)
			if sy == -1 then
				rot = flipBottom(Vector3.new(col.sx, 0, col.sz)) * rot
			end
			table.insert(p, { name = "Corner", fixKey = "Corner", cf = CFrame.new(pos) * rot })
		end
	end

	-- VerticalEdges: nY tiles stacked per column.
	for _, col in columns do
		for iY = 0, nY - 1 do
			local y = tileCenter(hH, cu.Y, iY)
			local pos = Vector3.new(col.sx * (hW - cuX2), y, col.sz * (hD - cuZ2))
			local cf = CFrame.new(pos) * CFrame.Angles(0, col.yRot, 0)
			table.insert(p, { name = "VerticalEdge", fixKey = "VerticalEdge", cf = cf })
		end
	end

	-- TopEdges along X: nX tiles each at top/bottom × front/back.
	for _, sy in { -1, 1 } do
		for _, sz in { -1, 1 } do
			for iX = 0, nX - 1 do
				local x = tileCenter(hW, cu.X, iX)
				local pos = Vector3.new(x, sy * (hH - cuY2), sz * (hD - cuZ2))
				local rot = CFrame.identity
				if sz == -1 then
					rot = CFrame.Angles(0, math.pi, 0)
				end
				if sy == -1 then
					rot = flipBottom(Vector3.new(0, 0, sz)) * rot
				end
				table.insert(p, { name = "TopEdge", fixKey = "TopEdgeAlongX", cf = CFrame.new(pos) * rot })
			end
		end
		-- TopEdges along Z: nZ tiles each at top/bottom × left/right.
		for _, sx in { -1, 1 } do
			for iZ = 0, nZ - 1 do
				local z = tileCenter(hD, cu.Z, iZ)
				local pos = Vector3.new(sx * (hW - cuX2), sy * (hH - cuY2), z)
				local rot = CFrame.Angles(0, math.pi / 2, 0)
				if sx == 1 then
					rot = rot * CFrame.Angles(0, math.pi, 0)
				end
				if sy == -1 then
					rot = flipBottom(Vector3.new(sx, 0, 0)) * rot
				end
				table.insert(p, { name = "TopEdge", fixKey = "TopEdgeAlongZ", cf = CFrame.new(pos) * rot })
			end
		end
	end

	-- VerticalFaces facing ±Z: nX × nY grid each.
	for _, sz in { -1, 1 } do
		for iX = 0, nX - 1 do
			for iY = 0, nY - 1 do
				local pos = Vector3.new(tileCenter(hW, cu.X, iX), tileCenter(hH, cu.Y, iY), sz * (hD - cuZ2))
				local cf = CFrame.new(pos)
				if sz == -1 then
					cf = cf * CFrame.Angles(0, math.pi, 0)
				end
				table.insert(p, { name = "VerticalFace", fixKey = "WallFaceZ", cf = cf })
			end
		end
	end
	-- VerticalFaces facing ±X: nZ × nY grid each.
	for _, sx in { -1, 1 } do
		for iZ = 0, nZ - 1 do
			for iY = 0, nY - 1 do
				local pos = Vector3.new(sx * (hW - cuX2), tileCenter(hH, cu.Y, iY), tileCenter(hD, cu.Z, iZ))
				local cf = CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0)
				if sx == -1 then
					cf = cf * CFrame.Angles(0, math.pi, 0)
				end
				table.insert(p, { name = "VerticalFace", fixKey = "WallFaceX", cf = cf })
			end
		end
	end

	-- TopFace + BottomFace: nX × nZ grid each.
	for _, sy in { -1, 1 } do
		for iX = 0, nX - 1 do
			for iZ = 0, nZ - 1 do
				local pos = Vector3.new(tileCenter(hW, cu.X, iX), sy * (hH - cuY2), tileCenter(hD, cu.Z, iZ))
				local rot = CFrame.identity
				if sy == -1 then
					rot = flipBottom(Vector3.zero) * rot
				end
				table.insert(p, { name = "TopFace", fixKey = "TopFace", cf = CFrame.new(pos) * rot })
			end
		end
	end

	return p
end

local Generator: GeneratorModuleDefinition<typeof(defaultAttributes)> = {
	Attributes = defaultAttributes,

	OnGenerate = function(parameters, targetContainer)
		local source = resolveSource(parameters.Attributes.Source)
		if not source then
			warn(`[9SliceTiled] could not resolve Source: {parameters.Attributes.Source}`)
			return
		end

		local sourceMap: { [string]: Instance } = {}
		for _, name in { "Corner", "VerticalEdge", "TopEdge", "VerticalFace", "TopFace" } do
			local piece = source:FindFirstChild(name)
			if not piece then
				warn(`[9SliceTiled] missing source piece: {name}`)
				return
			end
			sourceMap[name] = piece
		end

		local cornerBoundsPart = sourceMap.Corner:FindFirstChild("Bounds")
		if not (cornerBoundsPart and cornerBoundsPart:IsA("BasePart")) then
			warn(`[9SliceTiled] Corner is missing a 'Bounds' Part`)
			return
		end
		local cu = cornerBoundsPart.Size

		local skin: Skin = {
			tint = parameters.Attributes.Tint,
			color = parameters.Attributes.Color,
			material = resolveMaterial(parameters.Attributes.Material),
			materialVariant = parameters.Attributes.MaterialVariant,
		}

		for _, placement in buildPlacements(parameters.Size, cu) do
			local fix = SOURCE_FIX[placement.fixKey] or CFrame.identity
			emitPiece(sourceMap[placement.name], placement.cf, fix, skin, targetContainer)
			parameters:Pause()
		end
	end,
}

return Generator
