--[[
	Geometry module — Ear-clipping polygon triangulation

	Takes 2D polygon vertices (XZ plane) and decomposes into
	triangles via ear clipping. Used by the Machine Builder plugin.

	Public API:
	  Geometry.triangulate(vertices, holes)
	    vertices: {{x, z}, ...} — outer polygon (CCW or CW, auto-detected)
	    holes: {{{x, z}, ...}, ...} or nil
	    returns: {{ {x,z}, {x,z}, {x,z} }, ...} — array of triangles

	Also keeps the old API for backward compat with build system:
	  Geometry.decomposePolygon(vertices, holes) — same as triangulate
]]

local Geometry = {}

local EPS = 0.001

--------------------------------------------------------------------------------
-- 2D math helpers
--------------------------------------------------------------------------------

-- Signed area of polygon (positive = CCW)
local function signedArea(poly)
	local sum = 0
	local n = #poly
	for i = 1, n do
		local j = (i % n) + 1
		sum += poly[i][1] * poly[j][2] - poly[j][1] * poly[i][2]
	end
	return sum / 2
end

-- Cross product of vectors (b-a) x (c-a)
local function cross2D(a, b, c)
	return (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
end

-- Is point p strictly inside triangle (a, b, c)?
-- Strict: points on edges do NOT count as inside.
-- This is critical for hole-bridged polygons where duplicate bridge vertices
-- lie exactly on bridge edges and would otherwise block ear detection.
local function pointInTriangle(p, a, b, c)
	local d1 = cross2D(a, b, p)
	local d2 = cross2D(b, c, p)
	local d3 = cross2D(c, a, p)
	return (d1 > EPS and d2 > EPS and d3 > EPS) or (d1 < -EPS and d2 < -EPS and d3 < -EPS)
end

--------------------------------------------------------------------------------
-- Segment intersection helpers
--------------------------------------------------------------------------------

-- Do segments (p1→p2) and (p3→p4) intersect? (proper intersection, not collinear overlap)
local function segmentsIntersect(p1, p2, p3, p4)
	local d1 = cross2D(p3, p4, p1)
	local d2 = cross2D(p3, p4, p2)
	local d3 = cross2D(p1, p2, p3)
	local d4 = cross2D(p1, p2, p4)
	if
		((d1 > EPS and d2 < -EPS) or (d1 < -EPS and d2 > EPS))
		and ((d3 > EPS and d4 < -EPS) or (d3 < -EPS and d4 > EPS))
	then
		return true
	end
	return false
end

-- Does the segment (a→b) intersect any edge of polygon poly?
local function segmentCrossesPoly(a, b, poly)
	local n = #poly
	for i = 1, n do
		local j = (i % n) + 1
		-- Skip edges that share an endpoint with our segment
		local pi, pj = poly[i], poly[j]
		local shareA = (math.abs(a[1] - pi[1]) < EPS and math.abs(a[2] - pi[2]) < EPS)
			or (math.abs(a[1] - pj[1]) < EPS and math.abs(a[2] - pj[2]) < EPS)
		local shareB = (math.abs(b[1] - pi[1]) < EPS and math.abs(b[2] - pi[2]) < EPS)
			or (math.abs(b[1] - pj[1]) < EPS and math.abs(b[2] - pj[2]) < EPS)
		if shareA or shareB then
			continue
		end
		if segmentsIntersect(a, b, pi, pj) then
			return true
		end
	end
	return false
end

-- Is a vertex at index i in a CCW polygon reflex (interior angle > 180°)?
local function isReflex(poly, i)
	local n = #poly
	local prev = poly[((i - 2) % n) + 1]
	local curr = poly[i]
	local next_ = poly[(i % n) + 1]
	return cross2D(prev, curr, next_) < -EPS
end

--------------------------------------------------------------------------------
-- Hole bridging: merge holes into outer polygon
-- Uses the mutually-visible vertex algorithm from
-- "Triangulation by Ear Clipping" (David Eberly, Geometric Tools)
--------------------------------------------------------------------------------

local function mergeHoles(outerVerts, holes)
	if not holes or #holes == 0 then
		return outerVerts
	end

	-- Ensure outer polygon is CCW
	local poly = {}
	for _, v in outerVerts do
		table.insert(poly, { v[1], v[2] })
	end
	if signedArea(poly) < 0 then
		local reversed = {}
		for i = #poly, 1, -1 do
			table.insert(reversed, poly[i])
		end
		poly = reversed
	end

	-- Ensure each hole is CW (opposite winding to outer)
	local sortedHoles = {}
	for _, hole in holes do
		local h = {}
		for _, v in hole do
			table.insert(h, { v[1], v[2] })
		end
		if signedArea(h) > 0 then
			local reversed = {}
			for i = #h, 1, -1 do
				table.insert(reversed, h[i])
			end
			h = reversed
		end
		-- Find rightmost vertex for sorting
		local maxX = -math.huge
		local maxIdx = 1
		for i, v in h do
			if v[1] > maxX then
				maxX = v[1]
				maxIdx = i
			end
		end
		table.insert(sortedHoles, { verts = h, maxX = maxX, maxIdx = maxIdx })
	end

	-- Sort holes by rightmost X (descending) — process rightmost holes first
	table.sort(sortedHoles, function(a, b)
		return a.maxX > b.maxX
	end)

	for _, holeData in sortedHoles do
		local hole = holeData.verts
		local holeIdx = holeData.maxIdx
		local M = hole[holeIdx] -- rightmost vertex of hole

		-- Step 1: Cast ray from M in +X direction, find closest intersecting edge of poly
		local bestT = math.huge
		local bestEdgeIdx = -1
		local bestIntersection = nil
		local pn = #poly
		for i = 1, pn do
			local j = (i % pn) + 1
			local a, b = poly[i], poly[j]
			-- Check if edge (a,b) straddles the ray's Y (which is our Z coordinate)
			local ay, by = a[2], b[2]
			local my = M[2]
			if (ay > my + EPS) == (by > my + EPS) then
				continue
			end -- both above or below
			if math.abs(ay - by) < EPS then
				continue
			end -- horizontal edge

			-- Parametric intersection with horizontal ray at y=M[2], x >= M[1]
			local t = (my - ay) / (by - ay)
			local ix = a[1] + t * (b[1] - a[1])
			if ix < M[1] - EPS then
				continue
			end -- intersection is to the left of M

			local dist = ix - M[1]
			if dist < bestT then
				bestT = dist
				bestEdgeIdx = i
				bestIntersection = { ix, my }
			end
		end

		-- Fallback: if ray didn't hit anything, use closest vertex (shouldn't happen for valid polygons)
		if bestEdgeIdx == -1 then
			local bestDist = math.huge
			local bestIdx = 1
			for i, v in poly do
				local dx = v[1] - M[1]
				local dz = v[2] - M[2]
				local dist = dx * dx + dz * dz
				if dist < bestDist then
					bestDist = dist
					bestIdx = i
				end
			end
			bestEdgeIdx = bestIdx

			-- Simple bridge (fallback)
			local merged = {}
			for i = 1, bestEdgeIdx do
				table.insert(merged, poly[i])
			end
			local hn = #hole
			for i = 0, hn do
				local idx = ((holeIdx - 1 + i) % hn) + 1
				table.insert(merged, { hole[idx][1], hole[idx][2] })
			end
			table.insert(merged, { poly[bestEdgeIdx][1], poly[bestEdgeIdx][2] })
			for i = bestEdgeIdx + 1, pn do
				table.insert(merged, poly[i])
			end
			poly = merged
			continue
		end

		-- Step 2: P = the endpoint of the hit edge with the larger X value
		local edgeJ = (bestEdgeIdx % pn) + 1
		local P_idx
		if poly[bestEdgeIdx][1] >= poly[edgeJ][1] then
			P_idx = bestEdgeIdx
		else
			P_idx = edgeJ
		end
		local P = poly[P_idx]

		-- If the intersection IS a vertex (P), P is directly visible from M and we can bridge to it.
		local intersectionIsVertex = math.abs(P[1] - bestIntersection[1]) < EPS
			and math.abs(P[2] - bestIntersection[2]) < EPS
		if not intersectionIsVertex then
			-- Step 3: Check if any reflex vertices of poly lie inside triangle (M, I, P)
			-- If so, pick the one that minimizes the angle to the ray from M
			local bestReflex = nil
			local bestAngle = math.huge
			for i = 1, pn do
				local v = poly[i]
				if isReflex(poly, i) and pointInTriangle(v, M, bestIntersection, P) then
					local dx = v[1] - M[1]
					local dz = v[2] - M[2]
					local angle = math.abs(math.atan2(dz, dx))
					if
						angle < bestAngle - EPS
						or (
							math.abs(angle - bestAngle) < EPS
							and dx * dx + dz * dz
								< (poly[bestReflex][1] - M[1]) ^ 2 + (poly[bestReflex][2] - M[2]) ^ 2
						)
					then
						bestAngle = angle
						bestReflex = i
					end
				end
			end

			if bestReflex then
				P_idx = bestReflex
				P = poly[P_idx]
			end
		end

		-- Step 4: Verify the bridge (M → P) doesn't cross any polygon edges.
		-- If it does, fall back to closest visible vertex.
		if segmentCrossesPoly(M, P, poly) then
			local bestDist = math.huge
			local fallbackIdx = P_idx
			for i = 1, pn do
				local v = poly[i]
				local dx = v[1] - M[1]
				local dz = v[2] - M[2]
				local dist = dx * dx + dz * dz
				if dist < bestDist and not segmentCrossesPoly(M, v, poly) then
					bestDist = dist
					fallbackIdx = i
				end
			end
			P_idx = fallbackIdx
		end

		-- Bridge: insert hole vertices into outer polygon at P_idx
		local merged = {}
		for i = 1, P_idx do
			table.insert(merged, poly[i])
		end
		local hn = #hole
		for i = 0, hn do
			local idx = ((holeIdx - 1 + i) % hn) + 1
			table.insert(merged, { hole[idx][1], hole[idx][2] })
		end
		table.insert(merged, { poly[P_idx][1], poly[P_idx][2] })
		for i = P_idx + 1, pn do
			table.insert(merged, poly[i])
		end

		poly = merged
	end

	return poly
