local ReceiptProcessor = require(script.Parent.PurchaseHandling.ReceiptProcessor)
local PlayerDataServer = require(script.Parent.PurchaseHandling.PlayerData.Server)

local DEV_PRODUCT_ID = 1

PlayerDataServer.start({ coins = 0 }, "playerData")

ReceiptProcessor.registerProductCallback(DEV_PRODUCT_ID, function(player)
	PlayerDataServer.updateValue(player, "coins", function(oldValue)
		return oldValue + 1
	end)
end)

ReceiptProcessor.start()
