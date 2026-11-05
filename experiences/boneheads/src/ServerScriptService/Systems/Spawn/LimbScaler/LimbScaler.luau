local Players = game:GetService("Players")

local Constants = require(script.Parent.Constants)

local UPPER_LEG_SCALE = Constants.UPPER_LEG_SCALE
local LOWER_LEG_SCALE = Constants.LOWER_LEG_SCALE
local UPPER_ARM_SCALE = Constants.UPPER_ARM_SCALE
local LOWER_ARM_SCALE = Constants.LOWER_ARM_SCALE

type LimbSegment = { part: string, scale: number, attachments: { string }, groundsFeet: boolean }

local LIMB_SEGMENTS: { LimbSegment } = {
	{
		part = "UpperLeg",
		scale = UPPER_LEG_SCALE,
		attachments = { "HipRigAttachment", "KneeRigAttachment" },
		groundsFeet = true,
	},
	{
		part = "LowerLeg",
		scale = LOWER_LEG_SCALE,
		attachments = { "KneeRigAttachment", "AnkleRigAttachment" },
		groundsFeet = true,
	},
	{
		part = "UpperArm",
		scale = UPPER_ARM_SCALE,
		attachments = { "ShoulderRigAttachment", "ElbowRigAttachment" },
		groundsFeet = false,
	},
	{
		part = "LowerArm",
		scale = LOWER_ARM_SCALE,
		attachments = { "ElbowRigAttachment", "WristRigAttachment" },
		groundsFeet = false,
	},
}

local function scaleAttachmentHeight(attachment: Attachment, scale: number)
	local position = attachment.Position
	attachment.Position = Vector3.new(position.X, position.Y * scale, position.Z)
end

-- Segment length is the gap between attachments, not part Size, so Size.Y and
-- attachment Y-offsets must scale together to keep the rig's joints aligned.
local function scaleLimbs(character: Model, humanoid: Humanoid)
	local addedLegLength = 0

	for _, side in { "Left", "Right" } do
		for _, segment in LIMB_SEGMENTS do
			local part = character:FindFirstChild(side .. segment.part) :: BasePart?
			assert(part, `missing {side}{segment.part} on {character:GetFullName()}`)

			local firstAttachment = part:FindFirstChild(side .. segment.attachments[1]) :: Attachment?
			assert(firstAttachment, `missing {side}{segment.attachments[1]} on {part:GetFullName()}`)

			local secondAttachment = part:FindFirstChild(side .. segment.attachments[2]) :: Attachment?
			assert(secondAttachment, `missing {side}{segment.attachments[2]} on {part:GetFullName()}`)

			-- Only legs affect HipHeight; arms don't touch the ground.
			if segment.groundsFeet and side == "Left" then
				local gap = math.abs(firstAttachment.Position.Y - secondAttachment.Position.Y)
				addedLegLength += gap * (segment.scale - 1)
			end

			part.Size = Vector3.new(part.Size.X, part.Size.Y * segment.scale, part.Size.Z)
			scaleAttachmentHeight(firstAttachment, segment.scale)
			scaleAttachmentHeight(secondAttachment, segment.scale)
		end
	end

	humanoid.HipHeight += addedLegLength
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	character:WaitForChild("LeftUpperLeg")
	character:WaitForChild("LeftLowerLeg")
	character:WaitForChild("LeftUpperArm")
	character:WaitForChild("LeftLowerArm")

	scaleLimbs(character, humanoid)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local LimbScaler = {}

function LimbScaler.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return LimbScaler
