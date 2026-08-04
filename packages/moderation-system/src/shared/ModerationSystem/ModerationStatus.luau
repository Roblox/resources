--!strict

local ModerationAction = require(script.Parent.ModerationAction)
local formatTime = require(script.Parent.formatTime)

local ModerationStatus = {}
ModerationStatus.__index = ModerationStatus

function ModerationStatus.new(action: string, date: number, permanent: boolean?, duration: number?, reason: string?)
	if action == ModerationAction.Ban then
		assert(permanent ~= nil and duration, "No duration specified")
	end

	local self = {
		action = action,
		date = date,
		permanent = permanent,
		duration = if permanent then 0 else duration,
		reason = reason,
	}

	setmetatable(self, ModerationStatus)

	return self
end

function ModerationStatus:serialize()
	return {
		action = self.action,
		date = self.date,
		permanent = self.permanent,
		duration = self.duration,
		reason = self.reason,
	}
end

function ModerationStatus:getBanMessage()
	if self.action == ModerationAction.Ban then
		if self.permanent then
			if self.reason then
				return string.format("Permanently Banned: %s", self.reason)
			else
				return "Permanently Banned"
			end
		else
			local expirationString = formatTime(self:getTimeRemaining())
			if self.reason then
				return string.format("Banned: %s --- Expires in: %s", self.reason, expirationString)
			else
				return string.format("Banned --- Expires in: %s", expirationString)
			end
		end
	else
		return ""
	end
end

function ModerationStatus:getTimeRemaining(): number
	if self.action == ModerationAction.Ban then
		if self.permanent then
			return math.huge
		elseif self.duration then
			local now = DateTime.now().UnixTimestamp
			local startDate = self.date :: number
			local duration = self.duration :: number
			local expiration = startDate + duration
			return expiration - now
		else
			return 0
		end
	else
		return 0
	end
end

function ModerationStatus:isExpired(): boolean
	local timeRemaining = self:getTimeRemaining()
	return timeRemaining <= 0
end

return ModerationStatus
