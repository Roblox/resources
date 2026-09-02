local DataStoreService = game:GetService("DataStoreService")
local positionStore = DataStoreService:GetDataStore("PlayerPosition")

local function savePosition(player, position)
	local userId = player.UserId

	local success, err = pcall(function()
		positionStore:SetAsync(userId, { position.X, position.Y, position.Z })
	end)

	if not success then
		warn("Could not save position for", player.Name, ":", err)
	end
end
