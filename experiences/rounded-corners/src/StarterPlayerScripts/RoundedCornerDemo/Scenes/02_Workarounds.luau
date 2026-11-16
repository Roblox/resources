-- MEDIA — CREATOR WORKAROUNDS: PNG shadow vs stacked UIStroke vs UIShadow, while the frame
-- resizes and its corners change. Loops every 8 s.
local AssetService = game:GetService("AssetService")

local Root = script.Parent.Parent
local Util = require(Root.Util)
local Config = require(Root.Config)

local P = Util.Palette

-- 240x240 card, radius 24, blur 32, y-offset 12; the baked image matches these at 2x.
local BASE = 240
local BASE_RADIUS = 24
local SHADOW_BLUR = 32
local SHADOW_OFFSET = 12
local SHADOW_TRANSPARENCY = 0.65

local IMAGE_PX = 800 -- covers 400 design px around the card
local IMAGE_DESIGN = 400

local STROKE_LAYERS = 8
local STROKE_STEP = 6

local SHAPE = {
	{ 0, { 240, 240, 24 } },
	{ 2, { 240, 240, 24 } },
	{ 4, { 340, 200, 72 } },
	{ 6, { 340, 200, 72 } },
	{ 8, { 240, 240, 24 } },
}

-- Bakes the "Photoshop" shadow into an 800x800 EditableImage: a rounded-rect mask convolved with
-- a separable Gaussian (sigma = BlurRadius / 2, like UIShadow) at 1/4 resolution, then bilinearly
-- upsampled. Same algorithm as tools/make_shadow_png.py. Cached for the session.
local bakedImage = nil
local function bakeShadowImage()
	if bakedImage then
		return bakedImage
	end
	local ok, image = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(IMAGE_PX, IMAGE_PX) })
	end)
	if not ok or not image then
		return nil
	end

	local pxPerDesign = IMAGE_PX / IMAGE_DESIGN
	local work = 4
	local n = IMAGE_PX // work
	local half = BASE * pxPerDesign / 2 / work
	local radius = BASE_RADIUS * pxPerDesign / work
	local sigma = SHADOW_BLUR / 2 * pxPerDesign / work
	local maxAlpha = 1 - SHADOW_TRANSPARENCY

	local mask = table.create(n * n, 0)
	for y = 0, n - 1 do
		for x = 0, n - 1 do
			local hits = 0
			for sy = 0, 3 do
				for sx = 0, 3 do
					local qx = math.abs(x + (sx + 0.5) / 4 - n / 2) - (half - radius)
					local qy = math.abs(y + (sy + 0.5) / 4 - n / 2) - (half - radius)
					local d = math.sqrt(math.max(qx, 0) ^ 2 + math.max(qy, 0) ^ 2) + math.min(math.max(qx, qy), 0)
					if d <= radius then
						hits += 1
					end
				end
			end
			mask[y * n + x + 1] = hits / 16
		end
	end

	local taps = math.ceil(3 * sigma)
	local kernel, total = {}, 0
	for i = -taps, taps do
		local k = math.exp(-(i * i) / (2 * sigma * sigma))
		kernel[i + taps + 1] = k
		total += k
	end
	local function blur(src, horizontal)
		local out = table.create(n * n, 0)
		for a = 0, n - 1 do
			for b = 0, n - 1 do
				local acc = 0
				for i = -taps, taps do
					local c = b + i
					if c >= 0 and c < n then
						acc += kernel[i + taps + 1] * (horizontal and src[a * n + c + 1] or src[c * n + a + 1])
					end
				end
				if horizontal then
					out[a * n + b + 1] = acc / total
				else
					out[b * n + a + 1] = acc / total
				end
			end
		end
		return out
	end
	local blurred = blur(blur(mask, true), false)

	local pixels = buffer.create(IMAGE_PX * IMAGE_PX * 4)
	for y = 0, IMAGE_PX - 1 do
		local fy = math.clamp((y + 0.5) / work - 0.5, 0, n - 1)
		local y0 = math.floor(fy)
		local y1 = math.min(y0 + 1, n - 1)
		local ty = fy - y0
		for x = 0, IMAGE_PX - 1 do
			local fx = math.clamp((x + 0.5) / work - 0.5, 0, n - 1)
			local x0 = math.floor(fx)
			local x1 = math.min(x0 + 1, n - 1)
			local tx = fx - x0
			local top = blurred[y0 * n + x0 + 1] * (1 - tx) + blurred[y0 * n + x1 + 1] * tx
			local bottom = blurred[y1 * n + x0 + 1] * (1 - tx) + blurred[y1 * n + x1 + 1] * tx
			local alpha = math.round(maxAlpha * (top * (1 - ty) + bottom * ty) * 255)
			-- RGBA bytes, little-endian u32: black with alpha in the high byte.
			buffer.writeu32(pixels, (y * IMAGE_PX + x) * 4, bit32.lshift(alpha, 24))
		end
	end
	-- Published experiences can create an EditableImage but not write to it unless
	-- Allow Mesh / Image APIs is on in Experience Settings > Security.
	local wrote = pcall(function()
		image:WritePixelsBuffer(Vector2.zero, Vector2.new(IMAGE_PX, IMAGE_PX), pixels)
	end)
	if not wrote then
		image:Destroy()
		return nil
	end
	bakedImage = image
	return image
