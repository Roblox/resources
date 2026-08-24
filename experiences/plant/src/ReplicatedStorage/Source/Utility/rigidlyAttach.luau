--!strict

--[[
	Uses a RigidConstraint to attach secondaryAttachment to primaryAttachment
--]]

local function rigidlyAttach(primaryAttachment: Attachment, secondaryAttachment: Attachment)
	local rigidConstraint = Instance.new("RigidConstraint")
	rigidConstraint.Attachment0 = primaryAttachment
	rigidConstraint.Attachment1 = secondaryAttachment
	rigidConstraint.Parent = secondaryAttachment.Parent
	rigidConstraint.Enabled = true

	return rigidConstraint
end

return rigidlyAttach
