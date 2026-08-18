--!strict
-- Sets up the dialog system with CollectionService.
-- Tag Models or BaseParts with "dialog" and add a `DialogId` string attribute
-- to map to a dialog file in ReplicatedStorage.DialogData.
--
-- NPC animation playback (so every nearby player sees the same talking/gesture
-- animations) lives in the NPCAnimator child module.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPCAnimator = require(script.NPCAnimator)

local DIALOG_TAG = "dialog"

local dialogFolder = ReplicatedStorage.DialogSystem

local DialogConfig = require(dialogFolder.DialogConfig)
local DialogData = require(dialogFolder.DialogLoader)

local remotesFolder = dialogFolder.Remotes

local startEvent = remotesFolder.StartDialog
local endEvent = remotesFolder.EndDialog
local screenEvent = remotesFolder.ScreenChanged

local DialogService = {}

-- player -> { npc, dialog } currently in dialog with that player.
-- Cache the resolved dialog so per-screen handlers don't have to re-derive
-- it from attributes.
type ActiveDialog = { npc: Instance, dialog: DialogData.Dialog }
local activeDialogs: { [Player]: ActiveDialog } = {}

-- Prompt and remotes
local function getPromptAdornee(npc: Instance): BasePart?
	if npc:IsA("BasePart") then
		return npc
	end
	if npc:IsA("Model") then
		return npc.PrimaryPart
	end
	return nil
end

local function setupPrompt(npc: Instance)
	local adornee = getPromptAdornee(npc)
	if not adornee then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DialogPrompt"
	prompt.ActionText = DialogConfig.Prompt.ActionText
	prompt.HoldDuration = DialogConfig.Prompt.HoldDuration
	prompt.MaxActivationDistance = DialogConfig.Prompt.MaxActivationDistance
	prompt.RequiresLineOfSight = DialogConfig.Prompt.RequiresLineOfSight
	local displayName = npc:GetAttribute("DisplayName")
	prompt.ObjectText = if typeof(displayName) == "string" then displayName else npc.Name
	prompt.Parent = adornee

	prompt.Triggered:Connect(function(player: Player)
		local dialogId = npc:GetAttribute("DialogId")
		if typeof(dialogId) ~= "string" or dialogId == "" then
			-- Arguably these should be errors, but because they happen on prompt trigger,
			-- I'm choosing to warn instead.
			warn(`[DialogService] {npc:GetFullName()} is missing a DialogId attribute.`)
			return
		end
		local dialog = DialogData[dialogId]
		if not dialog then
			warn(`[DialogService] No dialog data for id "{dialogId}" (npc {npc:GetFullName()}).`)
			return
		end
		-- Check if the player is already talking to someone
		if activeDialogs[player] then
			return
		end
		activeDialogs[player] = { npc = npc, dialog = dialog }
		NPCAnimator.acquire(npc, dialog.animation)
		startEvent:FireClient(player, npc, dialogId)
	end)
end

local function teardownPrompt(npc: Instance)
	local prompt = npc:FindFirstChild("DialogPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt:Destroy()
	end
	-- Stop animations in case dialog tag get removed mid-dialog.
	NPCAnimator.clear(npc)
end

function DialogService.start()
	-- Tag lifecycle
	for _, npc in CollectionService:GetTagged(DIALOG_TAG) do
		setupPrompt(npc)
	end
	CollectionService:GetInstanceAddedSignal(DIALOG_TAG):Connect(setupPrompt)
	CollectionService:GetInstanceRemovedSignal(DIALOG_TAG):Connect(teardownPrompt)

	-- Client tells us which screen the player just advanced to so we can play
	-- the matching mood gesture on the NPC for everyone to see.
	local function playScreenGesture(player: Player, screenIndex: number)
		if typeof(screenIndex) ~= "number" then
			return
		end
		local active = activeDialogs[player]
		if not active then
			return
		end
		local screen = active.dialog.screens[screenIndex]
		if not screen then
			return
		end
		local moodAnim = screen.mood and screen.mood.animation or nil
		NPCAnimator.playGesture(active.npc, moodAnim)
	end

	screenEvent.OnServerEvent:Connect(playScreenGesture)

	-- Called both when the client signals end-of-dialog and when the player leaves.
	local function endDialog(player: Player)
		local active = activeDialogs[player]
		activeDialogs[player] = nil
		if active then
			NPCAnimator.release(active.npc)
		end
	end

	endEvent.OnServerEvent:Connect(endDialog)
	Players.PlayerRemoving:Connect(endDialog)
end

return DialogService