end

--------------------------------------------------------------------------------
-- Deduplication: remove near-coincident vertices that create degenerate triangles
--------------------------------------------------------------------------------

local function deduplicateVertices(poly)
	if #poly < 3 then
		return poly
	end
	local result = { poly[1] }
	for i = 2, #poly do
		local prev = result[#result]
		local curr = poly[i]
		local dx = curr[1] - prev[1]
		local dz = curr[2] - prev[2]
		if dx * dx + dz * dz > EPS * EPS then
			table.insert(result, curr)
		end
	end
	-- Check last vs first
	if #result >= 2 then
		local first = result[1]
		local last = result[#result]
		local dx = last[1] - first[1]
		local dz = last[2] - first[2]
		if dx * dx + dz * dz <= EPS * EPS then
			table.remove(result)
		end
	end
	return result
end

--------------------------------------------------------------------------------
-- Ear clipping
--------------------------------------------------------------------------------

-- Check if 4 points in cyclic perimeter order form a rectangle (all angles ~90°).
local function isRectangle(a, b, c, d)
	local abx, abz = b[1] - a[1], b[2] - a[2]
	local bcx, bcz = c[1] - b[1], c[2] - b[2]
	local cdx, cdz = d[1] - c[1], d[2] - c[2]
	local dax, daz = a[1] - d[1], a[2] - d[2]

	local lenAB = math.sqrt(abx * abx + abz * abz)
	local lenBC = math.sqrt(bcx * bcx + bcz * bcz)
	local lenCD = math.sqrt(cdx * cdx + cdz * cdz)
	local lenDA = math.sqrt(dax * dax + daz * daz)

	if lenAB < EPS or lenBC < EPS or lenCD < EPS or lenDA < EPS then
		return false
	end

	local tol = 0.015 -- <1° tolerance
	if math.abs(dax * abx + daz * abz) > tol * lenDA * lenAB then
		return false
	end
	if math.abs(abx * bcx + abz * bcz) > tol * lenAB * lenBC then
		return false
	end
	if math.abs(bcx * cdx + bcz * cdz) > tol * lenBC * lenCD then
		return false
	end
	if math.abs(cdx * dax + cdz * daz) > tol * lenCD * lenDA then
		return false
	end
	return true
end

-- Try to find and clip one ear from indices at the given convexity threshold.
-- Returns ear info table on success, nil on failure.
local function tryClipEar(vertices, indices, threshold)
	local count = #indices
	local candidates = {}

	for i = 1, count do
		local prevIdx = ((i - 2) % count) + 1
		local nextIdx = (i % count) + 1

		local a = vertices[indices[prevIdx]]
		local b = vertices[indices[i]]
		local c = vertices[indices[nextIdx]]

		local crossVal = cross2D(a, b, c)
		if crossVal > threshold then
			-- Check no other vertex is strictly inside this triangle
			local isEar = true
			for j = 1, count do
				if j ~= prevIdx and j ~= i and j ~= nextIdx then
					if pointInTriangle(vertices[indices[j]], a, b, c) then
						isEar = false
						break
					end
				end
			end

			if isEar then
				-- Right-angle preference (kept for the rectangle-merging
				-- code path) and a quality score that ranks ears by how
				-- "fat" the resulting triangle is. Quality = 2·area /
				-- longest_side² ∈ (0, √3/2]; ~0.866 = equilateral, →0 = sliver.
				-- Picking the highest quality at each step biases away from
				-- long thin slivers without changing complexity.
				local bax, baz = a[1] - b[1], a[2] - b[2]
				local bcx, bcz = c[1] - b[1], c[2] - b[2]
				local cax, caz = a[1] - c[1], a[2] - c[2]
				local len2BA = bax * bax + baz * baz
				local len2BC = bcx * bcx + bcz * bcz
				local len2CA = cax * cax + caz * caz
				local maxLen2 = math.max(len2BA, len2BC, len2CA)
				local quality = if maxLen2 > EPS * EPS then math.abs(crossVal) / maxLen2 else 0

				local dotB = bax * bcx + baz * bcz
				local lenBA = math.sqrt(len2BA)
				local lenBC = math.sqrt(len2BC)
				local rightAngle = lenBA > EPS and lenBC > EPS and math.abs(dotB) < 0.015 * lenBA * lenBC

				table.insert(candidates, {
					pos = i,
					area = math.abs(crossVal) / 2,
					quality = quality,
					rightAngle = rightAngle,
					crossVal = crossVal,
					a = a,
					b = b,
					c = c,
					aOrigIdx = indices[prevIdx],
					cOrigIdx = indices[nextIdx],
				})
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	-- Sort by triangle quality (fat triangles first, slivers last). Falls
	-- back to area as a stable tiebreaker for ears of similar quality.
	table.sort(candidates, function(x, y)
		if math.abs(x.quality - y.quality) > 1e-6 then
			return x.quality > y.quality
		end
		return x.area > y.area
	end)

	local best = candidates[1]
	table.remove(indices, best.pos)
	return {
		triangle = { { best.a[1], best.a[2] }, { best.b[1], best.b[2] }, { best.c[1], best.c[2] } },
		a = best.a,
		b = best.b,
		c = best.c,
		aOrigIdx = best.aOrigIdx,
		cOrigIdx = best.cOrigIdx,
		degenerate = best.crossVal <= EPS,
	}
end

-- Returns parameter t (0..1) if point p lies on segment s1→s2, else nil.
local function pointOnSegmentParam(p, s1, s2)
	local dx = s2[1] - s1[1]
	local dz = s2[2] - s1[2]
	local len2 = dx * dx + dz * dz
	if len2 < EPS * EPS then
		return nil
	end
	local t = ((p[1] - s1[1]) * dx + (p[2] - s1[2]) * dz) / len2
	if t < 0.01 or t > 0.99 then
		return nil
	end -- not at endpoints
	local projX = s1[1] + t * dx
	local projZ = s1[2] + t * dz
	local dist2 = (p[1] - projX) * (p[1] - projX) + (p[2] - projZ) * (p[2] - projZ)
	if dist2 > 0.01 then
		return nil
	end -- not on the line
	return t
end

-- After clipping ear B (triangle A,B,C), check if either neighbor (A or C)
-- can form a rectangle with the clipped triangle. Returns 4-vertex quad or nil.
-- Also tries introducing a new vertex if the ear tip has a right angle.
local function tryExtendToRect(vertices, indices, earInfo)
	local count = #indices
	if count < 3 then
		return nil
	end

	-- Find positions of A and C in current indices
	local aPos, cPos
	for j = 1, count do
		if indices[j] == earInfo.aOrigIdx then
			aPos = j
		end
		if indices[j] == earInfo.cOrigIdx then
			cPos = j
		end
	end
	if not aPos or not cPos then
		return nil
	end

	local a, b, c = earInfo.a, earInfo.b, earInfo.c

	-- Try vertex A: ear (prevA, A, C) → quad (prevA, A, B, C)
	local prevAPos = ((aPos - 2) % count) + 1
	local prevA = vertices[indices[prevAPos]]
	local crossA = cross2D(prevA, a, c)
	if crossA > EPS then
		local earOk = true
		for j = 1, count do
			if j ~= prevAPos and j ~= aPos and j ~= cPos then
				if pointInTriangle(vertices[indices[j]], prevA, a, c) then
					earOk = false
					break
				end
			end
		end
		if earOk and isRectangle(prevA, a, b, c) then
			table.remove(indices, aPos)
			return {
				{ prevA[1], prevA[2] },
				{ a[1], a[2] },
				{ b[1], b[2] },
				{ c[1], c[2] },
			}
		end
	end

	-- Try vertex C: ear (A, C, nextC) → quad (A, B, C, nextC)
	local nextCPos = (cPos % count) + 1
	local nextC = vertices[indices[nextCPos]]
	local crossC = cross2D(a, c, nextC)
	if crossC > EPS then
		local earOk = true
		for j = 1, count do
			if j ~= aPos and j ~= cPos and j ~= nextCPos then
				if pointInTriangle(vertices[indices[j]], a, c, nextC) then
					earOk = false
					break
				end
			end
		end
		if earOk and isRectangle(a, b, c, nextC) then
			table.remove(indices, cPos)
			return {
				{ a[1], a[2] },
				{ b[1], b[2] },
				{ c[1], c[2] },
				{ nextC[1], nextC[2] },
			}
		end
	end

	-- Vertex introduction: if ear tip B has a right angle, compute the 4th
	-- rectangle vertex D = A + C - B and check if it falls on an adjacent edge.
	local bax, baz = a[1] - b[1], a[2] - b[2]
	local bcx, bcz = c[1] - b[1], c[2] - b[2]
	local lenBA = math.sqrt(bax * bax + baz * baz)
	local lenBC = math.sqrt(bcx * bcx + bcz * bcz)
	if lenBA > EPS and lenBC > EPS then
		local dotB = bax * bcx + baz * bcz
		if math.abs(dotB) < 0.015 * lenBA * lenBC then
			local d = { a[1] + c[1] - b[1], a[2] + c[2] - b[2] }

			-- Check if D is on edge prevA → A
			local tA = pointOnSegmentParam(d, prevA, a)
			if tA then
				-- Verify no polygon vertex inside the rectangle area (triangle D,A,C)
				local earOk = true
				for j = 1, count do
					if j ~= aPos and j ~= cPos then
						if pointInTriangle(vertices[indices[j]], d, a, c) then
							earOk = false
							break
						end
					end
				end
				if earOk then
					table.insert(vertices, d)
					local dVertIdx = #vertices
					table.insert(indices, aPos, dVertIdx) -- D before A
					table.remove(indices, aPos + 1) -- remove A (shifted by insert)
					return {
						{ d[1], d[2] },
						{ a[1], a[2] },
						{ b[1], b[2] },
						{ c[1], c[2] },
					}
				end
			end

			-- Check if D is on edge C → nextC
			local tC = pointOnSegmentParam(d, c, nextC)
			if tC then
				local earOk = true
				for j = 1, count do
					if j ~= aPos and j ~= cPos then
						if pointInTriangle(vertices[indices[j]], a, c, d) then
							earOk = false
							break
						end
					end
				end
				if earOk then
					table.insert(vertices, d)
					local dVertIdx = #vertices
					if nextCPos > cPos then
						table.insert(indices, nextCPos, dVertIdx)
						table.remove(indices, cPos) -- remove C
					else
						-- Wrap: cPos near end, nextCPos = 1
						table.insert(indices, nextCPos, dVertIdx)
						table.remove(indices, cPos + 1) -- cPos shifted by insert
					end
					return {
						{ a[1], a[2] },
						{ b[1], b[2] },
						{ c[1], c[2] },
						{ d[1], d[2] },
					}
				end
			end
		end
	end

	return nil
end

-- Remove collinear vertices (cross product ≈ 0) from the index list.
-- These appear at bridge points where hole merging creates zero-area sequences.
local function removeCollinearVertices(vertices, indices)
	local removed = false
	local i = 1
	while i <= #indices and #indices > 3 do
		local count = #indices
		local prevIdx = ((i - 2) % count) + 1
		local nextIdx = (i % count) + 1
		local a = vertices[indices[prevIdx]]
		local b = vertices[indices[i]]
		local c = vertices[indices[nextIdx]]
		if math.abs(cross2D(a, b, c)) <= EPS then
			table.remove(indices, i)
			removed = true
			-- Don't advance i — the next vertex shifted into this position
		else
			i += 1
		end
	end
	return removed
end

local function earClip(vertices)
	local n = #vertices
	if n < 3 then
		return {}
	end

	-- Build index list
	local indices = {}
	for i = 1, n do
		indices[i] = i
	end

	-- Ensure CCW winding
	if signedArea(vertices) < 0 then
		local reversed = {}
		for i = n, 1, -1 do
			table.insert(reversed, indices[i])
		end
		indices = reversed
	end

	local shapes = {} -- 3-vertex triangles or 4-vertex quads

	while #indices > 3 do
		-- Pass 1: standard ear clip (strictly convex vertices)
		local earInfo = tryClipEar(vertices, indices, EPS)
		if not earInfo then
			-- Pass 2: relax threshold to catch near-degenerate bridge triangles
			earInfo = tryClipEar(vertices, indices, -EPS * 100)
		end
		if not earInfo then
			-- Pass 3: remove collinear vertices and retry
			if removeCollinearVertices(vertices, indices) then
				continue
			end
			warn("[Geometry] Ear clip stuck with " .. #indices .. " vertices remaining")
			break
		end

		-- TODO: revisit rectangle merging (tryExtendToRect)
		if not earInfo.degenerate then
			table.insert(shapes, earInfo.triangle)
		end
	end

	-- Last triangle
	if #indices == 3 then
		local a = vertices[indices[1]]
		local b = vertices[indices[2]]
		local c = vertices[indices[3]]
		if math.abs(cross2D(a, b, c)) > EPS then
			table.insert(shapes, {
				{ a[1], a[2] },
				{ b[1], b[2] },
				{ c[1], c[2] },
			})
		end
	end

	return shapes
end

--------------------------------------------------------------------------------
-- Convex hull (Andrew's monotone chain)
--------------------------------------------------------------------------------

function Geometry.convexHull(points)
	local n = #points
	if n < 3 then
		local out = {}
		for _, p in points do
			table.insert(out, { p[1], p[2] })
		end
		return out
	end

	-- Sort by X, then Z
	local sorted = {}
	for _, p in points do
		table.insert(sorted, { p[1], p[2] })
	end
	table.sort(sorted, function(a, b)
		if math.abs(a[1] - b[1]) > EPS then
			return a[1] < b[1]
		end
		return a[2] < b[2]
	end)

	-- Remove near-duplicates
	local unique = { sorted[1] }
	for i = 2, #sorted do
		local prev = unique[#unique]
		local dx = sorted[i][1] - prev[1]
		local dz = sorted[i][2] - prev[2]
		if dx * dx + dz * dz > EPS * EPS then
			table.insert(unique, sorted[i])
		end
	end
	if #unique < 3 then
		return unique
	end

	local function crossVal(o, a, b)
		return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
	end

	-- Lower hull
	local lower = {}
	for _, p in unique do
		while #lower >= 2 and crossVal(lower[#lower - 1], lower[#lower], p) <= 0 do
			table.remove(lower)
		end
		table.insert(lower, p)
	end

	-- Upper hull
	local upper = {}
	for i = #unique, 1, -1 do
		local p = unique[i]
		while #upper >= 2 and crossVal(upper[#upper - 1], upper[#upper], p) <= 0 do
			table.remove(upper)
		end
		table.insert(upper, p)
	end

	-- Remove last point of each half (it's the first point of the other)
	table.remove(lower)
	table.remove(upper)

	-- Combine
	for _, p in upper do
		table.insert(lower, p)
	end
	return lower
end

--------------------------------------------------------------------------------
-- Sutherland-Hodgman polygon clipping
--------------------------------------------------------------------------------

-- Clip a convex subject polygon against an arbitrary simple clip polygon.
-- Returns the intersection polygon (CCW), or nil if empty.
function Geometry.clipToPolygon(subject, clip)
	if #subject < 3 or #clip < 3 then
		return nil
	end

	-- Ensure clip polygon is CCW so "inside" is to the left of each edge
	local clipPoly = {}
	for _, v in clip do
		table.insert(clipPoly, { v[1], v[2] })
	end
	if signedArea(clipPoly) < 0 then
		local rev = {}
		for i = #clipPoly, 1, -1 do
			table.insert(rev, clipPoly[i])
		end
		clipPoly = rev
	end

	local output = {}
	for _, v in subject do
		table.insert(output, { v[1], v[2] })
	end

	local cn = #clipPoly
	for i = 1, cn do
		if #output == 0 then
			return nil
		end

		local input = output
		output = {}

		local edgeA = clipPoly[i]
		local edgeB = clipPoly[(i % cn) + 1]

		-- "inside" = left side of edge A→B (positive cross product)
		local function isInside(p)
			return (edgeB[1] - edgeA[1]) * (p[2] - edgeA[2]) - (edgeB[2] - edgeA[2]) * (p[1] - edgeA[1]) >= -EPS
		end

		local function intersect(p1, p2)
			local x1, y1 = p1[1], p1[2]
			local x2, y2 = p2[1], p2[2]
			local x3, y3 = edgeA[1], edgeA[2]
			local x4, y4 = edgeB[1], edgeB[2]

			local denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
			if math.abs(denom) < EPS * EPS then
				return { (p1[1] + p2[1]) / 2, (p1[2] + p2[2]) / 2 }
			end

			local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
			return { x1 + t * (x2 - x1), y1 + t * (y2 - y1) }
		end

		local inCount = #input
		for j = 1, inCount do
			local curr = input[j]
			local prev = input[((j - 2) % inCount) + 1]
			local currInside = isInside(curr)
			local prevInside = isInside(prev)

			if currInside then
				if not prevInside then
					table.insert(output, intersect(prev, curr))
				end
				table.insert(output, curr)
			elseif prevInside then
				table.insert(output, intersect(prev, curr))
			end
		end
	end

	if #output < 3 then
		return nil
	end
	return deduplicateVertices(output)
end

-- Shrink a polygon inward by `amount` studs using edge-normal offsetting.
-- Each edge is moved inward along its perpendicular by `amount`, and new
-- vertices are the intersections of adjacent offset edges. This gives a
-- uniform inset distance from every original edge — critical for CUT_HOLE
-- polygons whose edges may coincide with the outer polygon boundary.
function Geometry.insetPolygon(poly, amount)
	if #poly < 3 then
		return poly
	end

	-- Ensure CCW winding so inward normals point into the polygon interior
	local verts = {}
	for _, v in poly do
		table.insert(verts, { v[1], v[2] })
	end
	if signedArea(verts) < 0 then
		local rev = {}
		for i = #verts, 1, -1 do
			table.insert(rev, verts[i])
		end
		verts = rev
	end

	local n = #verts

	-- Compute inward normal for each edge (CCW: inward = left of edge direction)
	local normals = {}
	for i = 1, n do
		local j = (i % n) + 1
		local dx = verts[j][1] - verts[i][1]
		local dz = verts[j][2] - verts[i][2]
		local len = math.sqrt(dx * dx + dz * dz)
		if len < EPS then
			normals[i] = { 0, 0 }
		else
			normals[i] = { -dz / len, dx / len }
		end
	end

	-- New vertices = intersection of consecutive offset edges
	local result = {}
	for i = 1, n do
		local prev = ((i - 2) % n) + 1

		-- Offset edge 'prev': shifted by normals[prev] * amount
		local p1x = verts[prev][1] + normals[prev][1] * amount
		local p1z = verts[prev][2] + normals[prev][2] * amount
		local p2x = verts[i][1] + normals[prev][1] * amount
		local p2z = verts[i][2] + normals[prev][2] * amount

		-- Offset edge 'i': shifted by normals[i] * amount
		local p3x = verts[i][1] + normals[i][1] * amount
		local p3z = verts[i][2] + normals[i][2] * amount
		local p4x = verts[(i % n) + 1][1] + normals[i][1] * amount
		local p4z = verts[(i % n) + 1][2] + normals[i][2] * amount

		-- Line-line intersection
		local d1x = p2x - p1x
		local d1z = p2z - p1z
		local d2x = p4x - p3x
		local d2z = p4z - p3z
		local denom = d1x * d2z - d1z * d2x

		if math.abs(denom) < EPS * EPS then
			-- Parallel edges — use the offset vertex directly
			table.insert(result, { p3x, p3z })
		else
			local t = ((p3x - p1x) * d2z - (p3z - p1z) * d2x) / denom
			table.insert(result, { p1x + t * d1x, p1z + t * d1z })
		end
	end

	return result
end

-- Point-in-polygon test (ray casting, horizontal ray to +X).
function Geometry.pointInPolygon(p, poly)
	local n = #poly
	local inside = false
	local px, py = p[1], p[2]
	local j = n
	for i = 1, n do
		local yi, yj = poly[i][2], poly[j][2]
		local xi, xj = poly[i][1], poly[j][1]
		if (yi > py) ~= (yj > py) then
			local xIntersect = xi + (py - yi) / (yj - yi) * (xj - xi)
			if px < xIntersect then
				inside = not inside
			end
		end
		j = i
	end
	return inside
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function Geometry.triangulate(vertices, holes)
	local poly = mergeHoles(vertices, holes)
	poly = deduplicateVertices(poly)
	return earClip(poly)
end

-- Backward-compatible alias
Geometry.decomposePolygon = Geometry.triangulate

return Geometry
