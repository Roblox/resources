--!strict

--[[
	ActionManager provides a wrapper for ContextActionService that displays all bound actions on-screen.
	Input prompts automatically change based on the latest input type, rather than being set once based on peripherals.
--]]

local ActionManager = require(script.Parent.Parent.ActionManager)

-- A list of action functions
local actions = {
	["Backflip"] = require(script.backflip),
	["Emote"] = require(script.emote),
}

-- Function to call the appropriate action function when input is began
local function actionHandler(action: string, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		if actions[action] then
			actions[action]()
		end
	end
end

-- Actions are bound through ActionManager, rather than ContextActionService or UserInputService
ActionManager.bindAction("Backflip", actionHandler, Enum.KeyCode.Q, Enum.KeyCode.ButtonX, 1)
ActionManager.bindAction("Emote", actionHandler, Enum.KeyCode.E, Enum.KeyCode.ButtonY, 2)
