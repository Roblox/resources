--!strict
-- Locks the local player's movement while dialog is open.
-- Zeroes WalkSpeed and both JumpPower and JumpHeight so it works whether or not
-- the Humanoid's UseJumpPower flag is set. Restores the original values on release.

local Players = game:GetService("Players")

local DialogConfig = require(script.Parent.Parent:WaitForChild("DialogConfig"))

local player = Players.LocalPlayer
assert(player, "PlayerFreeze must run on the client")

local PlayerFreeze = {}

local originalWalkSpeed: number? = nil
local originalJumpPower: number? = nil
local originalJumpHeight: number? = nil

function PlayerFreeze.set(frozen: boolean)
	-- Do nothing if disabled in DialogConfig
	if not DialogConfig.FreezePlayer then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if frozen then
		-- Store existing values.
		originalWalkSpeed = humanoid.WalkSpeed
		originalJumpPower = humanoid.JumpPower
		originalJumpHeight = humanoid.JumpHeight
		-- Freeze.
		humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight = 0, 0, 0
	else
		-- Restore prior values or defaults.
		humanoid.WalkSpeed = originalWalkSpeed or 16
		humanoid.JumpPower = originalJumpPower or 50
		humanoid.JumpHeight = originalJumpHeight or 7.2
		-- Back to nil for tidiness.
		originalWalkSpeed, originalJumpPower, originalJumpHeight = nil, nil, nil
	end
end

return PlayerFreeze
