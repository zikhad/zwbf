--- Localized global functions from PZ
local Events = Events
local ZombRand = ZombRand
local SandboxVars = SandboxVars
local triggerEvent = ZWBFEngorgementUpdate
local LuaEventManager = LuaEventManager

local SBVars = SandboxVars.ZWBF

--- This class handles the lactation system
--- @class LactationClass
--- @field SBvars table Sandbox variables for lactation
--- @field data table Lactation data
--- @field CONSTANTS table Constants for lactation
--- @field Pregnancy table ZWBFPregnancy
--- @field Utils table ZWBFUtils
local LactationClass = {}
LactationClass.__index = LactationClass

LactationClass.SBvars = {
    MilkCapacity = 1000, -- Maximum amount of milk that can be stored
    MilkExpiration = 7,  -- Expiration in days
}

--- CONSTANTS
LactationClass.CONSTANTS = {
    AMOUNTS = {
        MIN = 0,   -- Minimum amount of milk produced
        MAX = 20   -- Maximum amount of milk produced
    },
    MAX_LEVEL = 5, -- Maximum level of milk
}

--- Initializes the Lactation
function LactationClass:new(props)
    props = props or {}
    local instance = setmetatable({}, LactationClass)

    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
    instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")

    return instance
end

--- Updates the data
function LactationClass:update()
    local player = self.player
    local data = self.data

    data.MilkAmount = (data.MilkAmount > 0) and data.MilkAmount or 0
    data.MilkAmount = (data.MilkAmount < self.SBvars.MilkCapacity) and data.MilkAmount or self.SBvars.MilkCapacity
    data.MilkMultiplier = (data.MilkMultiplier > 0) and data.MilkMultiplier or 0
    data.IsLactating = data.IsLactating or false
    data.Expiration = (data.Expiration > 0) and data.Expiration or 0

    player:getModData().ZWBFLactation = data
end

--- Set expiration to the lactation
--- @param days number
function LactationClass:setExpiration(days)
    local player = self.player
    local data = self.data

    data.Expiration = 24 * days -- (24h) * days

    -- Add 25% of lactation time if player has "Dairy cow" Trait
    if player:HasTrait("DairyCow") then
        data.Expiration = data.Expiration * 1.25;
    end
end

--- Use milk.
---
--- Handle milk usage (also affect multiplier and expiration)
--- @param amount number
--- @param multiplier number | nil
--- @param expiration number | nil
function LactationClass:useMilk(amount, multiplier, expiration)
    local data = self.data
    self:remove(amount)
    self:setMultiplier(multiplier or 0)
    self:setExpiration(expiration or self.SBvars.MilkExpiration)
    triggerEvent("ZWBFLactationUseMilk", self)
end

--- Returns the milk amount
--- @return number Womb.data.MilkAmount The amount of milk
function LactationClass:getMilkAmount()
    return self.data.MilkAmount
end

--- Returns the percentage 0-1 of current milk amount
function LactationClass:getMilkAmountPercentage()
    return self.data.MilkAmount / self.SBvars.MilkCapacity
end

--- Returns the image for the boobs
--- @return string
function LactationClass:getBoobImage()
    local function getImageName()
        local fullness = (self.data.MilkAmount > self.SBvars.MilkCapacity / 2) and "full" or "empty"
        if self.Pregnancy:getIsPregnant() and self.Pregnancy:getProgress() > 0.4 then
            local stage = (self.Pregnancy:getProgress() < 0.7) and "early" or "late"
            return string.format("pregnant_%s_%s.png", stage, fullness)
        end
        return string.format("normal_%s.png", fullness)
    end

    local skinColor = self.Utils:getSkinColor(self.player)
    local imageName = getImageName()

    return string.format("media/ui/lactation/boobs/color-%s/%s", skinColor, imageName)
end

--- Returns the image for the milk level
--- @return string
function LactationClass:getMilkLevelImage()
    local data = self.data
    local amount = (data.MilkAmount / self.SBvars.MilkCapacity) * 100
    local index = self.Utils:percentageToNumber(amount, self.CONSTANTS.MAX_LEVEL)
    return string.format("media/ui/lactation/level/milk_level_%s.png", index)
