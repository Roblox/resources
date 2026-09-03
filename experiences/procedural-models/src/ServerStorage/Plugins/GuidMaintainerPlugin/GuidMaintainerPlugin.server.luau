-- GUID Maintainer: watches CollectionService tag "HAS_GUID" and maintains
-- a unique string "Guid" attribute on every tagged instance. New tagged
-- instances get a fresh GUID stamped; duplicates (e.g. from paste /
-- duplicate where the Guid attribute replicates with the copy) get
-- re-rolled so each tagged instance is uniquely addressable by Guid.
--
-- Standalone plugin — does not depend on PolyEdit. Other tools (PolyEdit,
-- generators, etc.) add the HAS_GUID tag to whatever they want tracked;
-- this plugin handles all stamping / uniqueness on their behalf.

if not plugin then
	return
end

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local TAG = "HAS_GUID"
local GUID_ATTR = "Guid"
-- Safety-net sweep period. Most paste/duplicate cases are caught
-- synchronously via the tag-added signal; the sweep just guarantees
-- eventual convergence if a replication race slips through.
local SWEEP_INTERVAL = 30

local attrConns: { [Instance]: RBXScriptConnection } = {}

local function newGuid(): string
	return HttpService:GenerateGUID(false)
end

local function isDuplicate(guid: string, selfInst: Instance): boolean
	for _, inst in CollectionService:GetTagged(TAG) do
		if inst ~= selfInst and inst:GetAttribute(GUID_ATTR) == guid then
			return true
		end
	end
	return false
end

-- Idempotent per-instance check. Stamps a fresh Guid if missing/empty,
-- re-rolls if the current Guid collides with another tagged instance.
local function ensureInstance(inst: Instance)
	local g = inst:GetAttribute(GUID_ATTR)
	if typeof(g) ~= "string" or #g == 0 then
		inst:SetAttribute(GUID_ATTR, newGuid())
		return
	end
	if isDuplicate(g, inst) then
		inst:SetAttribute(GUID_ATTR, newGuid())
	end
end

-- Walk the entire tagged set in one pass. First-seen-wins on duplicates,
-- which is arbitrary but deterministic within a sweep.
local function sweep(): (number, number)
	local stamped, rerolled = 0, 0
	local seen: { [string]: Instance } = {}
	for _, inst in CollectionService:GetTagged(TAG) do
		local g = inst:GetAttribute(GUID_ATTR)
		if typeof(g) ~= "string" or #g == 0 then
			g = newGuid()
			inst:SetAttribute(GUID_ATTR, g)
			stamped += 1
		elseif seen[g] then
			g = newGuid()
			inst:SetAttribute(GUID_ATTR, g)
			rerolled += 1
		end
		seen[g] = inst
	end
	return stamped, rerolled
end

local function watch(inst: Instance)
	if attrConns[inst] then
		return
	end
	-- Deferred re-check: catches user-edited Guids that collide. Defer so
	-- our own SetAttribute inside ensureInstance doesn't reenter
	-- synchronously, and so multiple back-to-back sets settle first.
	attrConns[inst] = inst:GetAttributeChangedSignal(GUID_ATTR):Connect(function()
		task.defer(function()
			if not inst.Parent then
				return
			end
			if not CollectionService:HasTag(inst, TAG) then
				return
			end
			ensureInstance(inst)
		end)
	end)
end

local function unwatch(inst: Instance)
	local c = attrConns[inst]
	if c then
		c:Disconnect()
		attrConns[inst] = nil
	end
end

for _, inst in CollectionService:GetTagged(TAG) do
	watch(inst)
end
do
	local s, r = sweep()
	if s + r > 0 then
		print(string.format("[GuidMaintainer] startup sweep: stamped=%d rerolled=%d", s, r))
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	watch(inst)
	ensureInstance(inst)
end)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
	unwatch(inst)
end)

task.spawn(function()
	while true do
		task.wait(SWEEP_INTERVAL)
		local ok, err = pcall(function()
			local s, r = sweep()
			if s + r > 0 then
				print(string.format("[GuidMaintainer] periodic sweep: stamped=%d rerolled=%d", s, r))
			end
		end)
		if not ok then
			warn("[GuidMaintainer] sweep error: " .. tostring(err))
		end
	end
end)

-- ---------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("GuidMaintainer")
local toggleButton = toolbar:CreateButton("GuidMaintainer", "Open the GUID Maintainer panel", "")
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 280, 160, 240, 140)
local widget = plugin:CreateDockWidgetPluginGui("GuidMaintainer_MainWidget", widgetInfo)
widget.Title = "GUID Maintainer"
widget.Name = "GuidMaintainer"

local statusLabel: TextLabel?

local function refreshStatus()
	if not statusLabel then
		return
	end
	statusLabel.Text = string.format("Tagged instances: %d", #CollectionService:GetTagged(TAG))
end

local function clearWidget()
	for _, c in widget:GetChildren() do
		c:Destroy()
	end
	statusLabel = nil
end

local function buildUI()
	clearWidget()

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	frame.BorderSizePixel = 0
	frame.Parent = widget

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local title = Instance.new("TextLabel")
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 0)
	title.Font = Enum.Font.SourceSans
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(220, 220, 220)
	title.Text = 'Maintains a unique "Guid" attribute on every instance tagged "' .. TAG .. '".'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.TextWrapped = true
	title.LayoutOrder = 1
	title.Parent = frame

	local s = Instance.new("TextLabel")
	s.AutomaticSize = Enum.AutomaticSize.Y
	s.BackgroundTransparency = 1
	s.Size = UDim2.new(1, 0, 0, 0)
	s.Font = Enum.Font.SourceSans
	s.TextSize = 14
	s.TextColor3 = Color3.fromRGB(180, 200, 220)
	s.Text = ""
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.LayoutOrder = 2
	s.Parent = frame
	statusLabel = s
	refreshStatus()

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = "Sweep Now"
	btn.AutoButtonColor = true
	btn.LayoutOrder = 3
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.Parent = frame

	btn.Activated:Connect(function()
		local stamped, rerolled = sweep()
		print(string.format("[GuidMaintainer] manual sweep: stamped=%d rerolled=%d", stamped, rerolled))
		refreshStatus()
	end)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(refreshStatus)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(refreshStatus)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		buildUI()
	else
		clearWidget()
	end
end)

toggleButton:SetActive(widget.Enabled)
if widget.Enabled then
	buildUI()
end
