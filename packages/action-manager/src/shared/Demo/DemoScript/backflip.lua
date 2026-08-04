--!strict

local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player

local isFlipping = false

local function backflip()
	local character = player.Character
	if character then
		if isFlipping then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and character.PrimaryPart then
			local linearVelocity = character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0, 50, 20))
			local angularVelocity = character.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(12, 0, 0))

			isFlipping = true
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			character.PrimaryPart.AssemblyLinearVelocity += linearVelocity
			character.PrimaryPart.AssemblyAngularVelocity += angularVelocity
			task.wait(0.5)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			isFlipping = false
		end
	end
end

return backflip
