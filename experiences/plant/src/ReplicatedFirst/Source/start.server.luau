--!strict

--[[
	The client sided entry point for all code in the experience.
--]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LoadingScreen = require(ReplicatedFirst.Source.LoadingScreen)
local waitForGameLoadedAsync = require(ReplicatedFirst.Source.Utility.waitForGameLoadedAsync)

local localPlayer = Players.LocalPlayer :: Player

local function preGameLoadTasksAsync()
	LoadingScreen.enableAsync()
	LoadingScreen.updateDetailText("Landscaping world...")
end

local function postGameLoadTasksAsync()
	-- Generally, in-line dependency requires are considered bad practice. In this case however,
	-- they are necessary as because this code is running in ReplicatedFirst we cannot guarantee
	-- these modules exist until waitForGameLoadedAsync has returned.
	local Network = require(ReplicatedStorage.Source.Network)
	local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
	local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
	local LocalWalkJumpManager = require(ReplicatedStorage.Source.LocalWalkJumpManager)
	local FarmManagerClient = require(ReplicatedStorage.Source.Farm.FarmManagerClient)
	local UISetup = require(ReplicatedStorage.Source.UI.UISetup)
	local FtueManagerClient = require(ReplicatedStorage.Source.FtueManagerClient)
	local CharacterSprint = require(ReplicatedStorage.Source.CharacterSprint)
	local DevProductPriceList = require(ReplicatedStorage.Source.DevProductPriceList)

	LoadingScreen.updateDetailText("Waiting for network...")
	Network.startClientAsync()
	PlayerDataClient.start()

	if not PlayerDataClient.hasLoaded() then
		LoadingScreen.updateDetailText("Finding your data...")
		PlayerDataClient.loaded:Wait()
	end

	LoadingScreen.updateDetailText("Fetching products...")
	DevProductPriceList.setupAsync()

	local characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)
	if not characterLoadedWrapper:isLoaded() then
		LoadingScreen.updateDetailText("Spawning character...")
		characterLoadedWrapper.loaded:Wait()
	end

	LocalWalkJumpManager.setup()
	FarmManagerClient.start()
	UISetup.start()
	FtueManagerClient.start()

	LoadingScreen.updateDetailText("Finishing up...")
	LoadingScreen.disableAsync()

	CharacterSprint.start()
end

preGameLoadTasksAsync()
waitForGameLoadedAsync()
postGameLoadTasksAsync()
