local SpawnWithFriends = script:FindFirstAncestor("SpawnWithFriends")

local Cryo = require(SpawnWithFriends.Packages.Cryo)

local Configuration = {}

function Configuration.new(initialValues, validate)
	initialValues = Cryo.Dictionary.join(initialValues, {})

	local self = {
		initialValues = initialValues,
		values = initialValues,
		validate = validate or function() end,
	}

	self.changed = Instance.new("BindableEvent")

	self.getValues = function()
		return self.values
	end

	self.configure = function(configuration)
		local isValid, message = self.validate(configuration)
		if not isValid then
			error(message)
		end

		self.values = Cryo.Dictionary.join(self.values, configuration)
		self.changed:Fire(self.values)
	end

	self.reset = function()
		self.values = Cryo.Dictionary.join(self.initialValues, {})
		self.changed:Fire(self.values)
	end

	return self
end

return Configuration
