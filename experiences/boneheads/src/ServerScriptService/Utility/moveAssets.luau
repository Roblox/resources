local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function moveAssets()
	local assets = Workspace:FindFirstChild("Assets")
	if not assets then
		warn("[moveAssets] No Assets folder found in Workspace.")
		return
	end

	assets.Parent = ReplicatedStorage.Content
end

return moveAssets
