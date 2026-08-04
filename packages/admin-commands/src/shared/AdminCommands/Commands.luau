--!strict

local Workspace = game:GetService("Workspace")

export type Command = {
	PrimaryAlias: string,
	SecondaryAlias: string?,
	PermissionLevel: number, -- 0-255
	Function: (player: Player, args: { string }) -> (),
}

local Commands = {
	Prefix = "/",
	List = {
		{
			PrimaryAlias = "gravity",
			SecondaryAlias = "grav",
			PermissionLevel = 0,
			Function = function(player: Player, args: { string })
				local gravity = args[1]
				if gravity and tonumber(gravity) then
					Workspace.Gravity = tonumber(gravity) :: number
				end
			end,
		},
		{
			PrimaryAlias = "walkspeed",
			SecondaryAlias = "speed",
			PermissionLevel = 0,
			Function = function(player: Player, args: { string })
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local speed = args[1]
						if speed and tonumber(speed) then
							humanoid.WalkSpeed = tonumber(speed) :: number
						end
					end
				end
			end,
		},
		{
			PrimaryAlias = "explode",
			SecondaryAlias = nil,
			PermissionLevel = 0,
			Function = function(player: Player, args: { string })
				local character = player.Character
				if character then
					local primaryPart = character.PrimaryPart
					if primaryPart then
						local explosion = Instance.new("Explosion")
						explosion.Position = primaryPart.Position
						explosion.Parent = Workspace
					end
				end
			end,
		},
	} :: { Command },
}

return Commands
