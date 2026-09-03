--!strict
-- Landmass generator: two-piece closed-solid landmass baked from a
-- polygon. The PM has a stable Guid attribute + HAS_GUID tag stamped by
-- the PolyEdit plugin; we look ourselves up via CollectionService and
-- walk the polygon Model descendants directly for the live vertex list
-- (no attribute serialization round-trip).
--
-- Pipeline: raw vertices → corner-rounding (fillet with prescribed radius,
-- shrinking to MinCornerRadius if the full radius doesn't fit, sharp if
-- even that doesn't fit) → ear-clip triangulation
-- (ReplicatedFirst.Geometry) → two EditableMesh bakes:
--   1. Cliff body (sand) — bottom face + vertical walls (no top).
--   2. Cap "muffin top" (grass) — sloped bevel walls + inset top
--      (no bottom).
-- Splitting into two MeshParts lets each piece carry its own material /
-- colour. The interior cliffTopY interface is intentionally open on both
-- pieces — the cap mesh sits flush against the cliff, so the cliff's
-- top and the cap's bottom would just be coplanar coincident faces with
-- opposite normals. Skipping them saves geometry without any visual
-- change from any external viewpoint.
--
-- Heights stack upward from polygon vertices:
--   baseY     = polygon vertex Y
--   cliffTopY = baseY + CliffHeight          (top of vertical cliff face)
--   capTopY   = cliffTopY + CapHeight       (top of beveled cap)
-- The top face is the refined polygon inset inward by BevelInset.

local AssetService = game:GetService("AssetService")
local Geometry = require(script.Parent.Parent.Parent.Geometry)

-- Live Color3 attributes — generator reads these directly. Each has a
-- companion *Palette string (e.g. CliffColorBottomPalette = "CliffBottom")
-- that SeasonDirector uses to look up Palettes.Landmass.<key> and write
-- the seasonal value back into the live attr.
local FALLBACK_CLIFF_BOTTOM = Color3.fromRGB(115, 100, 85)
local FALLBACK_CLIFF_TOP = Color3.fromRGB(180, 165, 145)
local FALLBACK_CAP_BOTTOM = Color3.fromRGB(55, 90, 45)
local FALLBACK_CAP_TOP = Color3.fromRGB(120, 165, 80)

local Attributes = {
	CliffHeight = 8.0,
	CapHeight = 1.5,
	-- Pillow profile: at parameter t ∈ [0, 1] the cross-section is offset
	-- from the cliff edge by `BevelOutset · sin(π·t) − BevelInset · t`.
	-- Positive offset = outward (bulge over the cliff face), negative =
	-- inward. So the cap starts at the cliff edge, swells outward, and
	-- comes back in to BevelInset at the top — like a cushion / muffin top.
	BevelInset = 0.4,
	BevelOutset = 0.7,
	BevelLevels = 6,
	-- XZ subdivision step (in studs) for the cap top/bottom face
	-- triangulation. Each polygon-cell intersection is ear-clipped
	-- separately, so any sliver triangles are bounded by GridSize and
	-- the long awful slivers from whole-polygon ear-clipping go away.
	GridSize = 32,
	-- Vertical gradients: each piece blends from *Bottom at its lowest Y
	-- to *Top at its highest. Cliff goes baseY → cliffTopY; Cap goes
	-- cliffTopY → capTopY (where the top of the dome lives).
	CliffColorBottom = Color3.fromRGB(115, 100, 85),
	CliffColorTop = Color3.fromRGB(180, 165, 145),
	CapColorBottom = Color3.fromRGB(55, 90, 45),
	CapColorTop = Color3.fromRGB(120, 165, 80),
	CliffColorBottomPalette = "CliffBottom",
	CliffColorTopPalette = "CliffTop",
	CapColorBottomPalette = "CapBottom",
	CapColorTopPalette = "CapTop",
	-- Cap vertex shading driven by hill displacement. ShadeStrength is
	-- the maximum lerp toward white/black at peak displacement.
	-- ShadeReference is the displacement (in studs) that hits that peak.
	ShadeStrength = 0.15,
	ShadeReference = 6.0,
	CornerRadius = 1.5,
	MinCornerRadius = 0.4,
	CornerSegments = 6,
	-- Generation order. Both kickers (in-game ProceduralModelKicker and
	-- the EditableMesh Studio plugin) bake all PMs at this layer fully
	-- before starting any higher-layer PM, so generators that depend on
	-- the landmass (fences raycasting onto its top, props placed on it)
	-- can safely sit on Layer 1+ and trust the terrain is already there.
	Layer = 0,
	Version = 0,
}

type Attrs = { [string]: any }

type Params = {
	Attributes: Attrs,
	Size: Vector3,
	Pause: any,
	Version: number,
}

-- ---- vertex extraction ----------------------------------------------------

-- Walk the live PM for its child polygon Model (PolyEditPolygon attribute)
-- and read each vertex Part (PolyEditVertexIndex attribute) directly.
-- Positions are transformed into the PM's local frame so XZ matches the
-- proc-local coordinates the rest of the pipeline expects.
local function readVerticesFromPM(pm: Instance): { Vector3 }?
	local pivot = pm:GetPivot()
	local polygonModel: Instance? = nil
	for _, d in ipairs(pm:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("PolyEditPolygon") == true then
			polygonModel = d
			break
		end
	end
	if not polygonModel then
		return nil
	end
	local indexed: { { idx: number, pos: Vector3 } } = {}
	for _, child in ipairs(polygonModel:GetChildren()) do
		local idx = child:GetAttribute("PolyEditVertexIndex")
		if typeof(idx) == "number" and child:IsA("BasePart") then
			indexed[#indexed + 1] = { idx = idx, pos = pivot:PointToObjectSpace(child.Position) }
		end
	end
	if #indexed < 2 then
		return nil
	end
	table.sort(indexed, function(a, b)
		return a.idx < b.idx
	end)
	local out: { Vector3 } = table.create(#indexed)
	for i, v in ipairs(indexed) do
		out[i] = v.pos
	end
	return out
end

-- ---- 2D helpers ----------------------------------------------------------

-- Signed area in the XZ plane. Positive = CCW from above (+Y looking down).
local function signedAreaXZ(verts: { Vector3 }): number
	local n = #verts
	local s = 0
	for i = 1, n do
		local a = verts[i]
		local b = verts[(i % n) + 1]
		s += a.X * b.Z - b.X * a.Z
	end
	return s * 0.5
end

-- ---- polygon refinement: corner rounding ---------------------------------

-- For each polygon corner, fillet with a circular arc.
-- Tangent length along each adjacent edge is t = r / tan(θ/2). The largest
-- radius that fits in the corner is rMax = tan(θ/2) * min(edgeA, edgeB)/2.
-- We use min(radius, rMax); if that falls below `minRadius` the corner
-- stays sharp. Otherwise it's replaced by `segments + 1` arc points.
local function refinePolygon(
	verts: { Vector3 },
	radius: number?,
	minRadius: number?,
	segments: number?,
	noFillet: { boolean }?,
	immune: { boolean }?
): ({ Vector3 }, { boolean }, { boolean })
	local r = radius or 0
	local rMin = minRadius or 0
	local seg = segments or 0
	local n = #verts
	local function passthroughImmune(): { boolean }
		local arr = table.create(n, true)
		if immune then
			for i = 1, n do
				arr[i] = immune[i]
			end
		end
		return arr
	end
	local function passthroughNoFillet(): { boolean }
		local arr = table.create(n, false)
		if noFillet then
			for i = 1, n do
				arr[i] = noFillet[i]
			end
		end
		return arr
	end
	if r <= 0 or seg < 1 or n < 3 then
		return verts, passthroughImmune(), passthroughNoFillet()
	end
	if rMin < 0 then
		rMin = 0
	end
	if rMin > r then
		rMin = r
	end
	local out: { Vector3 } = {}
	local outImmune: { boolean } = {}
	local outNoFillet: { boolean } = {}

	local function emit(v: Vector3, idx: number)
		table.insert(out, v)
		table.insert(outImmune, if immune then immune[idx] else true)
		table.insert(outNoFillet, if noFillet then noFillet[idx] else false)
	end

	for i = 1, n do
		if noFillet and noFillet[i] then
			emit(verts[i], i)
			continue
		end
		local prev = verts[((i - 2) % n) + 1]
		local curr = verts[i]
		local nxt = verts[(i % n) + 1]

		local dAx, dAz = prev.X - curr.X, prev.Z - curr.Z
		local lenA = math.sqrt(dAx * dAx + dAz * dAz)
		local dCx, dCz = nxt.X - curr.X, nxt.Z - curr.Z
		local lenC = math.sqrt(dCx * dCx + dCz * dCz)
		if lenA < 1e-3 or lenC < 1e-3 then
			emit(curr, i)
			continue
		end
		dAx, dAz = dAx / lenA, dAz / lenA
		dCx, dCz = dCx / lenC, dCz / lenC

		local cosTheta = math.clamp(dAx * dCx + dAz * dCz, -1, 1)
		local theta = math.acos(cosTheta)
		if theta < 1e-3 or math.pi - theta < 1e-3 then
			emit(curr, i)
			continue
		end

		local halfTheta = theta * 0.5
		local tanHalf = math.tan(halfTheta)
		local tMax = math.min(lenA, lenC) * 0.5
		local rMax = tMax * tanHalf
		local rEff = math.min(r, rMax)
		if rEff < rMin then
			emit(curr, i)
			continue
		end
		local t = rEff / tanHalf

		local tangentInX = curr.X + dAx * t
		local tangentInZ = curr.Z + dAz * t
		local tangentOutX = curr.X + dCx * t
		local tangentOutZ = curr.Z + dCz * t

		local biX, biZ = dAx + dCx, dAz + dCz
		local biLen = math.sqrt(biX * biX + biZ * biZ)
		biX, biZ = biX / biLen, biZ / biLen
		local centerDist = rEff / math.sin(halfTheta)
		local centerX = curr.X + biX * centerDist
		local centerZ = curr.Z + biZ * centerDist

		local startAngle = math.atan2(tangentInZ - centerZ, tangentInX - centerX)
		local endAngle = math.atan2(tangentOutZ - centerZ, tangentOutX - centerX)
		local diff = endAngle - startAngle
		if diff > math.pi then
			diff -= 2 * math.pi
		end
		if diff <= -math.pi then
			diff += 2 * math.pi
		end

		for s = 0, seg do
			local frac = s / seg
			local ang = startAngle + diff * frac
			emit(Vector3.new(centerX + rEff * math.cos(ang), curr.Y, centerZ + rEff * math.sin(ang)), i)
		end
	end

	return out, outImmune, outNoFillet
end

-- Inward offset of a 2D polygon by `amount`. Wraps Geometry.insetPolygon
-- and lifts back to Vector3 with each input vertex's Y preserved.
local function insetPolygonXZ(verts: { Vector3 }, amount: number): { Vector3 }
	local poly2D = table.create(#verts)
	for i, v in ipairs(verts) do
		poly2D[i] = { v.X, v.Z }
	end
	local inset2D = Geometry.insetPolygon(poly2D, amount)
	local out: { Vector3 } = table.create(#inset2D)
	for i, v in ipairs(inset2D) do
		out[i] = Vector3.new(v[1], verts[i].Y, v[2])
	end
	return out
end

-- ---- grid subdivision ----------------------------------------------------

-- Insert intermediate vertices wherever a polygon edge crosses an X or Z
-- grid line spaced at `cellSize` studs, and report the position of each
-- original corner in the carved polygon. The corner-index map lets the
-- cap pipeline pair pillow panels by polygon edge across rings whose
-- grid carvings differ in vertex count. The optional `immune` array (one
-- entry per input vertex) is propagated to the carved polygon: each
-- subdivision on edge i inherits AND of immune[i] and immune[i+1] — so a
-- new vertex on a fully-exterior edge stays immune, on a fully-interior
-- edge stays subject to displacement, and on a mixed edge is flagged
-- immune (conservatively, since mixed edges only happen at the slit's
-- entry where subdivisions are physically outside the cutter footprint).
local function subdivideOnGridTracked(
	poly: { Vector3 },
	immune: { boolean }?,
	noFillet: { boolean }?,
	cellSize: number
): ({ Vector3 }, { number }, { boolean }, { boolean })
	local n = #poly
	local function passthroughImmune(): { boolean }
		local out = table.create(n, true)
		if immune then
			for i = 1, n do
				out[i] = immune[i]
			end
		end
		return out
	end
	local function passthroughNoFillet(): { boolean }
		local out = table.create(n, false)
		if noFillet then
			for i = 1, n do
				out[i] = noFillet[i]
			end
		end
		return out
	end
	if cellSize <= 0 or n < 3 then
		local cornerIdx = table.create(n)
		for i = 1, n do
			cornerIdx[i] = i
		end
		return poly, cornerIdx, passthroughImmune(), passthroughNoFillet()
	end
	local out: { Vector3 } = {}
	local outImmune: { boolean } = {}
	local outNoFillet: { boolean } = {}
	local cornerIdx: { number } = table.create(n)
	for i = 1, n do
		local a = poly[i]
		local b = poly[(i % n) + 1]
		local immA = if immune then immune[i] else true
		local immB = if immune then immune[(i % n) + 1] else true
		local subdivImmune = immA and immB
		local nfA = if noFillet then noFillet[i] else false
		table.insert(out, a)
		table.insert(outImmune, immA)
		table.insert(outNoFillet, nfA)
		cornerIdx[i] = #out

		local crossings: { { t: number, p: Vector3 } } = {}
		local function addX(x: number)
			local denom = b.X - a.X
			if math.abs(denom) < 1e-9 then
				return
			end
			local t = (x - a.X) / denom
			if t > 1e-6 and t < 1 - 1e-6 then
				local y = a.Y + t * (b.Y - a.Y)
				local z = a.Z + t * (b.Z - a.Z)
				table.insert(crossings, { t = t, p = Vector3.new(x, y, z) })
			end
		end
		local function addZ(z: number)
			local denom = b.Z - a.Z
			if math.abs(denom) < 1e-9 then
				return
			end
			local t = (z - a.Z) / denom
			if t > 1e-6 and t < 1 - 1e-6 then
				local x = a.X + t * (b.X - a.X)
				local y = a.Y + t * (b.Y - a.Y)
				table.insert(crossings, { t = t, p = Vector3.new(x, y, z) })
			end
		end

		local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
		for k = math.ceil(minX / cellSize), math.floor(maxX / cellSize) do
			addX(k * cellSize)
		end
		local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
		for k = math.ceil(minZ / cellSize), math.floor(maxZ / cellSize) do
			addZ(k * cellSize)
		end

		table.sort(crossings, function(p, q)
			return p.t < q.t
		end)
		for _, c in ipairs(crossings) do
			table.insert(out, c.p)
			table.insert(outImmune, subdivImmune)
			-- Subdivision verts are never noFillet — they're new mid-edge
			-- points, never original detour corners.
			table.insert(outNoFillet, false)
		end
	end
	return out, cornerIdx, outImmune, outNoFillet
end

-- ---- triangulation wrapper ------------------------------------------------

local function triangulateXZ(verts: { Vector3 }): { { Vector3 } }
	local poly2D = table.create(#verts)
	for i, v in ipairs(verts) do
		poly2D[i] = { v.X, v.Z }
	end
	local tris2D = Geometry.triangulate(poly2D)
	local out: { { Vector3 } } = {}
	for _, t in ipairs(tris2D) do
		table.insert(out, {
			Vector3.new(t[1][1], 0, t[1][2]),
			Vector3.new(t[2][1], 0, t[2][2]),
			Vector3.new(t[3][1], 0, t[3][2]),
		})
	end
	return out
end

-- Returns true if the polygon has any reflex (concave) vertex — i.e. a
-- right-turn at a CCW polygon. Sutherland-Hodgman cell-clipping below
-- can self-intersect on concave subjects (it produces "spike" results
-- that double back along the cell edge), so we fall back to a single
-- ear-clip pass on the whole polygon for those.
local function hasConcaveVert(verts: { Vector3 }): boolean
	local n = #verts
	for i = 1, n do
		local a = verts[((i - 2) % n) + 1]
		local b = verts[i]
		local c = verts[(i % n) + 1]
		local cross = (b.X - a.X) * (c.Z - b.Z) - (b.Z - a.Z) * (c.X - b.X)
		if cross < -1e-6 then
			return true
		end
	end
	return false
end

-- Like triangulateXZ but first dices the polygon's AABB into XZ cells of
-- `cellSize` studs, clips the polygon to each cell, and ear-clips the
-- per-cell piece. This keeps any sliver triangles bounded to a single
-- cell instead of letting them stretch the full polygon width.
local function triangulateOnGrid(verts: { Vector3 }, cellSize: number): { { Vector3 } }
	if cellSize <= 0 or #verts < 3 then
		return triangulateXZ(verts)
	end
	-- Sutherland-Hodgman cell-clipping mishandles concave subjects (the
	-- per-cell clip can produce self-intersecting "spike" polygons that
	-- earclipping then triangulates into reverse-winding triangles).
	-- Fall back to a single full-polygon triangulation for concave
	-- subjects — slightly less uniform triangle density, but correct.
	if hasConcaveVert(verts) then
		return triangulateXZ(verts)
	end

	local minX, minZ = math.huge, math.huge
	local maxX, maxZ = -math.huge, -math.huge
	for _, v in ipairs(verts) do
		if v.X < minX then
			minX = v.X
		end
		if v.X > maxX then
			maxX = v.X
		end
		if v.Z < minZ then
			minZ = v.Z
		end
		if v.Z > maxZ then
			maxZ = v.Z
		end
	end

	local startX = math.floor(minX / cellSize) * cellSize
	local startZ = math.floor(minZ / cellSize) * cellSize

	local poly2D = table.create(#verts)
	for i, v in ipairs(verts) do
		poly2D[i] = { v.X, v.Z }
	end

	local triangles: { { Vector3 } } = {}
	local x = startX
	while x < maxX do
		local z = startZ
		while z < maxZ do
			-- Cell rectangle (CCW). Sutherland-Hodgman wants the CLIP
			-- polygon to be convex; the rectangle qualifies.
			local cellRect = {
				{ x, z },
				{ x + cellSize, z },
				{ x + cellSize, z + cellSize },
				{ x, z + cellSize },
			}
			local clipped = Geometry.clipToPolygon(poly2D, cellRect)
			if clipped and #clipped >= 3 then
				for _, t in ipairs(Geometry.triangulate(clipped)) do
					table.insert(triangles, {
						Vector3.new(t[1][1], 0, t[1][2]),
						Vector3.new(t[2][1], 0, t[2][2]),
						Vector3.new(t[3][1], 0, t[3][2]),
					})
				end
			end
			z += cellSize
		end
		x += cellSize
	end
	return triangles
end

-- ---- mesh bake helper -----------------------------------------------------

local FIDELITY_OPTS = {
	RenderFidelity = Enum.RenderFidelity.Precise,
	CollisionFidelity = Enum.CollisionFidelity.Default,
	FluidFidelity = Enum.FluidFidelity.UseCollisionGeometry,
}

local function bakeAndMount(em, name: string, color: Color3, material: Enum.Material, parent: Instance)
	local Content = (getfenv(1) :: any).Content
	local bakeResult, baked = AssetService:CreateDataModelContentAsync(Content.fromObject(em), FIDELITY_OPTS)
	em:Destroy()
	if bakeResult ~= Enum.CreateContentResult.Success then
		warn("[Landmass] " .. name .. " CreateDataModelContentAsync returned " .. tostring(bakeResult))
		return
	end
	local ok, meshPart = pcall(function()
		return AssetService:CreateMeshPartAsync(baked, FIDELITY_OPTS)
	end)
	if not ok or not meshPart then
		warn("[Landmass] " .. name .. " CreateMeshPartAsync failed: " .. tostring(meshPart))
		return
	end
	meshPart.Name = name
	meshPart.Anchored = true
	meshPart.CanCollide = true
	meshPart.CastShadow = true
	meshPart.Material = material
	meshPart.Color = color
	pcall(function()
		(meshPart :: any).RenderFidelity = Enum.RenderFidelity.Precise
	end)
	pcall(function()
		(meshPart :: any).CollisionFidelity = Enum.CollisionFidelity.Default
	end)
	pcall(function()
		(meshPart :: any).FluidFidelity = Enum.FluidFidelity.UseCollisionGeometry
	end)
	meshPart.Parent = parent
end

-- ---- piece builders -------------------------------------------------------

-- ---- displacement-based shading ------------------------------------------

-- Shading: lerps toward white (positive disp) or black (negative disp).
-- `strength` = maximum lerp factor at peak displacement. `reference` =
-- displacement (studs) that hits that peak. Both come from attributes
-- so artists can dial them without editing code.
local SHADE_WHITE = Color3.new(1, 1, 1)
local SHADE_BLACK = Color3.new(0, 0, 0)

local function shadeTint(base: Color3, disp: number, strength: number, reference: number): Color3
	if reference < 1e-6 or strength < 1e-6 then
		return base
	end
	if disp >= 0 then
		local f = math.clamp(disp / reference, 0, 1) * strength
		return base:Lerp(SHADE_WHITE, f)
	else
		local f = math.clamp(-disp / reference, 0, 1) * strength
		return base:Lerp(SHADE_BLACK, f)
	end
end

-- ---- self-identity lookup ------------------------------------------------

-- The generator sandbox can read Workspace but can't directly find the
-- ProceduralModel it's running for. PolyEdit stamps a stable Guid
-- attribute + HAS_GUID tag on each PM, so we can look ourselves up via
-- CollectionService and read live state (pivot, etc.) instead of relying
-- on stamped attributes that go stale when the PM moves.
local function findSelfPM(guid: any): Instance?
	if typeof(guid) ~= "string" or #guid == 0 then
		return nil
	end
	local CS = game:GetService("CollectionService")
	for _, inst in CS:GetTagged("HAS_GUID") do
		if inst:GetAttribute("Guid") == guid then
			return inst
		end
	end
	return nil
end

-- ---- displacers ----------------------------------------------------------

type Hill = { x: number, z: number, radius: number, height: number }

-- ADD_PART: a thin Part dropped into the PM whose top-down XZ footprint
-- becomes a heightmap stamp. The part's TOP face plane defines the
-- height — sample Y at (x, z) by intersecting a vertical line with the
-- plane through `topRef` (= cframe.Position + cframe.UpVector * size.Y/2)
-- with normal `cframe.UpVector`. Tilt the part → wedge. Footprint is
-- Size.X × Size.Z in part-local; outside-only halo falloff over
-- `falloff` studs.
type WedgePart = {
	cframe: CFrame, -- proc-local
	topRef: Vector3, -- proc-local center of the top face (where sampleY is referenced from)
	halfX: number,
	halfZ: number,
	falloff: number,
	cut: boolean, -- when true, also notches the polygon along this part's footprint
	-- For cut wedges: cached XZ footprint quad in proc-local. Used both for
	-- slit insertion (perimeter crossings) and for the top face's
	-- "is this boundary vert on/inside the cutter" check, which can't rely
	-- on the loaf-immune flag (slit entry A is loaf-immune by design but
	-- still on the cutter footprint, and the top face must follow the
	-- cutter plane there to avoid a green wedge artifact).
	footprint: { { number } }?,
}

-- Bundle passed through buildCliff/buildCap so per-vertex displacement
-- only needs one call site. `surfaceY` is the cap's nominal top Y
-- (baseY + cliffHeight + capHeight) — wedge parts treat it as the
-- zero-displacement reference so a Block placed at world-Y matches the
-- cap surface there exactly. (Hills don't use surfaceY; their height is
-- a scalar attribute regardless of part Y.)
type Displacers = {
	hills: { Hill },
	wedges: { WedgePart },
	surfaceY: number,
}

-- Read ADD_HILL tagged parts that are descendants of selfPM and transform
-- their world positions into the polygon's local frame. Hills are
-- local-only — drop into a landmass PM to add detail to that landmass.
-- Unparented hills (not under any PM) are ignored.
local function readHills(
	pivotCF: CFrame,
	selfPM: Instance,
	minX: number,
	minZ: number,
	maxX: number,
	maxZ: number
): { Hill }
	local out: { Hill } = {}
	local CS = game:GetService("CollectionService")
	for _, part in ipairs(CS:GetTagged("ADD_HILL")) do
		if not part:IsA("BasePart") then
			continue
		end
		if not part:IsDescendantOf(selfPM) then
			continue
		end
		local radius = tonumber(part:GetAttribute("Radius")) or 0
		local height = tonumber(part:GetAttribute("Height")) or 0
		if radius <= 0 or math.abs(height) < 1e-6 then
			continue
		end

		local localPos = pivotCF:PointToObjectSpace(part.Position)
		if
			localPos.X + radius < minX
			or localPos.X - radius > maxX
			or localPos.Z + radius < minZ
			or localPos.Z - radius > maxZ
		then
			continue
		end
		table.insert(out, {
			x = localPos.X,
			z = localPos.Z,
			radius = radius,
			height = height,
		})
	end
	return out
end

-- Compute a wedge part's XZ footprint in proc-local coords as a CCW 4-gon
-- (or nil if the projection collapses).
local function wedgeFootprint(p: WedgePart): { { number } }?
	local hx, hz = p.halfX, p.halfZ
	local corners = {
		Vector3.new(-hx, 0, -hz),
		Vector3.new(hx, 0, -hz),
		Vector3.new(hx, 0, hz),
		Vector3.new(-hx, 0, hz),
	}
	local out: { { number } } = table.create(4)
	for i, c in ipairs(corners) do
		local proj = p.cframe:PointToWorldSpace(c)
		out[i] = { proj.X, proj.Z }
	end
	local s = 0
	for i = 1, 4 do
		local a = out[i]
		local b = out[(i % 4) + 1]
		s += a[1] * b[2] - b[1] * a[2]
	end
	if math.abs(s) < 1e-9 then
		return nil
	end
	if s < 0 then
		out = { out[4], out[3], out[2], out[1] }
	end
	return out
end

-- Clip the cutter footprint along the line where its tilted top plane
-- crosses surfaceY. Keep the half where sampleY <= surfaceY (the
-- portion of the cutter that sits at or below the hilltop). The user
-- positions the cutter's plane so the line where it crosses surfaceY
-- runs along where they want the ramp to meet the hilltop; the
-- clipped footprint is what the ramp generator and applyCutter-
-- Difference both use, so the host's notch and the ramp's outer
-- boundary share the same clip line.
local function clipFootprintBelowSurface(
	footprint: { { number } },
	plane: {
		topRefX: number,
		topRefY: number,
		topRefZ: number,
		upX: number,
		upY: number,
		upZ: number,
	},
	surfaceY: number
): { { number } }?
	-- sampleY <= surfaceY ⇔ A*x + C*z >= B  where
	-- A = upX/upY, C = upZ/upY, B = (upX*topRefX + upZ*topRefZ)/upY + (topRefY - surfaceY).
	if math.abs(plane.upY) < 1e-3 then
		return footprint
	end
	local A = plane.upX / plane.upY
	local C = plane.upZ / plane.upY
	local B = A * plane.topRefX + C * plane.topRefZ + (plane.topRefY - surfaceY)
	local function side(x: number, z: number): number -- positive = below surface (keep)
		return A * x + C * z - B
	end
	local out: { { number } } = {}
	local n = #footprint
	for i = 1, n do
		local curr = footprint[i]
		local prev = footprint[((i - 2) % n) + 1]
		local sCurr = side(curr[1], curr[2])
		local sPrev = side(prev[1], prev[2])
		if sCurr >= -1e-9 then
			if sPrev < -1e-9 then
				local t = sPrev / (sPrev - sCurr)
				table.insert(out, { prev[1] + t * (curr[1] - prev[1]), prev[2] + t * (curr[2] - prev[2]) })
			end
			table.insert(out, { curr[1], curr[2] })
		elseif sPrev >= -1e-9 then
			local t = sPrev / (sPrev - sCurr)
			table.insert(out, { prev[1] + t * (curr[1] - prev[1]), prev[2] + t * (curr[2] - prev[2]) })
		end
	end
	if #out < 3 then
		return nil
	end
	return out
end

-- Point-in-polygon for a CCW 2D polygon stored as { {x, z}, ... }. Used
-- to tag subject verts that lie inside the cutter footprint quad.
local function pointInQuadXZ(px: number, pz: number, poly: { { number } }): boolean
	local n = #poly
	local inside = false
	local j = n
	for i = 1, n do
		local pi, pj = poly[i], poly[j]
		if (pi[2] > pz) ~= (pj[2] > pz) then
			local xIntersect = pi[1] + (pz - pi[2]) / (pj[2] - pi[2]) * (pj[1] - pi[1])
			if px < xIntersect then
				inside = not inside
			end
		end
		j = i
	end
	return inside
end

-- Read ADD_PART tagged parts under selfPM and project into proc-local.
-- Skips parts whose Up vector has no Y component (laid on their side) —
-- the plane equation can't sample a vertical line through them.
local function readWedgeParts(pivotCF: CFrame, selfPM: Instance): { WedgePart }
	local out: { WedgePart } = {}
	local CS = game:GetService("CollectionService")
	local pivotInv = pivotCF:Inverse()
	for _, part in ipairs(CS:GetTagged("ADD_PART")) do
		if not part:IsA("BasePart") then
			continue
		end
		if not part:IsDescendantOf(selfPM) then
			continue
		end
		local localCF = pivotInv * part.CFrame
		if math.abs(localCF.UpVector.Y) < 1e-3 then
			continue
		end
		local falloff = tonumber(part:GetAttribute("Falloff")) or 0
		if falloff < 0 then
			falloff = 0
		end
		-- Cut parts notch the polygon along their footprint, so the
		-- surrounding terrain shouldn't fade in via the halo — that would
		-- displace the pillows just outside the cut edge that we don't
		-- want touched. Force falloff to 0 for cut parts.
		local cut = part:GetAttribute("Cut") == true
		if cut then
			falloff = 0
		end
		local size = part.Size
		local topRef = localCF.Position + localCF.UpVector * (size.Y * 0.5)
		local wedge: WedgePart = {
			cframe = localCF,
			topRef = topRef,
			halfX = size.X * 0.5,
			halfZ = size.Z * 0.5,
			falloff = falloff,
			cut = cut,
			footprint = nil,
		}
		if cut then
			wedge.footprint = wedgeFootprint(wedge)
		end
		table.insert(out, wedge)
	end
	return out
end

-- Returns (total, nonCut, hills) Y-delta at proc-local (x, z).
--   total   = hills + non-cut wedges + cut wedges. Used for non-
--             immune verts (ramp polygon — follows cutter plane).
--   nonCut  = hills + non-cut wedges. Used for immune verts (host
--             perimeter — affected by hills and slope wedges, but
--             not by cut wedges).
--   hills   = hill displacement only. Drives shadeTint (slope wedges
--             are uniform tilts, not peaks, so they'd paint a stale
--             brightness gradient if included in tinting).
-- `cutInside`: caller-provided "this vertex was generated inside a cut
-- wedge's footprint" tag. Slit verts (entries + interior corners) and
-- pre-existing polygon verts inside the cutter footprint set it true, so
-- displacement skips the SDF check for cut wedges and uses factor=1
-- directly. The SDF was failing at the cutter's interior corner because
-- the part-local→world→part-local roundtrip drops 1e-7..1e-5 of precision
-- onto a corner whose distance to the rectangle edge is exactly 0; with
-- falloff=0 (cut parts) any positive epsilon zeroed the factor and silently
-- killed the displacement at the very vertex we wanted displaced. Since
-- we generated those verts ourselves, we know they're inside — just say
-- so, no epsilon needed. Non-cut wedges (with halo falloff) still run the
-- SDF since the factor is genuinely a function of XZ position there.
local function displacement(d: Displacers, x: number, z: number, cutInside: boolean?): (number, number, number)
	local hills = 0

	for _, h in ipairs(d.hills) do
		local dx = x - h.x
		local dz = z - h.z
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < h.radius then
			local t = dist / h.radius
			-- 1 - smoothstep(t) = 1 - (3t² - 2t³)
			hills += h.height * (1 - (3 * t * t - 2 * t * t * t))
		end
	end

	local nonCutWedges = 0
	local cutWedges = 0

	for _, p in ipairs(d.wedges) do
		local up = p.cframe.UpVector
		local topRef = p.topRef
		-- Plane through topRef (top face centre), normal up: solve up·(P - topRef) = 0 for P.Y.
		local sampleY = topRef.Y - (up.X * (x - topRef.X) + up.Z * (z - topRef.Z)) / up.Y
		-- Rectangle SDF in part-local coords. Inside: distance is 0
		-- (factor = 1, full effect). Outside: positive distance to the
		-- rectangle edge — falloff is a halo *around* the footprint, so
		-- the slope inside is unreducible and tapers smoothly outside.
		--
		-- The SDF check projects the world (x, z) onto the part's CENTER
		-- plane (part-local Y=0), NOT the top plane. wedgeFootprint also
		-- uses the centre plane to compute the cutter quad, so the slit's
		-- "interior corner" lands exactly on the centre-plane rectangle
		-- corner. If we projected onto the top plane (part-local Y=halfY),
		-- a tilted part's top-plane rectangle in world XZ is shifted
		-- relative to its centre-plane rectangle, and the interior corner
		-- falls just outside — which silently kills the wedge contribution
		-- (factor=0 with falloff=0) at the very vertex we wanted displaced.
		local factor: number
		if p.cut and cutInside then
			-- Caller tagged this vert as inside this cutter's footprint at
			-- generation time. Skip the SDF — factor is exactly 1.
			factor = 1
		else
			local pos = p.cframe.Position
			local centerY = pos.Y - (up.X * (x - pos.X) + up.Z * (z - pos.Z)) / up.Y
			local localPos = p.cframe:PointToObjectSpace(Vector3.new(x, centerY, z))
			local dx = math.abs(localPos.X) - p.halfX
			local dz = math.abs(localPos.Z) - p.halfZ
			local outsideDist
			if dx <= 0 and dz <= 0 then
				outsideDist = 0
			else
				local ox = if dx > 0 then dx else 0
				local oz = if dz > 0 then dz else 0
				outsideDist = math.sqrt(ox * ox + oz * oz)
			end
			if outsideDist <= 0 then
				factor = 1
			elseif p.falloff > 1e-6 and outsideDist < p.falloff then
				factor = 1 - outsideDist / p.falloff
			else
				continue
			end
		end
		local contrib = (sampleY - d.surfaceY) * factor
		if p.cut then
			cutWedges += contrib
		else
			nonCutWedges += contrib
		end
	end

	local nonCut = hills + nonCutWedges
	return nonCut + cutWedges, nonCut, hills
end

-- ---- polygon slits ------------------------------------------------------

-- Compute polygon difference: subject - clip. Returns the polygon with
-- the cutter footprint removed. The result perimeter follows the
-- subject perimeter outside the cutter, and detours along the cutter
-- perimeter (CW around cutter, so cutter interior stays outside the
-- result) for the portion that would otherwise be inside the cutter.
--
-- Only handles the "ramp pokes through one polygon edge" case: exactly
-- two subject↔cutter crossings forming an entry/exit pair. Falls back
-- to returning the subject unchanged for 0 crossings (cutter doesn't
-- cross the perimeter — either entirely inside or entirely outside)
-- or any other count (multi-pass cuts not supported here).
-- Returns (cutPolygon, noFillet, immune) where:
--  - noFillet[i] = true at the cutter's INTERIOR detour corners
--    (kept sharp via refinePolygon so the host/ramp boundary reads as a
--    crisp right-angle line).
--  - immune[i] = false at every cut-inserted vertex (entry/exit
--    crossings + detour corners). Original subject perimeter verts
--    stay immune=true. buildCap uses this to detect "host-ramp join"
--    edges (both endpoints non-immune) and skip the loaf bevel there.
local function applyCutterDifference(
	subject: { Vector3 },
	clip: { { number } }
): ({ Vector3 }, { boolean }, { boolean })
	local nS = #subject
	local nC = #clip
	if nS < 3 or nC < 3 then
		return subject, table.create(nS, false), table.create(nS, true)
	end

	-- Find all subject↔cutter intersections.
	type Ix = { sEdge: number, sT: number, cEdge: number, x: number, y: number, z: number }
	local ixs: { Ix } = {}
	for i = 1, nS do
		local sa = subject[i]
		local sb = subject[(i % nS) + 1]
		local d1x, d1z = sb.X - sa.X, sb.Z - sa.Z
		for j = 1, nC do
			local ca = clip[j]
			local cb = clip[(j % nC) + 1]
			local d2x, d2z = cb[1] - ca[1], cb[2] - ca[2]
			local denom = d1x * d2z - d1z * d2x
			if math.abs(denom) > 1e-9 then
				local t1 = ((ca[1] - sa.X) * d2z - (ca[2] - sa.Z) * d2x) / denom
				local t2 = ((ca[1] - sa.X) * d1z - (ca[2] - sa.Z) * d1x) / denom
				if t1 > 1e-6 and t1 < 1 - 1e-6 and t2 > 1e-6 and t2 < 1 - 1e-6 then
					table.insert(ixs, {
						sEdge = i,
						sT = t1,
						cEdge = j,
						x = sa.X + t1 * d1x,
						y = sa.Y + t1 * (sb.Y - sa.Y),
						z = sa.Z + t1 * d1z,
					})
				end
			end
		end
	end

	if #ixs == 0 then
		return subject, table.create(nS, false), table.create(nS, true)
	end
	if #ixs ~= 2 then
		warn(
			"[Landmass] applyCutterDifference: expected 2 polygon-cutter crossings, got " .. #ixs .. " — skipping cut"
		)
		return subject, table.create(nS, false), table.create(nS, true)
	end

	-- Order crossings by walk position; then identify entry vs exit by
	-- checking whether the polygon vertex at the start of the first
	-- crossing's edge is inside the cutter (then the first crossing is
	-- actually the exit).
	table.sort(ixs, function(a, b)
		if a.sEdge ~= b.sEdge then
			return a.sEdge < b.sEdge
		end
		return a.sT < b.sT
	end)
	local entry, exit
	if pointInQuadXZ(subject[ixs[1].sEdge].X, subject[ixs[1].sEdge].Z, clip) then
		exit, entry = ixs[1], ixs[2]
	else
		entry, exit = ixs[1], ixs[2]
	end

	-- Detour from entry to exit, walking the cutter perimeter CW (cutter
	-- interior on right of walk → cutter region stays OUTSIDE the result).
	-- Visit cutter corners clip[entry.cEdge], clip[entry.cEdge - 1], …,
	-- clip[exit.cEdge + 1]; the exit point itself is appended later via
	-- the polygon walk's exit-crossing handler.
	local detour: { { number } } = {}
	local k = entry.cEdge
	while k ~= exit.cEdge do
		table.insert(detour, { clip[k][1], clip[k][2] })
		k = ((k - 2) % nC) + 1
	end

	local subjectBaseY = subject[1].Y
	local crossingsByEdge: { { Ix } } = table.create(nS)
	for i = 1, nS do
		crossingsByEdge[i] = {}
	end
	table.insert(crossingsByEdge[entry.sEdge], entry)
	table.insert(crossingsByEdge[exit.sEdge], exit)
	for i = 1, nS do
		if #crossingsByEdge[i] > 1 then
			table.sort(crossingsByEdge[i], function(a, b)
				return a.sT < b.sT
			end)
		end
	end

	local result: { Vector3 } = {}
	local noFillet: { boolean } = {}
	local immune: { boolean } = {}
	local insideCutter = pointInQuadXZ(subject[1].X, subject[1].Z, clip)
	for i = 1, nS do
		if not insideCutter then
			table.insert(result, subject[i])
			table.insert(noFillet, false)
			table.insert(immune, true) -- original subject vert
		end
		for _, ix in ipairs(crossingsByEdge[i]) do
			-- Crossing point (entry or exit) — on polygon perimeter, gets
			-- rounded by refine but is non-immune so buildCap can detect
			-- the join-edge that connects to the detour corners.
			table.insert(result, Vector3.new(ix.x, ix.y, ix.z))
			table.insert(noFillet, false)
			table.insert(immune, false)
			if ix == entry then
				-- Detour corners are at cutter interior corners (inside
				-- the host polygon). Kept sharp (noFillet) and tagged
				-- non-immune so the join-edge bevel is suppressed.
				for _, d in ipairs(detour) do
					table.insert(result, Vector3.new(d[1], subjectBaseY, d[2]))
					table.insert(noFillet, true)
					table.insert(immune, false)
				end
				insideCutter = true
			else
				insideCutter = false
			end
		end
	end

	return result, noFillet, immune
end

-- ---- cap ring preparation ------------------------------------------------

-- A bevel ring before grid carving: same vertex count + indexing as the
-- boundary refined polygon, with each vertex inset inward by a per-ring
-- offset (negative offset = outward bulge). `immune[i]` mirrors the slit
-- tag from the source refined polygon — true for original (exterior)
-- vertices, false for slit-inserted vertices that should pick up cut-
-- wedge displacement.
type CornerRing = { polygon: { Vector3 }, immune: { boolean }, noFillet: { boolean }, y: number, t: number }

-- A bevel ring after grid carving: each ring's edges have been subdivided
-- at world-grid line crossings. Different rings can end up with different
-- vertex counts (varying inset offsets cross the grid at different
-- positions), so we keep `cornerIdx[i]` = position of the i-th original
-- corner inside this ring's carved polygon. Pillow panels are paired by
-- corner index, not by carved-polygon index. `immune` is parallel to
-- `polygon` (one entry per carved vertex); subdivisions on an edge
-- inherit immune via AND of the edge endpoints' flags.
type CarvedRing = {
	polygon: { Vector3 },
	immune: { boolean },
	noFillet: { boolean },
	cornerIdx: { number },
	y: number,
	t: number,
}

-- Drop corner indices that have collapsed (zero-length edge to neighbor)
-- in ANY ring, then apply that drop to ALL rings — preserves the per-corner
-- index correspondence between rings, which is what lets pillow panels
-- pair up across the bevel stack. Without this, an over-aggressive inset
-- would silently desync the rings and produce twisted panels.
local function cleanupCornerRings(rings: { CornerRing }, epsilon: number): { CornerRing }?
	if #rings == 0 then
		return rings
	end
	local n = #rings[1].polygon
	if n < 3 then
		return rings
	end
	for _, ring in ipairs(rings) do
		if #ring.polygon ~= n then
			return nil
		end
	end

	local valid: { boolean } = table.create(n, true)
	for i = 1, n do
		for _, ring in ipairs(rings) do
			local curr = ring.polygon[i]
			local nxt = ring.polygon[(i % n) + 1]
			if (curr - nxt).Magnitude < epsilon then
				valid[i] = false
				break
			end
		end
	end

	local out: { CornerRing } = {}
	for r, ring in ipairs(rings) do
		local cleanedPoly: { Vector3 } = {}
		local cleanedImmune: { boolean } = {}
		local cleanedNoFillet: { boolean } = {}
		for i = 1, n do
			if valid[i] then
				table.insert(cleanedPoly, ring.polygon[i])
				table.insert(cleanedImmune, ring.immune[i])
				table.insert(cleanedNoFillet, ring.noFillet[i])
			end
		end
		if #cleanedPoly < 3 then
			return nil
		end
		out[r] = { polygon = cleanedPoly, immune = cleanedImmune, noFillet = cleanedNoFillet, y = ring.y, t = ring.t }
	end
	return out
end

-- Build the cap's bevel rings (corner-only insets along the pillow
-- profile), run cleanup with corner-drop propagation, then grid-carve
-- every ring on the world grid. Same grid spacing on every ring is what
-- gives the hill displacement consistent (x, z) sample points across the
-- bevel stack — without it, the lower ring would have a hill peak at a
-- mid-edge grid crossing while the upper ring would skip straight over
-- it, producing a kink AND a T-junction between the two rings.
local function prepareCapRings(
	refined: { Vector3 },
	refinedImmune: { boolean },
	refinedNoFillet: { boolean },
	cliffTopY: number,
	capHeight: number,
	bevelInset: number,
	bevelOutset: number,
	bevelLevels: number,
	gridSize: number
): ({ CarvedRing }?, number)
	if capHeight <= 0 then
		return nil, 0
	end
	local levels = math.max(1, math.floor(bevelLevels))

	local cornerRings: { CornerRing } = {}
	-- Inset preserves vertex count + index correspondence, so each ring
	-- shares the same per-vert flag arrays as `refined`. Clone per ring so
	-- downstream cleanup edits don't bleed across rings.
	local function cloneBools(src: { boolean }): { boolean }
		local c = table.create(#src)
		for i, v in ipairs(src) do
			c[i] = v
		end
		return c
	end
	table.insert(cornerRings, {
		polygon = refined,
		immune = cloneBools(refinedImmune),
		noFillet = cloneBools(refinedNoFillet),
		y = cliffTopY,
		t = 0,
	})
	for i = 1, levels do
		local t = i / levels
		local offset = bevelOutset * math.sin(math.pi * t) - bevelInset * t
		local y = cliffTopY + capHeight * t
		local poly: { Vector3 } = if math.abs(offset) > 1e-6 then insetPolygonXZ(refined, -offset) else refined
		if #poly < 3 then
			warn("[Landmass] bevel level " .. i .. " collapsed; truncating bevel here")
			break
		end
		table.insert(cornerRings, {
			polygon = poly,
			immune = cloneBools(refinedImmune),
			noFillet = cloneBools(refinedNoFillet),
			y = y,
			t = t,
		})
	end
	if #cornerRings < 2 then
		return nil, 0
	end

	local cleaned = cleanupCornerRings(cornerRings, 0.05)
	if not cleaned then
		warn("[Landmass] cap ring cleanup produced fewer than 3 vertices; aborting cap")
		return nil, 0
	end
	local nCorners = #cleaned[1].polygon

	local carved: { CarvedRing } = table.create(#cleaned)
	for r, ring in ipairs(cleaned) do
		local poly, cornerIdx, immune, noFillet =
			subdivideOnGridTracked(ring.polygon, ring.immune, ring.noFillet, gridSize)
		carved[r] =
			{ polygon = poly, immune = immune, noFillet = noFillet, cornerIdx = cornerIdx, y = ring.y, t = ring.t }
	end
	return carved, nCorners
end

-- Cliff body: closed solid going from baseY (refined polygon) up to
-- cliffTopY (refined polygon) — straight vertical walls. Wall vertices
-- are shared around the perimeter so the cliff face shades smoothly
-- around filleted corners; bottom and top faces use their own vertices to
-- keep sharp horizontal creases. Caller must hand in a CCW-oriented
-- refined polygon.
local function buildCliff(
	refined: { Vector3 },
	refinedImmune: { boolean },
	trisRefined: { { Vector3 } },
	baseY: number,
	cliffTopY: number,
	displacers: Displacers,
	a: Attrs,
	parent: Instance
)
	if cliffTopY <= baseY then
		return
	end
	local n = #refined
	local em = AssetService:CreateEditableMesh()

	-- Two color stops for the Y gradient (baseY → cliffTopY). Read directly
	-- from live Color3 attrs; SeasonDirector pushes lerped seasonal values.
	local cliffBot = (typeof(a.CliffColorBottom) == "Color3" and a.CliffColorBottom) or FALLBACK_CLIFF_BOTTOM
	local cliffTop = (typeof(a.CliffColorTop) == "Color3" and a.CliffColorTop) or FALLBACK_CLIFF_TOP
	local cidBot = (em :: any):AddColor(cliffBot, 1)
	local cidTop = (em :: any):AddColor(cliffTop, 1)

	-- Bottom face (refined at baseY, -Y normal). Separate vertices.
	-- Top face is intentionally omitted — the cap mesh sits flush at
	-- cliffTopY and occludes anything we'd put there.
	for _, tri in ipairs(trisRefined) do
		local v1 = em:AddVertex(Vector3.new(tri[1].X, baseY, tri[1].Z))
		local v2 = em:AddVertex(Vector3.new(tri[2].X, baseY, tri[2].Z))
		local v3 = em:AddVertex(Vector3.new(tri[3].X, baseY, tri[3].Z))
		local fid = em:AddTriangle(v1, v2, v3);
		(em :: any):SetVertexFaceColor(v1, fid, cidBot);
		(em :: any):SetVertexFaceColor(v2, fid, cidBot);
		(em :: any):SetVertexFaceColor(v3, fid, cidBot)
	end

	-- Vertical wall: one shared vertex per (level, polygon-corner) so that
	-- adjacent quads around the perimeter share their seam vertices. That
	-- shared topology is what gives smooth vertex-normal averaging.
	-- The top edge is displaced by ADD_HILL/ADD_PART effectors (whole
	-- landmass lifts under the displacer); the bottom stays at baseY.
	local vTop = table.create(n)
	local vBot = table.create(n)
	for i = 1, n do
		local p = refined[i]
		local total, nonCut = displacement(displacers, p.X, p.Z, not refinedImmune[i])
		-- Immune verts (host perimeter): pick up hills + non-cut wedges
		-- (slope displacers) but NOT cut wedges. Non-immune verts (ramp
		-- polygon, follows the cutter plane): pick up everything.
		local dy = if refinedImmune[i] then nonCut else total
		local y = cliffTopY + dy
		vTop[i] = em:AddVertex(Vector3.new(p.X, y, p.Z))
		vBot[i] = em:AddVertex(Vector3.new(p.X, baseY, p.Z))
	end
	for i = 1, n do
		local j = (i % n) + 1
		local f1 = em:AddTriangle(vTop[i], vTop[j], vBot[j]);
		(em :: any):SetVertexFaceColor(vTop[i], f1, cidTop);
		(em :: any):SetVertexFaceColor(vTop[j], f1, cidTop);
		(em :: any):SetVertexFaceColor(vBot[j], f1, cidBot)
		local f2 = em:AddTriangle(vTop[i], vBot[j], vBot[i]);
		(em :: any):SetVertexFaceColor(vTop[i], f2, cidTop);
		(em :: any):SetVertexFaceColor(vBot[j], f2, cidBot);
		(em :: any):SetVertexFaceColor(vBot[i], f2, cidBot)
	end

	bakeAndMount(em, "Cliff", Color3.new(1, 1, 1), Enum.Material.Sand, parent)
end

-- Cap "muffin top": closed solid going from cliffTopY up to capTopY.
-- Pipeline (single triangle pool, single vid pool):
--   1. `prepareCapRings` builds N+1 grid-carved rings up front (see its
--      doc for the cleanup invariant).
--   2. Emit one EditableMesh vid per (ring, carved-vertex) pair. Boundary
--      sharing between top face and pillow panels falls out of using the
--      same vid table — no coord-key dedupe across topologies, no per-
--      corner normal override.
--   3. Top face = topmost ring's polygon, ear-clipped per grid cell.
--   4. Each pillow panel = one face loop per (adjacent ring pair, logical
--      polygon edge): bottom = forward run from corner i to corner j on
--      the lower carved ring, top = reverse run on the upper ring. Project
--      to (u, v) where u is along the polygon edge in XZ and v=Y, then
--      ear-clip. (u, v) winds CCW but the right-hand normal in 3D points
--      inward, so we flip when emitting — same rule the top face uses.
local function buildCap(
	carvedRings: { CarvedRing },
	nCorners: number,
	displacers: Displacers,
	a: Attrs,
	parent: Instance
)
	if #carvedRings < 2 or nCorners < 3 then
		return
	end
	local gridSize = a.GridSize or 0

	local em = AssetService:CreateEditableMesh()

	local cBottom = (typeof(a.CapColorBottom) == "Color3" and a.CapColorBottom) or FALLBACK_CAP_BOTTOM
	local cTop = (typeof(a.CapColorTop) == "Color3" and a.CapColorTop) or FALLBACK_CAP_TOP
	local shadeStrength = tonumber(a.ShadeStrength) or 0.15
	local shadeReference = tonumber(a.ShadeReference) or 6

	-- One vid per carved-ring vertex. Adjacent panels and the top face share
	-- boundary verts by reusing these — Roblox's per-vertex normal averaging
	-- then handles the bevel/top seam without any explicit override.
	local cidByVid: { [number]: number } = {}
	local vidsPerRing: { { number } } = table.create(#carvedRings)
	for r, ring in ipairs(carvedRings) do
		local row = table.create(#ring.polygon)
		local base = cBottom:Lerp(cTop, ring.t)
		for i, p in ipairs(ring.polygon) do
			local total, nonCut, hills = displacement(displacers, p.X, p.Z, not ring.immune[i])
			-- Immune verts: hills + slope wedges. Non-immune (ramp): full
			-- displacement including cut-wedge contribution. shadeTint
			-- uses hills only — slope wedges are uniform tilts, not
			-- peaks/dips, so they shouldn't paint a brightness gradient.
			local dy = if ring.immune[i] then nonCut else total
			local vid = em:AddVertex(Vector3.new(p.X, ring.y + dy, p.Z))
			cidByVid[vid] = (em :: any):AddColor(shadeTint(base, hills, shadeStrength, shadeReference), 1)
			row[i] = vid
		end
		vidsPerRing[r] = row
	end

	local function emitTri(v1: number, v2: number, v3: number): number
		local fid = em:AddTriangle(v1, v2, v3);
		(em :: any):SetVertexFaceColor(v1, fid, cidByVid[v1]);
		(em :: any):SetVertexFaceColor(v2, fid, cidByVid[v2]);
		(em :: any):SetVertexFaceColor(v3, fid, cidByVid[v3])
		return fid
	end

	-- Top face: triangulate topmost ring per grid cell. Boundary verts
	-- reuse `vidsPerRing[top]` (the loaf top vids) so the cap top and
	-- loaf top share verts at every polygon-perimeter position — no
	-- discontinuity even when the cutter pulls verts far below
	-- surfaceY. The asymmetric slit immunity (A loaf-immune at
	-- surfaceY, D loaf-non-immune at sampleY) carries through to the
	-- top face: A stays high, D dips. Interior grid verts inside the
	-- cutter footprint dip via topVid's SDF, so the cut still shows
	-- through the cap interior.
	local topRing = carvedRings[#carvedRings]
	local topVids = vidsPerRing[#carvedRings]
	local topRingBase = cBottom:Lerp(cTop, topRing.t)
	local topVidByCoord: { [string]: number } = {}
	local function coordKey(x: number, z: number): string
		return string.format("%d_%d", math.floor(x * 1000 + 0.5), math.floor(z * 1000 + 0.5))
	end
	for i, p in ipairs(topRing.polygon) do
		topVidByCoord[coordKey(p.X, p.Z)] = topVids[i]
	end
	local function topVid(x: number, z: number): number
		local key = coordKey(x, z)
		local existing = topVidByCoord[key]
		if existing then
			return existing
		end
		-- Interior grid verts run the SDF — inside the cutter footprint
		-- they pull down to sampleY, outside they sit at surfaceY.
		local dy, _nonCut, hills = displacement(displacers, x, z)
		local vid = em:AddVertex(Vector3.new(x, topRing.y + dy, z))
		cidByVid[vid] = (em :: any):AddColor(shadeTint(topRingBase, hills, shadeStrength, shadeReference), 1)
		topVidByCoord[key] = vid
		return vid
	end
	local topFaceFids: { number } = {}
	for _, tri in ipairs(triangulateOnGrid(topRing.polygon, gridSize)) do
		local v1 = topVid(tri[1].X, tri[1].Z)
		local v2 = topVid(tri[2].X, tri[2].Z)
		local v3 = topVid(tri[3].X, tri[3].Z)
		table.insert(topFaceFids, emitTri(v1, v3, v2))
	end

	-- Pillow panels: one face loop per (adjacent ring pair, polygon edge).
	-- Topmost panel fids are tracked separately so we can override their
	-- contribution to the boundary vertex normals — see below.
	local topmostPanelFids: { number } = {}
	for r = 1, #carvedRings - 1 do
		local lower = carvedRings[r]
		local upper = carvedRings[r + 1]
		local lowerVids = vidsPerRing[r]
		local upperVids = vidsPerRing[r + 1]
		local lowerN = #lower.polygon
		local upperN = #upper.polygon

		for ci = 1, nCorners do
			local cj = (ci % nCorners) + 1
			local lowerStart = lower.cornerIdx[ci]
			local lowerEnd = lower.cornerIdx[cj]
			local upperStart = upper.cornerIdx[ci]
			local upperEnd = upper.cornerIdx[cj]
			-- For the host/ramp clip-line join edge (both endpoints noFillet
			-- = both detour corners), we override bevelInset/Outset to 0 so
			-- the panel is a clean vertical wall — no horizontal offset
			-- between lower and upper rings. That fills what would
			-- otherwise be a trapezoidal hole at the seam, while the rest
			-- of the polygon's panels still use the user's authored bevel.
			-- Implementation: build the panel as if the upper ring were
			-- the same XZ as the lower at these specific verts.
			local isJoinEdge = lower.noFillet[lowerStart] and lower.noFillet[lowerEnd]

			local panelVids: { number } = {}
			local panelPos: { Vector3 } = {}

			-- panelPos uses the EMITTED Y (ring.y + hill displacement), not the
			-- source polygon's Y — the projection's v-axis reads p.Y so every
			-- vertex needs its real bake-time height, otherwise the whole
			-- panel projects to a horizontal line and the ear-clipper returns
			-- zero triangles.
			local idx = lowerStart
			while true do
				local p = lower.polygon[idx]
				local total, nonCut = displacement(displacers, p.X, p.Z, not lower.immune[idx])
				local dy = if lower.immune[idx] then nonCut else total
				table.insert(panelVids, lowerVids[idx])
				table.insert(panelPos, Vector3.new(p.X, lower.y + dy, p.Z))
				if idx == lowerEnd then
					break
				end
				idx = (idx % lowerN) + 1
			end
			idx = upperEnd
			while true do
				-- For the join edge, force the upper ring to use the LOWER
				-- ring's XZ — equivalent to bevelInset=0 just for this
				-- panel, so the seam is a vertical wall instead of a
				-- horizontally-inset slope. Keeps the user's authored
				-- bevel everywhere else.
				local p = if isJoinEdge then lower.polygon[idx] else upper.polygon[idx]
				local total, nonCut = displacement(displacers, p.X, p.Z, not upper.immune[idx])
				local dy = if upper.immune[idx] then nonCut else total
				table.insert(panelVids, upperVids[idx])
				table.insert(panelPos, Vector3.new(p.X, upper.y + dy, p.Z))
				if idx == upperStart then
					break
				end
				idx = ((idx - 2) % upperN) + 1
			end

			if #panelVids < 3 then
				continue
			end

			-- Project to (u along polygon edge in XZ, v = Y) and ear-clip.
			local edgeStart = lower.polygon[lowerStart]
			local edgeEnd = lower.polygon[lowerEnd]
			local ex, ez = edgeEnd.X - edgeStart.X, edgeEnd.Z - edgeStart.Z
			local edgeLen = math.sqrt(ex * ex + ez * ez)
			if edgeLen < 1e-6 then
				continue
			end
			ex, ez = ex / edgeLen, ez / edgeLen

			local panel2D: { { number } } = table.create(#panelPos)
			local keyToVid: { [string]: number } = {}
			local function panelKey(u: number, v: number): string
				return string.format("%.4f|%.4f", u, v)
			end
			for k, p in ipairs(panelPos) do
				local u = (p.X - edgeStart.X) * ex + (p.Z - edgeStart.Z) * ez
				local v = p.Y
				panel2D[k] = { u, v }
				keyToVid[panelKey(u, v)] = panelVids[k]
			end

			local isTopmostPair = (r == #carvedRings - 1)
			for _, tri in ipairs(Geometry.triangulate(panel2D)) do
				local v1 = keyToVid[panelKey(tri[1][1], tri[1][2])]
				local v2 = keyToVid[panelKey(tri[2][1], tri[2][2])]
				local v3 = keyToVid[panelKey(tri[3][1], tri[3][2])]
				if v1 and v2 and v3 then
					local fid = emitTri(v1, v3, v2)
					if isTopmostPair then
						table.insert(topmostPanelFids, fid)
					end
				else
					warn("[Landmass] pillow panel triangle vertex lookup failed at ring " .. r)
				end
			end
		end
	end

	-- Low-poly seam hack: pin BOTH the top face and the topmost pillow panel
	-- corner normals at top-ring vids to +Y. Roblox's per-vid averaged
	-- normal at the boundary mixes face normals from both surfaces — the
	-- pillow's tilted face contribution drags the top face's edge corners
	-- away from +Y, which shows up as a dark line on the top face right at
	-- the seam. Overriding both sides via SetVertexFaceNormal makes the
	-- corner render with explicit +Y regardless of the per-vertex average,
	-- so the top face stays flat-shaded all the way to its edge and the
	-- pillow rolls up to meet it cleanly.
	local topRowVidSet: { [number]: boolean } = {}
	for _, vid in ipairs(vidsPerRing[#carvedRings]) do
		topRowVidSet[vid] = true
	end
	local normalsOk, normalsErr = pcall(function()
		local nid = (em :: any):AddNormal(Vector3.yAxis)
		local function pinBoundary(fids: { number })
			for _, fid in ipairs(fids) do
				for _, cv in ipairs((em :: any):GetFaceVertices(fid)) do
					if topRowVidSet[cv] then
						(em :: any):SetVertexFaceNormal(cv, fid, nid)
					end
				end
			end
		end
		pinBoundary(topFaceFids)
		pinBoundary(topmostPanelFids)
	end)
	if not normalsOk then
		warn("[Landmass] could not pin top-ring boundary normals: " .. tostring(normalsErr))
	end

	bakeAndMount(em, "Cap", Color3.new(1, 1, 1), Enum.Material.Concrete, parent)
end

-- Invisible collision skirt hanging straight down from the cap's outermost
-- silhouette to baseY. The pillow profile bulges past the cliff face, so
-- without this skirt a player can squeeze in beside the cliff and end up
-- under the loaf. Top edge reuses the carved-ring vertices (with the same
-- displacement buildCap applies) so it sits flush against the visible
-- loaf rim with no gap or overlap; bottom is the same XZ extruded to baseY.
-- Top + bottom face triangulations close the shell — VHACD/convex decomp
-- needs a watertight surface to produce a usable collision volume.
local function buildOverhangBlocker(
	carvedRings: { CarvedRing },
	displacers: Displacers,
	baseY: number,
	a: Attrs,
	parent: Instance
)
	if #carvedRings < 2 then
		return
	end
	local bevelOutset = tonumber(a.BevelOutset) or 0
	local bevelInset = tonumber(a.BevelInset) or 0
	-- Pick the ring whose pillow-profile offset is most outward. Cliff
	-- edge (ring 1) is at t=0 → offset 0; max-bulge ring is somewhere
	-- mid-bevel; top ring (t=1) is inset. If everything inset, skip — the
	-- cliff itself already blocks walk-under.
	local bestIdx, bestOff = 0, 0
	for r = 2, #carvedRings do
		local t = carvedRings[r].t
		local off = bevelOutset * math.sin(math.pi * t) - bevelInset * t
		if off > bestOff then
			bestOff = off
			bestIdx = r
		end
	end
	if bestIdx == 0 or bestOff <= 1e-3 then
		return
	end

	local ring = carvedRings[bestIdx]
	local poly = ring.polygon
	local immune = ring.immune
	local n = #poly
	if n < 3 then
		return
	end

	local em = AssetService:CreateEditableMesh()
	local vTop = table.create(n)
	local vBot = table.create(n)
	for i = 1, n do
		local p = poly[i]
		-- Match buildCap's per-vertex displacement so the wall's top edge
		-- coincides with the actual cap rim vertex by vertex.
		local total, nonCut = displacement(displacers, p.X, p.Z, not immune[i])
		local dy = if immune[i] then nonCut else total
		vTop[i] = em:AddVertex(Vector3.new(p.X, ring.y + dy, p.Z))
		vBot[i] = em:AddVertex(Vector3.new(p.X, baseY, p.Z))
	end
	for i = 1, n do
		local j = (i % n) + 1
		em:AddTriangle(vTop[i], vTop[j], vBot[j])
		em:AddTriangle(vTop[i], vBot[j], vBot[i])
	end

	-- Top + bottom faces: triangulate the corner-only polygon (skip grid
	-- subdivisions) so Geometry.triangulate doesn't have to chew through
	-- collinear runs. Faces share vTop / vBot at the corners; the
	-- intermediate side-wall verts become T-junctions on the face edges,
	-- which is fine for collision (VHACD voxelizes the surface).
	local cornerPoly2D: { { number } } = {}
	local cornerVidIdx: { number } = {}
	for k, idx in ipairs(ring.cornerIdx) do
		local p = poly[idx]
		if p then
			table.insert(cornerPoly2D, { p.X, p.Z })
			table.insert(cornerVidIdx, idx)
		end
	end
	if #cornerPoly2D >= 3 then
		local function key(x: number, z: number): string
			return string.format("%d_%d", math.floor(x * 1000 + 0.5), math.floor(z * 1000 + 0.5))
		end
		local idxByKey: { [string]: number } = {}
		for ck, c in ipairs(cornerPoly2D) do
			idxByKey[key(c[1], c[2])] = cornerVidIdx[ck]
		end
		local tris2D = Geometry.triangulate(cornerPoly2D)
		if tris2D then
			for _, tri in ipairs(tris2D) do
				local i1 = idxByKey[key(tri[1][1], tri[1][2])]
				local i2 = idxByKey[key(tri[2][1], tri[2][2])]
				local i3 = idxByKey[key(tri[3][1], tri[3][2])]
				if i1 and i2 and i3 then
					em:AddTriangle(vTop[i1], vTop[i2], vTop[i3])
					em:AddTriangle(vBot[i1], vBot[i3], vBot[i2])
				end
			end
		end
	end

	local Content = (getfenv(1) :: any).Content
	local bakeResult, baked = AssetService:CreateDataModelContentAsync(Content.fromObject(em), FIDELITY_OPTS)
	em:Destroy()
	if bakeResult ~= Enum.CreateContentResult.Success then
		warn("[Landmass] OverhangBlocker CreateDataModelContentAsync returned " .. tostring(bakeResult))
		return
	end
	local ok, meshPart = pcall(function()
		return AssetService:CreateMeshPartAsync(baked, FIDELITY_OPTS)
	end)
	if not ok or not meshPart then
		warn("[Landmass] OverhangBlocker CreateMeshPartAsync failed: " .. tostring(meshPart))
		return
	end
	meshPart.Name = "OverhangBlocker"
	meshPart.Anchored = true
	meshPart.CanCollide = true
	meshPart.CanQuery = false
	meshPart.CanTouch = false
	meshPart.CastShadow = false
	meshPart.Transparency = 1
	pcall(function()
		(meshPart :: any).CollisionFidelity = Enum.CollisionFidelity.Default
	end)
	meshPart.Parent = parent
end

-- ---- main -----------------------------------------------------------------

local function OnGenerate(parameters: Params, targetContainer: Instance)
	local a = parameters.Attributes
	local selfPM = findSelfPM(a.Guid)
	if not selfPM then
		warn("[Landmass] could not find PM by Guid — re-edit the polygon to stamp Guid + HAS_GUID tag")
		return
	end
	local verts = readVerticesFromPM(selfPM)
	if not verts then
		warn("[Landmass] no PolyEdit polygon descendant found under " .. selfPM:GetFullName())
		return
	end
	if #verts < 3 then
		return
	end

	-- Normalize raw polygon to CCW. We need this BEFORE applying cuts
	-- because applyCutterDifference assumes CCW input.
	local refined: { Vector3 } = table.create(#verts)
	for i, v in ipairs(verts) do
		refined[i] = v
	end
	if signedAreaXZ(refined) < 0 then
		local reversed = table.create(#refined)
		for i = #refined, 1, -1 do
			table.insert(reversed, refined[i])
		end
		refined = reversed
	end

	local cliffHeight = a.CliffHeight or 0
	local capHeight = a.CapHeight or 0
	local bevelInset = a.BevelInset or 0
	local bevelOutset = a.BevelOutset or 0
	local bevelLevels = a.BevelLevels or 1
	local baseY = refined[1].Y
	local cliffTopY = baseY + cliffHeight
	local gridSize = a.GridSize or 0

	-- Read wedge parts up front: cut parts notch the polygon (applied
	-- before the cap rings are built) and all wedges drive displacement
	-- (applied per-vertex during cap/cliff bake). One read serves both.
	local pivotCF = selfPM:GetPivot()
	local wedges = readWedgeParts(pivotCF, selfPM)

	-- Snapshot the pre-cut polygon — needed by the ramp loop below to
	-- decide which cutter corners count as "internal-to-everything"
	-- (those falling inside this snapshot are kept sharp; outside ones
	-- round normally).
	local preCutPoly2D: { { number } } = table.create(#refined)
	for i, v in ipairs(refined) do
		preCutPoly2D[i] = { v.X, v.Z }
	end

	-- Clip each cut wedge's footprint along the line where its tilted
	-- top plane crosses surfaceY (keep the half at or below surface).
	-- The user positions the cutter's plane so this line runs along
	-- where the ramp should meet the hilltop; the clipped footprint
	-- gets passed to applyCutterDifference (host notch) and the ramp
	-- generator below, so both share the same clip line and butt
	-- together cleanly along the surfaceY-crossing line.
	local surfaceY = cliffTopY + capHeight
	for _, p in ipairs(wedges) do
		if p.cut and p.footprint then
			local clipped = clipFootprintBelowSurface(p.footprint, {
				topRefX = p.topRef.X,
				topRefY = p.topRef.Y,
				topRefZ = p.topRef.Z,
				upX = p.cframe.UpVector.X,
				upY = p.cframe.UpVector.Y,
				upZ = p.cframe.UpVector.Z,
			}, surfaceY)
			if clipped then
				p.footprint = clipped
			end
		end
	end

	-- Apply each cut wedge as a polygon difference BEFORE corner
	-- rounding, so the notch's new corners (entry/exit, plus the
	-- cutter's inner corners) get rounded by refinePolygon along with
	-- the original polygon corners. Convex corners (entry, exit) round
	-- outward; concave corners (cutter NE/SE inside polygon) round
	-- inward into the notch — except detour corners (cutter interior
	-- corners) which are kept sharp via the noFillet array so the
	-- host/ramp boundary reads as a crisp line.
	local refinedNoFillet: { boolean } = table.create(#refined, false)
	local preRefineImmune: { boolean } = table.create(#refined, true)
	for _, p in ipairs(wedges) do
		if p.cut and p.footprint then
			local cut, nf, im = applyCutterDifference(refined, p.footprint)
			if cut and #cut >= 3 then
				refined = cut
				refinedNoFillet = nf
				preRefineImmune = im
			end
		end
	end

	local refinedNoFilletOut: { boolean }
	local _refinedImmuneDiscard: { boolean }
	refined, _refinedImmuneDiscard, refinedNoFilletOut =
		refinePolygon(refined, a.CornerRadius, a.MinCornerRadius, a.CornerSegments, refinedNoFillet, preRefineImmune)
	if #refined < 3 then
		return
	end
	-- The host polygon's cap stays at the normal polygon levels — no
	-- cut-wedge displacement on the host. (The ramp landmass below is
	-- what follows the cutter's tilted plane.) refinePolygon's immune
	-- output (which propagates the cut's non-immune tag through corner
	-- rounding) is therefore discarded here; the only thing we keep
	-- from it is `refinedNoFilletOut`, which buildCap uses to skip the
	-- loaf bevel on the host/ramp join edge.
	local refinedImmune: { boolean } = table.create(#refined, true)

	-- Build + cleanup + grid-carve all bevel rings in one pass. Ring 0 is
	-- the cap's bottom ring AND the cliff's top edge polygon, so the
	-- cliff/cap seam stays watertight by construction (same vertex set on
	-- both sides). Cleanup propagates corner-drops across rings — a
	-- corner that collapses on the topmost (most-inset) ring is dropped
	-- everywhere, including on the cliff, so the whole stack stays in
	-- sync. The immune array rides alongside, propagated through inset
	-- (vertex-count-preserving) and grid carve (subdivisions inherit the
	-- AND of edge endpoints).
	local carvedRings, nCorners = prepareCapRings(
		refined,
		refinedImmune,
		refinedNoFilletOut,
		cliffTopY,
		capHeight,
		bevelInset,
		bevelOutset,
		bevelLevels,
		gridSize
	)
	if not carvedRings or nCorners < 3 then
		warn("[Landmass] failed to prepare cap rings; aborting")
		return
	end

	local ring0Polygon = carvedRings[1].polygon

	-- Read hill displacers in proc-local coords (uses the polygon's AABB
	-- for range culling). Wedges were already read above for the cuts.
	local minX, minZ = math.huge, math.huge
	local maxX, maxZ = -math.huge, -math.huge
	for _, v in ipairs(ring0Polygon) do
		if v.X < minX then
			minX = v.X
		end
		if v.X > maxX then
			maxX = v.X
		end
		if v.Z < minZ then
			minZ = v.Z
		end
		if v.Z > maxZ then
			maxZ = v.Z
		end
	end
	local displacers: Displacers = {
		hills = readHills(pivotCF, selfPM, minX, minZ, maxX, maxZ),
		wedges = wedges,
		surfaceY = surfaceY,
	}

	local ring0Immune = carvedRings[1].immune

	local trisRing0 = triangulateOnGrid(ring0Polygon, gridSize)
	buildCliff(ring0Polygon, ring0Immune, trisRing0, baseY, cliffTopY, displacers, a, targetContainer)
	buildCap(carvedRings, nCorners, displacers, a, targetContainer)
	buildOverhangBlocker(carvedRings, displacers, baseY, a, targetContainer)

	-- For each cut wedge, generate a separate "ramp" landmass at the
	-- cutter's full footprint (not just the polygon ∩ cutter slice).
	-- This lets the ramp extend beyond the host polygon's perimeter —
	-- you get a continuous ramp surface that pokes out into the world.
	-- All ramp verts are tagged non-immune so the displacement pulls
	-- the cliff top to sampleY - capHeight and the cap top to sampleY
	-- at every vert, tilting the ramp's top to follow the cutter plane.
	for _, p in ipairs(wedges) do
		if not (p.cut and p.footprint) then
			continue
		end
		local rampPoly: { Vector3 } = table.create(#p.footprint)
		for i, v in ipairs(p.footprint) do
			rampPoly[i] = Vector3.new(v[1], baseY, v[2])
		end
		if signedAreaXZ(rampPoly) < 0 then
			local reversed = table.create(#rampPoly)
			for i = #rampPoly, 1, -1 do
				table.insert(reversed, rampPoly[i])
			end
			rampPoly = reversed
		end
		-- Refine the ramp's corners with the same params as the host —
		-- the host's notch corners get the same fillet radius, so the
		-- two meshes meet cleanly along the shared boundary. Cutter
		-- corners that fall inside the host polygon are the same
		-- vertices kept sharp on the host's notch, so we keep them
		-- sharp here too — both meshes share a crisp right-angle line
		-- at the boundary.
		-- ALL ramp verts are non-immune — the entire ramp surface follows
		-- the cutter's tilted plane (sampleY at each XZ). The verts that
		-- happen to lie on the clip line (sampleY=surfaceY there) end up
		-- at the host's normal cap height automatically, since the
		-- cut-wedge displacement is 0 on that line. Cutter corners
		-- inside the host polygon also get noFillet=true so the join
		-- edge between host and ramp stays a crisp right angle.
		local rampNoFillet: { boolean } = table.create(#rampPoly, false)
		local rampPreRefineImmune: { boolean } = table.create(#rampPoly, false)
		for i, v in ipairs(rampPoly) do
			if pointInQuadXZ(v.X, v.Z, preCutPoly2D) then
				rampNoFillet[i] = true
			end
		end
		local rampImmune: { boolean }
		local rampNoFilletOut: { boolean }
		rampPoly, rampImmune, rampNoFilletOut = refinePolygon(
			rampPoly,
			a.CornerRadius,
			a.MinCornerRadius,
			a.CornerSegments,
			rampNoFillet,
			rampPreRefineImmune
		)
		if #rampPoly < 3 then
			continue
		end
		local rampRings, rampNCorners = prepareCapRings(
			rampPoly,
			rampImmune,
			rampNoFilletOut,
			cliffTopY,
			capHeight,
			bevelInset,
			bevelOutset,
			bevelLevels,
			gridSize
		)
		if not rampRings or rampNCorners < 3 then
			continue
		end
		local rampRing0 = rampRings[1].polygon
		local rampRing0Immune = rampRings[1].immune
		local rampTris = triangulateOnGrid(rampRing0, gridSize)
		buildCliff(rampRing0, rampRing0Immune, rampTris, baseY, cliffTopY, displacers, a, targetContainer)
		buildCap(rampRings, rampNCorners, displacers, a, targetContainer)
		buildOverhangBlocker(rampRings, displacers, baseY, a, targetContainer)
	end
end

return {
	Attributes = Attributes,
	OnGenerate = OnGenerate,
}
