local TweenService = game:GetService("TweenService")

local function crossfadeAsync(fadeFromSound: Sound, fadeToSound: Sound, fadeTime: number, volume: number)
	local tweenInfo = TweenInfo.new(fadeTime)

	local fadeOutTween = TweenService:Create(fadeFromSound, tweenInfo, { Volume = 0 })
	local fadeInTween = TweenService:Create(fadeToSound, tweenInfo, { Volume = volume })

	fadeOutTween:Play()
	fadeInTween:Play()

	fadeInTween.Completed:Wait()
end

return crossfadeAsync
