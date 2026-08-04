--!strict

--[[
	Utility for attempting to play sound. If soundId is invalid, or permission is insufficient, it will not play.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)

local function playSound(soundId: string, volume: number?)
	pcall(function()
		local soundEffect = Instance.new("Sound")
		soundEffect.SoundId = `rbxassetid://{soundId}`
		soundEffect.Volume = volume or SharedConstants.Sounds.VOLUME
		soundEffect.Parent = SoundService
		soundEffect:Play()

		soundEffect.Ended:Once(function()
			soundEffect:Destroy()
		end)
	end)
end

return playSound
