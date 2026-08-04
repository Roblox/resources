--[[
	Sets up humanoid properties to always see player's name and health. Also prevents the character
	from falling apart when they are tagged out.

	Waits for the given humanoid's Died event, then runs all tagged out logic within onHumanoidDied.
--]]

local onHumanoidDied = require(script.onHumanoidDied)

local function setupHumanoidAsync(player: Player, humanoid: Humanoid)
	-- Give each humanoid full control over its name/health display distance
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject

	-- Set name and health display distances to a sufficiently large value to show display name
	-- and health bar at any practical distance, as long as it is not occluded
	humanoid.NameDisplayDistance = 1000
	humanoid.HealthDisplayDistance = 1000
	humanoid.NameOcclusion = Enum.NameOcclusion.OccludeAll
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

	-- Prevent character from falling apart when health is depleted
	humanoid.BreakJointsOnDeath = false

	humanoid.Died:Wait()
	onHumanoidDied(player, humanoid)
end

return setupHumanoidAsync
