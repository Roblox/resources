local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Systems.CustomAbilities.Emote.Types)

return {
	{
		id = "wave",
		assetIds = { "rbxassetid://507770239" },
		label = "Wave",
		image = "rbxthumb://type=Asset&id=3576686446&w=150&h=150",
	},
	{
		id = "point",
		assetIds = {
			"rbxassetid://507770453",
			"rbxassetid://10714395441",
		},
		label = "Point",
		image = "rbxthumb://type=Asset&id=3576823880&w=150&h=150",
	},
	{
		id = "yes",
		assetIds = { "rbxassetid://10713954623" },
		label = "Yes",
		image = "rbxthumb://type=Asset&id=3360689775&w=150&h=150",
	},
	{
		id = "no",
		assetIds = { "rbxassetid://10714065135" },
		label = "No",
		image = "rbxthumb://type=Asset&id=4689362868&w=150&h=150",
	},
	{
		id = "dance",
		assetIds = {
			"rbxassetid://10714388352",
			"rbxassetid://10714340543",
			"rbxassetid://10714383856",
			"rbxassetid://10714069471",
			"rbxassetid://10714392151",
		},
		label = "Dance",
		image = "rbxthumb://type=Asset&id=5917570207&w=150&h=150",
	},
} :: { Types.Element }
