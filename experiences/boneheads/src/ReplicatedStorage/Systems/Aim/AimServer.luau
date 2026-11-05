local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Systems.Aim.Constants)
local isFiniteVector = require(ReplicatedStorage.Utility.isFiniteVector)

local AimUpdate = ReplicatedStorage.Systems.Aim.Remotes.AimUpdate

local MIN_UPDATE_INTERVAL = Constants.STREAM_INTERVAL_SECONDS * 0.5

local AimServer = {}
local started = false
local lastUpdateAt: { [Player]: number } = {}

local function onAimUpdate(player: Player, aimPoint: Vector3)
	if typeof(aimPoint) ~= "Vector3" or not isFiniteVector(aimPoint) then
		return
	end
	local now = os.clock()
	local last = lastUpdateAt[player]
	if last and now - last < MIN_UPDATE_INTERVAL then
		return
	end
	lastUpdateAt[player] = now
	player:SetAttribute(Constants.AIM_POINT_ATTRIBUTE, aimPoint)
end

function AimServer.start()
	if started then
		return
	end
	started = true

	AimUpdate.OnServerEvent:Connect(onAimUpdate)
	Players.PlayerRemoving:Connect(function(player)
		lastUpdateAt[player] = nil
	end)
end

return AimServer
