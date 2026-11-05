-- TextToSpeech: configures native TextChatService bubble chat and drives text-to-speech
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Constants = require(script.Parent.Constants)
local VoiceEffects = require(script.Parent.VoiceEffects)

local localPlayer = Players.LocalPlayer

local TextToSpeech = {}

function TextToSpeech.start()
	local bubbleConfig = TextChatService:WaitForChild("BubbleChatConfiguration") :: BubbleChatConfiguration
	bubbleConfig.Enabled = false

	local windowConfig = TextChatService:WaitForChild("ChatWindowConfiguration") :: ChatWindowConfiguration
	windowConfig.Enabled = false

	TextChatService.MessageReceived:Connect(function(message: TextChatMessage)
		local source = message.TextSource
		if not source then
			return
		end

		local sender = Players:GetPlayerByUserId(source.UserId)
		if not sender then
			return
		end

		if sender ~= localPlayer then
			local localCharacter = localPlayer.Character
			local senderCharacter = sender.Character
			if localCharacter and senderCharacter then
				local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
				local senderRoot = senderCharacter:FindFirstChild("HumanoidRootPart")
				if
					localRoot
					and senderRoot
					and (localRoot.Position - senderRoot.Position).Magnitude > Constants.CHAT_RANGE
				then
					return
				end
			end
		end

		VoiceEffects.speakText(sender, message.Text)
	end)
end

return TextToSpeech
