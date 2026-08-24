-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Token = {}

function Token.canTake(holder: Instance, token: string): boolean
	local tokens = holder:GetAttribute(token)
	return typeof(tokens) == "number" and tokens > 0
end

function Token.take(holder: Instance, token: string): boolean
	if Token.canTake(holder, token) then
		local tokens = holder:GetAttribute(token) :: number
		holder:SetAttribute(token, tokens - 1)
		return true
	end

	return false
end

function Token.release(holder: Instance, token: string)
	local tokens = holder:GetAttribute(token)

	if typeof(tokens) == "number" then
		holder:SetAttribute(token, tokens + 1)
	end
end

return Token
