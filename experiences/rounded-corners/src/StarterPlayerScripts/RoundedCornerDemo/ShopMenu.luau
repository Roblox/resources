-- The article's running example: a rounded shop panel with layered UIShadows, a gradient
-- header, and item cards scrolling under curved edges inside a CanvasGroup.
local Util = require(script.Parent.Util)
local Icons = require(script.Parent.Icons)

local P = Util.Palette

local CARD_HEIGHT = 96
local CARD_GAP = 12
local HEADER_HEIGHT = 110
local PANEL_RADIUS = 28

local ITEMS = {
	{
		name = "Starfall Sword",
		rarity = "Legendary",
		color = P.Gold,
		price = "1,200",
		glow = true,
		icon = function(p)
			return Icons.sword(p, Color3.fromRGB(255, 214, 120))
		end,
	},
	{
		name = "Frost Blade",
		rarity = "Rare",
		color = P.Cyan,
		price = "450",
		icon = function(p)
			return Icons.sword(p, Color3.fromRGB(120, 210, 255))
		end,
	},
	{
		name = "Healing Draught",
		rarity = "Uncommon",
		color = P.Green,
		price = "60",
		timer = true,
		icon = function(p)
			return Icons.potion(p, Color3.fromRGB(255, 92, 140))
		end,
	},
	{
		name = "Void Shard",
		rarity = "Epic",
		color = P.Purple,
		price = "800",
		icon = function(p)
			return Icons.gem(p, Color3.fromRGB(200, 170, 255), Color3.fromRGB(90, 50, 200))
		end,
	},
	{
		name = "Ember Guard",
		rarity = "Rare",
		color = P.Orange,
		price = "380",
		icon = function(p)
			return Icons.shield(p, Color3.fromRGB(255, 150, 60), Color3.fromRGB(220, 50, 60))
		end,
	},
	{
		name = "Oak Buckler",
		rarity = "Common",
		color = Color3.fromRGB(170, 178, 196),
		price = "120",
		icon = function(p)
			return Icons.shield(p, Color3.fromRGB(170, 120, 80), Color3.fromRGB(110, 70, 40))
		end,
	},
}

local ShopMenu = {}
ShopMenu.__index = ShopMenu
ShopMenu.SetHeight = #ITEMS * (CARD_HEIGHT + CARD_GAP)
ShopMenu.CardHeight = CARD_HEIGHT
ShopMenu.CardGap = CARD_GAP
ShopMenu.ItemCount = #ITEMS

local function buildCard(parent, item, y, refs)
	local card = Util.frame(parent, {
		Name = item.name,
		Position = UDim2.new(0, 12, 0, y),
		Size = UDim2.new(1, -24, 0, CARD_HEIGHT),
		BackgroundColor3 = P.Card,
		BackgroundTransparency = 0,
	})
	Util.corner(card, 16)
	Util.shadow(card, { blur = 10, offset = Vector2.new(0, 4), transparency = 0.55 })

	if item.glow then
		-- Soft rays (conical) under a halo (radial): the "rare item" treatment from the article.
		local rays = Util.frame(card, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(48, CARD_HEIGHT / 2),
			Size = UDim2.fromOffset(96, 96),
			BackgroundColor3 = P.Gold,
			BackgroundTransparency = 0,
			ZIndex = 1,
		})
		Util.corner(rays, 48)
		local rayPoints = {}
		for k = 0, 16 do
			table.insert(rayPoints, { k / 16, k % 2 == 0 and 0.45 or 1 })
		end
		local rayGradient = Util.gradient(rays, { type = "Conical", transparency = Util.numSeq(rayPoints) })
		local halo = Util.frame(card, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(48, CARD_HEIGHT / 2),
			Size = UDim2.fromOffset(100, 100),
			BackgroundColor3 = Color3.fromRGB(255, 230, 150),
			BackgroundTransparency = 0,
			ZIndex = 1,
		})
		Util.corner(halo, 50)
		Util.gradient(halo, { type = "Radial", transparency = Util.numSeq({ { 0, 0.15 }, { 0.55, 0.6 }, { 1, 1 } }) })
		table.insert(refs.rays, rayGradient)
		table.insert(refs.halos, halo)
	end

	local tile = Util.frame(card, {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(72, 72),
		BackgroundColor3 = item.color,
		BackgroundTransparency = item.glow and 0.55 or 0.8,
		ZIndex = 2,
	})
	Util.corner(tile, 14)
	item.icon(tile)

	local nameLabel = Util.label(card, item.name, {
		Position = UDim2.fromOffset(100, 18),
		Size = UDim2.new(1, item.timer and -300 or -250, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = true,
		FontFace = Util.Font.Bold,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
	})
	Util.new("UITextSizeConstraint", { Parent = nameLabel, MaxTextSize = 24, MinTextSize = 15 })
	Util.label(card, item.rarity, {
		Position = UDim2.fromOffset(100, 50),
		Size = UDim2.new(1, -250, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = Util.Font.Medium,
		TextSize = 18,
		TextColor3 = item.color,
	})

	local pill = Util.frame(card, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(108, 44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
	})
	Util.corner(pill, 22)
	Util.gradient(pill, {
		color = Util.colorSeq({ Color3.fromRGB(74, 222, 128), Color3.fromRGB(22, 163, 74) }),
		rotation = 90,
	})
	local coin = Icons.coin(pill, 20)
	coin.Position = UDim2.fromOffset(14, 12)
	Util.label(pill, item.price, {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -46, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Util.Font.Black,
		TextSize = 20,
		TextColor3 = Color3.new(1, 1, 1),
	})

	if item.timer then
		-- A conical sweep with a hard transparency step at the remaining fraction = countdown dial.
		local dial = Util.frame(card, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -136, 0.5, 0),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = P.Green,
			BackgroundTransparency = 0,
		})
		Util.corner(dial, 22)
		local dialGradient = Util.gradient(dial, { type = "Conical", rotation = -90 })
		local hole = Util.frame(dial, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = P.Card,
			BackgroundTransparency = 0,
		})
		Util.corner(hole, 16)
		local text = Util.label(hole, "0:42", {
			Size = UDim2.fromScale(1, 1),
			FontFace = Util.Font.Bold,
			TextSize = 11,
			TextColor3 = Color3.new(1, 1, 1),
		})
		table.insert(refs.dials, { gradient = dialGradient, text = text })
	end
	return card
