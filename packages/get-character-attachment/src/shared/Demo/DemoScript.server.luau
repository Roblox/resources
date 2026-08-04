--[[
	Returns the attachment corresponding with AttachmentName under the character.
	The DemoScript uses getCharacterAttachment to correctly attach a pizza slice to a character's RightGripAttachment.
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local getCharacterAttachment = require(script.Parent.Parent.getCharacterAttachment)

local pizzaTemplate = script.Parent.Pizza
local characterAttachmentName = "RightGripAttachment"

pizzaTemplate.Parent = nil

-- Creates a RigidConstraint between two attachments
local function rigidlyAttach(primaryAttachment: Attachment, secondaryAttachment: Attachment)
	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Attachment0 = primaryAttachment
	rigidConstraint.Attachment1 = secondaryAttachment
	rigidConstraint.Parent = secondaryAttachment.Parent
	rigidConstraint.Enabled = true

	return rigidConstraint
end

local function onPlayerAdded(player: Player)
	player.CharacterAppearanceLoaded:Connect(function(character: Model)
		local pizzaSlice = pizzaTemplate:Clone()
		local pizzaAttachment = pizzaSlice.Attachment

		-- Use getCharacterAttachment to get the correct attachment from the character
		local characterAttachment = getCharacterAttachment(character, characterAttachmentName)
		-- Create a rigid constrain between the pizza and character attachments
		rigidlyAttach(pizzaAttachment, characterAttachment)

		pizzaSlice.Parent = Workspace
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
