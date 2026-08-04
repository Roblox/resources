--[[
	Substitutes the default ForceField visual with our own custom visual in first-person.
	This only impact the local player's force field, not other players' force fields
--]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function onCharacterAddedAsync(character: Model)
	local forceField = character:WaitForChild("ForceField")
	forceField.Visible = false
	localPlayer.PlayerGui:WaitForChild("ForceFieldGui").Enabled = true
	forceField.Destroying:Wait()
	localPlayer.PlayerGui.ForceFieldGui.Enabled = false
end

if localPlayer.Character then
	onCharacterAddedAsync(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAddedAsync)
