-- require "TimedActions/ISBaseTimedAction"
-- require "Map/SGlobalObjectSystem"
-- require "ISUI/ISInventoryPaneContextMenu"

--- Localized global functions from PZ
local getPlayer = getPlayer
local ZombRandFloat = ZombRandFloat

--- VARIABLES
ZWBFRecipes = {
    OnTest = {},
    OnCreate = {}
}

local Lactation = require("ZWBF/ZWBFLactation")
local Womb = require("ZWBF/ZWBFWomb")

-- Test if Player can Hand Express
-- Hand expression uses double of the Breast pump milk amount
--- @param item table
--- @param result table
--- @return boolean
function ZWBFRecipes.OnTest.HandExpress(item, result)
    local player = getPlayer()
    return player:isFemale() and Lactation:getMilkAmount() >= Lactation:getBottleAmount() * 2
end

--- Run after the Hand Expression is used
--- @param item table
--- @param result table
function ZWBFRecipes.OnCreate.HandExpress(item, result)
    Lactation:useMilk(
        Lactation:getBottleAmount() * 2,
        ZombRandFloat(0.05, 0.1)
    )
end


--- Test if the Breast Pump can be used
--- @param item table
--- @param result table
--- @return boolean
function ZWBFRecipes.OnTest.BreastPump(item, result)
    local player = getPlayer()
    return player:isFemale() and Lactation:getMilkAmount() >= Lactation:getBottleAmount()
end

--- Run after the Breast Pump is used
--- @param item table
--- @param result table
function ZWBFRecipes.OnCreate.BreastPump(item, result)
    Lactation:useMilk(
        Lactation:getBottleAmount(),
        ZombRandFloat(0.1, 0.2)
    )
end

--- Run if the sperm can be cleaned
--- @param item table
--- @param result table
function ZWBFRecipes.OnTest.ClearSperm(item, result)
    local player = getPlayer()
    return player:isFemale() and Womb:getSpermAmount() > 0
end

--- Run after the Vaginal douche is used
--- @param item table
--- @param result table
function ZWBFRecipes.OnCreate.ClearSperm(item, result)
    Womb:setSpermAmount(0)
    Womb:applyWetness()
end
