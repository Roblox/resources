--!strict

local CodeReservationService = require(script.Parent.Parent.CodeReservationService)

local DEMO_KEY = "DemoReservation"

CodeReservationService.openReservation(DEMO_KEY, 10)
print("opened reservation, waiting for available codes")
repeat
	task.wait(1)
until CodeReservationService.reservationHasCodes(DEMO_KEY)
local success, code = CodeReservationService.getCode(DEMO_KEY)
print("result:", success, code)
