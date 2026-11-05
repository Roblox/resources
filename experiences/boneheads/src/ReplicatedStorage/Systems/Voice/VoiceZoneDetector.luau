-- Polls tagged VoiceZone parts/models and applies voice presets to players within their bounds
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Constants = require(script.Parent.Constants)
local VoiceEffects = require(script.Parent.VoiceEffects)
local VOICE_PRESETS = Constants.VOICE_PRESETS

local VoiceZoneDetector = {}

local running = false
local MIN_HALF_EXTENT = 5

local function getZoneBounds(zone: Instance): (CFrame?, Vector3?)
	if zone:IsA("BasePart") then
		return zone.CFrame, zone.Size
	elseif zone:IsA("Model") then
		return zone:GetBoundingBox()
	end
	return nil, nil
end

local function isInZone(zone: Instance, position: Vector3): boolean
	local cframe, size = getZoneBounds(zone)
	if not cframe or not size then
		return false
	end

	local half = size / 2
	local localPosition = cframe:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= math.max(half.X, MIN_HALF_EXTENT)
		and math.abs(localPosition.Y) <= math.max(half.Y, MIN_HALF_EXTENT)
		and math.abs(localPosition.Z) <= math.max(half.Z, MIN_HALF_EXTENT)
end

function VoiceZoneDetector.start()
	if running then
		return
	end
	running = true

	task.spawn(function()
		while running do
			task.wait(0.4)

			local zones = CollectionService:GetTagged(Constants.VOICE_ZONE_TAG)

			for _, player in Players:GetPlayers() do
				local character = player.Character
				local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

				if not humanoidRootPart then
					continue
				end

				local activeZonePreset = Constants.DEFAULT_VOICE_PRESET

				for _, zone in zones do
					if isInZone(zone, humanoidRootPart.Position) then
						local presetAttribute = zone:GetAttribute(Constants.VOICE_PRESET_ATTRIBUTE)
						if presetAttribute and VOICE_PRESETS[presetAttribute] then
							activeZonePreset = presetAttribute
							break
						end
					end
				end
				VoiceEffects.applyPresetToPlayer(player.UserId, activeZonePreset)
			end
		end
	end)
end

function VoiceZoneDetector.stop()
	running = false
end

return VoiceZoneDetector
