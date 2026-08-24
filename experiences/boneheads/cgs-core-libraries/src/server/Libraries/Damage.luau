-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Health = require(ReplicatedStorage.Core.Libraries.Health)

local lastAttackers: { [Model]: Instance? } = {}

local Damage = {}

function Damage.dealDamage(target: Model, amount: number, attacker: Instance?)
	if not Health.hasHealth(target) or not Health.isAlive(target) then
		return
	end

	if lastAttackers[target] == nil then
		target.Destroying:Once(function()
			lastAttackers[target] = nil
		end)
	end

	lastAttackers[target] = attacker
	Health.takeDamage(target, amount)
end

function Damage.onKilled(target: Model, callback: (attacker: Instance?) -> ()): RBXScriptConnection
	return Health.onDied(target, function()
		local attacker = lastAttackers[target]
		callback(attacker)
	end)
end

return Damage
