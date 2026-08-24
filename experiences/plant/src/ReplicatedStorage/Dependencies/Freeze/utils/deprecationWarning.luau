--!strict
return function(deprecatedName: string, recommendation: string)
	warn(`[Freeze] {deprecatedName} will be removed in version 1.0, please use {recommendation} instead.`)
end
