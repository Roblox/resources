--!strict

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local donationProducts = require(script.Parent.DonationProducts)
local formatLargeNumber = require(script.formatLargeNumber)
local retryAsync = require(script.retryAsync)
local instances = script.Parent.Instances
local leaderboard = script.Parent.Leaderboard

local USER_ICON_TEMPLATE = "rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60"
local ROBUX_TEMPLATE = utf8.char(0xE002) .. " %s"

local DATA_STORE_NAME = "DonationLeaderboard"
local DATA_STORE = DataStoreService:GetOrderedDataStore(DATA_STORE_NAME)

local DISPLAY_COUNT = 100
local UPDATE_INTERVAL = 60
local UPDATE_MAX_ATTEMPTS = 3 -- Make up to 3 attempts (Initial attempt + 2 retries)
local UPDATE_RETRY_PAUSE_CONSTANT = 1 -- Base wait time between attempts
local UPDATE_RETRY_PAUSE_EXPONENT_BASE = 2 -- Base number raised to the power of the retry number for exponential backoff

local userIdUsernameCache: { string } = {}
local displayFrames: { Instance } = {}

-- Return the username associated with a userId, caching the results
-- Returns <unknownXXXXXXXX> if GetNameFromUserIdAsync fails, which can happen when the specified user is banned
local function getUsernameFromUserIdAsync(userId: number): string
	if userIdUsernameCache[userId] then
		return userIdUsernameCache[userId]
	else
		local success, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if success then
			userIdUsernameCache[userId] = result
			return result
		else
			return string.format("<unknown%d>", userId)
		end
	end
end

-- Update a display frame with the specified userId and robuxAmount
local function updateDisplayFrameInfoAsync(displayFrame: any, userId: number?, robuxAmount: number?)
	if userId and robuxAmount then
		local displayUsername = getUsernameFromUserIdAsync(userId)
		local displayRobuxAmount = string.format(ROBUX_TEMPLATE, formatLargeNumber(robuxAmount))
		local displayIcon = string.format(USER_ICON_TEMPLATE, userId)

		displayFrame.UserDisplay.NameLabel.Text = displayUsername
		displayFrame.UserDisplay.IconLabel.Image = displayIcon
		displayFrame.RobuxLabel.Text = displayRobuxAmount

		displayFrame.Visible = true
	else
		displayFrame.Visible = false
	end
end

-- Create necessary display frames to be used on the leaderboard
local function createDisplayFrames()
	for i = 1, DISPLAY_COUNT do
		local isEven = i % 2 == 0
		local displayFrame = instances.DisplayFrame:Clone()
		displayFrame.BackgroundTransparency = if isEven then 0.9 else 1
		displayFrame.LayoutOrder = i
		displayFrame.UserDisplay.RankLabel.Text = tostring(i)
		displayFrame.Visible = false
		displayFrame.Parent = leaderboard.Display.LeaderboardGui.DonorList :: any

		displayFrames[i] = displayFrame
	end
end

-- Retreive the top <DISPLAY_COUNT> donors and display their information on the leaderboard
local function refreshLeaderboardAsync()
	local success, result = retryAsync(function()
		-- DataStorePages support up to 100 items per page, so page size must be clamped in the case of DISPLAY_COUNT > 100
		local data = DATA_STORE:GetSortedAsync(false, math.min(DISPLAY_COUNT, 100))
		return data
	end, UPDATE_MAX_ATTEMPTS, UPDATE_RETRY_PAUSE_CONSTANT, UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if not success then
		warn(string.format("Failed to retrieve leaderboard data because: %s", result))
		return
	end

	local pages = result :: DataStorePages
	local topDonors = {}

	-- Pull items from the pages object until we have enough to satisfy DISPLAY_COUNT or run out of pages
	repeat
		local currentPage = pages:GetCurrentPage()
		for _, data in currentPage do
			table.insert(topDonors, data)
		end
		if pages.IsFinished then
			break
		else
			pages:AdvanceToNextPageAsync()
		end
	until #topDonors >= DISPLAY_COUNT

	for i = 1, DISPLAY_COUNT do
		local donorData = topDonors[i]
		local displayFrame = displayFrames[i]

		if donorData then
			local userId = donorData.key
			local robuxAmount = donorData.value
			updateDisplayFrameInfoAsync(displayFrame, userId, robuxAmount)
		else
			updateDisplayFrameInfoAsync(displayFrame, nil, nil)
		end
	end
end

-- Process DevProduct purchases and increment the leaderboard values
-- PurchaseGranted is only returned if the DataStore is successfully updated
-- No checks are made for if the purchaseId has been processed already, meaning a purchase could
-- be processed twice if the backend fails to record the purchase after PurchaseGranted is returned.
-- A more robust solution would keep track of purchaseIds to avoid processing multiple times, but
-- for the sake of simplicity we will accept the shortcomings of this method.
local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	if not table.find(donationProducts, receiptInfo.ProductId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Make sure the player is in this server
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, result = retryAsync(function()
		-- Make sure the player hasn't left during a retry
		assert(player.Parent == Players, "Player left during DataStore update")
		-- Increment the value associated with the PlayerId based on how much currency was spent
		-- Note: CurrencySpent will be 0 in studio because test purchases do not charge anything
		DATA_STORE:IncrementAsync(tostring(receiptInfo.PlayerId), receiptInfo.CurrencySpent)
	end, UPDATE_MAX_ATTEMPTS, UPDATE_RETRY_PAUSE_CONSTANT, UPDATE_RETRY_PAUSE_EXPONENT_BASE)

	if success then
		-- If the datastore was successfully updated, confirm that the purchase was successful
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn(`Failed to increment leaderboard value because: {result}`)
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function initialize()
	-- Note: this may overwrite or be overwritten by other code that processes DevProduct receipts
	-- A centralized purchase handler can be used to avoid this issue
	MarketplaceService.ProcessReceipt = processReceipt

	createDisplayFrames()

	task.spawn(function()
		while true do
			refreshLeaderboardAsync()
			task.wait(UPDATE_INTERVAL)
		end
	end)
end

initialize()
