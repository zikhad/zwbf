--- Localized global functions from PZ
local getPlayer = getPlayer

--- VARIABLES
ZWBFRecipes = {
    OnTest = {},
    OnCreate = {}
}

local Lactation = require("ZWBF/ZWBFLactation")

--- Test if the Breast Pump can be used
--- @param items any
--- @param result any
--- @param player any
--- @return boolean
function ZWBFRecipes.OnTest.BreastPump(items, result, player)
    local playerObj = getPlayer()
    return playerObj:isFemale() and Lactation:getMilkAmount() >= Lactation:getBottleAmount()
end

--- Run after the Breast Pump is used
--- @param items any
--- @param result any
--- @param player any
function ZWBFRecipes.OnCreate.BreastPump(items, result, player)
    print("ZWBF - Recipes - OnCreate - Breast Pump")
    Lactation:remove(Lactation:getBottleAmount())
    Lactation:addExpiration(Lactation.CONSTANTS.EXPIRATION)
end
