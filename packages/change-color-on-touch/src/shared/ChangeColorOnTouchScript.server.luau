--[[
	Demonstrates changing the color of a part upon being touched by a player's character.
	The color change is debounced to ensure the Touched event does not trigger a color change too quickly.
	The part's color is randomly set using math.random.
--]]

local Players = game:GetService("Players")

local part = script.Parent.Part
local DEBOUNCE_TIME = 1
local random = Random.new()
local enabled = true

local function onPartTouched(otherPart: BasePart)
	if enabled then
		-- Check if a player touched the part
		local character = otherPart.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Temporarily disable changing the Part's color
			enabled = false

			-- Set the Part to a random color
			part.Color = Color3.new(random:NextNumber(), random:NextNumber(), random:NextNumber())

			-- Wait some time before reenabling
			task.wait(DEBOUNCE_TIME)

			-- Enable changing the Part's color
			enabled = true
		end
	end
end

-- Enable changing the Part's color initially
part.Touched:Connect(onPartTouched)
