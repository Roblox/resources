-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")

local failureCounts: { [Player]: number } = {}

local StudioSimulator = {}

function StudioSimulator.simulateTeleport(
	player: Player,
	placeId: number,
	delaySeconds: number,
	simulateFailure: boolean,
	failureCount: number,
	shouldCancel: () -> boolean
)
	task.wait(delaySeconds)

	if shouldCancel() then
		return
	end

	if simulateFailure then
		local count = failureCounts[player] or 0
		count += 1
		failureCounts[player] = count

		if count <= failureCount then
			error(`Studio simulated teleport failure (attempt {count}/{failureCount})`)
		end
	end

	warn(`[TeleportServer] Studio mode: simulated teleport for {player.Name} to place {placeId}`)
	player:Kick(`[Studio] Teleported to place {placeId}`)
end

function StudioSimulator.cleanupPlayer(player: Player)
	failureCounts[player] = nil
end

function StudioSimulator.resetPlayer(player: Player)
	failureCounts[player] = 0
end

function StudioSimulator.start()
	Players.PlayerRemoving:Connect(StudioSimulator.cleanupPlayer)
end

return StudioSimulator
