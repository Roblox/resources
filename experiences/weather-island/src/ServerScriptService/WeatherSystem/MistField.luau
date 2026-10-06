--!strict
-- Ground mist: a flat sheet of parts across the map, each carrying an upward
-- particle emitter.
--
-- Built like the rain field and driven by the same storm, on the same half of
-- the transition, but near the ground rather than in the air. Ignores roofs.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)
local FieldGrid = require(script.Parent.FieldGrid)

local MistField = {}

local PARTS_PER_STEP = 32
local RATE_STEPS = 10

type Cell = {
	position: Vector3,
	part: BasePart?,
	emitter: ParticleEmitter?,
	appliedRate: number,
}

local folder: Folder? = nil
local cells: { Cell } = {}

local activeCount = 0

local function createPart(cell: Cell)
	local part = Instance.new("Part")
	part.Name = "MistCell"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Transparency = 1
	part.Size = Vector3.new(WeatherSystemConfig.MIST_PART_XZ_STUDS, 1, WeatherSystemConfig.MIST_PART_XZ_STUDS)
	part.Position = cell.position

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = WeatherSystemConfig.MIST_EMITTER_TEXTURE
	emitter.Color = ColorSequence.new(WeatherSystemConfig.MIST_EMITTER_COLOR)
	emitter.Size = WeatherSystemConfig.MIST_EMITTER_SIZE
	emitter.Transparency = WeatherSystemConfig.MIST_EMITTER_TRANSPARENCY
	emitter.LightEmission = WeatherSystemConfig.MIST_EMITTER_LIGHT_EMISSION
	emitter.LightInfluence = WeatherSystemConfig.MIST_EMITTER_LIGHT_INFLUENCE
	emitter.Shape = WeatherSystemConfig.MIST_EMITTER_SHAPE
	emitter.ShapeStyle = WeatherSystemConfig.MIST_EMITTER_SHAPE_STYLE
	emitter.ShapeInOut = WeatherSystemConfig.MIST_EMITTER_SHAPE_IN_OUT
	emitter.EmissionDirection = WeatherSystemConfig.MIST_EMITTER_EMISSION_DIRECTION
	emitter.Orientation = WeatherSystemConfig.MIST_EMITTER_ORIENTATION
	emitter.Speed = NumberRange.new(WeatherSystemConfig.MIST_EMITTER_SPEED)
	emitter.Lifetime = NumberRange.new(
		WeatherSystemConfig.MIST_EMITTER_MIN_LIFETIME_SECONDS,
		WeatherSystemConfig.MIST_EMITTER_MAX_LIFETIME_SECONDS
	)
	emitter.Rotation =
		NumberRange.new(WeatherSystemConfig.MIST_EMITTER_MIN_ROTATION, WeatherSystemConfig.MIST_EMITTER_MAX_ROTATION)
	emitter.RotSpeed =
		NumberRange.new(WeatherSystemConfig.MIST_EMITTER_MIN_ROT_SPEED, WeatherSystemConfig.MIST_EMITTER_MAX_ROT_SPEED)
	emitter.SpreadAngle =
		Vector2.new(WeatherSystemConfig.MIST_EMITTER_SPREAD_ANGLE, WeatherSystemConfig.MIST_EMITTER_SPREAD_ANGLE)
	emitter.Acceleration = WeatherSystemConfig.MIST_EMITTER_ACCELERATION
	emitter.Drag = WeatherSystemConfig.MIST_EMITTER_DRAG
	emitter.WindAffectsDrag = WeatherSystemConfig.MIST_EMITTER_RESPECT_GLOBAL_WIND
	emitter.ZOffset = WeatherSystemConfig.MIST_EMITTER_ZOFFSET
	-- Silent until the storm ramps up. Tiles are built well before the mist is
	-- meant to be visible.
	emitter.Rate = 0
	emitter.Parent = part

	part.Parent = folder
	cell.part = part
	cell.emitter = emitter
	cell.appliedRate = 0
end

local function destroyPart(cell: Cell)
	local part = cell.part
	if part then
		part:Destroy()
	end
	cell.part = nil
	cell.emitter = nil
	cell.appliedRate = -1
end

-- Grow or shrink towards the target, spending at most a frame's budget.
-- Building a whole sheet in one frame could cause server hitches.
local function resize(targetCount: number)
	local target = math.clamp(targetCount, 0, #cells)
	local spent = 0

	while activeCount < target and spent < PARTS_PER_STEP do
		createPart(cells[activeCount + 1])
		activeCount += 1
		spent += 1
	end

	while activeCount > target and spent < PARTS_PER_STEP do
		destroyPart(cells[activeCount])
		activeCount -= 1
		spent += 1
	end
end

function MistField.init()
	if not folder then
		local container = Instance.new("Folder")
		container.Name = "MistField"
		container.Parent = workspace
		folder = container
	end
end

-- Lay out a fresh sheet under the storm that just rolled.
function MistField.beginStorm(centre: Vector2)
	MistField.clear()

	local positions = FieldGrid.build(
		WeatherSystemConfig.MIST_COVERAGE_PERCENTAGE,
		WeatherSystemConfig.MIST_PART_XZ_STUDS,
		WeatherSystemConfig.MIST_COVERAGE_Y_STUDS,
		centre
	)

	local built: { Cell } = {}
	for _, position in positions do
		table.insert(built, {
			position = position,
			part = nil,
			emitter = nil,
			appliedRate = -1,
		})
	end
	cells = built
end

local function quantise(value: number): number
	return math.floor(value * RATE_STEPS + 0.5) / RATE_STEPS
end

local function applyEmitters(intensity: number)
	local rate = WeatherSystemConfig.MIST_EMITTER_RATE * quantise(intensity)

	for index = 1, activeCount do
		local cell = cells[index]
		local emitter = cell.emitter
		if emitter and math.abs(rate - cell.appliedRate) > 1e-3 then
			cell.appliedRate = rate
			emitter.Rate = rate
		end
	end
end

function MistField.step(present: boolean, density: number)
	local wanted = present and WeatherSystemConfig.MIST_ENABLED

	resize(if wanted then #cells else 0)
	applyEmitters(if wanted then math.clamp(density, 0, 1) else 0)
end

function MistField.clear()
	for index = 1, activeCount do
		destroyPart(cells[index])
	end
	activeCount = 0
end

function MistField.getActiveCount(): number
	return activeCount
end

function MistField.getCellCount(): number
	return #cells
end

return MistField