end

local List = {}
List.__index = List

-- Two stacked copies of the item list so scrolling can wrap seamlessly.
-- period: seconds for one full loop of the list (also the countdown dial's period).
function ShopMenu.newList(parent: Instance, period: number)
	local self = setmetatable({}, List)
	self.period = period
	self.refs = { rays = {}, halos = {}, dials = {} }
	local content = Util.frame(parent, {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, ShopMenu.SetHeight * 2),
	})
	self.Content = content
	for copy = 0, 1 do
		for i, item in ITEMS do
			buildCard(content, item, copy * ShopMenu.SetHeight + (i - 1) * (CARD_HEIGHT + CARD_GAP), self.refs)
		end
	end
	return self
end

-- Scroll distance in px at time t.
function List:scrollAt(t: number)
	return (t / self.period) * ShopMenu.SetHeight % ShopMenu.SetHeight
end

function List:update(t: number)
	self.Content.Position = UDim2.fromOffset(0, CARD_GAP - self:scrollAt(t))

	-- 8 rays repeat every 45 degrees; 30 deg/s keeps a 12 s capture loop seamless.
	for _, rays in self.refs.rays do
		rays.Rotation = t * 30
	end
	local pulse = 0.5 + 0.5 * math.sin(t * math.pi)
	for _, halo in self.refs.halos do
		local s = 88 + 24 * pulse
		halo.Size = UDim2.fromOffset(s, s)
	end
	local remaining = 1 - (t % self.period) / self.period
	local p = math.clamp(remaining, 0.002, 0.996)
	for _, dial in self.refs.dials do
		dial.gradient.Transparency = Util.numSeq({ { 0, 0 }, { p, 0 }, { p + 0.002, 0.82 }, { 1, 0.82 } })
		dial.text.Text = string.format("0:%02d", math.ceil(remaining * 42))
	end
end

-- opts.width / opts.height: panel size in design px. opts.scrollPeriod: seconds per full loop.
function ShopMenu.new(parent: Instance, opts: { [string]: any }?)
	local o = opts or {}
	local self = setmetatable({}, ShopMenu)
	self.scrollPeriod = o.scrollPeriod or 12

	local panel = Util.frame(parent, {
		Name = "ShopPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = o.position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(o.width or 480, o.height or 620),
		BackgroundColor3 = P.Panel,
		BackgroundTransparency = 0,
	})
	self.Root = panel
	self.Corner = Util.corner(panel, PANEL_RADIUS)
	Util.stroke(panel, 1, Color3.new(1, 1, 1), 0.9)
	-- Two layers: a tight contact shadow plus a large ambient one.
	self.KeyShadow = Util.shadow(panel, { blur = 8, offset = Vector2.new(0, 4), transparency = 0.55, zIndex = -1 })
	self.AmbientShadow = Util.shadow(panel, { blur = 64, offset = Vector2.new(0, 28), transparency = 0.5, zIndex = -2 })

	local header = Util.frame(panel, {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
	})
	self.HeaderCorner = Util.corner(header, { PANEL_RADIUS, PANEL_RADIUS, 0, 0 })
	self.HeaderGradient = Util.gradient(header, {
		color = Util.colorSeq({ P.Orange, P.Pink, P.Purple }),
		rotation = 20,
	})
	Util.label(header, "SWORD SHOP", {
		Position = UDim2.fromOffset(28, 20),
		Size = UDim2.new(1, -200, 0, 42),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Util.Font.Black,
		TextSize = 36,
		TextColor3 = Color3.new(1, 1, 1),
	})
	Util.label(header, "Fresh steel every morning", {
		Position = UDim2.fromOffset(28, 62),
		Size = UDim2.new(1, -200, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = Util.Font.Medium,
		TextSize = 19,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 0.2,
	})
	local wallet = Util.frame(header, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 33),
		Size = UDim2.fromOffset(128, 44),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.75,
	})
	Util.corner(wallet, 22)
	Icons.coin(wallet, 24).Position = UDim2.fromOffset(12, 10)
	Util.label(wallet, "1,250", {
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -50, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Util.Font.Black,
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
	})

	local body = Util.new("CanvasGroup", {
		Parent = panel,
		Name = "Body",
		Position = UDim2.fromOffset(16, HEADER_HEIGHT + 16),
		Size = UDim2.new(1, -32, 1, -(HEADER_HEIGHT + 32)),
		BackgroundColor3 = P.PanelDeep,
	})
	Util.corner(body, 20)
	self.Body = body

	self.List = ShopMenu.newList(body, self.scrollPeriod)
	return self
end

function ShopMenu:update(t: number)
	self.List:update(t)
end

function ShopMenu:setSize(w: number, h: number)
	self.Root.Size = UDim2.fromOffset(w, h)
end

return ShopMenu
