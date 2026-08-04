--!strict

--[[
	ModalManager provides a module for managing multiple GuiObject-based modals.
	Opening and closing modals set with ModalManager will ensure only one modal is open at a time.
	ModalManager also helps with tweening the modals in and out of view.
	It also contains a getter for a centralized ScreenGui for all HUD buttons to be parented to so they can be centrally organized.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UITween = require(ReplicatedStorage.FeaturePackagesCore.Modules.UITween)
local getInstance = require(ReplicatedStorage.FeaturePackagesCore.Utils.getInstance)

local localPlayer = Players.LocalPlayer :: Player
local hudGui: ScreenGui = getInstance(ReplicatedStorage, "FeaturePackagesCore", "Objects", "FeaturePackagesHud")

local modals: { [string]: GuiObject } = {}

local ModalManager = {}

local function animateOpen(id: string): Tween?
	local modal = modals[id]
	if not modal then
		return nil
	end

	modal.Visible = true
	return UITween.transparency(modal, 0, 0.5)
end

local function animateClose(id: string): Tween?
	local modal = modals[id]
	if not modal then
		return nil
	end

	local tween = UITween.transparency(modal, 1, 0.25)

	if not tween then
		return nil
	end

	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			modal.Visible = false
		end
	end)

	return tween
end

function ModalManager.get(id: string): GuiObject?
	return modals[id]
end

function ModalManager.getActive(): (string?, GuiObject?)
	for id, modal in pairs(modals) do
		if modal.Visible then
			return id, modal
		end
	end

	return nil, nil
end

function ModalManager.isOpen(id: string): boolean
	local activeId, _modal = ModalManager.getActive()
	return id == activeId
end

function ModalManager.set(id: string, modal: GuiObject)
	modals[id] = modal

	-- Set the modal to the closed state initially
	modal.Visible = false

	if modal:IsA("CanvasGroup") then
		modal.GroupTransparency = 1
	end
end

function ModalManager.unset(id: string)
	modals[id] = nil
end

function ModalManager.open(id: string): Tween?
	-- Check if the modal exists before opening
	local modal = modals[id]
	if not modal then
		warn(`No modal with id {id} to open.`)
		return nil
	end

	if ModalManager.isOpen(id) then
		return nil
	end

	ModalManager.close()
	return animateOpen(id)
end

function ModalManager.close(id: string?): Tween?
	-- Check if there is an active modal to close
	local activeId, activeModal = ModalManager.getActive()
	if not activeModal then
		return nil
	end

	-- If id was specified, verify that the active modal matches the id
	if id then
		-- Check if the modal exists before opening
		local modal = modals[id]
		if not modal then
			warn(`No modal with id {id} to close.`)
			return nil
		end

		if activeModal ~= modal then
			-- Different modal is active
			return nil
		end
	end

	local idToClose = id or activeId
	if not idToClose then
		return nil
	end

	return animateClose(idToClose)
end

function ModalManager.toggleOpen(id: string?): Tween?
	local activeId, _ = ModalManager.getActive()
	id = id or activeId

	if not id then
		return nil
	end

	if id == activeId then
		return ModalManager.close(id)
	else
		return ModalManager.open(id)
	end
end

function ModalManager.getHudGui(): ScreenGui
	hudGui.Parent = localPlayer.PlayerGui
	return hudGui
end

return ModalManager
