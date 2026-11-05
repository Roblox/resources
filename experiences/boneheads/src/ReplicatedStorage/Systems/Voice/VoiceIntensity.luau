local RunService = game:GetService("RunService")

local VoiceIntensity = {}

type TalkingState = { endTime: number, targetVolume: number, smoothedVolume: number }

local SILENCE_GRACE = 0.25

local talkingPlayers: { [number]: TalkingState } = {}
local heartbeatConnection: RBXScriptConnection? = nil

function VoiceIntensity.feedVoice(userId: number, volume: number)
	local now = os.clock()
	local existing = talkingPlayers[userId]
	if existing then
		existing.endTime = now + SILENCE_GRACE
		existing.targetVolume = volume
	else
		talkingPlayers[userId] = {
			endTime = now + SILENCE_GRACE,
			targetVolume = volume,
			smoothedVolume = volume * 0.5,
		}
	end
end

function VoiceIntensity.stopUser(userId: number)
	talkingPlayers[userId] = nil
end

function VoiceIntensity.getIntensity(userId: number): number
	local data = talkingPlayers[userId]
	return math.clamp(data and data.smoothedVolume or 0, 0, 1)
end

function VoiceIntensity.start()
	if heartbeatConnection then
		return
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		local now = os.clock()

		for userId, data in pairs(talkingPlayers) do
			if now > data.endTime then
				talkingPlayers[userId] = nil
				continue
			end

			data.smoothedVolume = data.smoothedVolume + (data.targetVolume - data.smoothedVolume) * 0.45
		end
	end)
end

function VoiceIntensity.stop()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	table.clear(talkingPlayers)
end

return VoiceIntensity
