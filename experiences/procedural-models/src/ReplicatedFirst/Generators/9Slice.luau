--!strict
-- 3D 9-slice generator (really 27-slice, sans center).
-- Reads a `Source` folder containing 5 named child Models — Corner, VerticalEdge, TopEdge,
-- VerticalFace, TopFace — and assembles them into a cuboidal shell sized to the PM's
-- editable bounds. Corners are placed verbatim; edges stretch along one axis; faces
-- stretch along two.
--
-- Assumptions about the source set:
--   - All pieces share the same corner unit length (read from Corner:GetBoundingBox().X).
--   - Pieces are authored with their parts axis-aligned to the piece's local frame
--     (no internal rotations) — otherwise stretch axes won't align cleanly with part Size.
--   - The natural orientation of each piece is the "+x +y +z" face; mirrors and rotations
--     are composed from there for the other positions.
--
-- BaseParts are flattened directly into targetContainer (no Model wrappers). Each Part's
-- CFrame is in pivot-local space; the engine post-multiplies by the PM's pivot on reparent.

local defaultAttributes = {
	Source = "Mall.Concrete",
	Tint = true,
	Color = Color3.fromRGB(220, 220, 220),
	Material = "SmoothPlastic",
	MaterialVariant = "",
}

local function resolveMaterial(name: string): Enum.Material
	for _, item in Enum.Material:GetEnumItems() do
		if item.Name == name then
			return item
		end
	end
	return Enum.Material.SmoothPlastic
end

