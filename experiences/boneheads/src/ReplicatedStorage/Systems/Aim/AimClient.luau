local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local AbilityConstants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.Aim.Constants)
local ThrowUtil = require(ReplicatedStorage.Systems.CustomAbilities.Interact.ThrowUtil)

local AimUpdate = ReplicatedStorage.Systems.Aim.Remotes.AimUpdate

local localPlayer = Players.LocalPlayer

local AimClient = {}
local started = false
local lastStreamedAt = 0
local aimMarker: BasePart? = nil
local aimHighlight: Highlight? = nil

local processedTouches: { InputObject } = {}
local aimTouch: InputObject? = nil
local aimTouchOrigin = Vector2.zero
local cursorStart = Vector2.zero
local cursorPosition: Vector2? = nil
local charging = false

local function isGamepad(): boolean
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.Gamepad1
		or last == Enum.UserInputType.Gamepad2
		or last == Enum.UserInputType.Gamepad3
		or last == Enum.UserInputType.Gamepad4
		or last == Enum.UserInputType.Gamepad5
		or last == Enum.UserInputType.Gamepad6
		or last == Enum.UserInputType.Gamepad7
		or last == Enum.UserInputType.Gamepad8
end

local function isTouch(): boolean
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local function isChargingThrow(): boolean
	return ThrowUtil.getThrowCharge(localPlayer.Character) ~= nil
end

local function getDefaultCursorPosition(camera: Camera): Vector2
	local viewport = camera.ViewportSize
	return Vector2.new(viewport.X / 2, viewport.Y * Constants.CURSOR_START_HEIGHT_RATIO)
end

local function clampToViewport(camera: Camera, position: Vector2): Vector2
	local viewport = camera.ViewportSize
	return Vector2.new(math.clamp(position.X, 0, viewport.X), math.clamp(position.Y, 0, viewport.Y))
end

-- The throw button press is the most recent consumed touch still down when charging starts.
local function updateChargeState()
	local isCharging = isChargingThrow()
	if isCharging == charging then
		return
	end
	charging = isCharging
	aimTouch = nil
	cursorPosition = nil
	if not isCharging then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	cursorStart = getDefaultCursorPosition(camera)
	cursorPosition = cursorStart
	aimTouch = processedTouches[#processedTouches]
	if aimTouch then
		aimTouchOrigin = Vector2.new(aimTouch.Position.X, aimTouch.Position.Y)
	end
end

-- Fixed distance along the cursor ray (a sphere around the camera) so aim tracks the
-- cursor's on-screen spot without distant geometry flattening it.
local function computeAimPoint(): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local origin, direction
	if isTouch() then
		local point = cursorPosition or getDefaultCursorPosition(camera)
		local ray = camera:ViewportPointToRay(point.X, point.Y)
		origin = ray.Origin
		direction = ray.Direction
	elseif isGamepad() or not UserInputService.MouseEnabled then
		origin = camera.CFrame.Position
		direction = camera.CFrame.LookVector
	else
		local mouseLocation = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
		origin = ray.Origin
		direction = ray.Direction
	end

	return origin + direction.Unit * Constants.AIM_DISTANCE
end

local function isHoldingItem(): boolean
	local character = localPlayer.Character
	local weld = character and CarryableUtil.getWeld(character, AbilityConstants.HOLD_WELD_NAME)
	return weld ~= nil and weld.Part1 ~= nil
end

local function stream()
	updateChargeState()
	if not isHoldingItem() then
		return
	end
	local now = os.clock()
	if now - lastStreamedAt < Constants.STREAM_INTERVAL_SECONDS then
		return
	end
	local aimPoint = computeAimPoint()
	if not aimPoint then
		return
	end
	lastStreamedAt = now
	AimUpdate:FireServer(aimPoint)
end

local function getThrowCharge(): number
	local throwCharge = ThrowUtil.getThrowCharge(localPlayer.Character)
	return if throwCharge ~= nil then throwCharge else 0
end

local function hideAimMarker()
	if aimMarker then
		aimMarker:Destroy()
		aimMarker = nil
	end
	aimHighlight = nil
end

local function applyAimColor(charge: number)
	local color = Constants.AIM_COLOR_MIN:Lerp(Constants.AIM_COLOR_MAX, charge)
	if aimMarker then
		aimMarker.Color = color
	end
	if aimHighlight then
		aimHighlight.FillColor = color
		aimHighlight.OutlineColor = color
	end
end

local function createAimMarker(): Part
	local marker = Instance.new("Part")
	marker.Name = "AimMarker"
	marker.Shape = Enum.PartType.Ball
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Massless = true
	marker.Size = Vector3.one
	marker.Material = Enum.Material.Neon
	marker.Parent = Workspace

	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.25
	highlight.OutlineTransparency = 0
	highlight.Parent = marker
	aimHighlight = highlight

	return marker
end

local function drawAimMarker()
	updateChargeState()
	if not (charging and isHoldingItem()) then
		hideAimMarker()
		return
	end
	local aimPoint = computeAimPoint()
	if not aimPoint then
		hideAimMarker()
		return
	end

	local marker: BasePart = if aimMarker and aimMarker.Parent then aimMarker else createAimMarker()
	aimMarker = marker
	applyAimColor(getThrowCharge())
	marker.Position = aimPoint
end

function AimClient.start()
	if started then
		return
	end
	started = true

	RunService.Heartbeat:Connect(stream)
	RunService.RenderStepped:Connect(drawAimMarker)
	UserInputService.TouchStarted:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			table.insert(processedTouches, input)
		end
	end)
	UserInputService.TouchMoved:Connect(function(input: InputObject)
		if input ~= aimTouch then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local drag = Vector2.new(input.Position.X, input.Position.Y) - aimTouchOrigin
		cursorPosition = clampToViewport(camera, cursorStart + drag * Constants.CURSOR_DRAG_SENSITIVITY)
	end)
	UserInputService.TouchEnded:Connect(function(input: InputObject)
		local index = table.find(processedTouches, input)
		if index then
			table.remove(processedTouches, index)
		end
		-- Keep cursorPosition after release so the final streamed aim still uses it.
		if input == aimTouch then
			aimTouch = nil
		end
	end)
end

return AimClient
