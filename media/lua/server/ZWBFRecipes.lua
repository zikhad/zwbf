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
    Lactation:setMultiplier(ZombRandFloat(0.1, 0.2))
    Lactation:addExpiration(Lactation.SBvars.MilkExpiration)
end

--- Run if the sperm can be cleanned
--- @param items any
--- @param result any
--- @param player any
function ZWBFRecipes.OnTest.ClearSperm(items, result, player)
    local playerObj = getPlayer()
    return playerObj:isFemale() and Womb:getSpermAmount() > 0
end

--- Run after the Vaginal douche is used
--- @param items any
--- @param result any
--- @param player any
function ZWBFRecipes.OnCreate.ClearSperm(items, result, player)
    Womb:setSpermAmount(0)
    Womb:applyWetness()
end