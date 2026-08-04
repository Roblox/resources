local Admins = {
	-- Users in this group will have their permission level set to their current rank in the group
	GroupId = -1,
	-- Ranks set here for player UserIds will override ranks from the GroupId
	UserIds = {
		-- [game.CreatorId] = 255,
		-- [123456789] = 10,
	},
}

return Admins
