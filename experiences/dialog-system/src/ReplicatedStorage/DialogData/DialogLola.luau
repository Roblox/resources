--!strict
-- Built-in Roblox R15 emote animations.
local anims = {
	idle = "rbxassetid://507766388", -- R15 idle, used as a looping base
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	cheer = "rbxassetid://507770677",
	laugh = "rbxassetid://507770818",
}

-- Placeholders from Andrew.
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

local DialogLola = {
	id = "lola",
	animation = anims.idle,
	screens = {
		{
			text = "Hello there! I haven't seen ~such a unique face~ a new face in ages!",
			mood = moods.hello,
		},
		{
			text = "My name is Lola. I find you *extremely aggravating*!",
			mood = moods.hostile,
		},
		{
			text = [[If you're looking for !!some key word or phrase!!, check out the path to the east.
I saw some hungry badgers, so be careful out there.]],
			mood = moods.eager,
		},
		{
			text = "Safe travels, friend! Come back anytime!",
			mood = moods.confused,
		},
	},
}

return DialogLola