end

--- Returns if the player is lactating
--- @return boolean
function LactationClass:getIsLactating()
    return self.data.IsLactating
end

--- Remove Milk from the player
--- @param amount any
function LactationClass:remove(amount)
    local data = self.data
    data.MilkAmount = data.MilkAmount - amount
end

--- Get the amount needed to make a bottle
--- @return number
function LactationClass:getBottleAmount()
    return self.SBvars.MilkCapacity / self.CONSTANTS.MAX_LEVEL
end

--- Set the lactation status
--- @param status boolean
function LactationClass:set(status)
    local data = self.data
    data.IsLactating = status
    if not data.IsLactating then
        data.MilkAmount = 0
        data.MilkMultiplier = 0
        data.Expiration = 0
    end
end

--- Set the multiplier for the milk
--- @param multiplier number
function LactationClass:setMultiplier(multiplier)
    local data = self.data
    local player = self.player

    data.MilkMultiplier = math.min(multiplier, 1)

    -- Add  25% of bonus to the multiplier if player has "Dairy cow" Trait
    if player:HasTrait("DairyCow") then
        data.MilkMultiplier = data.MilkMultiplier * 1.25;
    end
end

--- Get The Milk Multiplier amount
--- @return number
function LactationClass:getMultiplier()
    return self.data.MilkMultiplier
end

--- EVENT LISTERNERS ---
--- Initializes Lactation when creating the player
function LactationClass:onCreatePlayer(player)
    local data = player:getModData().ZWBFLactation or {}

    -- setup SandboxVars
    self.SBvars.MilkCapacity = SBVars.MilkCapacity
    self.SBvars.MilkExpiration = SBVars.MilkExpiration

    -- setup data
    data.IsLactating = data.IsLactating or false
    data.MilkAmount = data.MilkAmount or 0
    data.MilkMultiplier = data.MilkMultiplier or 0
    data.Expiration = data.Expiration or 0

    self.player = player
    self.data = data
end

--- Check if the expiration is over and remove lactation if it is
function LactationClass:onCheckExpiration()
    local data = self.data
    if data.Expiration > 0 then
        data.Expiration = data.Expiration - 1
    else
        self:set(false)
    end
end

--- Check if the player is pregnant and if the pregnancy is advanced enough to be lactating
function LactationClass:onCheckPregnancy()
    if self.Pregnancy:getProgress() < 0.5 then return end

    self:set(true)
    self:setMultiplier(self.Pregnancy:getProgress())
    self:setExpiration(self.SBvars.MilkExpiration)
end

--- Update that should occur every hour
function LactationClass:onEveryHours()
    local data = self.data
    if not data.IsLactating then return end

    local amount = ZombRand(self.CONSTANTS.AMOUNTS.MIN, self.CONSTANTS.AMOUNTS.MAX)
    local multiplier = 1 + data.MilkMultiplier

    data.MilkAmount = data.MilkAmount + (amount * multiplier)
    data.MilkMultiplier = data.MilkMultiplier - 0.1

    self:onCheckExpiration()
end

--- Register the events
function LactationClass:registerEvents()
    -- Register default Events
    local function defaultEvents()
        Events.OnCreatePlayer.Add(function(_, player)
            self:onCreatePlayer(player)
        end)

        Events.EveryOneMinute.Add(function()
            self:update()
        end)

        Events.EveryHours.Add(function()
            self:onEveryHours()
        end)
    end
    -- Register custom Events Listeners
    local function customEvents()
        LuaEventManager.AddEvent("ZWBFLactationUseMilk")
        LuaEventManager.AddEvent("ZWBFLactationOnEveryHour")
        Events.ZWBFPregnancyProgressOneHour.Add(function(pregnancy)
            self:onCheckPregnancy()
        end)
    end
    defaultEvents()
    customEvents()
end

--- DEBUG FUNCTIONS ---
LactationClass.Debug = {}
--- (DEBUG) Add Milk to the player
--- @param amount any
function LactationClass.Debug:add(amount)
    local data = self.data
    data.MilkAmount = data.MilkAmount + amount
end

return LactationClass
