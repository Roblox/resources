--!strict

--[[
	Moves a model's PrimaryPart CFrame to targetCFrame, offset by attachment.CFrame
	It's recommended to have attachment be a child of the model's PrimaryPart, because
	attachment.CFrame is local to the attachment's parent
--]]

local function moveModelByAttachment(model: Model, attachment: Attachment, targetCFrame: CFrame)
	assert(
		model.PrimaryPart,
		"moveModelByAttachment requires model to have a PrimaryPart. Model: " .. model:GetFullName()
	)
	model:PivotTo(targetCFrame * attachment.CFrame:Inverse())
end

return moveModelByAttachment
