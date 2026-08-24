-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function dampFactor(speed: number, delta: number)
	return 1 - math.pow(2, -delta * speed)
end

return dampFactor
