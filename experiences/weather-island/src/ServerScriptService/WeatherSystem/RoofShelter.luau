--!strict
-- Stops rain at roofs by shortening particle lifetime.
--
-- Particles do not collide, so an emitter above a building pours straight
-- through it. This casts one ray down from each rain cell, and where it lands
-- on something solid it shortens that emitter's lifetime to end the drops just
-- above the surface. Nothing else about the rain changes: the rate, the grid,
-- and the ramps are all left alone.
--
-- One ray per cell, aimed along the fall rather than straight down. Rain leans
-- downwind and lands away from the cell that made it. Height 150 and wind 50
-- moves a drop about 38 studs or 54 studs diagonally, so a vertical ray doesn't
-- work if you have wind.
--
-- The aim treats the fall as a right triangle, leaning the ray by the ratio of
-- sideways speed to falling speed.
--
-- With debug enabled, you can expect cells that bumped into a roof to be upwind
-- of the roof, sometimes by several cells.
--
-- Accuracy is... okay, and limited by cell size. Tiny cells would give better
-- precision, but I doubt the performance cost is worthwhile.
--
-- In particular, this module is self-contained so that it's easy to rip out.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)
local RainBallistics = require(script.Parent.RainBallistics)

local RoofShelter = {}

type Entry = {
	position: Vector3,
	part: BasePart,
	emitter: ParticleEmitter,
	-- Whatever RainField set before this module saw the emitter, which is what
	-- an uncovered cell gets handed back.
	openLifetime: NumberRange,
	applied: NumberRange,
	sheltered: boolean,
}

-- Rain cells are CanQuery false, so the field cannot occlude itself and doesn't
-- need a filter list.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true
params.RespectCanCollide = true

local entries: { Entry } = {}
local indexByPart: { [BasePart]: number } = {}
local cursor = 1
local sweepCredit = 0

local function isRoof(instance: BasePart): boolean
	if instance:IsA("Terrain") then
		-- The ground the rain is aiming for, not shelter.
		return false
	end

	local model = instance:FindFirstAncestorWhichIsA("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		-- Somebody standing in the open should not shelter themselves.
		return false
	end

	return true
end

-- A little above the surface rather than exactly on it. Drops are stretched
-- streaks rather than points, so aiming a bit high compensates for the tail.
local function shelteredLifetime(distance: number): NumberRange
	local drop = math.max(distance - WeatherSystemConfig.ROOF_CLEARANCE_STUDS, 1)
	-- Never longer than the open sky lifetime. Roofs are above the ground.
	local seconds =
		math.clamp(RainBallistics.fallSeconds(drop), 0.05, WeatherSystemConfig.RAIN_EMITTER_LIFETIME_SECONDS)
	return NumberRange.new(seconds)
end

-- How far downwind a drop slides while falling this many studs.
--
-- Once a drop is up to speed it falls at gravity / drag and slides sideways at
-- wind speed. The initial path is a curve, but this approach ignores that for
-- simpler math with still-decent accuracy.
local function leanOver(drop: number): Vector3
	if not WeatherSystemConfig.RAIN_EMITTER_RESPECT_GLOBAL_WIND then
		return Vector3.zero
	end

	local gravity = math.abs(WeatherSystemConfig.RAIN_EMITTER_ACCELERATION.Y)
	local drag = WeatherSystemConfig.RAIN_EMITTER_DRAG
	if gravity <= 0 or drag <= 0 then
		-- Nothing to fall towards, or nothing for the wind to pull against.
		return Vector3.zero
	end

	local wind = workspace.GlobalWind
	return Vector3.new(wind.X, 0, wind.Z) * (drop * drag / gravity)
end

local function refresh(entry: Entry)
	-- Exactly as far down as the rain reaches before its lifetime runs out.
	-- Anything lower is a surface no drop ever meets, and hitting it would mark
	-- the cell sheltered without changing its lifetime.
	local length = RainBallistics.fallDistance(WeatherSystemConfig.RAIN_EMITTER_LIFETIME_SECONDS)
	local lean = leanOver(length)
	local result = workspace:Raycast(entry.position, Vector3.new(lean.X, -length, lean.Z), params)

	local lifetime = entry.openLifetime
	local sheltered = false
	if result and isRoof(result.Instance) then
		sheltered = true
		-- Height lost, not distance along the ray. The two diverge once the ray
		-- leans, and it is the vertical drop that sets the fall time.
		lifetime = shelteredLifetime(entry.position.Y - result.Position.Y)
	end

	-- Every emitter here replicates, so only write on a real change.
	if lifetime.Min ~= entry.applied.Min or lifetime.Max ~= entry.applied.Max then
		entry.applied = lifetime
		entry.emitter.Lifetime = lifetime
	end

	if WeatherSystemConfig.ROOF_DEBUG_VISUALIZE and sheltered ~= entry.sheltered then
		entry.part.Color = if sheltered
			then WeatherSystemConfig.ROOF_DEBUG_SHELTERED_COLOR
			else WeatherSystemConfig.ROOF_DEBUG_OPEN_COLOR
	end
	entry.sheltered = sheltered
end

-- Start watching a cell. Called after the emitter is fully configured.
function RoofShelter.track(position: Vector3, part: BasePart, emitter: ParticleEmitter)
	if not WeatherSystemConfig.ROOF_DETECTION_ENABLED then
		return
	end

	local entry: Entry = {
		position = position,
		part = part,
		emitter = emitter,
		openLifetime = emitter.Lifetime,
		applied = emitter.Lifetime,
		sheltered = false,
	}

	table.insert(entries, entry)
	indexByPart[part] = #entries

	if WeatherSystemConfig.ROOF_DEBUG_VISUALIZE then
		part.Transparency = WeatherSystemConfig.ROOF_DEBUG_TRANSPARENCY
		part.Color = WeatherSystemConfig.ROOF_DEBUG_OPEN_COLOR
	end

	-- Sample immediately so that the cell isn't wrong until the regular
	-- re-check.
	refresh(entry)
end

function RoofShelter.forget(part: BasePart)
	local index = indexByPart[part]
	if not index then
		return
	end

	local last = #entries
	local moved = entries[last]
	entries[index] = moved
	indexByPart[moved.part] = index
	entries[last] = nil
	indexByPart[part] = nil

	if cursor > #entries then
		cursor = 1
	end
end

-- Roofs almost never move, so re-read over time instead of every frame.
function RoofShelter.step(deltaSeconds: number)
	if not WeatherSystemConfig.ROOF_DETECTION_ENABLED or #entries == 0 then
		return
	end

	local sweepSeconds = math.max(WeatherSystemConfig.ROOF_RECHECK_SECONDS, 0.1)
	sweepCredit = math.min(sweepCredit + #entries * deltaSeconds / sweepSeconds, #entries)

	local budget = math.floor(sweepCredit)
	sweepCredit -= budget

	for _ = 1, budget do
		if cursor > #entries then
			cursor = 1
		end
		refresh(entries[cursor])
		cursor += 1
	end
end

function RoofShelter.clear()
	entries = {}
	indexByPart = {}
	cursor = 1
	sweepCredit = 0
end

return RoofShelter
