--!strict

--[[
	Module with helpers for protecting the context of a ModuleScript. This is useful for ensuring that the ModuleScript is only run on the server or client, and not both.
--]]

local RunService = game:GetService("RunService")

local ProtectRunContext = {}

function ProtectRunContext.client()
	if not RunService:IsClient() then
		error("This ModuleScript should only be run on the client.")
	end
end

function ProtectRunContext.server()
	if not RunService:IsServer() then
		error("This ModuleScript should only be run on the server.")
	end
end

return ProtectRunContext
