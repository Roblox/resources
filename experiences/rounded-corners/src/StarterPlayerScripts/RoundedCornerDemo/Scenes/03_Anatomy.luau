-- MEDIA — ANATOMY OF A SHADOW. Rebuilds, in Luau, the same mesh the renderer emits for a
-- UIShadow (StreamerBase::drawShadow, low-tessellation path): one center vertex, an inset ring
-- and an expanded ring of 4 corners x 9 vertices, with the band between them triangulated
-- exactly like kShadowIndices8. Steps auto-advance; Left/Right jump between steps.
local Root = script.Parent.Parent
local Util = require(Root.Util)

local P = Util.Palette

local W, H = 520, 320
local RADIUS = 64
local BLUR = 36
-- computeShadowOutsetAndInset: sigma = BlurRadius / 2, band extends 3 sigma each side of the edge.
local HALF_BAND = 1.5 * BLUR
local ARC_STEPS = 8
local CENTER = Vector2.new(800, 400)
local ORIGIN = CENTER - Vector2.new(W, H) / 2

local STEPS = {
	{ at = 0, text = "Start with the frame's rounded rectangle" },
	{ at = 2.5, text = "Add an outer outline, 1.5 × BlurRadius outside the frame" },
	{ at = 5, text = "Add an inner outline, 1.5 × BlurRadius inside the frame" },
	{ at = 7.5, text = "Split the shape into 108 triangles: 72 in the band and 36 around the center" },
	{ at = 10.5, text = "Give each vertex a value: 0 on the inner outline, 1 on the outer one" },
	{ at = 13.5, text = "The GPU looks up each pixel's opacity in a small Gaussian texture" },
	{ at = 16.5, text = "The finished shadow" },
}
local LOOP = 22
local FADE_IN = 0.6

-- Ring vertices in the renderer's order: TL, TR, BR, BL corners, 9 vertices each.
-- rectMin/rectMax bound the ring; radius is that ring's corner radius.
local function ring(rectMin: Vector2, rectMax: Vector2, radius: number)
	local corners = {
		{ Vector2.new(rectMin.X, rectMin.Y), Vector2.new(1, 1) },
		{ Vector2.new(rectMax.X, rectMin.Y), Vector2.new(-1, 1) },
		{ Vector2.new(rectMax.X, rectMax.Y), Vector2.new(-1, -1) },
		{ Vector2.new(rectMin.X, rectMax.Y), Vector2.new(1, -1) },
	}
	local verts = {}
	for _, c in corners do
		local corner, towardCenter = c[1], c[2]
		local arcCenter = corner + towardCenter * radius
		for j = 0, ARC_STEPS do
			local theta = j / ARC_STEPS * math.pi / 2
			local trig = Vector2.new(math.cos(theta), math.sin(theta))
			table.insert(verts, arcCenter + trig * -towardCenter * radius)
		end
	end
	return verts
end

-- Ring outline edges: along each arc, plus the straight sides joining corners
-- (TL end-TR end, TR start-BR start, BR end-BL end, BL start-TL start).
local function ringEdges()
	local edges = {}
	for c = 0, 3 do
		for j = 1, ARC_STEPS do
			table.insert(edges, { c * 9 + j, c * 9 + j + 1 })
		end
	end
	for _, e in { { 9, 18 }, { 10, 19 }, { 27, 36 }, { 28, 1 } } do
		table.insert(edges, e)
	end
	return edges
end

local function stepIndex(t: number)
	local index = 1
	for i, s in STEPS do
		if t >= s.at then
			index = i
		end
	end
	return index
end

local function reveal(t: number, step: number)
	return Util.smooth((t - STEPS[step].at) / FADE_IN)
end

