local SpawnWithFriends = script:FindFirstAncestor("SpawnWithFriends")

local t = require(SpawnWithFriends.Packages.t)
local Configuration = require(script.Parent.Configuration)

local initialValues = {
	teleportToFriendOnRespawn = true,
	teleportDistance = 5, -- in studs
	showLogs = false, -- wether or not to display log messages
	maxCharacterVelocity = 48, -- characters moving faster than this won't be picked as teleportation candidates
	bypassFriendshipCheck = false,
}

local validator = t.strictInterface({
	teleportToFriendOnRespawn = t.optional(t.boolean),
	teleportDistance = t.optional(t.numberPositive),
	showLogs = t.optional(t.boolean),
	maxCharacterVelocity = t.optional(t.numberPositive),
	bypassFriendshipCheck = t.optional(t.boolean),
})

return Configuration.new(initialValues, validator)
