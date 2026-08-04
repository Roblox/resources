--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer :: Player
local playerScripts = player:FindFirstChild("PlayerScripts") :: PlayerScripts
local playerModuleBase = playerScripts:WaitForChild("PlayerModule") :: ModuleScript
local playerModule = require(playerModuleBase) :: any
local playerGui = player.PlayerGui

local instances = script.Parent.Instances
local interior = instances:WaitForChild("Interior")
local exterior = instances:WaitForChild("Exterior")
local doorGui = instances.PortalDoorGui :: ScreenGui

local ENTRY_ANIMATION_TIME = 0.75
local ENTRY_CAMERA_END_OFFSET = CFrame.new(0, 1, -3) * CFrame.Angles(0, math.rad(180), 0)
local EXIT_ANIMATION_TIME = 0.75
local EXIT_CAMERA_START_OFFSET = CFrame.new(0, 1, 0)
local EXIT_CAMERA_END_OFFSET = CFrame.new(0, 2, -3) * CFrame.Angles(math.rad(-20), 0, 0)

local ENTRY_EXTERIOR_OFFSET = Vector3.new(0, 0, -3)
local ENTRY_INTERIOR_OFFSET = Vector3.new(0, 0, 3)
local EXIT_EXTERIOR_OFFSET = Vector3.new(0, 0, -8)

local ENTRY_TWEEN_INFO = TweenInfo.new(ENTRY_ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local EXIT_TWEEN_INFO = TweenInfo.new(EXIT_ANIMATION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local isWalkingThroughDoors = false

local function setCharacterControlsEnabled(enabled: boolean)
	-- Set desktop controls enabled through the PlayerModule
	local controls = playerModule:GetControls()
	controls:Enable(enabled)
	-- Set touch controls enabled
	GuiService.TouchControlsEnabled = enabled
end

local function setCameraControlsEnabled(enabled: boolean)
	-- Toggle between Scriptable and Custom camera types to disable or enable camera control respectively
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera.CameraType = if enabled then Enum.CameraType.Custom else Enum.CameraType.Scriptable
	end
end

local function setDoorOpen(door, open: boolean)
	-- When a door is open, it should be able to be walked through and the proximity prompt should be disabled
	-- When the door is closed, the opposite applies
	door.Entrance.ProximityPrompt.Enabled = not open
	door.Entrance.CanCollide = not open
end

local function walkIntoDoor(character, door)
	local doorExteriorPosition = door.Entrance.CFrame:PointToWorldSpace(ENTRY_EXTERIOR_OFFSET)
	local doorInteriorPosition = door.Entrance.CFrame:PointToWorldSpace(ENTRY_INTERIOR_OFFSET)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if humanoid then
		task.spawn(function()
			-- Walk in front of the door before walking into it
			humanoid:MoveTo(doorExteriorPosition)
			humanoid.MoveToFinished:Wait()
			humanoid:MoveTo(doorInteriorPosition)
		end)
	end
end

local function walkOutOfDoor(character, door)
	local doorExteriorPosition = door.Entrance.CFrame:PointToWorldSpace(EXIT_EXTERIOR_OFFSET)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if humanoid then
		humanoid:MoveTo(doorExteriorPosition)
	end
end

local function zoomIntoDoor(door)
	local camera = Workspace.CurrentCamera :: Camera
	local entrance = door.Entrance :: BasePart
	local zoomCFrame = entrance.CFrame * ENTRY_CAMERA_END_OFFSET
	local cameraTween = TweenService:Create(camera, ENTRY_TWEEN_INFO, { CFrame = zoomCFrame })

	cameraTween:Play()
end

local function zoomOutOfDoor(door)
	local camera = Workspace.CurrentCamera :: Camera
	local entrance = door.Entrance :: BasePart
	local zoomCFrame = entrance.CFrame * EXIT_CAMERA_END_OFFSET
	local cameraTween = TweenService:Create(camera, EXIT_TWEEN_INFO, { CFrame = zoomCFrame })

	camera.CFrame = entrance.CFrame * EXIT_CAMERA_START_OFFSET
	cameraTween:Play()
end

local function fadeOutScreen()
	local frame = doorGui:FindFirstChild("Frame") :: Frame
	local fadeTween = TweenService:Create(frame, ENTRY_TWEEN_INFO, { BackgroundTransparency = 0 })
	fadeTween:Play()
end

local function fadeInScreen()
	local frame = doorGui:FindFirstChild("Frame") :: Frame
	local fadeTween = TweenService:Create(frame, EXIT_TWEEN_INFO, { BackgroundTransparency = 1 })
	fadeTween:Play()
end

local function walkThroughDoorsAsync(doorIn, doorOut)
	if isWalkingThroughDoors then
		return
	end

	if not player.Character then
		return
	end

	local character = player.Character :: Model

	isWalkingThroughDoors = true
	-- Disable character and camera controls
	setCharacterControlsEnabled(false)
	setCameraControlsEnabled(false)
	-- Disable interaction with the doors and allow them to be walked through
	setDoorOpen(doorIn, true)
	setDoorOpen(doorOut, true)

	-- Play the walk in, camera, and screen fade animations
	zoomIntoDoor(doorIn)
	walkIntoDoor(character, doorIn)
	fadeOutScreen()
	task.wait(ENTRY_ANIMATION_TIME)

	-- Teleport the character to the door they are exiting from
	character:PivotTo(doorOut.Entrance.CFrame)

	-- Play the walk out, camera, and screen fade animations
	zoomOutOfDoor(doorOut)
	walkOutOfDoor(character, doorOut)
	fadeInScreen()
	task.wait(EXIT_ANIMATION_TIME)

	-- Re-enable character and camera controls
	setCharacterControlsEnabled(true)
	setCameraControlsEnabled(true)
	-- Allow interaction with the doors and disallow them to be walked through
	setDoorOpen(doorIn, false)
	setDoorOpen(doorOut, false)
	isWalkingThroughDoors = false
end

local function initialize()
	exterior.Door.Entrance.ProximityPrompt.Triggered:Connect(function()
		walkThroughDoorsAsync(exterior.Door, interior.Door)
	end)

	interior.Door.Entrance.ProximityPrompt.Triggered:Connect(function()
		walkThroughDoorsAsync(interior.Door, exterior.Door)
	end)

	doorGui.Parent = playerGui
end

initialize()