-- Source-orientation corrections. Each value is a SOURCE-LOCAL rotation applied to every
-- emitted instance of that placement category. Tweak these to align with how your source
-- pieces are authored. Pieces of the same source mesh used at different orientations
-- (TopEdge along X vs along Z, walls facing X vs Z) get separate knobs.
local SOURCE_FIX: { [string]: CFrame } = {
	-- Corner pieces. All 8 placements share this correction.
	Corner = CFrame.identity,
	-- VerticalEdge: long axis = world +y.
	VerticalEdge = CFrame.identity,
	-- TopEdge running along world X (top+bottom edges at z = ±D/2).
	TopEdgeAlongX = CFrame.fromEulerAngles(0, math.rad(90), 0),
	-- TopEdge running along world Z (top+bottom edges at x = ±W/2).
	TopEdgeAlongZ = CFrame.fromEulerAngles(0, -math.rad(90), 0),
	-- Walls facing ±Z (at z = ±D/2).
	WallFaceZ = CFrame.fromEulerAngles(0, math.pi, 0),
	-- Walls facing ±X (at x = ±W/2).
	WallFaceX = CFrame.fromEulerAngles(0, math.pi, 0),
	-- TopFace + its bottom mirror.
	TopFace = CFrame.identity,
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

-- Emit stretched copies of every BasePart in sourcePiece, placed under `placementCF` in
-- the PM's pivot-local frame. Stretch is applied axis-wise in source-local coordinates
-- BEFORE composition with placementCF, so it scales the piece along its own axes (which,
-- after placementCF, may correspond to any world axis).
-- For each placement-frame axis (X, Y, Z), find the part-local axis it maps to via the
-- part's effective rotation and apply the corresponding stretch factor to that axis of
-- the part's Size. Works for axis-aligned rotations (90° multiples).
local function stretchedSizeFor(originalSize: Vector3, partRotInPlacement: CFrame, placementStretch: Vector3): Vector3
	local newX, newY, newZ = originalSize.X, originalSize.Y, originalSize.Z

	local function applyAxis(placementAxis: Vector3, factor: number)
		local partLocalDir = partRotInPlacement:VectorToObjectSpace(placementAxis)
		local ax = math.abs(partLocalDir.X)
		local ay = math.abs(partLocalDir.Y)
		local az = math.abs(partLocalDir.Z)
		if ax >= ay and ax >= az then
			newX = newX * factor
		elseif ay >= az then
			newY = newY * factor
		else
			newZ = newZ * factor
		end
	end

	applyAxis(Vector3.xAxis, placementStretch.X)
	applyAxis(Vector3.yAxis, placementStretch.Y)
	applyAxis(Vector3.zAxis, placementStretch.Z)

	return Vector3.new(newX, newY, newZ)
end

type Skin = { tint: boolean, color: Color3, material: Enum.Material, materialVariant: string }

local function emitPiece(
	sourcePiece: Instance,
	placementCF: CFrame,
	fix: CFrame,
	stretch: Vector3,
	skin: Skin,
	target: Instance
)
	-- Use the source model's pivot as the reference. Each part inside the source carries
	-- its own rotation independently — Bounds and Mesh don't drag each other.
	local sourceRef = sourcePiece:GetPivot()

	for _, src in sourcePiece:GetDescendants() do
		if not src:IsA("BasePart") then
			continue
		end

		local relCF = sourceRef:ToObjectSpace(src.CFrame)
		-- Pre-rotate the part into placement frame via fix; stretch is then applied along
		-- placement-frame axes so SOURCE_FIX rotations don't drag the stretch direction
		-- with them.
		local partInPlacement = fix * relCF
		local placementPos = partInPlacement.Position
		local placementRot = partInPlacement - placementPos

		local stretchedPos =
			Vector3.new(placementPos.X * stretch.X, placementPos.Y * stretch.Y, placementPos.Z * stretch.Z)
		local stretchedSize = stretchedSizeFor(src.Size, placementRot, stretch)
		local stretchedPartInPlacement = placementRot + stretchedPos

		local part = src:Clone()
		if not part:IsA("BasePart") then
			-- Defensive: clone should preserve class, but bail rather than touch BasePart-only props.
			part:Destroy()
			continue
		end
		part.CFrame = placementCF * stretchedPartInPlacement
		part.Size = stretchedSize
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

type Placement = { name: string, fixKey: string, cf: CFrame, stretch: Vector3 }

local function buildPlacements(size: Vector3, cu: Vector3): { Placement }
	-- Clamp each dimension to at least 2 corner units on that axis. Below that, corners
	-- would overlap and the layout is degenerate. At exactly 2*cu the edges/faces collapse
	-- to zero length but stay well-defined.
	size = Vector3.new(math.max(size.X, 2 * cu.X), math.max(size.Y, 2 * cu.Y), math.max(size.Z, 2 * cu.Z))

	local hW, hH, hD = size.X / 2, size.Y / 2, size.Z / 2
	local cuX2, cuY2, cuZ2 = cu.X / 2, cu.Y / 2, cu.Z / 2

	-- Stretch factor: how many "corner units" of length the stretched section spans.
	local sX = math.max(0.001, (size.X - 2 * cu.X) / cu.X)
	local sY = math.max(0.001, (size.Y - 2 * cu.Y) / cu.Y)
	local sZ = math.max(0.001, (size.Z - 2 * cu.Z) / cu.Z)

	-- The four (x,z) corner columns with the Y rotation needed to face outward.
	-- Source +x face is taken as the "natural" outward direction.
	local columns = {
		{ sx = 1, sz = 1, yRot = math.pi / 2 }, --
		{ sx = -1, sz = 1, yRot = 0 }, --tl
		{ sx = -1, sz = -1, yRot = -math.pi / 2 },
		{ sx = 1, sz = -1, yRot = math.pi }, --br
	}

	local p: { Placement } = {}

	-- 8 Corners (4 columns × top/bottom)
	for _, col in columns do
		for _, sy in { -1, 1 } do
			local pos = Vector3.new(col.sx * (hW - cuX2), sy * (hH - cuY2), col.sz * (hD - cuZ2))
			local rot = CFrame.Angles(0, col.yRot, 0)
			if sy == -1 then
				rot = flipBottom(Vector3.new(col.sx, 0, col.sz)) * rot
			end
			table.insert(p, { name = "Corner", fixKey = "Corner", cf = CFrame.new(pos) * rot, stretch = Vector3.one })
		end
	end

	-- 4 VerticalEdges (one per column)
	for _, col in columns do
		local pos = Vector3.new(col.sx * (hW - cuX2), 0, col.sz * (hD - cuZ2))
		local cf = CFrame.new(pos) * CFrame.Angles(0, col.yRot, 0)
		table.insert(p, { name = "VerticalEdge", fixKey = "VerticalEdge", cf = cf, stretch = Vector3.new(1, sY, 1) })
	end

	-- 8 TopEdges: top+bottom × (along X) and top+bottom × (along Z).
	-- Source TopEdge is taken to run along +X with outward face at +Z.
	for _, sy in { -1, 1 } do
		-- Along X, at z = ±hD
		for _, sz in { -1, 1 } do
			local pos = Vector3.new(0, sy * (hH - cuY2), sz * (hD - cuZ2))
			local rot = CFrame.identity
			if sz == -1 then
				rot = CFrame.Angles(0, math.pi, 0)
			end
			if sy == -1 then
				rot = flipBottom(Vector3.new(0, 0, sz)) * rot
			end
			table.insert(p, {
				name = "TopEdge",
				fixKey = "TopEdgeAlongX",
				cf = CFrame.new(pos) * rot,
				stretch = Vector3.new(sX, 1, 1),
			})
		end
		-- Along Z, at x = ±hW (90° around Y from source orientation)
		for _, sx in { -1, 1 } do
			local pos = Vector3.new(sx * (hW - cuX2), sy * (hH - cuY2), 0)
			local rot = CFrame.Angles(0, math.pi / 2, 0)
			if sx == 1 then
				rot = rot * CFrame.Angles(0, math.pi, 0)
			end
			if sy == -1 then
				rot = flipBottom(Vector3.new(sx, 0, 0)) * rot
			end
			table.insert(p, {
				name = "TopEdge",
				fixKey = "TopEdgeAlongZ",
				cf = CFrame.new(pos) * rot,
				stretch = Vector3.new(sZ, 1, 1),
			})
		end
	end

	-- 4 VerticalFaces (walls). Source assumed facing +Z.
	for _, sz in { -1, 1 } do
		local pos = Vector3.new(0, 0, sz * (hD - cuZ2))
		local cf = CFrame.new(pos)
		if sz == -1 then
			cf = cf * CFrame.Angles(0, math.pi, 0)
		end
		table.insert(p, { name = "VerticalFace", fixKey = "WallFaceZ", cf = cf, stretch = Vector3.new(sX, sY, 1) })
	end
	for _, sx in { -1, 1 } do
		local pos = Vector3.new(sx * (hW - cuX2), 0, 0)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0)
		if sx == -1 then
			cf = cf * CFrame.Angles(0, math.pi, 0)
		end
		table.insert(p, { name = "VerticalFace", fixKey = "WallFaceX", cf = cf, stretch = Vector3.new(sZ, sY, 1) })
	end

	-- 2 TopFace/BottomFace (mirror top across Y for bottom). Source assumed facing +Y.
	for _, sy in { -1, 1 } do
		local pos = Vector3.new(0, sy * (hH - cuY2), 0)
		local rot = CFrame.identity
		if sy == -1 then
			rot = flipBottom(Vector3.zero) * rot
		end
		table.insert(
			p,
			{ name = "TopFace", fixKey = "TopFace", cf = CFrame.new(pos) * rot, stretch = Vector3.new(sX, 1, sZ) }
		)
	end

	return p
end

local Generator: GeneratorModuleDefinition<typeof(defaultAttributes)> = {
	Attributes = defaultAttributes,

	OnGenerate = function(parameters, targetContainer)
		local source = resolveSource(parameters.Attributes.Source)
		if not source then
			warn(`[9Slice] could not resolve Source: {parameters.Attributes.Source}`)
			return
		end

		local sourceMap: { [string]: Instance } = {}
		for _, name in { "Corner", "VerticalEdge", "TopEdge", "VerticalFace", "TopFace" } do
			local piece = source:FindFirstChild(name)
			if not piece then
				warn(`[9Slice] missing source piece: {name}`)
				return
			end
			sourceMap[name] = piece
		end

		local cornerBoundsPart = sourceMap.Corner:FindFirstChild("Bounds")
		if not (cornerBoundsPart and cornerBoundsPart:IsA("BasePart")) then
			warn(`[9Slice] Corner is missing a 'Bounds' Part`)
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
			emitPiece(sourceMap[placement.name], placement.cf, fix, placement.stretch, skin, targetContainer)
			parameters:Pause()
		end
	end,
}

return Generator
