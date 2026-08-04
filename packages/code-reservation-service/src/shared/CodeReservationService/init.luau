--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CodeStatus = require(script.CodeStatus)
local Constants = require(script.Constants)
local Manager = require(script.Manager)
local Reservation = require(script.Reservation)

local CodeReservationService = {
	_initialized = false,
	_reservations = {} :: { [string]: typeof(Reservation.new("", 0)) },
	_managers = {} :: { [string]: typeof(Manager.new("")) },
}

function CodeReservationService.registerCodesAsync(key: string, codes: { string })
	assert(RunService:IsStudio(), "Codes must be registered in Studio")

	local dataStore = DataStoreService:GetDataStore(string.format(Constants.DATA_STORE_NAME_TEMPLATE, key))

	dataStore:UpdateAsync(Constants.DATA_STORE_CODES_KEY, function(oldData)
		if not oldData then
			oldData = {}
		end
		local newData = oldData :: { [string]: string }

		for _, code in codes do
			newData[code] = CodeStatus.Available
		end

		return newData
	end)
end

-- Check if the specified reservation has codes available
function CodeReservationService.reservationHasCodes(key: string): boolean
	local reservation = CodeReservationService._reservations[key]
	assert(reservation, `Reservation '{key}' is not open`)

	return reservation:hasCodes()
end

-- Attempt to get a code from the specified reservation
function CodeReservationService.getCode(key: string): (boolean, string?)
	local reservation = CodeReservationService._reservations[key]
	assert(reservation, `Reservation '{key}' is not open`)

	if reservation:hasCodes() then
		local code = reservation:getCode()
		return true, code
	else
		return false
	end
end

-- Open up a new code reservation, starting a DataStore manager if necessary
function CodeReservationService.openReservation(key: string, reserveCount: number?)
	assert(not CodeReservationService._reservations[key], `Reservation '{key}' is already open`)

	local reservation = Reservation.new(key, reserveCount or Players.MaxPlayers)

	-- If no manager exists for this key, create a new one to manager DataStore saving/loading
	if not CodeReservationService._managers[key] then
		local manager = Manager.new(key)
		CodeReservationService._managers[key] = manager
		manager:initialize()
	end

	CodeReservationService._reservations[key] = reservation
	reservation:open()
end

function CodeReservationService.closeReservationAsync(key: string)
	local reservation = CodeReservationService._reservations[key]
	assert(reservation, `Reservation '{key}' is not open`)

	CodeReservationService._reservations[key] = nil
	reservation:closeAsync()
end

function CodeReservationService.closeAllReservationsAsync()
	for key in CodeReservationService._reservations do
		CodeReservationService.closeReservationAsync(key)
	end
end

function CodeReservationService._initialize()
	assert(not CodeReservationService._initialized, "CodeReservationService is already initialized")

	game:BindToClose(CodeReservationService.closeAllReservationsAsync)

	CodeReservationService._initialized = true
end

CodeReservationService._initialize()

return CodeReservationService
