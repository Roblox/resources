--!strict
-- Create the rain: grid of transparent parts, each carrying a downward particle
-- emitter, arranged in concentric square rings around a center.
--
-- Everything here is server owned and replicated, so emitter writes are
-- in steps.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)
local FieldGrid = require(script.Parent.FieldGrid)
local RoofShelter = require(script.Parent.RoofShelter)

local RainField = {}

-- Cells built per frame.
local PARTS_PER_STEP = 32
-- Steps the rate ramp is rounded to, so it moves ten times across a transition
-- instead of writing a new rate to every emitter every frame.
local RATE_STEPS = 10

type Cell = {
	position: Vector3,
	part: BasePart?,
	emitter: ParticleEmitter?,
	appliedRate: number,
}

local folder: Folder? = nil
local cells: { Cell } = {}
-- Cells 1..activeCount are the ones that currently exist in the world.
local activeCount = 0

local function buildCells(centre: Vector2): { Cell }
	local positions = FieldGrid.build(
		WeatherSystemConfig.RAIN_COVERAGE_PERCENTAGE,
		WeatherSystemConfig.RAIN_PART_XZ_STUDS,
		WeatherSystemConfig.RAIN_COVERAGE_Y_STUDS,
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
	return built
end

local function createPart(cell: Cell)
	local part = Instance.new("Part")
	part.Name = "RainCell"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Transparency = 1
	part.Size = Vector3.new(WeatherSystemConfig.RAIN_PART_XZ_STUDS, 1, WeatherSystemConfig.RAIN_PART_XZ_STUDS)
	part.Position = cell.position

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = WeatherSystemConfig.RAIN_EMITTER_TEXTURE
	emitter.Color = ColorSequence.new(WeatherSystemConfig.RAIN_EMITTER_COLOR)
	emitter.Size = NumberSequence.new(WeatherSystemConfig.RAIN_EMITTER_SIZE)
	emitter.Transparency = NumberSequence.new(WeatherSystemConfig.RAIN_EMITTER_TRANSPARENCY)
	emitter.Squash = NumberSequence.new(WeatherSystemConfig.RAIN_EMITTER_SQUASH)
	emitter.Orientation = WeatherSystemConfig.RAIN_EMITTER_ORIENTATION
	emitter.LightEmission = WeatherSystemConfig.RAIN_EMITTER_LIGHT_EMISSION
	emitter.LightInfluence = WeatherSystemConfig.RAIN_EMITTER_LIGHT_INFLUENCE
	emitter.Shape = WeatherSystemConfig.RAIN_EMITTER_SHAPE
	emitter.ShapeInOut = WeatherSystemConfig.RAIN_EMITTER_SHAPE_IN_OUT
	emitter.EmissionDirection = WeatherSystemConfig.RAIN_EMITTER_EMISSION_DIRECTION
	emitter.Speed = NumberRange.new(WeatherSystemConfig.RAIN_EMITTER_SPEED)
	emitter.SpreadAngle =
		Vector2.new(WeatherSystemConfig.RAIN_EMITTER_SPREAD_ANGLE, WeatherSystemConfig.RAIN_EMITTER_SPREAD_ANGLE)
	emitter.Acceleration = WeatherSystemConfig.RAIN_EMITTER_ACCELERATION
	emitter.Drag = WeatherSystemConfig.RAIN_EMITTER_DRAG
	emitter.WindAffectsDrag = WeatherSystemConfig.RAIN_EMITTER_RESPECT_GLOBAL_WIND
	emitter.ZOffset = WeatherSystemConfig.RAIN_EMITTER_ZOFFSET
	emitter.Lifetime = NumberRange.new(WeatherSystemConfig.RAIN_EMITTER_LIFETIME_SECONDS)
	emitter.Rate = 0
	emitter.Parent = part

	part.Parent = folder

	cell.part = part
	cell.emitter = emitter
	cell.appliedRate = 0

	RoofShelter.track(cell.position, part, emitter)
end

local function destroyPart(cell: Cell)
	local part = cell.part
	if part then
		RoofShelter.forget(part)
		part:Destroy()
	end
	cell.part = nil
	cell.emitter = nil
	cell.appliedRate = -1
end

-- Grow or shrink towards the target, spending at most a frame's budget.
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

local function quantise(value: number): number
	return math.floor(value * RATE_STEPS + 0.5) / RATE_STEPS
end

local function applyEmitters(rateScale: number)
	local rate = WeatherSystemConfig.RAIN_EMITTER_RATE * quantise(math.clamp(rateScale, 0, 1))

	for index = 1, activeCount do
		local cell = cells[index]
		local emitter = cell.emitter
		if emitter and math.abs(rate - cell.appliedRate) > 1e-3 then
			cell.appliedRate = rate
			emitter.Rate = rate
		end
	end
end

function RainField.init()
	if not folder then
		local container = Instance.new("Folder")
		container.Name = "RainField"
		container.Parent = workspace
		folder = container
	end
end

-- Lay out a fresh field somewhere new, and report where, so the mist can be
-- laid under the same patch of sky.
function RainField.beginStorm(): Vector2
	local centre =
		FieldGrid.rollCentre(WeatherSystemConfig.RAIN_COVERAGE_PERCENTAGE, WeatherSystemConfig.RAIN_PART_XZ_STUDS)

	RainField.clear()
	cells = buildCells(centre)
	return centre
end

function RainField.step(deltaSeconds: number, coverage: number, rateScale: number)
	resize(math.floor(math.clamp(coverage, 0, 1) * #cells + 0.5))
	applyEmitters(rateScale)
	RoofShelter.step(deltaSeconds)
end

function RainField.clear()
	for index = 1, activeCount do
		destroyPart(cells[index])
	end
	activeCount = 0
	RoofShelter.clear()
end

function RainField.getActiveCount(): number
	return activeCount
end

function RainField.getCellCount(): number
	return #cells
end

return RainField
