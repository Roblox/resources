--!strict

--[[
	Returns the attachment corresponding with AttachmentName under the character
--]]

-- There can be multiple attachments with the same name in a character.
-- This table specifies exactly where to find the attachment point on the character
-- given an attachment name. R6 and R15 characters have differently named parts, so
-- we must include them both here.
local ATTACHMENT_LOCATIONS = {
	LeftGripAttachment = { R6 = "Left Arm", R15 = "LeftHand" },
	LeftShoulderAttachment = { R6 = "Left Arm", R15 = "LeftUpperArm" },
	RightGripAttachment = { R6 = "Right Arm", R15 = "RightHand" },
	RightShoulderAttachment = { R6 = "Right Arm", R15 = "RightUpperArm" },
	BodyFrontAttachment = { R6 = "Torso", R15 = "UpperTorso" },
	BodyBackAttachment = { R6 = "Torso", R15 = "UpperTorso" },
	LeftCollarAttachment = { R6 = "Torso", R15 = "UpperTorso" },
	RightCollarAttachment = { R6 = "Torso", R15 = "UpperTorso" },
	NeckAttachment = { R6 = "Torso", R15 = "UpperTorso" },
	WaistCenterAttachment = { R6 = "Torso", R15 = "LowerTorso" },
	WaistFrontAttachment = { R6 = "Torso", R15 = "LowerTorso" },
	WaistBackAttachment = { R6 = "Torso", R15 = "LowerTorso" },
	FaceCenterAttachment = { R6 = "Head", R15 = "Head" },
	FaceFrontAttachment = { R6 = "Head", R15 = "Head" },
	HairAttachment = { R6 = "Head", R15 = "Head" },
	HatAttachment = { R6 = "Head", R15 = "Head" },
}

local function getCharacterAttachment(character: Model, attachmentName: string)
	local locations = ATTACHMENT_LOCATIONS[attachmentName]
	assert(locations, string.format("Invalid attachmentName given: %s", attachmentName))
	assert(character, "Character does not exist")

	local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	local parentPartName = locations[humanoid.RigType.Name]
	local parentPart = character:FindFirstChild(parentPartName)

	local attachment = parentPart:FindFirstChild(attachmentName)

	return attachment
end

return getCharacterAttachment
