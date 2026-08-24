-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Constants)

local function getHealth(entity: Instance): number
	local health = entity:GetAttribute(Constants.HEALTH_ATTRIBUTE)
	if typeof(health) ~= "number" then
		return -1
	end

	return health
end

local function getMaxHealth(entity: Instance): number
	local maxHealth = entity:GetAttribute(Constants.MAX_HEALTH_ATTRIBUTE)
	if typeof(maxHealth) ~= "number" then
		return -1
	end

	return maxHealth
end

local function hasHealth(entity: Instance): boolean
	return typeof(entity:GetAttribute(Constants.HEALTH_ATTRIBUTE)) == "number"
end

local function isAlive(entity: Instance): boolean
	return hasHealth(entity) and getHealth(entity) > 0
end

local function assign(entity: Instance, health: number, maxHealth: number?)
	assert(not hasHealth(entity), "Entity already has assigned health")

	entity:SetAttribute(Constants.MAX_HEALTH_ATTRIBUTE, maxHealth or health)
	entity:SetAttribute(Constants.HEALTH_ATTRIBUTE, math.clamp(health, 0, maxHealth or health))
end

local function setHealth(entity: Instance, health: number)
	local maxHealth = getMaxHealth(entity)
	local actualHealth = if maxHealth == -1 then health else math.clamp(health, 0, maxHealth)

	entity:SetAttribute(Constants.HEALTH_ATTRIBUTE, actualHealth)
end

local function setMaxHealth(entity: Instance, maxHealth: number)
	entity:SetAttribute(Constants.MAX_HEALTH_ATTRIBUTE, maxHealth)
end

local function resetHealth(entity: Instance)
	local maxHealth = getMaxHealth(entity)
	entity:SetAttribute(Constants.HEALTH_ATTRIBUTE, maxHealth)
end

local function takeDamage(entity: Instance, damage: number)
	if not hasHealth(entity) then
		return
	end

	local health = getHealth(entity)
	local maxHealth = getMaxHealth(entity)

	if health <= 0 then
		return
	end

	entity:SetAttribute(Constants.HEALTH_ATTRIBUTE, math.clamp(health - damage, 0, maxHealth))
end

local function onHealthChanged(entity: Instance, callback: (health: number, diff: number) -> ()): RBXScriptConnection
	local previousHealth = getHealth(entity)

	return entity:GetAttributeChangedSignal(Constants.HEALTH_ATTRIBUTE):Connect(function()
		local currentHealth = getHealth(entity)
		local diff = currentHealth - previousHealth
		previousHealth = currentHealth

		callback(currentHealth, diff)
	end)
end

local function onDied(entity: Instance, callback: () -> ()): RBXScriptConnection
	return onHealthChanged(entity, function(health: number)
		if health <= 0 then
			task.defer(callback) -- Allow other health changed events to process first
		end
	end)
end

local Health = {
	assign = assign,

	hasHealth = hasHealth,
	getHealth = getHealth,
	getMaxHealth = getMaxHealth,
	isAlive = isAlive,

	setHealth = setHealth,
	setMaxHealth = setMaxHealth,
	resetHealth = resetHealth,
	takeDamage = takeDamage,

	onHealthChanged = onHealthChanged,
	onDied = onDied,
}

return Health
