local ReplicatedFirst = game:GetService("ReplicatedFirst")

local InstructionsOverlay = require(script.Parent.Instructions.InstructionsOverlay)

local MIN_SECONDS_TO_SHOW_LOADING_SCREEN = 1

local function initialize()
	InstructionsOverlay.show()

	ReplicatedFirst:RemoveDefaultLoadingScreen()

	task.wait(MIN_SECONDS_TO_SHOW_LOADING_SCREEN)

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	InstructionsOverlay.autoHide()
end

initialize()
