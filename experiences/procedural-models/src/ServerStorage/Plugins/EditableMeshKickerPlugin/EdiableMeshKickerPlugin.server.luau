if not plugin then
	return
end

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Allow this many regenerations in flight at once. Roblox caps EditableMesh
-- at ~7 concurrent and most generators bake 1-2 EMs per run, so 4 leaves
-- comfortable headroom while still parallelising more than strict serial.
local IN_FLIGHT_CAP = 4
-- If a generator never fires GeneratorDone (older generator, errored mid-bake,
-- whatever), don't block the queue forever — assume it's done after this.
local KICK_TIMEOUT = 5.0
local SIGNAL_NAME = "GeneratorDone"

local toolbar = plugin:CreateToolbar("EditableMeshKicker")
local toggleButton = toolbar:CreateButton("EditableMeshKicker", "Open the EditableMesh Kicker panel", "")
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 260, 120, 200, 100)
local widget = plugin:CreateDockWidgetPluginGui("EditableMeshKicker_MainWidget", widgetInfo)
widget.Title = "EditableMesh Kicker"
widget.Name = "EditableMeshKicker"

local kicking = false

local function ensureSignal()
	local sig = ReplicatedStorage:FindFirstChild(SIGNAL_NAME)
	if sig and sig:IsA("BindableEvent") then
		return sig
	end
	if sig then
		sig:Destroy()
	end
	sig = Instance.new("BindableEvent")
	sig.Name = SIGNAL_NAME
	sig.Parent = ReplicatedStorage
	return sig
end

local function bumpVersion(inst)
	local current = inst:GetAttribute("Version")
	if type(current) == "number" then
		inst:SetAttribute("Version", current + 1)
	else
		inst:SetAttribute("Version", 1)
	end
end

local function getLayer(inst)
	local v = inst:GetAttribute("Layer")
	if type(v) == "number" then
		return math.floor(v)
	end
	return 0
end

local function kickAll(button)
	if kicking then
		return
	end
	kicking = true
	local origText = button.Text

	local pms = {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d.ClassName == "ProceduralModel" then
			table.insert(pms, d)
		end
	end
	print(string.format("[EditableMeshKicker] kicking %d ProceduralModel(s)", #pms))

	-- Group by Layer attribute (default 0) and process in ascending layer
	-- order. Each layer fully drains (inFlight → 0) before the next starts
	-- so dependent generators (e.g. fences raycasting onto landmasses) see
	-- the world their lower-layer dependencies produced.
	local byLayer = {}
	for _, pm in ipairs(pms) do
		local L = getLayer(pm)
		byLayer[L] = byLayer[L] or {}
		table.insert(byLayer[L], pm)
	end
	local layers = {}
	for L in pairs(byLayer) do
		table.insert(layers, L)
	end
	table.sort(layers)

	local signal = ensureSignal()

	-- Each fire of the BindableEvent advances `fireCount` by 1; each bump
	-- claims a `myTarget` index and waits for `fireCount >= myTarget` (or
	-- the per-bump timeout). This way one fire = one drained slot, no
	-- matter how many listeners are connected.
	local fireCount = 0
	local conn = signal.Event:Connect(function()
		fireCount += 1
	end)

	task.spawn(function()
		local issued = 0
		local inFlight = 0
		local processed = 0
		local total = #pms

		for _, L in ipairs(layers) do
			for _, pm in ipairs(byLayer[L]) do
				-- Wait until there's a slot.
				while inFlight >= IN_FLIGHT_CAP do
					task.wait()
				end
				if not pm.Parent then
					continue
				end

				processed += 1
				button.Text = string.format("Kicking %d / %d (L%d)…", processed, total, L)

				issued += 1
				inFlight += 1
				local myTarget = issued
				bumpVersion(pm)

				task.spawn(function()
					local start = os.clock()
					while fireCount < myTarget and (os.clock() - start) < KICK_TIMEOUT do
						task.wait()
					end
					inFlight -= 1
				end)
			end

			-- Drain THIS layer fully before moving to the next. Higher
			-- layers can't start until everything below them has signaled
			-- GeneratorDone (or hit the per-bump timeout).
			while inFlight > 0 do
				task.wait()
			end
		end

		conn:Disconnect()
		-- Wipe the undo stack: each Version bump is a SetAttribute change
		-- that would otherwise pile into Studio's undo history. The kick
		-- isn't user-meaningful work — it's a one-shot regen trigger — so
		-- we don't want it cluttering the user's undo. ResetWaypoints
		-- clears all history, including any pre-kick edits, but that's the
		-- explicit intent here: kicking is a "from scratch" operation.
		ChangeHistoryService:ResetWaypoints()
		button.Text = origText
		kicking = false
	end)
end

local function clearWidget()
	for _, c in ipairs(widget:GetChildren()) do
		c:Destroy()
	end
end

local function buildUI()
	clearWidget()

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	frame.BorderSizePixel = 0
	frame.Parent = widget

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = frame

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = "Kick All ProceduralModels"
	btn.AutoButtonColor = true
	btn.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	btn.Activated:Connect(function()
		kickAll(btn)
	end)
end

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
