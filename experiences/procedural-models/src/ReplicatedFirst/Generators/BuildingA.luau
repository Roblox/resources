--!strict
-- Multi-story tiled building generator.
-- Source structure (e.g., Mall.BuildingA):
--   bot/    - bottom-floor pieces. Models with `type` attribute "corner" or "wall".
--   top/    - middle-floor pieces (same scheme).
--   cap/    - topmost-floor pieces (same scheme).
--   roof/   - roof tiles. Models with `type = "roof"`.
-- Each variant Model has optional `tiles` attribute (defaults to 1) indicating how many
-- step units it spans along a wall. Wall spans are filled by repeatedly picking a random
-- variant that fits the remaining budget.
--
-- Descendant BaseParts with a `palette` attribute (e.g., "brick", "awning") get
-- recolored from a palette derived from the PM's Seed attribute.

local defaultAttributes = {
	Source = "Mall.BuildingA",
	Step = Vector3.new(7.5, 15, 7.5),
	Seed = 1,
	Recolor = true,
	Foundation = true,
	FoundationHeight = 4,
	Roof = true,
	RoofHeight = 2,
	ConcreteColor = Color3.fromRGB(160, 160, 160),
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

type Palette = { [string]: Color3 }
type Skin = { recolor: boolean, palette: Palette }

-- Two stylistic brick families; the random number splits between them.
local function generatePalette(rng: Random): Palette
	if rng:NextNumber() > 0.5 then
		return {
			brick = Color3.new(0.654902, 0.360784, 0.105882)
				:Lerp(Color3.new(0.776471, 0.568627, 0.470588), rng:NextNumber()),
			awning = Color3.fromHSV(rng:NextNumber(), 0.3, 1),
		}
	end
	return {
		brick = Color3.new(0.486275, 0.360784, 0.27451)
			:Lerp(Color3.new(0.419608, 0.176471, 0.0627451), rng:NextNumber()),
		awning = Color3.fromHSV(rng:NextNumber(), 0.3, 1),
	}
end

type Variant = { model: Instance, tiles: number }

local function getVariants(folder: Instance?, tag: string): { Variant }
	local out: { Variant } = {}
	if not folder then
		return out
	end
	for _, child in folder:GetChildren() do
		if child:GetAttribute("type") == tag then
			table.insert(out, {
				model = child,
				tiles = (child:GetAttribute("tiles") :: number?) or 1,
			})
		end
	end
	return out
end

-- Pick a random variant whose `tiles` fits within `tilesAvailable`.
local function chooseVariant(variants: { Variant }, tilesAvailable: number, rng: Random): (Instance?, number)
	if #variants == 0 then
		return nil, 1
	end
	if tilesAvailable < 1 then
		tilesAvailable = 1
	end
	local candidates: { Variant } = {}
	for _, v in variants do
		if v.tiles <= tilesAvailable then
			table.insert(candidates, v)
		end
	end
	if #candidates == 0 then
		return nil, 1
	end
	local pick = candidates[rng:NextInteger(1, #candidates)]
	return pick.model, pick.tiles
end

-- Emit a model's descendant BaseParts flat into target, at the given pivot-local CFrame.
-- Applies palette recoloring to any descendant with a `palette` attribute.
local function emitModel(modelTemplate: Instance?, placementCF: CFrame, skin: Skin, target: Instance)
	if not modelTemplate then
		return
	end
	local modelPivot = (modelTemplate :: any):GetPivot()
	for _, src in modelTemplate:GetDescendants() do
		if not src:IsA("BasePart") then
			continue
		end
		local relCF = modelPivot:ToObjectSpace(src.CFrame)
		local part = src:Clone()
		if not part:IsA("BasePart") then
			part:Destroy()
			continue
		end
		part.CFrame = placementCF * relCF
		part.Anchored = true
		if skin.recolor then
			local paletteKey = src:GetAttribute("palette")
			if paletteKey then
				local color = skin.palette[paletteKey :: string]
				if color then
					part.Color = color
				end
			end
		end
		part.Parent = target
	end
end

-- Fill a linear span of tiles between two corners by picking variants that fit.
local function fillSpan(
	startPos: number,
	endPos: number,
	variants: { Variant },
	angleDeg: number,
	origin: Vector3,
	stepper: Vector3,
	rng: Random,
	skin: Skin,
	target: Instance
)
	local tilesRemaining = (endPos - startPos) + 1
	local position = startPos
	while tilesRemaining > 0 do
		local model, numTiles = chooseVariant(variants, tilesRemaining, rng)
		if not model then
			return
		end
		local offset = 0
		if numTiles > 1 then
			offset = (numTiles / 2) - 0.5
		end
		local cf = CFrame.new(origin + stepper * (position + offset)) * CFrame.fromEulerAngles(0, math.rad(angleDeg), 0)
		emitModel(model, cf, skin, target)
		tilesRemaining -= numTiles
		position += numTiles
	end
end

-- Place 4 corners + 4 wall spans for a single floor at the given vertical step index.
-- `yOffset` shifts every row's Y position; OnGenerate uses it to plant the first row on
-- top of the foundation, with the foundation's bottom sitting at the PM's bottom face.
local function fillRow(
	size: Vector3,
	step: Vector3,
	height: number,
	yOffset: number,
	corners: { Variant },
	walls: { Variant },
	rng: Random,
	skin: Skin,
	target: Instance
)
	local halfSize = size / 2
	local origin = Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z)
		+ Vector3.new(step.X * 0.5, 0, step.Z * 0.5)
		+ Vector3.new(0, step.Y * height + yOffset, 0)

	local sx = math.floor(size.X / step.X) - 1
	local sz = math.floor(size.Z / step.Z) - 1

	-- 4 corners
	local placements = {
		{ pos = Vector3.new(sx, 0, 0) * step, angle = 0 },
		{ pos = Vector3.new(0, 0, 0) * step, angle = 90 },
		{ pos = Vector3.new(0, 0, sz) * step, angle = 180 },
		{ pos = Vector3.new(sx, 0, sz) * step, angle = 270 },
	}
	for _, place in placements do
		local model = chooseVariant(corners, 1, rng)
		local cf = CFrame.new(origin + place.pos) * CFrame.fromEulerAngles(0, math.rad(place.angle), 0)
		emitModel(model, cf, skin, target)
	end

	-- 4 wall spans
	fillSpan(1, sx - 1, walls, 90, origin, Vector3.new(step.X, 0, 0), rng, skin, target)
	fillSpan(
		1,
		sx - 1,
		walls,
		270,
		origin + Vector3.new(0, 0, sz * step.Z),
		Vector3.new(step.X, 0, 0),
		rng,
		skin,
		target
	)
	fillSpan(1, sz - 1, walls, 0, origin + Vector3.new(sx * step.X, 0, 0), Vector3.new(0, 0, step.Z), rng, skin, target)
	fillSpan(1, sz - 1, walls, 180, origin, Vector3.new(0, 0, step.Z), rng, skin, target)
end

-- Emit a single concrete slab at the given Y center spanning the building footprint.
-- `inset` shrinks the slab in X and Z (applied to both sides, so X dimension loses 2*inset).
local function emitSlab(
	name: string,
	centerY: number,
	size: Vector3,
	step: Vector3,
	height: number,
	inset: number,
	color: Color3,
	target: Instance
)
	-- Use the stepped building footprint (not raw PM size) so the slab matches the
	-- walls' extent rather than overhanging when PM Size isn't a clean step multiple.
	local sx = math.floor(size.X / step.X)
	local sz = math.floor(size.Z / step.Z)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(sx * step.X - 2 * inset, height, sz * step.Z - 2 * inset)
	part.CFrame = CFrame.new(0, centerY, 0)
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = Enum.Material.Concrete
	part.Parent = target
end

-- Tile a horizontal grid (e.g., roof) at the given vertical step index, with the same
-- y-baseline as fillRow.
local function fillFloor(
	size: Vector3,
	step: Vector3,
	height: number,
	yOffset: number,
	tiles: { Variant },
	rng: Random,
	skin: Skin,
	target: Instance
)
	local halfSize = size / 2
	local origin = Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z)
		+ Vector3.new(step.X * 0.5, 0, step.Z * 0.5)
		+ Vector3.new(0, step.Y * height + yOffset, 0)

	local sx = math.floor(size.X / step.X) - 1
	local sz = math.floor(size.Z / step.Z) - 1

	for x = 0, sx do
		for z = 0, sz do
			local model = chooseVariant(tiles, 1, rng)
			local cf = CFrame.new(origin + Vector3.new(x, 0, z) * step)
			emitModel(model, cf, skin, target)
		end
	end
end

local Generator: GeneratorModuleDefinition<typeof(defaultAttributes)> = {
	Attributes = defaultAttributes,

	OnGenerate = function(parameters, targetContainer)
		local source = resolveSource(parameters.Attributes.Source)
		if not source then
			warn(`[BuildingA] could not resolve Source: {parameters.Attributes.Source}`)
			return
		end

		local botFolder = source:FindFirstChild("bot")
		local topFolder = source:FindFirstChild("top")
		local capFolder = source:FindFirstChild("cap")
		local roofFolder = source:FindFirstChild("roof")
		if not (botFolder and topFolder and capFolder and roofFolder) then
			warn(`[BuildingA] Source must contain bot/top/cap/roof folders`)
			return
		end

		local rng = Random.new(parameters.Attributes.Seed)
		local skin: Skin = {
			recolor = parameters.Attributes.Recolor,
			palette = generatePalette(rng),
		}

		local step = parameters.Attributes.Step
		local size = parameters.Size
		local halfSize = size / 2

		-- Anchor: foundation starts at PM bottom; everything else stacks upward from there.
		-- Source row pieces are authored with their pivot at the BOTTOM, so the row's Y
		-- origin = its bottom edge. Bot row bottom = PM bottom + foundationDepth.
		local foundationDepth = if parameters.Attributes.Foundation then parameters.Attributes.FoundationHeight else 0
		local rowYOffset = foundationDepth
		local maxHeight = math.max(0, math.floor((size.Y - foundationDepth) / step.Y) - 1)

		-- Bottom floor
		local botCorner = getVariants(botFolder, "corner")
		local botWall = getVariants(botFolder, "wall")
		fillRow(size, step, 0, rowYOffset, botCorner, botWall, rng, skin, targetContainer)
		parameters:Pause()

		-- Middle floors
		local topCorner = getVariants(topFolder, "corner")
		local topWall = getVariants(topFolder, "wall")
		for height = 1, maxHeight do
			fillRow(size, step, height, rowYOffset, topCorner, topWall, rng, skin, targetContainer)
			parameters:Pause()
		end

		-- Cap floor
		local capCorner = getVariants(capFolder, "corner")
		local capWall = getVariants(capFolder, "wall")
		fillRow(size, step, maxHeight + 1, rowYOffset, capCorner, capWall, rng, skin, targetContainer)
		parameters:Pause()

		-- Roof tiles
		fillFloor(size, step, maxHeight + 1, rowYOffset, getVariants(roofFolder, "roof"), rng, skin, targetContainer)

		-- Foundation: concrete slab anchored to PM bottom, extending up.
		if parameters.Attributes.Foundation then
			local fy = parameters.Attributes.FoundationHeight
			emitSlab(
				"Foundation",
				-halfSize.Y + fy / 2,
				size,
				step,
				fy,
				0,
				parameters.Attributes.ConcreteColor,
				targetContainer
			)
		end

		-- Roof: concrete slab tucked just below the cap row's top, inset on all sides.
		if parameters.Attributes.Roof then
			local capTopY = -halfSize.Y + foundationDepth + step.Y * (maxHeight + 2)
			local ry = parameters.Attributes.RoofHeight
			emitSlab(
				"Roof",
				capTopY + ry / 2 - 13,
				size,
				step,
				ry,
				3,
				parameters.Attributes.ConcreteColor,
				targetContainer
			)
		end
	end,
}

return Generator
