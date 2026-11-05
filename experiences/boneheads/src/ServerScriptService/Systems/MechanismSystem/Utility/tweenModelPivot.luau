local TweenService = game:GetService("TweenService")

local function tweenModelPivot(model: Model, targetCFrame: CFrame, tweenInfo: TweenInfo): () -> ()
	local cleaned = false

	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(value.Value)
	end)

	local tween = TweenService:Create(value, tweenInfo, { Value = targetCFrame })

	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		tween:Cancel()
		connection:Disconnect()
		value:Destroy()
	end

	tween.Completed:Once(cleanup)
	tween:Play()

	return cleanup
end

return tweenModelPivot