return {
	title = "Anatomy of a shadow",
	backdrop = "flat",
	period = LOOP,
	build = function(stage: Frame, ctx)
		local inner = ring(
			Vector2.new(HALF_BAND, HALF_BAND),
			Vector2.new(W - HALF_BAND, H - HALF_BAND),
			math.max(RADIUS - HALF_BAND, 0)
		)
		local outer =
			ring(Vector2.new(-HALF_BAND, -HALF_BAND), Vector2.new(W + HALF_BAND, H + HALF_BAND), RADIUS + HALF_BAND)
		local center = Vector2.new(W, H) / 2

		local shape = Util.frame(stage, {
			Position = UDim2.fromOffset(ORIGIN.X, ORIGIN.Y),
			Size = UDim2.fromOffset(W, H),
			BackgroundColor3 = P.Paper,
			BackgroundTransparency = 0,
			ZIndex = 1,
		})
		Util.corner(shape, RADIUS)
		local shapeStroke = Util.stroke(shape, 2, P.Ink, 0.2)
		local shadow = Util.shadow(shape, { blur = BLUR, transparency = 1 })

		local wire = Util.frame(stage, {
			Position = UDim2.fromOffset(ORIGIN.X, ORIGIN.Y),
			Size = UDim2.fromOffset(W, H),
			ZIndex = 2,
		})

		-- Each group: { step it appears at, resting transparency, items }.
		local groups = {}
		local function group(step, transparency)
			local g = { step = step, transparency = transparency, items = {} }
			table.insert(groups, g)
			return g
		end
		local outerGroup = group(2, 0)
		local innerGroup = group(3, 0)
		local meshGroup = group(4, 0.35)
		local fanGroup = group(4, 0.65)

		local MESH = Color3.fromRGB(100, 116, 139)
		for _, e in ringEdges() do
			table.insert(outerGroup.items, Util.line(wire, outer[e[1]], outer[e[2]], 2.5, P.Blue))
			table.insert(innerGroup.items, Util.line(wire, inner[e[1]], inner[e[2]], 2.5, P.Orange))
		end
		for k = 1, 36 do
			table.insert(meshGroup.items, Util.line(wire, inner[k], outer[k], 1.5, MESH))
			table.insert(fanGroup.items, Util.line(wire, center, inner[k], 1, MESH))
		end
		-- Quad diagonals, matching kShadowIndices8: inner[j+1]-outer[j] along arcs, plus the four side wedges.
		for c = 0, 3 do
			for j = 1, ARC_STEPS do
				table.insert(meshGroup.items, Util.line(wire, inner[c * 9 + j + 1], outer[c * 9 + j], 1.5, MESH))
			end
		end
		for _, d in { { 9, 18 }, { 10, 19 }, { 27, 36 }, { 28, 1 } } do
			table.insert(meshGroup.items, Util.line(wire, inner[d[1]], outer[d[2]], 1.5, MESH))
		end

		local outerDots, innerDots = {}, {}
		for k = 1, 36 do
			table.insert(outerDots, Util.dot(wire, outer[k], 7, P.Blue))
			table.insert(innerDots, Util.dot(wire, inner[k], 7, P.Orange))
		end
		local centerDot = Util.dot(wire, center, 9, MESH)
		for _, d in outerDots do
			table.insert(outerGroup.items, d)
		end
		for _, d in innerDots do
			table.insert(innerGroup.items, d)
		end
		table.insert(fanGroup.items, centerDot)
		local dotStrokes = {}
		for _, d in outerDots do
			table.insert(dotStrokes, Util.stroke(d, 1.5, P.Ink, 1))
		end

		local function callout(text, pos, align)
			return Util.label(wire, text, {
				AnchorPoint = align,
				Position = UDim2.fromOffset(pos.X, pos.Y),
				Size = UDim2.fromOffset(160, 28),
				FontFace = Util.Font.Mono,
				TextSize = 20,
				TextColor3 = P.Ink,
				TextXAlignment = align.X < 0.5 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
				TextTransparency = 1,
			})
		end
		local valueCallouts = {
			callout("u = 1", Vector2.new(W + HALF_BAND + 12, -HALF_BAND), Vector2.new(0, 0)),
			callout("u = 0", Vector2.new(HALF_BAND + 18, HALF_BAND + 6), Vector2.new(0, 0)),
			callout("edge: u = 0.5", Vector2.new(W + 12, H / 2), Vector2.new(0, 0.5)),
		}

		-- Gaussian edge lookup: alpha(u) = 0.5 * erfc(3 * (2u - 1) / sqrt(2)), sampled into 19 stops.
		local lutY = ORIGIN.Y + H + HALF_BAND + 64
		local lut = Util.frame(stage, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(CENTER.X, lutY),
			Size = UDim2.fromOffset(520, 30),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0,
			ZIndex = 2,
		})
		Util.corner(lut, 6)
		local lutStroke = Util.stroke(lut, 1.5, P.Ink, 0.5)
		local points = {}
		for i = 0, 18 do
			local u = i / 18
			local alpha = 0.5 * Util.erfc(3 * (2 * u - 1) / math.sqrt(2))
			table.insert(points, { u, 1 - alpha })
		end
		local lutGradient = Util.gradient(lut, { transparency = Util.numSeq(points) })
		local lutLabels = {
			Util.label(stage, "u = 0", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromOffset(CENTER.X - 272, lutY + 15),
				Size = UDim2.fromOffset(100, 30),
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Util.Font.Mono,
				TextSize = 20,
			}),
			Util.label(stage, "u = 1", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromOffset(CENTER.X + 272, lutY + 15),
				Size = UDim2.fromOffset(100, 30),
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Util.Font.Mono,
				TextSize = 20,
			}),
			Util.label(stage, "Gaussian lookup texture", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(CENTER.X, lutY + 40),
				Size = UDim2.fromOffset(600, 26),
				TextSize = 19,
				TextColor3 = P.SubInk,
			}),
		}
		local marker = Util.frame(stage, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(CENTER.X, lutY + 15),
			Size = UDim2.fromOffset(4, 44),
			BackgroundColor3 = P.Pink,
			BackgroundTransparency = 1,
			ZIndex = 3,
		})
		Util.corner(marker, 2)

		local function setAlpha(item: GuiObject, a: number, resting: number)
			local tr = 1 - (1 - resting) * a
			if item:IsA("TextLabel") then
				item.TextTransparency = tr
			else
				item.BackgroundTransparency = tr
			end
		end

		local instance = {}

		function instance.update(_, t: number)
			t = t % LOOP
			local finale = reveal(t, 7)
			local wireAlpha = 1 - finale

			for _, g in groups do
				local a = (t >= STEPS[g.step].at and reveal(t, g.step) or 0) * wireAlpha
				for _, item in g.items do
					setAlpha(item, a, g.transparency)
				end
			end

			-- Step 5: recolor vertices by fade value (dark = 0, white = 1).
			local values = t >= STEPS[5].at and reveal(t, 5) or 0
			for _, d in innerDots do
				d.BackgroundColor3 = P.Orange:Lerp(Color3.new(0, 0, 0), values)
			end
			for i, d in outerDots do
				d.BackgroundColor3 = P.Blue:Lerp(Color3.new(1, 1, 1), values)
				dotStrokes[i].Transparency = 1 - (values * wireAlpha)
			end
			for _, c in valueCallouts do
				c.TextTransparency = 1 - values * wireAlpha
			end

			-- Step 6: the lookup texture, with a marker sampling it.
			local lutAlpha = (t >= STEPS[6].at and reveal(t, 6) or 0) * wireAlpha
			lut.BackgroundTransparency = 1 - lutAlpha
			lutGradient.Enabled = lutAlpha > 0
			lutStroke.Transparency = 1 - 0.5 * lutAlpha
			for _, l in lutLabels do
				l.TextTransparency = 1 - lutAlpha
			end
			marker.BackgroundTransparency = 1 - lutAlpha
			local u = 0.5 + 0.45 * math.sin((t - STEPS[6].at) * 1.6)
			marker.Position = UDim2.fromOffset(CENTER.X - 260 + 520 * u, lutY + 15)

			-- Step 7: the real UIShadow, same rect and BlurRadius as the diagram.
			if shadow then
				shadow.Transparency = 1 - 0.55 * finale
			end
			shapeStroke.Transparency = 0.2 + 0.8 * finale
		end

		function instance.caption(_, t: number)
			return STEPS[stepIndex(t % LOOP)].text
		end

		-- Returns false past the first/last step so the arrow keys fall through to scene navigation.
		function instance.step(_, t: number, direction: number)
			local i = stepIndex(t % LOOP) + direction
			if i < 1 or i > #STEPS then
				return false
			end
			ctx.setTime(STEPS[i].at + FADE_IN)
			return true
		end

		return instance
	end,
}
