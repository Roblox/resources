-- Radial "emote wheel" GUI. A factory: each call builds one self-contained menu
-- (ScreenGui under PlayerGui) driven by mouse, gamepad thumbstick, or touch.
--
-- Selection is direction-based: the pointer's angle from the wheel center picks the
-- nearest slot, matching the built-in Roblox emote menu. Confirming (mouse/touch tap
-- on a slot, or gamepad ButtonA/R2 on the highlighted slot) fires onSelected with the
-- element's id and closes the menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

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

-- Placement angle for slot `index` of `count`, measured clockwise from the top.
local function getSlotAngle(index: number, count: number): number
	return (index - 1) / count * (2 * math.pi)
end

-- Smallest signed angle between two directions, wrapped to (-pi, pi].
local function getAngularDelta(angleA: number, angleB: number): number
	return (angleA - angleB + math.pi) % (2 * math.pi) - math.pi
end

local function createEmoteMenu(config: Types.Config): Types.EmoteMenu
	local onSelected = config.onSelected
	local onDismissed = config.onDismissed
	local onHighlightChanged = config.onHighlightChanged

	local emoteMenu: Types.EmoteMenu
	local elements: { Types.Element } = config.elements
	local menuOpen = false
	local highlightedIndex: number? = nil
	local thumbstickDirection = Vector2.zero
	local slotButtons: { TextButton } = {}
	local slotAngles: { number } = {}
	local connections: { RBXScriptConnection } = {}
	local highlightConnection: RBXScriptConnection? = nil

	local latestTouch: InputObject? = nil
	local dragTouch: InputObject? = nil
	local dragOrigin = Vector2.zero

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = Constants.SCREEN_GUI_NAME
	screenGui.DisplayOrder = Constants.DISPLAY_ORDER
	-- The old character's OnTeardown never runs on respawn, so let the engine clean this up.
	screenGui.ResetOnSpawn = true
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Constants.BACKDROP_COLOR
	backdrop.BackgroundTransparency = Constants.BACKDROP_TRANSPARENCY
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	local wheel = Instance.new("Frame")
	wheel.Name = "Wheel"
	wheel.AnchorPoint = Vector2.new(0.5, 0.5)
	wheel.Position = UDim2.fromScale(0.5, 0.5)
	wheel.BackgroundTransparency = 1
	wheel.ZIndex = 2
	wheel.Parent = screenGui

	local centerLabel = Instance.new("TextLabel")
	centerLabel.Name = "CenterLabel"
	centerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	centerLabel.Position = UDim2.fromScale(0.5, 0.5)
	centerLabel.Size = UDim2.fromScale(0.45, 0.2)
	centerLabel.BackgroundTransparency = 1
	centerLabel.Font = Enum.Font.GothamBold
	centerLabel.TextColor3 = Constants.CENTER_TEXT_COLOR
	centerLabel.TextSize = Constants.CENTER_TEXT_SIZE
	centerLabel.TextWrapped = true
	centerLabel.Text = ""
	centerLabel.ZIndex = 3
	centerLabel.Parent = wheel

	local camera = Workspace.CurrentCamera

	local function updateWheelSize()
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		local diameter = math.clamp(
			math.min(viewport.X, viewport.Y) * Constants.WHEEL_DIAMETER_SCALE,
			Constants.MIN_WHEEL_DIAMETER,
			Constants.MAX_WHEEL_DIAMETER
		)
		task.defer(function()
			wheel.Size = UDim2.fromOffset(diameter, diameter)
		end)
	end

	local function styleSlot(button: TextButton, highlighted: boolean)
		local diameter = Constants.SLOT_DIAMETER * (if highlighted then Constants.HIGHLIGHT_SCALE else 1)
		local tween = TweenService:Create(button, TweenInfo.new(Constants.TWEEN_TIME), {
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundColor3 = if highlighted then Constants.SLOT_HIGHLIGHT_COLOR else Constants.SLOT_COLOR,
			BackgroundTransparency = if highlighted
				then Constants.SLOT_HIGHLIGHT_TRANSPARENCY
				else Constants.SLOT_TRANSPARENCY,
			TextColor3 = if highlighted then Constants.SLOT_HIGHLIGHT_TEXT_COLOR else Constants.SLOT_TEXT_COLOR,
		})
		button.ZIndex = if highlighted then 4 else 2
		tween:Play()
	end

	local function setHighlight(index: number?)
		if index == highlightedIndex then
			return
		end
		local previous = highlightedIndex
		highlightedIndex = index

		if previous then
			styleSlot(slotButtons[previous], false)
		end
		if index then
			styleSlot(slotButtons[index], true)
		end

		centerLabel.Text = if index then elements[index].label or elements[index].id else ""

		if onHighlightChanged then
			onHighlightChanged(if index then elements[index].id else nil)
		end
	end

	local function closeMenu()
		if not menuOpen then
			return
		end
		menuOpen = false
		dragTouch = nil
		screenGui.Enabled = false
		setHighlight(nil)

		if highlightConnection then
			highlightConnection:Disconnect()
			highlightConnection = nil
		end
	end

	local function dismissMenu()
		closeMenu()
		if onDismissed then
			onDismissed()
		end
	end

	local function selectIndex(index: number)
		assert(elements[index], `no emote element at slot {index}`)
		closeMenu()
		if onSelected then
			onSelected(index)
		end
	end

	local function clearSlots()
		for _, button in slotButtons do
			button:Destroy()
		end
		table.clear(slotButtons)
		table.clear(slotAngles)
	end

	local function buildSlots()
		clearSlots()

		local count = #elements
		for index, element in elements do
			local angle = getSlotAngle(index, count)
			slotAngles[index] = angle

			local button = Instance.new("TextButton")
			button.Name = element.id
			button.AnchorPoint = Vector2.new(0.5, 0.5)
			button.Position = UDim2.fromScale(
				0.5 + math.sin(angle) * Constants.RING_SCALE,
				0.5 - math.cos(angle) * Constants.RING_SCALE
			)
			button.Size = UDim2.fromOffset(Constants.SLOT_DIAMETER, Constants.SLOT_DIAMETER)
			button.BackgroundColor3 = Constants.SLOT_COLOR
			button.BackgroundTransparency = Constants.SLOT_TRANSPARENCY
			button.AutoButtonColor = false
			button.Font = Enum.Font.GothamMedium
			button.TextColor3 = Constants.SLOT_TEXT_COLOR
			button.TextSize = Constants.SLOT_TEXT_SIZE
			button.TextWrapped = true
			button.Text = if element.image then "" else element.label or element.id
			button.ZIndex = 2
			button.Parent = wheel

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = button

			if element.image then
				local image = Instance.new("ImageLabel")
				image.AnchorPoint = Vector2.new(0.5, 0.5)
				image.Position = UDim2.fromScale(0.5, 0.5)
				image.Size = UDim2.fromScale(0.7, 0.7)
				image.BackgroundTransparency = 1
				image.Image = element.image
				image.ZIndex = 3
				image.Parent = button
			end

			-- Tap/click a slot to select it directly (mouse and touch); the button
			-- Instance owns this connection, so destroying it disconnects.
			local capturedIndex = index
			button.Activated:Connect(function()
				selectIndex(capturedIndex)
			end)

			slotButtons[index] = button
		end
	end

	-- Direction the player is pointing, and whether it clears the neutral deadzone.
	local function getPointerAngle(): number?
		if dragTouch then
			local offset = Vector2.new(dragTouch.Position.X, dragTouch.Position.Y) - dragOrigin
			if offset.Magnitude < Constants.TOUCH_DRAG_DEADZONE then
				return nil
			end
			return math.atan2(offset.X, -offset.Y)
		end

		if isGamepad() then
			if thumbstickDirection.Magnitude < Constants.THUMBSTICK_DEADZONE then
				return nil
			end
			return math.atan2(thumbstickDirection.X, thumbstickDirection.Y)
		end

		local center = wheel.AbsolutePosition + wheel.AbsoluteSize / 2
		local pointer = UserInputService:GetMouseLocation() - center
		local deadzone = (wheel.AbsoluteSize.X / 2) * Constants.CENTER_DEADZONE_SCALE
		if pointer.Magnitude < deadzone then
			return nil
		end
		return math.atan2(pointer.X, -pointer.Y)
	end

	local function getNearestSlot(angle: number): number
		local nearest = 1
		local nearestDistance = math.huge
		for index, slotAngle in slotAngles do
			local distance = math.abs(getAngularDelta(angle, slotAngle))
			if distance < nearestDistance then
				nearestDistance = distance
				nearest = index
			end
		end
		return nearest
	end

	local function updateHighlight()
		if #slotAngles == 0 then
			return
		end
		local angle = getPointerAngle()
		setHighlight(if angle then getNearestSlot(angle) else nil)
	end

	local function openMenu()
		if menuOpen then
			return
		end
		menuOpen = true
		setHighlight(nil)

		dragTouch = latestTouch
		if dragTouch then
			dragOrigin = Vector2.new(dragTouch.Position.X, dragTouch.Position.Y)
		end

		task.defer(function()
			if not menuOpen then
				return
			end
			updateWheelSize()
			screenGui.Enabled = true

			if highlightConnection then
				highlightConnection:Disconnect()
				highlightConnection = nil
			end
			highlightConnection = RunService.RenderStepped:Connect(updateHighlight)
		end)
	end

	local function setElements(newElements: { Types.Element })
		elements = newElements
		setHighlight(nil)
		buildSlots()
	end

	local function destroy()
		closeMenu()
		disconnectAndClear(connections)
		screenGui:Destroy()
	end

	local function isMenuOpen()
		return menuOpen
	end

	local function getSelectedId()
		return if highlightedIndex then elements[highlightedIndex].id else nil
	end

	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if input.KeyCode == Constants.NAVIGATE_THUMBSTICK then
				thumbstickDirection = Vector2.new(input.Position.X, input.Position.Y)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.TouchStarted:Connect(function(touch: InputObject)
			latestTouch = touch
		end)
	)

	table.insert(
		connections,
		UserInputService.TouchEnded:Connect(function(touch: InputObject)
			if touch == latestTouch then
				latestTouch = nil
			end

			if touch ~= dragTouch then
				return
			end
			dragTouch = nil
			if menuOpen and highlightedIndex then
				selectIndex(highlightedIndex)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end

			if not menuOpen then
				return
			end
			if not table.find(Constants.CONFIRM_KEYCODES, input.KeyCode) then
				return
			end
			if highlightedIndex then
				selectIndex(highlightedIndex)
			end
		end)
	)

	-- Close without selecting when tapping/clicking outside the slots.
	backdrop.Activated:Connect(dismissMenu)

	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateWheelSize))
	end

	local parent = config.parent or playerGui
	buildSlots()
	updateWheelSize()
	screenGui.Parent = parent

	emoteMenu = {
		open = openMenu,
		close = closeMenu,
		isOpen = isMenuOpen,
		getSelectedId = getSelectedId,
		setElements = setElements,
		destroy = destroy,
	}
	return emoteMenu
end

return createEmoteMenu