end

local function column(stage, x, title, subtitle)
	local holder = Util.frame(stage, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, 400),
		Size = UDim2.fromOffset(BASE, BASE),
	})
	local card = Util.frame(holder, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.Paper,
		BackgroundTransparency = 0,
		ZIndex = 2,
	})
	local corner = Util.corner(card, BASE_RADIUS)
	Util.label(stage, title, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(x, 640),
		FontFace = Util.Font.Bold,
		TextSize = 30,
	})
	Util.label(stage, subtitle, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(x, 678),
		TextSize = 20,
		TextColor3 = P.SubInk,
	})
	return holder, card, corner
end

return {
	title = "Shadow workarounds",
	caption = "A PNG, UIStrokes, and a UIShadow as the frame changes shape",
	backdrop = "flat",
	period = 8,
	build = function(stage: Frame)
		local columns = {}

		-- 1. Pre-rendered image behind the frame: fixed size, fixed corners.
		do
			local holder, _, corner = column(stage, 400, "PNG image", "800 × 800, 2.5 MB in memory")
			local image = Util.new("ImageLabel", {
				Parent = holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, SHADOW_OFFSET),
				Size = UDim2.fromOffset(IMAGE_DESIGN, IMAGE_DESIGN),
				BackgroundTransparency = 1,
				ZIndex = 1,
			})
			if Config.ShadowImage ~= "" then
				image.Image = Config.ShadowImage
			else
				local baked = bakeShadowImage()
				if baked then
					image.ImageContent = Content.fromObject(baked)
				else
					Util.label(stage, "EditableImage unavailable: see README", {
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromOffset(400, 140),
						TextSize = 18,
						TextColor3 = P.Red,
					})
				end
			end
			table.insert(columns, { holder = holder, corners = { corner } })
		end

		-- 2. Stacked UIStroke outlines, each wider and fainter, behind the card. UIStroke draws
		-- entirely outside its frame (BorderStrokePosition defaults to Outer), so the layers can't
		-- take the shadow's y-offset: that would leave a gap under the card's bottom edge.
		do
			local holder, _, corner = column(stage, 800, "Stacked UIStroke", "8 strokes")
			local corners = { corner }
			for i = 1, STROKE_LAYERS do
				local layer = Util.frame(holder, {
					Size = UDim2.fromScale(1, 1),
					ZIndex = 1,
				})
				table.insert(corners, Util.corner(layer, BASE_RADIUS))
				Util.stroke(layer, i * STROKE_STEP, Color3.new(0, 0, 0), 0.94)
			end
			table.insert(columns, { holder = holder, corners = corners })
		end

		-- 3. UIShadow.
		do
			local holder, card, corner = column(stage, 1200, "UIShadow", "Follows the frame")
			Util.shadow(card, {
				blur = SHADOW_BLUR,
				offset = Vector2.new(0, SHADOW_OFFSET),
				transparency = SHADOW_TRANSPARENCY,
			})
			table.insert(columns, { holder = holder, corners = { corner } })
		end

		return {
			update = function(_, t: number)
				local s = Util.track(SHAPE, t)
				for _, c in columns do
					c.holder.Size = UDim2.fromOffset(s[1], s[2])
					for _, corner in c.corners do
						corner.CornerRadius = UDim.new(0, s[3])
					end
				end
			end,
		}
	end,
}
