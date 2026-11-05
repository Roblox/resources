local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)
local getPlayerFromPart = require(ServerScriptService.Systems.MechanismSystem.Utility.getPlayerFromPart)
local setTorchEnabled = require(ServerScriptService.Systems.MechanismSystem.Utility.setTorchEnabled)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE
local SKULL_SPACING = 4

local state: {
	[Model]: {
		connections: { RBXScriptConnection },
		characterConnections: { [Player]: RBXScriptConnection },
		partToPlayer: { [BasePart]: Player },
		playerCounts: { [Player]: number },
		candle: Model,
		skullTemplate: MeshPart,
		skullOriginalCFrame: CFrame,
		candleOriginalCFrame: CFrame,
		skulls: { MeshPart },
		collider: BasePart,
		activated: boolean,
	},
} =
	{}

local function getPlayersInZoneCount(model: Model): number
	local entry = state[model]
	if not entry then
		return 0
	end

	local count = 0
	for _ in entry.playerCounts do
		count += 1
	end
	return count
end

local function removePlayerFromModel(model: Model, player: Player)
	local entry = state[model]
	if not entry then
		return
	end

	for part, trackedPlayer in entry.partToPlayer do
		if trackedPlayer == player then
			entry.partToPlayer[part] = nil
		end
	end

	entry.playerCounts[player] = nil

	if entry.characterConnections[player] then
		entry.characterConnections[player]:Disconnect()
		entry.characterConnections[player] = nil
	end
end

local function updateSkullLights(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	if entry.activated then
		for _, skull in entry.skulls do
			setTorchEnabled(skull, true)
		end
		setTorchEnabled(entry.candle, true)
		return
	end

	local playersInZone = getPlayersInZoneCount(model)
	local totalPlayers = #Players:GetPlayers()

	for index, skull in entry.skulls do
		setTorchEnabled(skull, index <= playersInZone)
	end

	local allPresent = playersInZone >= totalPlayers and totalPlayers > 0

	if allPresent then
		entry.activated = true
		model:SetAttribute(ACTIVATED, true)
		AudioServer.playOnInstance("TorchActivate", model)
		for _, skull in entry.skulls do
			setTorchEnabled(skull, true)
		end
		setTorchEnabled(entry.candle, true)
	else
		setTorchEnabled(entry.candle, false)
	end
end

local function rebuildSkullStack(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	local targetCount = math.max(1, #Players:GetPlayers())
	local currentCount = #entry.skulls

	if targetCount > currentCount then
		for index = currentCount + 1, targetCount do
			local clone = entry.skullTemplate:Clone()
			clone.Name = `SkullPart{index}`
			clone.CFrame = entry.skullOriginalCFrame * CFrame.new(0, SKULL_SPACING * (index - 1), 0)
			setTorchEnabled(clone, false)
			clone.Parent = model
			table.insert(entry.skulls, clone)
		end
	elseif targetCount < currentCount then
		for index = currentCount, targetCount + 1, -1 do
			local skull = entry.skulls[index]
			skull:Destroy()
			entry.skulls[index] = nil
		end
	end

	local candleOffset = SKULL_SPACING * math.max(0, #entry.skulls - 1)
	entry.candle:PivotTo(entry.candleOriginalCFrame * CFrame.new(0, candleOffset, 0))

	updateSkullLights(model)
end

local function onStart(model: Model, _inputs: { Model })
	local candle = model:FindFirstChild("Candle")
	if not (candle and candle:IsA("Model")) then
		warn(`[PlayerCounter] Model {model:GetFullName()} does not have a Model named Candle.`)
		return
	end

	local skullTemplate = model:FindFirstChild("SkullPart1")
	if not (skullTemplate and skullTemplate:IsA("MeshPart")) then
		warn(`[PlayerCounter] Model {model:GetFullName()} does not have a MeshPart named SkullPart1.`)
		return
	end

	local collider = model:FindFirstChild("Collider")
	if not (collider and collider:IsA("BasePart")) then
		warn(`[PlayerCounter] Model {model:GetFullName()} does not have a BasePart named Collider.`)
		return
	end

	model:SetAttribute(ACTIVATED, false)
	setTorchEnabled(candle, false)
	setTorchEnabled(skullTemplate, false)

	state[model] = {
		connections = {},
		characterConnections = {},
		partToPlayer = {},
		playerCounts = {},
		candle = candle,
		skullTemplate = skullTemplate,
		skullOriginalCFrame = skullTemplate.CFrame,
		candleOriginalCFrame = candle:GetPivot(),
		skulls = { skullTemplate },
		collider = collider,
		activated = false,
	}

	rebuildSkullStack(model)

	local playerAddedConnection = Players.PlayerAdded:Connect(function(_player: Player)
		rebuildSkullStack(model)
	end)

	local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player: Player)
		removePlayerFromModel(model, player)
		task.defer(function()
			rebuildSkullStack(model)
		end)
	end)

	local touchedConnection = collider.Touched:Connect(function(other: BasePart)
		local player = getPlayerFromPart(other)
		if not player then
			return
		end

		local entry = state[model]
		if not entry then
			return
		end

		if entry.partToPlayer[other] then
			return
		end
		entry.partToPlayer[other] = player

		local isNewPlayer = not entry.playerCounts[player]
		entry.playerCounts[player] = (entry.playerCounts[player] or 0) + 1

		if isNewPlayer and not entry.characterConnections[player] then
			entry.characterConnections[player] = player.CharacterRemoving:Connect(function()
				removePlayerFromModel(model, player)
				updateSkullLights(model)
			end)
		end

		updateSkullLights(model)
	end)

	local touchEndedConnection = collider.TouchEnded:Connect(function(other: BasePart)
		local entry = state[model]
		if not entry then
			return
		end

		local player = entry.partToPlayer[other]
		if not player then
			return
		end
		entry.partToPlayer[other] = nil

		local remaining = (entry.playerCounts[player] or 1) - 1
		if remaining <= 0 then
			entry.playerCounts[player] = nil
		else
			entry.playerCounts[player] = remaining
		end

		updateSkullLights(model)
	end)

	state[model].connections = {
		playerAddedConnection,
		playerRemovingConnection,
		touchedConnection,
		touchEndedConnection,
	}
end

local function onUpdate(_model: Model, _inputs: { Model }) end

local function onStop(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	for _, connection in entry.connections do
		connection:Disconnect()
	end

	for _, connection in entry.characterConnections do
		connection:Disconnect()
	end

	for index = #entry.skulls, 2, -1 do
		entry.skulls[index]:Destroy()
	end

	state[model] = nil
end

return {
	name = "PlayerCounter",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
