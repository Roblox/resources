-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function tapInputAction(inputAction: InputAction, duration: number?)
	assert(inputAction.Type == Enum.InputActionType.Bool, "Only InputAction of type Bool is supported for tapping")

	if inputAction:GetState() == true then
		return
	end

	inputAction:Fire(true)
	task.delay(duration or 0, function()
		inputAction:Fire(false)
	end)
end

return tapInputAction
