--[[
	The FollowingAttachment module creates an attachment that trails on the ground at some max distance behind a player's character.
	DemoScript uses constraints to align a rock's position and orientation with the attachment such that the rock follows each player's character.
	The attachment stops updating and the rock model is destroyed when the character dies.
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FollowingAttachment = require(script.Parent.Parent.FollowingAttachment)
local rockTemplate = script.Parent.Rock
rockTemplate.Parent = nil

local followingAttachmentProperties: FollowingAttachment.FollowingAttachmentProperties = {
	maxFollowDistance = 10,
	verticalRayOffset = 0,
	downVectorDistance = 0,
	raycastParams = RaycastParams.new(),
}

local function attachModel(player: Player, followingAttachment)
	local followAttachment = followingAttachment:getAttachment()

	local rock = rockTemplate:Clone()
	local rockAttachment = rock.Attachment

	-- align the position and orientation of the rock's attachment with the FollowAttachment
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = rockAttachment
	alignPosition.Attachment1 = followAttachment
	alignPosition.MaxForce = 100000
	alignPosition.Responsiveness = 25
	alignPosition.Parent = rock

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Attachment0 = rockAttachment
	alignOrientation.Attachment1 = followAttachment
	alignOrientation.MaxTorque = 100000
	alignOrientation.Responsiveness = 25
	alignOrientation.Parent = rock

	rock:PivotTo(followAttachment.CFrame)
	-- parent to the FollowAttachment to ensure it is destroyed with the attachment
	rock.Parent = followAttachment
	rock:SetNetworkOwner(player)
end

local function onPlayerAdded(player: Player)
	local function onCharacterAdded(character: Model)
		-- wait for Character to exist in workspace, then create FollowAttachment
		if not character:IsDescendantOf(Workspace) then
			character.AncestryChanged:Wait()
		end
		local followingAttachment = FollowingAttachment.new(player, followingAttachmentProperties)

		-- destroy the FollowAttachment when the player dies
		local function onDied()
			followingAttachment:destroy()
		end

		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(onDied)

		attachModel(player, followingAttachment)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
