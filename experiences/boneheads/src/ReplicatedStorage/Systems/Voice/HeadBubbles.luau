-- HeadBubbles: shows a single chat bubble anchored above a player's custom head
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)

local getCharacterTextAnchor = require(ReplicatedStorage.Utility.getCharacterTextAnchor)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)
local getPlayerHead = require(ReplicatedStorage.Utility.getPlayerHead)

local MESSAGE_TOKEN_ATTRIBUTE = "messageToken"

local HeadBubbles = {}

-- Built once per head; getBubble reuses these afterwards.
local function buildBubble(headHost: BasePart): (Frame?, TextLabel?)
	local anchor = getCharacterTextAnchor(headHost)
	if not anchor then
		warn("No anchor to attach bubble to...")
		return nil, nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = Constants.BUBBLE_BILLBOARD_NAME
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(Constants.BUBBLE_MAX_WIDTH, Constants.BUBBLE_MAX_HEIGHT)
	billboard.StudsOffsetWorldSpace = Vector3.zero
	billboard.MaxDistance = Constants.CHAT_RANGE
	billboard.ResetOnSpawn = false
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = headHost

	local frame = Instance.new("Frame")
	frame.Name = Constants.BUBBLE_LABEL_NAME
	frame.BackgroundColor3 = Constants.BUBBLE_BACKGROUND_COLOR
	frame.BackgroundTransparency = 1
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.Size = UDim2.fromOffset(0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.TextColor3 = Constants.BUBBLE_TEXT_COLOR
	label.TextSize = Constants.BUBBLE_TEXT_SIZE
	label.TextTransparency = 1
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.FontFace = Font.fromEnum(Enum.Font.Gotham)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(Constants.BUBBLE_MAX_WIDTH, math.huge)
	sizeConstraint.Parent = label

	return frame, label
end

local function getBubble(headHost: BasePart): (Frame?, TextLabel?)
	local frame: Frame?
	local label: TextLabel?

	local billboard = headHost:FindFirstChild(Constants.BUBBLE_BILLBOARD_NAME) :: BillboardGui?
	if billboard then
		frame = billboard:FindFirstChild(Constants.BUBBLE_LABEL_NAME) :: Frame
		if frame then
			label = frame:FindFirstChildWhichIsA("TextLabel") :: TextLabel
		end
	else
		frame, label = buildBubble(headHost)
	end

	return frame, label
end

local function setBubbleVisible(frame: Frame, label: TextLabel, visible: boolean)
	local transparency = if visible then 0 else 1
	frame.BackgroundTransparency = transparency
	label.TextTransparency = transparency
end

local function isOutOfRange(headHost: BasePart): boolean
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end

	return (camera.CFrame.Position - headHost.Position).Magnitude > Constants.CHAT_RANGE
end

local function onMessageReceived(message: TextChatMessage)
	local source = message.TextSource
	if not source then
		return
	end

	local sender = Players:GetPlayerByUserId(source.UserId)
	if not sender then
		return
	end

	local headModel = getPlayerHead(sender.UserId)
	if not headModel then
		return
	end

	local headHost = getHostPart(headModel)
	if not headHost then
		return
	end

	if isOutOfRange(headHost) then
		return
	end

	local frame, label = getBubble(headHost)
	if not frame or not label then
		return
	end

	label.Text = message.Text
	setBubbleVisible(frame, label, true)

	-- A newer message bumps the token, so this timeout no longer hides the bubble.
	local token = (frame:GetAttribute(MESSAGE_TOKEN_ATTRIBUTE) :: number? or 0) + 1
	frame:SetAttribute(MESSAGE_TOKEN_ATTRIBUTE, token)

	task.delay(Constants.BUBBLE_DURATION_SECONDS, function()
		if frame.Parent and frame:GetAttribute(MESSAGE_TOKEN_ATTRIBUTE) == token then
			setBubbleVisible(frame, label, false)
		end
	end)
end

function HeadBubbles.start()
	TextChatService.MessageReceived:Connect(onMessageReceived)
end

return HeadBubbles
