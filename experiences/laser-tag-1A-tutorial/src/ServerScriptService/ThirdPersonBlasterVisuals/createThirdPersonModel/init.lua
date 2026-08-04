--!nocheck
--[[
	Creates a third-person blaster view model for other players to see.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)
local weldBlasterToCharacter = require(script.weldBlasterToCharacter)

local viewModelName = require(ReplicatedStorage.ViewModelName)

local laserSound = SoundService.LaserSound

local function createThirdPersonModel(player: Player)
	-- Destroy any existing view model
	local existingViewModel = player.Character:FindFirstChild(viewModelName)
	if existingViewModel then
		existingViewModel:Destroy()
	end

	-- Create a new view model
	local blasterConfig = getBlasterConfig(player)
	local viewModel = blasterConfig.ViewModel:Clone()

	-- Create sound instances per laser parented to the tip attachment to be played when blasted
	local tipAttachment = viewModel.PrimaryPart.TipAttachment
	local sound = laserSound:Clone()
	sound.Parent = tipAttachment

	-- Give it a standard name to reference by later when other players are
	-- determining the visual origin for blasts (see ReplicatedBlastRendering)
	viewModel.Name = viewModelName
	local character = player.Character or player.CharacterAdded:Wait()
	weldBlasterToCharacter(viewModel, character)
	viewModel.Parent = character
end

return createThirdPersonModel
