--!strict

--[[
	Iterates over a Pages object for paginated web requests
	Based on code sample from: https://create.roblox.com/docs/reference/engine/classes/Pages
--]]

local function iterateOverPagesAsync(pages: Pages)
	return coroutine.wrap(function()
		local pageNumber = 1

		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item, pageNumber)
			end

			if pages.IsFinished then
				break
			end

			pages:AdvanceToNextPageAsync()

			pageNumber += 1
		end
	end)
end

return iterateOverPagesAsync
