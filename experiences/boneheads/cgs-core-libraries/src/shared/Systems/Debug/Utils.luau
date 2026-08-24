-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local container: Folder? = nil

local Util = {}

function Util.getContainer(): Folder
	if not container then
		local folder = Instance.new("Folder")
		folder.Name = Constants.CONTAINER_NAME
		folder.Parent = Workspace
		container = folder
	end
	return container :: Folder
end

function Util.makeIntangible(basePart: BasePart)
	basePart.CanCollide = false
	basePart.CanTouch = false
	basePart.CanQuery = false
	basePart.Anchored = true
	basePart.CastShadow = false
	basePart.AudioCanCollide = false
end

function Util.createBillboard(): (BillboardGui, TextLabel)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = Constants.BILLBOARD.BILLBOARD_NAME
	billboard.AlwaysOnTop = true
	billboard.Size = Constants.BILLBOARD.BILLBOARD_SIZE

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	return billboard, label
end

return Util
