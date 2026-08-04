--!nocheck
--[[
	Handles dealing damage to a tagged humanoid. Ensures the humanoids health is never negative.

	Awards the player who blasted a point if they tag a player out (Health = 0).

	SetupHumanoid handles updated the player's state upon their health reaching 0 by waiting for
	the humanoid Died event.
--]]

local function onPlayerTagged(playerBlasted: Player, playerTagged: Player, damageAmount: number)
	local character = playerTagged.Character

	local humanoid = character and character:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		-- Avoid negative health
		local damage = math.min(damageAmount, humanoid.Health)

		-- TakeDamage ensures health is not lowered if ForceField is active
		humanoid:TakeDamage(damage)
		if humanoid.Health <= 0 then
			-- Award taggedByPlayer a point for tagging playerTagged
			playerBlasted.leaderstats.Points.Value += 1
		end
	end
end

return onPlayerTagged
