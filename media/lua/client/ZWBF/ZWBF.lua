local EngorgementClass = require("ZWBF/ZWBFEngorgementClass")
local InventoryClass = require("ZWBF/ZWBFInventoryClass")
-- local WombClass = require("ZWBF/ZWBFWombClass")
-- local Lactation = require("ZWBF/ZWBFLactation")

local Engorgement = EngorgementClass:new()
local Inventory = InventoryClass:new()
-- local Womb = WombClass:new()

Inventory:registerEvents()
Engorgement:registerEvents()
-- Womb:registerEvents()

