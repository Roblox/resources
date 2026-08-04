--[[
	Connects the blast functionality (attemptBlastClient) to specific user input.

	ContextActionService binds the left mouse click and R2 (gamepad) inputs.
	The HUDGui contains a button for blasting on mobile devices that is also connected.
--]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local attemptBlastClient = require(ReplicatedStorage.Blaster.attemptBlastClient)

local function onBlasterActivated(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		attemptBlastClient()
	end
end

-- Listen for activation input
-- An 'actionName' is irrelevant as we never unbind the action
ContextActionService:BindAction("_", onBlasterActivated, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

-- Listen for touch activation on the HUD blast button
local HUDGui = Players.LocalPlayer.PlayerGui:WaitForChild("HUDGui")
local blastButton = HUDGui.BlastButton
blastButton.Activated:Connect(attemptBlastClient)
