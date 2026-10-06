--!strict
-- Cell centres for a square field of parts, ordered from the middle outwards.
--
-- Cells are sorted by Chebyshev distance from the centre, which is the ring
-- they sit on, so walking the list forwards grows a field from the middle and
-- walking it backwards peels it off from the edges. Callers never name a cell;
-- they ask for a count and take that many from the front.
--
-- Spacing is the gap between centres rather than the size of whatever goes
-- there, so a caller passing its part size gets a solid grid and anything
-- larger leaves gaps. Both fields pass their part size.
--
-- Centres are rolled once per storm and handed to both fields, so the rain and
-- the mist under it cover the same patch of map. Each field clamps the centre
-- to its own limits, which only bites when the two are set to different
-- coverages: the wider one shifts inwards rather than hanging off the edge.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)

local FieldGrid = {}

-- How many rings fit on one axis. The cell count has to be odd so the pattern
-- has a true middle, and it rounds down so the field never exceeds the coverage
-- that was asked for.
local function ringsForAxis(mapStuds: number, coveragePercent: number, spacingStuds: number): number
	local coverageStuds = mapStuds * coveragePercent / 100
	local count = math.floor(coverageStuds / math.max(spacingStuds, 1))
	if count % 2 == 0 then
		count -= 1
	end
	return math.max(count, 1) // 2
end

-- Ring counts and half widths for a field of this size, which is everything
-- both entry points below need to know about its shape.
local function shapeFor(coveragePercent: number, spacingStuds: number): (number, number, number, number)
	local ringsX = ringsForAxis(WeatherSystemConfig.MAP_DIMENSIONS_X_STUDS, coveragePercent, spacingStuds)
	local ringsZ = ringsForAxis(WeatherSystemConfig.MAP_DIMENSIONS_Z_STUDS, coveragePercent, spacingStuds)
	return ringsX, ringsZ, (ringsX * 2 + 1) * spacingStuds / 2, (ringsZ * 2 + 1) * spacingStuds / 2
end

-- The range a centre can sit in with the whole field still on the map. The
-- inset is half the field, or a quarter of it would hang off the edge.
local function window(centre: number, mapStuds: number, halfField: number): (number, number)
	local low = centre - mapStuds / 2 + halfField
	local high = centre + mapStuds / 2 - halfField
	if high <= low then
		-- Field is wider than the map; centring it is the best on offer.
		return centre, centre
	end
	return low, high
end

-- Where a storm lands. Rolled once and shared, rather than each field picking
-- for itself, or the rain and the mist would sit over different ground.
function FieldGrid.rollCentre(coveragePercent: number, spacingStuds: number): Vector2
	local _, _, halfFieldX, halfFieldZ = shapeFor(coveragePercent, spacingStuds)
	local lowX, highX =
		window(WeatherSystemConfig.MAP_CENTER_X_STUDS, WeatherSystemConfig.MAP_DIMENSIONS_X_STUDS, halfFieldX)
	local lowZ, highZ =
		window(WeatherSystemConfig.MAP_CENTER_Z_STUDS, WeatherSystemConfig.MAP_DIMENSIONS_Z_STUDS, halfFieldZ)

	return Vector2.new(lowX + math.random() * (highX - lowX), lowZ + math.random() * (highZ - lowZ))
end

function FieldGrid.build(coveragePercent: number, spacingStuds: number, y: number, centre: Vector2): { Vector3 }
	local ringsX, ringsZ, halfFieldX, halfFieldZ = shapeFor(coveragePercent, spacingStuds)
	local lowX, highX =
		window(WeatherSystemConfig.MAP_CENTER_X_STUDS, WeatherSystemConfig.MAP_DIMENSIONS_X_STUDS, halfFieldX)
	local lowZ, highZ =
		window(WeatherSystemConfig.MAP_CENTER_Z_STUDS, WeatherSystemConfig.MAP_DIMENSIONS_Z_STUDS, halfFieldZ)

	-- A field wider than the one the centre was rolled for pulls back inside
	-- the map instead of overhanging it.
	local origin = Vector3.new(math.clamp(centre.X, lowX, highX), y, math.clamp(centre.Y, lowZ, highZ))

	local built: { Vector3 } = {}
	for ring = 0, math.max(ringsX, ringsZ) do
		for x = -ringsX, ringsX do
			for z = -ringsZ, ringsZ do
				if math.max(math.abs(x), math.abs(z)) == ring then
					table.insert(built, origin + Vector3.new(x * spacingStuds, 0, z * spacingStuds))
				end
			end
		end
	end
	return built
end

return FieldGrid
