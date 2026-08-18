--!strict
-- Builds and drives the dialog UI on the local player.
-- Call DialogClient.start() exactly once on the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local dialogFolder = ReplicatedStorage:WaitForChild("DialogSystem")
local DialogConfig = require(dialogFolder:WaitForChild("DialogConfig"))
local DialogData = require(dialogFolder:WaitForChild("DialogLoader"))
local DialogGui = require(dialogFolder:WaitForChild("DialogGui"))
local remoteFolder = dialogFolder:WaitForChild("Remotes")
local startEvent: RemoteEvent = remoteFolder:WaitForChild("StartDialog")
local endEvent: RemoteEvent = remoteFolder:WaitForChild("EndDialog")
local screenEvent: RemoteEvent = remoteFolder:WaitForChild("ScreenChanged")

local Typewriter = require(script.Typewriter)
local PlayerFreeze = require(script.PlayerFreeze)

-- Camera shake for moods that request it. Layered on top of the
-- normal camera each frame.
local CameraShaker = require(ReplicatedStorage.Utility.CameraShaker)
local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
	local cam = workspace.CurrentCamera
	if cam then
		cam.CFrame = cam.CFrame * shakeCf
	end
end)

local player = Players.LocalPlayer
assert(player, "DialogClient must run on the client")

local DialogClient = {}

-- Session state. A single Sound is created per session and reused as the mood changes;
-- creating Instances per screen gets expensive and fragile if the player advances quickly.
local session: {
	npc: Instance,
	dialog: DialogData.Dialog,
	index: number,
	sound: Sound,
}? = nil

local gui: ScreenGui
local parts: DialogGui.Parts

local function playMoodSound(assetId: string?)
	if not session then
		return
	end
	session.sound:Stop()
	if assetId and assetId ~= "" then
		session.sound.SoundId = assetId
		session.sound:Play()
	end
end

local function showScreen(screenIndex: number)
	if not session then
		return
	end
	-- Ugly but satisfies strict type checking
	local s = session
	local screen = s.dialog.screens[screenIndex]
	if not screen then
		return
	end

	s.index = screenIndex
	local isLast = screenIndex >= #s.dialog.screens

	local mood = screen.mood
	local moodImage = mood and mood.image or nil
	local moodSound = mood and mood.sound or nil

	parts.image.Image = moodImage or ""
	parts.image.Visible = (moodImage ~= nil and moodImage ~= "")

	parts.advanceBtn.Text = if isLast then "Exit" else "Next  \u{25B6}"
	parts.advanceBtn.Visible = true

	if mood and mood.shake then
		local cfg = DialogConfig.Shake
		-- Accepting type errors here rather than modifying the library
		camShake:ShakeOnce(cfg.Magnitude, cfg.Roughness, cfg.FadeIn, cfg.FadeOut)
	end

	playMoodSound(moodSound)

	-- Let the server play the matching mood gesture animation on the NPC so
	-- every nearby player sees it, not just the one in dialog.
	screenEvent:FireServer(screenIndex)

	Typewriter.play(parts.text, screen.text, DialogConfig.TextSpeed)
end

local function endSession(notifyServer: boolean)
	if not session then
		return
	end
	-- Ugly, but satisfies the type checker
	local s = session
	session = nil
	s.sound:Destroy()
	Typewriter.stop()
	gui.Enabled = false
	parts.text.Text = ""
	parts.image.Image = ""
	parts.advanceBtn.Visible = false
	PlayerFreeze.set(false)
	if notifyServer then
		endEvent:FireServer()
	end
end

local function advance()
	if not session then
		return
	end
	local s = session
	if Typewriter.isTyping() then
		-- First press: skip to end of current line.
		Typewriter.skip()
		return
	end
	if s.index >= #s.dialog.screens then
		-- Final screen: the advance button is now "Exit", and keyboard
		-- shortcuts mirror it so Space/Enter close the dialog too.
		endSession(true)
	else
		showScreen(s.index + 1)
	end
end

local function startSession(npc: Instance, dialogId: string)
	local dialog = DialogData[dialogId]
	if not dialog then
		endEvent:FireServer()
		return
	end

	-- Reset any prior session
	if session then
		endSession(false)
	end

	local sound = Instance.new("Sound")
	sound.Volume = DialogConfig.SoundEffectVolume
	sound.Parent = SoundService

	session = {
		npc = npc,
		dialog = dialog,
		index = 0,
		sound = sound,
	}

	PlayerFreeze.set(true)
	gui.Enabled = true
	showScreen(1)
end

-- Start

local started = false
function DialogClient.start()
	if started then
		return
	end
	started = true

	local playerGui = player:WaitForChild("PlayerGui")
	gui, parts = DialogGui.build()
	gui.Parent = playerGui

	camShake:Start()

	parts.advanceBtn.Activated:Connect(advance)

	-- Allow Space/Enter on keyboard to advance dialog.
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not session then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			advance()
		end
	end)

	startEvent.OnClientEvent:Connect(function(npc: Instance, dialogId: string)
		if typeof(npc) ~= "Instance" or typeof(dialogId) ~= "string" then
			return
		end
		startSession(npc, dialogId)
	end)

	-- If the player respawns mid-dialog, end gracefully so the new character isn't stuck.
	player.CharacterAdded:Connect(function()
		if session then
			endSession(true)
		end
	end)
end

return DialogClient
