local Constants = require(script.Parent.Parent.Constants)

local function updateStatusColor(part: BasePart, activated: boolean)
	if activated then
		part.Color = Constants.STATUS_COLOR_ENABLED
	else
		part.Color = Constants.STATUS_COLOR_DISABLED
	end
end

return updateStatusColor
