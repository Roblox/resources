--!strict

--[[
	Provides an API to use when referencing a Player's character
	to make sure it is "Fully loaded", which is defined as:
		1) Character is a descendant of workspace
		2) Character has a PrimaryPart set
		3) Character contains a child which is a Humanoid
		4) The Humanoid's RootPart property is not nil

	This differs from Player.CharacterAdded and Player.CharacterAppearanceLoaded which fire
	before a character is parented to workspace and does not guarantee these other conditions.

	This loaded event won't be necessary once the Player.CharacterAdded is moved to the end of the event
	call stack, per https://devforum.roblox.com/t/avatar-loading-event-ordering-improvements/269607

	This wrapper provides a died event when the first of the following happens:

	1) Humanoid's .Died event fires
	2) Character is removed

	We need this because there are some cases where a character can be removed without the humanoid dying,
	such as if :LoadCharacter() is called before a character dies. Cleanup code often needs to run when a
	character's "lifespan" is over, whether it be because the humanoid died or because the character is removed.
	To avoid having to connect to both events in multiple places, this wrapper moves both events into one.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Signal = require(ReplicatedStorage.Source.Signal)
local Connections = require(ReplicatedStorage.Source.Connections)
local waitForChildOfClassAsync = require(ReplicatedStorage.Source.Utility.waitForChildOfClassAsync)

local function isPrimaryPartSet(character: Model)
	return if character.PrimaryPart then true else false
end

local function isHumanoidRootPartSet(humanoid: Humanoid)
	return if humanoid.RootPart then true else false
end

local function getHumanoid(character: Model)
	return character:FindFirstChildOfClass("Humanoid")
end

local function isHumanoidAlive(character: Model)
	local humanoidMaybe = getHumanoid(character)
	if not humanoidMaybe then
		return false
	end

	local humanoid = humanoidMaybe :: Humanoid
	return isHumanoidRootPartSet(humanoid) and humanoid.Health > 0
end

local CharacterLoadedWrapper = {}
CharacterLoadedWrapper.__index = CharacterLoadedWrapper

export type ClassType = typeof(setmetatable(
	{} :: {
		loaded: Signal.ClassType,
		died: Signal.ClassType,
		_player: Player,
		_destroyed: boolean,
		_connections: Connections.ClassType,
	},
	CharacterLoadedWrapper
))

function CharacterLoadedWrapper.new(player: Player): ClassType
	local self = {
		loaded = Signal.new(),
		died = Signal.new(),
		_player = player,
		_destroyed = false,
		_connections = Connections.new(),
	}
	setmetatable(self, CharacterLoadedWrapper)

	self:_listenForCharacterAdded()

	return self
end

function CharacterLoadedWrapper.isLoaded(self: ClassType, optionalCharacter: Model?)
	-- Character can be passed in to check if a specific character model is
	-- the currently loaded character model. Useful if you are maintaining a reference
	-- to a specific character model, you want to verify that :isLoaded() is true, but
	-- you also want to make sure your current character reference isn't out of date.
	local characterMaybe = optionalCharacter or self._player.Character
	if not characterMaybe then
		return false
	end

	local character = characterMaybe :: Model

	return isPrimaryPartSet(character) and isHumanoidAlive(character) and character:IsDescendantOf(Workspace)
end

function CharacterLoadedWrapper._listenForCharacterAdded(self: ClassType)
	task.spawn(function()
		local character = self._player.Character

		-- Avoids firing .loaded event when the character is already loaded
		if character then
			if self:isLoaded() then
				self:_listenForDeath(character)
			else
				self:_waitForLoadedAsync(character)
			end
		end

		local characterAddedConnection = self._player.CharacterAdded:Connect(function(newCharacter: Model)
			self:_waitForLoadedAsync(newCharacter)
		end)

		self._connections:add(characterAddedConnection)
	end)
end

-- This function assumes the character exists when it's called and has default behavior,
-- i.e. developer is not parenting the character somewhere manually
function CharacterLoadedWrapper._waitForLoadedAsync(self: ClassType, character: Model)
	if not self:isLoaded() then
		-- Wait until the character is in Workspace so that the following conditions don't skip running.
		-- If the character is destroyed after this and never parented, :Wait() never resumes, causing the thread
		-- to yield forever, preventing the character from being garbage collected. Bug filed here:
		-- TODO: Add link to bug report
		if not character:IsDescendantOf(Workspace) then
			-- The character should be in workspace after waiting. However, deferred events may
			-- cause a character to get parented in and then back out before this :Wait() resumes,
			-- so we still need to check character.Parent later
			character.AncestryChanged:Wait()
		end

		-- Check character.Parent to avoid starting a :Wait() if the character is already destroyed
		-- which would keep the character from being garbage collected
		if character.Parent then
			if not isPrimaryPartSet(character) then
				character:GetPropertyChangedSignal("PrimaryPart"):Wait()
			end

			local humanoidMaybe = getHumanoid(character)
			if not humanoidMaybe then
				humanoidMaybe = waitForChildOfClassAsync(character, "Humanoid") :: Humanoid
			end

			local humanoid = humanoidMaybe :: Humanoid
			while not isHumanoidRootPartSet(humanoid) do
				humanoid.Changed:Wait() -- GetPropertyChangedSignal doesn't fire for RootPart, so we rely on .Changed
			end
		end

		-- Verify the character hasn't been destroyed and that no loaded criteria has become un-met.
		-- For example, the Humanoid being destroyed before the PrimaryPart was set
		if not self:isLoaded(character) then
			return
		end
	end

	-- Make sure this class wasn't destroyed while waiting for conditions to be true
	if self._destroyed then
		return
	end

	self:_listenForDeath(character)
	self.loaded:Fire(character)
end

function CharacterLoadedWrapper._listenForDeath(self: ClassType, character: Model)
	-- Debounce to prevent deferred events from letting .died event fire more than once,
	-- such as if the humanoid dies and the character is destroyed in the same compute cycle.
	-- With deferred events, that would fire both events on the next cycle, even if the connection
	-- is disconnected within the response to the event.
	local humanoid = getHumanoid(character) :: Humanoid

	local alreadyDied = false
	local diedConnection, removedConnection

	local function onDied()
		if alreadyDied then
			return
		end
		alreadyDied = true

		diedConnection:Disconnect()
		removedConnection:Disconnect()
		self.died:Fire(character)
	end

	diedConnection = humanoid.Died:Connect(onDied)

	-- .Destroying event would be preferred, but :LoadCharacter() just removes
	-- the character instead of destroying it. As long as that is the case, we
	-- can't use .Destroying to cover all edge cases.
	removedConnection = character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(Workspace) then
			onDied()
		end
	end)

	self._connections:add(diedConnection, removedConnection)
end

function CharacterLoadedWrapper.destroy(self: ClassType)
	self.loaded:DisconnectAll()
	self.died:DisconnectAll()
	self._destroyed = true

	self._connections:disconnect()
end

return CharacterLoadedWrapper
