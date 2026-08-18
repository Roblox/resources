--!strict
-- Built-in Roblox R15 emote animations.
local anims = {
	idle = "rbxassetid://507766388", -- R15 idle, used as a looping base
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	cheer = "rbxassetid://507770677",
	laugh = "rbxassetid://507770818",
}

local sounds = {
	dunno = "rbxassetid://78493587409325",
	hey = "rbxassetid://73321240458482",
	no = "rbxassetid://73921607954914",
	what = "rbxassetid://100452274047975",
	yeah = "rbxassetid://126142041947569",
}

local moods = {
	hostile = {
		image = "rbxassetid://120525174840991",
		sound = sounds.no,
		animation = anims.point,
		shake = true,
	},
	confused = {
		image = "rbxassetid://126021573637466",
		sound = sounds.dunno,
		animation = anims.laugh,
	},
	eager = {
		image = "rbxassetid://110492387653763",
		sound = sounds.yeah,
		animation = anims.cheer,
	},
	hello = {
		image = "rbxassetid://120174189550665",
		sound = sounds.hey,
		animation = anims.wave,
	},
}

local DialogRick = {
	id = "rick",
	animation = anims.idle,
	screens = {
		{
			text = "Please ignore the fact that I use the same portrait as Lola. I am a *unique person*. A unique _fish_ person.",
			mood = moods.hello,
		},
		{
			text = "Talk to her for the more immersive experience. Or don't. I matter, too.",
			mood = moods.eager,
		},
		{
			text = "Safe travels, friend! Come back anytime!",
			mood = moods.confused,
		},
	},
}

return DialogRick
