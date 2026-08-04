--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")

local retryAsync = require(script.Parent.retryAsync)
local setSequentialInterval = require(script.Parent.setSequentialInterval)

local TAKEOVER_INTERVAL_MULTIPLIER = 2
local LEADER_EXPIRATION_MULTIPLIER = 2
-- Key expiration is set to longer than leadership expiration so that delta times can be
-- kept consistent if the leader server crashes
local KEY_EXPIRATION_MULTIPLIER = 3
local KEY = "Info"

local UPDATE_ATTEMPTS = 3
local UPDATE_RETRY_PAUSE_CONSTANT = 2
local UPDATE_RETRY_PAUSE_EXPONENT_BASE = 2

local LoopMode = {
	Idle = "Idle",
	Update = "Update",
	Takeover = "Takeover",
}

type LeaderInfo = {
	Leader: string,
	LastUpdate: number,
	LeaderExpiration: number,
}

local Loop = {}
Loop.__index = Loop

function Loop.new(id: string, interval: number, updateFunction: (number) -> ())
	local self = {
		id = id,
		_started = false,
		_mode = LoopMode.Idle,
		_memoryStore = MemoryStoreService:GetSortedMap(string.format("Loop_%s", id)),
		_updateInterval = interval,
		_takeoverInterval = interval * TAKEOVER_INTERVAL_MULTIPLIER,
		_leaderExpiration = interval * LEADER_EXPIRATION_MULTIPLIER,
		_keyExpiration = interval * KEY_EXPIRATION_MULTIPLIER,
		_updateFunction = updateFunction,
		_clearIntervalFunction = nil,
	}

	setmetatable(self, Loop)

	return self
end

-- Set a function to be called on an interval, taking into account the time it takes for the function to complete if it is Async
-- Only one function can be set to be called at once
function Loop:_setIntervalFunction(functionToCall: () -> (), interval: number)
	if self._clearIntervalFunction then
		self._clearIntervalFunction()
	end

	self._clearIntervalFunction = setSequentialInterval(functionToCall, interval)
end

-- Attempt to take over leadership of the loop
function Loop:_attemptTakeoverAsync(): boolean
	local tookLeadership = false

	local success = pcall(function()
		self._memoryStore:UpdateAsync(KEY, function(oldInfo): LeaderInfo?
			-- When the same key is updated by multiple servers at once, this callback may be called multiple
			-- times in order to resolve correctly. Since we have a flag variable that was defined outside of
			-- this scope, we need to reset it at the start of each callback.
			tookLeadership = false
			local newInfo = oldInfo :: LeaderInfo?
			local now = DateTime.now().UnixTimestamp

			if newInfo then
				local isThisServerLeader = newInfo.Leader == game.JobId
				local isLeaderExpired = now > newInfo.LeaderExpiration

				if isThisServerLeader or isLeaderExpired then
					-- Leadership can expire in 3 cases:
					--   1. The server crashed and is no longer refreshing its expiration
					--   2. The server is getting MemoryStore API errors or being throttled
					--   3. The server shut down and released leadership, setting expiration to 0
					-- If the server fails to relinquish leadership for some reason, it can enter into the
					-- takeover loop while still retaining leadership in MemoryStore. In this case the
					-- server will attempt to take over leadership again.
					newInfo.Leader = game.JobId
					newInfo.LeaderExpiration = now + self._leaderExpiration

					tookLeadership = true
				end
			else
				newInfo = {
					Leader = game.JobId,
					LastUpdate = now,
					LeaderExpiration = now + self._leaderExpiration,
				} :: LeaderInfo

				tookLeadership = true
			end

			return if tookLeadership then newInfo else nil
		end, self._keyExpiration)
	end)

	return success and tookLeadership
end

-- Attempt to run the Update function for the loop
function Loop:_attemptUpdateAsync()
	local memoryStoreSuccess, lastUpdate = retryAsync(function()
		local oldUpdate: number? = nil

		self._memoryStore:UpdateAsync(KEY, function(oldInfo): LeaderInfo?
			oldUpdate = nil
			local newInfo = oldInfo :: LeaderInfo?
			local now = DateTime.now().UnixTimestamp

			if newInfo and newInfo.Leader == game.JobId then
				oldUpdate = newInfo.LastUpdate
				newInfo.LastUpdate = now
				newInfo.LeaderExpiration = now + self._leaderExpiration

				return newInfo
			else
				return nil
			end
		end, self._keyExpiration)

		return oldUpdate
	end, UPDATE_ATTEMPTS, UPDATE_RETRY_PAUSE_CONSTANT, UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if memoryStoreSuccess and lastUpdate then
		local updateSuccess = retryAsync(function()
			local now = DateTime.now().UnixTimestamp
			self._updateFunction(now - lastUpdate)
		end, UPDATE_ATTEMPTS, UPDATE_RETRY_PAUSE_CONSTANT, UPDATE_RETRY_PAUSE_EXPONENT_BASE)
		return updateSuccess
	end

	return false
end

-- Release leadership of the loop, allowing another server to take control
function Loop:_releaseLeadershipAsync()
	retryAsync(function()
		self._memoryStore:UpdateAsync(KEY, function(oldInfo): LeaderInfo?
			local newInfo = oldInfo :: LeaderInfo?

			if newInfo and newInfo.Leader == game.JobId then
				newInfo.LeaderExpiration = 0
				return newInfo
			else
				return nil
			end
		end, self._keyExpiration)
	end, UPDATE_ATTEMPTS, UPDATE_RETRY_PAUSE_CONSTANT, UPDATE_RETRY_PAUSE_EXPONENT_BASE)
end

function Loop:_startTakeoverLoop()
	assert(self._mode ~= LoopMode.Takeover, string.format("Loop '%s' is already in takeover mode!", self.id))

	self._mode = LoopMode.Takeover
	self:_setIntervalFunction(function()
		local success = self:_attemptTakeoverAsync()
		if success then
			self:_startUpdateLoop()
		end
	end, self._takeoverInterval)
end

function Loop:_startUpdateLoop()
	assert(self._mode ~= LoopMode.Update, string.format("Loop '%s' is already in update mode!", self.id))

	self._mode = LoopMode.Update
	self:_setIntervalFunction(function()
		local success = self:_attemptUpdateAsync()
		if not success then
			self:_startTakeoverLoop()
		end
	end, self._updateInterval)
end

function Loop:start()
	assert(not self._started, "Loop is already started!")
	self._started = true

	game:BindToClose(function()
		-- End the current interval loop so we don't try to take leadership while shutting down
		if self._clearIntervalFunction then
			self._clearIntervalFunction()
		end

		-- If the loop is currently in Update mode (i.e. this server is already the leader), release leadership
		if self._mode == LoopMode.Update then
			self:_releaseLeadershipAsync()
		end
	end)

	-- Start in Takeover mode
	self:_startTakeoverLoop()
end

return Loop
