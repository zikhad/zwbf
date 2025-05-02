--- Localized global functions from PZ
local getPlayer = getPlayer
local Events = Events
local ZombRand = ZombRand
local SandboxVars = SandboxVars

local SBVars = SandboxVars.ZWBF

--- LactationClass
--- This class handles the lactation system for the player
local LactationClass = {}
LactationClass.__index = LactationClass

LactationClass.SBvars = {
    MilkCapacity = 1000, -- Maximum amount of milk that can be stored
    MilkExpiration = 7, -- Expiration in days
}

-- local representation of Lactation Data
LactationClass.data = {
    IsLactating = false, -- Controls if the player is lactating
    MilkAmount = 0, -- Amount of milk currently stored
    MilkMultiplier = 0, -- Multiplier for the milk
    Expiration = 0, -- Expiration in minutes
}

--- CONSTANTS
LactationClass.CONSTANTS = {
    AMOUNTS = {
        MIN = 0, -- Minimum amount of milk produced
        MAX = 20 -- Maximum amount of milk produced
    },
    MAX_CAPACITY = 1000, -- Maximum amount of milk that can be stored
    MAX_LEVEL = 5, -- Maximum level of milk
}

function LactationClass:new(props)
    local instance = setmetatable({}, LactationClass)
    props = props or {}
    instance.name = props.name or "Lactation"
    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
    instance.Utils = props.Utils or require("ZWBF/ZWBFUtilsClass")
    return instance
end

--- Updates the data
function LactationClass:update()
    local player = getPlayer()
    local data = self.data
    data.MilkAmount = (data.MilkAmount > 0) and data.MilkAmount or 0
    data.MilkMultiplier = (data.MilkMultiplier > 0) and data.MilkMultiplier or 0
    data.IsLactating = data.IsLactating or false
    data.Expiration = (data.Expiration > 0) and data.Expiration or 0

    player:getModData().ZWBFLactation = data
end

--- Add expiration to the lactation
--- @param days integer
function LactationClass:addExpiration(days)
    local data = self.data
    data.Expiration = 60 * 24 * days -- 60 minutes * 24 hours * days
    local player = getPlayer()

    -- Add 25% of lactation time if player has "Dairy cow" Trait
    if player:HasTrait("Dairy cow") then
        data.Expiration = data.Expiration * 1.25;
    end
end

--- Initializes the Lactation
function LactationClass:init()

    -- setup SandboxVars
    self.SBvars.MilkCapacity = SBVars.MilkCapacity
    self.SBvars.MilkExpiration = SBVars.MilkExpiration

    local player = getPlayer()
    local data = player:getModData().ZWBFLactation or {}

    data.IsLactating = data.IsLactating or false
    data.MilkAmount = data.MilkAmount or 0
    data.MilkMultiplier = data.MilkMultiplier or 0
    data.Expiration = data.Expiration or 0

    self.data = data

    self:update()
end

--- Returns the milk amount
--- @return integer Womb.data.MilkAmount The amount of milk
function LactationClass:getMilkAmount()
    local data = self.data
    return data.MilkAmount
end

--- Returns the percentage 0-1 of current milk amount
function LactationClass:getMilkAmountPercentage()
    local data = self.data
    return data.MilkAmount / self.SBvars.MilkCapacity
end

--- Returns the image for the boobs
--- @return string
function LactationClass:getBoobImage()
    local data = self.data
    local skinColor = self.Utils:getSkinColor()
    local fullness = (data.MilkAmount > self.SBvars.MilkCapacity / 2) and "full" or "empty"
    local basePath = string.format("media/ui/lactation/boobs/color-%s/", skinColor)
    local imageName = ""

    if self.Pregnancy:getIsPregnant() and self.Pregnancy:getProgress() > 0.4 then
        local stage = (self.Pregnancy:getProgress() < 0.7) and "early" or "late"
        imageName = string.format("pregnant_%s_%s.png", stage, fullness)
    else
        imageName = string.format("normal_%s.png", fullness)
    end

    return basePath .. imageName
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
    local data = self.data
    return data.IsLactating
end

--- [DEBUG] Add Milk to the player
--- @param amount any
function LactationClass:add(amount)
    local data = self.data
    data.MilkAmount = data.MilkAmount + amount
end

--- Remove Milk from the player
--- @param amount any
function LactationClass:remove(amount)
    local data = self.data
    data.MilkAmount = data.MilkAmount - amount
    self:update()
end

--- Get the amount needed to make a bottle
--- @return number
function LactationClass:getBottleAmount()
    return self.SBvars.MilkCapacity / self.CONSTANTS.MAX_LEVEL
end

--- Clear the milk amount
function LactationClass:clear()
    local data = self.data
    data.MilkAmount = 0
    data.MilkMultiplier = 0
    data.Expiration = 0

end

--- Set the lactation status
--- @param status boolean
function LactationClass:set(status)
    local data = self.data
    data.IsLactating = status
    if (not data.IsLactating) then
        self:clear()
    end
end

--- Set the multiplier for the milk
--- @param multiplier number
function LactationClass:setMultiplier(multiplier)
    local data = self.data
    data.MilkMultiplier = multiplier
    local player = getPlayer()

    -- Add  25% of bonus to the multiplier if player has "Dairy cow" Trait
    if player:HasTrait("Dairy cow") then
        data.MilkMultiplier = data.MilkMultiplier * 1.25;
    end
end

--- Get The Milk Multiplier amount
--- @return number
function LactationClass:getMultiplier()
    local data = self.data
    return data.MilkMultiplier
end

--- Update that should occur every hour
function LactationClass:onEveryHour()
    local data = self.data
    if not data.IsLactating then return end

    local amount = ZombRand(self.CONSTANTS.AMOUNTS.MIN, self.CONSTANTS.AMOUNTS.MAX)
    local multiplier = 1 + data.MilkMultiplier
    data.MilkAmount = (data.MilkAmount + amount) * multiplier
    data.MilkMultiplier = data.MilkMultiplier - 0.1

    if (data.MilkAmount < 0) then
        data.MilkAmount = 0
    elseif data.MilkAmount > self.SBvars.MilkCapacity then
        data.MilkAmount = self.SBvars.MilkCapacity
    end
end

--- Check if the player is pregnant and if the pregnancy is advanced enough to be lactating
function LactationClass:onCheckPregnancy()
    local data = self.data
    if self.Pregnancy:getIsPregnant() and self.Pregnancy:getProgress() > 0.4 then
        self:set(true)
        self:setMultiplier(self.Pregnancy:getProgress())
        self:addExpiration(self.SBvars.MilkExpiration)
    end
end

--- Update that should occur every minute
function LactationClass:onEveryMinute()
    self:onCheckExpiration()
    self:onCheckPregnancy()
    self:update()
end

--- Check if the expiration is over and remove lactation if it is
function LactationClass:onCheckExpiration()
    local data = self.data
    if data.Expiration > 0 then
        data.Expiration = data.Expiration - 1
        if data.Expiration <= 0 then
            self:set(false)
        end
    end
end

--- Register the events
function LactationClass:registerEvents()
    Events.OnCreatePlayer.Add(function()
        self:init()
    end)
    Events.EveryHours.Add(function()
        self:onEveryHour()
    end)
    Events.EveryOneMinute.Add(function()
        self:onEveryMinute()
    end)
end

return LactationClass
