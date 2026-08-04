--[[
	Attaches a new instance of a "cooldown meter" part to the given attachment to provide visual feedback
	through a surface GUI for when the player can fire.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cooldownBarPrefab = ReplicatedStorage.Instances.Guis.CooldownBarPrefab

local function addCooldownBar(attachment: Attachment): Part
	local part = cooldownBarPrefab:Clone()

	-- Move and weld the cooldown bar part to the blaster
	part:PivotTo(attachment.WorldCFrame)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = attachment.Parent
	weld.Part1 = part
	weld.Parent = part

	-- Make sure the weld is setup prior to parenting to the blaster
	part.Parent = attachment.Parent

	return part
end

return addCooldownBar
