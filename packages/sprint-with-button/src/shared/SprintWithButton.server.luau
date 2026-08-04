--[[
	Demonstrates how to increase a player's speed when specific inputs are pressed.
	This sample implements left shift to run on keyboard, X to run on gamepad, and a touch button for mobile.
	The input buttons can be modified to any input desired.
--]]

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

-- Get the player's humanoid
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local SPRINT_ACTION = "SprintAction"
-- Keep track of the original walkspeed and a multiplier to use for sprinting
local WALK_SPEED = humanoid.WalkSpeed
local SPRINT_SPEED_MULTIPLIER = 2

-- Define buttons to use for sprinting on both keyboard and gamepad
local SPRINT_BUTTON_KEYBOARD = Enum.KeyCode.LeftShift
local SPRINT_BUTTON_GAMEPAD = Enum.KeyCode.ButtonX

-- When the player respawns, we need to get new reference to their humanoid
local function onCharacterAdded(newCharacter)
	humanoid = newCharacter:WaitForChild("Humanoid")
	character = newCharacter
end

local function handleAction(actionName, inputState)
	-- Make sure that the SPRINT_ACTION is being handled
	if actionName == SPRINT_ACTION then
		if inputState == Enum.UserInputState.Begin then
			-- If the input is beginning, set the humanoid's WalkSpeed based on SPRINT_SPEED_MULTIPLIER
			humanoid.WalkSpeed = WALK_SPEED * SPRINT_SPEED_MULTIPLIER
		elseif inputState == Enum.UserInputState.End then
			-- If the input is ending, set the humanoid's WalkSpeed back to its default
			humanoid.WalkSpeed = WALK_SPEED
		end
	end
end

-- If the player respawns, we need to handle their new character
player.CharacterAdded:Connect(onCharacterAdded)

-- Bind the keyboard and gamepad buttons to our handleAction function
-- BindAction automatically creates a mobile button to activate this action
ContextActionService:BindAction(SPRINT_ACTION, handleAction, true, SPRINT_BUTTON_KEYBOARD, SPRINT_BUTTON_GAMEPAD)
-- Set the title of the mobile button
ContextActionService:SetTitle(SPRINT_ACTION, "Sprint")
