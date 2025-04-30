local EngorgementClass = require("ZWBF/ZWBFEngorgement")
local InventoryClass = require("ZWBF/ZWBFInventory")
-- local Lactation = require("ZWBF/ZWBFLactation")

local Engorgement = EngorgementClass:new()
local Inventory = InventoryClass:new()

Inventory:registerEvents()
Engorgement:registerEvents()

