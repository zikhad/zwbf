--- Localized global functions from PZ
local getPlayer = getPlayer
local ZombRandFloat = ZombRandFloat
local ZombRand = ZombRand
local Events = Events
local BodyPartType = BodyPartType
local HaloTextHelper = HaloTextHelper
local getText = getText
local SandboxVars = SandboxVars

local SBVars = SandboxVars.ZWBF

-- VARIABLES
local Utils = require("ZWBF/ZWBFUtils")
local Pregnancy = require("ZWBF/ZWBFPregnancy")

local WombClass = {}

WombClass.SBvars = {
    PregnancyRecovery = 7, -- Number of days to recover after pregnancy,
    WombMaxCapacity = 1000, -- Maximum amount of sperm the womb can hold
    FertilityBonus = 50 -- Fertility Bonus of Fertile Trait
}

WombClass.data = {
    SpermAmount = 0,
    SpermAmountTotal = 0,
    CycleDay = 0,
    CyclePhase = "",
    Fertility = 0,
    OnContraceptive = false
}

-- CONSTANTS
WombClass.CONSTANTS = {
    SPERM_LEVEL = 17, -- Number of sperm levels (For UI)
    WETNESS = { -- Wetness range for the groin
        MIN = 30,
        MAX = 100
    }
}

-- WombClass.isAnimation = false -- Animation status
WombClass.Animation = {
    isAnimation = false,
    delta = 0,
    duration = 0
}

WombClass.AnimationsSettings = {
    normal = {
        steps = {
            0, 1, 2, 3, 4,
            0, 1, 2, 3, 4,
            0, 1, 2, 3, 4,
            0, 1, 2, 3, 4,
            5, 6, 7, 8, 9
        },
        loop = 1
    },
    pregnant = {
        steps = {
            0, 1, 2, 3,
            0, 1, 2, 3,
            0, 1, 2, 3,
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11
        },
        loop = 1
    },
    condom = {
        steps = {
            0, 1, 2, 3, 4, 5, 6
        },
        loop = 4
    }
}

function WombClass:new(name)
    local instance = setmetatable({}, WombClass)
    instance.name = name or "Womb"
    return instance
end

--- Methods ---

--- Apply wetness to the groin
--- @param amount number | nil (optional) The amount of wetness to apply
function WombClass:applyWetness(amount)
    amount = amount or ZombRand(self.CONSTANTS.WETNESS.MIN, self.CONSTANTS.WETNESS.MAX)
    local player = getPlayer()
    local Groin = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Groin"))
    Groin:setWetness(Groin:getWetness() + amount)
end

--- Add one day to the cycle
function WombClass:addCycleDay()
    local player = getPlayer()
    local data = self.data
    data.OnContraceptive = false
    print("ZWBF - Womb - Add Cycle Day - " .. data.CycleDay)
    if not Pregnancy:getIsPregnant() then
        data.OnContraceptive = player:getModData().wombOnContraceptive or false
        data.CycleDay = (data.CycleDay < 28) and (data.CycleDay + 1) or 1
    end
    self:setFertility()
end

--- Adds sperm to the womb
--- @param amount number
function WombClass:addSperm(amount)
    local data = self.data
    data.SpermAmount = data.SpermAmount + amount
    data.SpermAmountTotal = data.SpermAmountTotal + amount -- add to total
end

--- Update the Womb data
function WombClass:update()
    local player = getPlayer()
    local data = self.data

    if data.SpermAmount > self.SBvars.WombMaxCapacity then
        data.SpermAmount = self.SBvars.WombMaxCapacity
    elseif data.SpermAmount < 0 then
        data.SpermAmount = 0
    end
    player:getModData().ZWBFWomb = data
    self:setCyclePhase()
end

--- Modify the variables according to player Traits
function WombClass:applyTraits()
    local player = getPlayer()
    -- Hyperfertile
    if player:HasTrait("Fertile") then
        -- +50% fertility
        self.SBvars.FertilityBonus = SBVars.FertilityBonus * 1.5
    end
    if player:HasTrait("Hyperfertile") then
        -- +100% fertility
        self.SBvars.FertilityBonus = SBVars.FertilityBonus * 2
        -- Halves the time before being ready to get pregnant again after birth
        self.SBvars.PregnancyRecovery = math.floor(SBVars.PregnancyRecovery / 2)
    end
end

--- Initializes the Womb, settings variables and mod data
function WombClass:init()

    -- setup SandboxVars
    self.SBvars.PregnancyRecovery = SBVars.PregnancyRecovery
    self.SBvars.WombMaxCapacity = SBVars.WombMaxCapacity
    self.SBvars.FertilityBonus = SBVars.FertilityBonus
    -- Apply Traits that are related to the Womb
    self:applyTraits()

    local player = getPlayer()
    local data = player:getModData().ZWBFWomb or {}

    data.SpermAmount = data.SpermAmount or 0
    data.SpermAmountTotal = data.SpermAmountTotal or 0
    data.CycleDay = data.CycleDay or ZombRand(1, 28)
    data.OnContraceptive = data.OnContraceptive or false
    self.data = data

    self:setFertility()
end


--- Events Listeners ---

--- Initialize the Womb when the player is created ---
function WombClass:onCreatePlayer()
    self:init()
end

--- Check if the player is on contraceptives
function WombClass:onCheckContraceptive()
    local player = getPlayer()
    local data = self.data
    data.OnContraceptive = player:getModData().wombOnContraceptive or false
    if data.OnContraceptive then
        data.Fertility = 0
    end
end

--- Check if the player is pregnant
function WombClass:onCheckPregnancy()
    local data = self.data
    if Pregnancy:getIsPregnant() then
        data.CycleDay = -self.SBvars.PregnancyRecovery
        if Pregnancy:getProgress() > 0.5 then
            data.SpermAmount = 0
        end
        self:setFertility()
    end
    self:update()
end

--- Run down logic to eventually empty the womb
function WombClass:onRunDown()
    if ZombRand(100) < 80 then return end -- 80% chance not doing anything
    local player = getPlayer()
    local amount = ZombRand(10)
    local data = self.data
    if data.SpermAmount > 0 then
        local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
        HaloTextHelper.addTextWithArrow(player, text, false, HaloTextHelper.getColorWhite())
        self:applyWetness()
    end
    data.SpermAmount = data.SpermAmount - amount
end

--- (DEBUG) This function is used to clear All the sperm in the Womb
function WombClass:clearAllSperm()
    local data = self.data
    data.SpermAmount = 0
    data.SpermAmountTotal = 0
end

--- Scenes ---

--- Determines fullness based on sperm amount in Womb data
--- @return string "full" if the womb is above half capacity, "empty" otherwise.
function WombClass:getFullness()
    -- Checks if sperm amount is above half the womb's max capacity
    return (self.data.SpermAmount > (self.SBvars.WombMaxCapacity / 2)) and "full" or "empty"
end

--- Returns the normal Womb image depending on Womb's conditions
--- @return string
function WombClass:normalWomb()
    local data = self.data
    local percentage = math.floor((data.SpermAmount / self.SBvars.WombMaxCapacity) * 100)
    local imageIndex = Utils:percentageToNumber(percentage, self.CONSTANTS.SPERM_LEVEL)
    local status = "normal"

    -- If any amount of sperm is present, give the first image
    if imageIndex == 0 and data.SpermAmount > 0 then
        imageIndex = 1
    end

    if Pregnancy:getIsPregnant() then
        status = "conception"

        if Pregnancy:getInLabor() then
            status = "birth"
            imageIndex = Utils:percentageToNumber(Pregnancy:getLaborProgress() * 100, 11)
        elseif Pregnancy:getProgress() > 0.05 then
            status = "pregnant"
            local progress = (Pregnancy:getProgress() < 0.9) and (Pregnancy:getProgress() * 100) or 100
            imageIndex = Utils:percentageToNumber(progress, 6)
        end
    end

    return string.format("media/ui/womb/%s/womb_%s_%s.png", status, status, imageIndex)
end

function WombClass:getAnimationSetting()
    local isCondom = Utils.Inventory:hasItem("ZWBF.Condom") -- Check for condom use case
    local isPregnant = Pregnancy:getIsPregnant()
    local pregnancyProgress = Pregnancy:getProgress()

    if (isPregnant and pregnancyProgress > 0.5) then
        return self.AnimationsSettings.pregnant, "pregnant"
    end

    if (isCondom or (isPregnant and pregnancyProgress > 0.25)) then
        return self.AnimationsSettings.condom, "condom"
    end

    return self.AnimationsSettings.normal, "normal"
end

function WombClass:sceneWomb()
    local animation, type = self:getAnimationSetting()
    local steps = animation.steps
    local loop = animation.loop
    local duration = self:getAnimationDuration()
    local delta = self:getAnimationDelta()

    -- Calculate the total duration of one loop
    local loopDuration = duration / loop

    -- Calculate the current position in the loop
    local currentLoopDelta = (delta * duration) % loopDuration

    -- Calculate the step duration
    local stepDuration = loopDuration / #steps

    -- Determine the current step index
    local stepIndex = math.floor(currentLoopDelta / stepDuration) % #steps + 1
    local step = steps[stepIndex]

    print("Animation index: " .. stepIndex)
    print("Animation frame: " .. tostring(step))

    if type == "pregnant" or type == "condom" then
        return string.format("media/ui/sex/%s/sex_%s.png", type, step)
    end

    local fullness = self:getFullness()
    return string.format("media/ui/sex/normal/sex_%s_%s.png", fullness, step)
end

--- Getters and Setters ---

--- Get if it is in animation state
--- @return number Womb.isAnimation cycle day
function WombClass:getIsAnimation()
    return self.Animation.isAnimation
end

--- Set if it is in animation state
--- @param status boolean Animation status
function WombClass:setIsAnimation(status)
    self.Animation.isAnimation = status
end

--- Get the current cycle phase to be used in the UI
--- @return string Womb.data.cyclePhase cycle phase
function WombClass:getCyclePhase()
    local cycleTranslations = {
        ["Recovery"] = "IGUI_ZWBF_UI_Recovery",
        ["Menstruation"] = "IGUI_ZWBF_UI_Menstruation",
        ["Follicular"] = "IGUI_ZWBF_UI_Follicular",
        ["Ovulation"] = "IGUI_ZWBF_UI_Ovulation",
        ["Luteal"] = "IGUI_ZWBF_UI_Luteal",
        ["Pregnant"] = "IGUI_ZWBF_UI_Pregnant"
    }
    return cycleTranslations[self.data.CyclePhase]
end

--- Set cycle phase based on the current day
function WombClass:setCyclePhase()
    local data = self.data
    if Pregnancy:getIsPregnant() then
        data.CyclePhase = "Pregnant"
        data.Fertility = Pregnancy:getIsPregnant() and Pregnancy:getProgress() or 0
    elseif data.CycleDay < 1 then
        data.CyclePhase = "Recovery"
        data.Fertility = 0
    elseif data.CycleDay < 6 then
        data.CyclePhase = "Menstruation"
    elseif data.CycleDay < 13 then
        data.CyclePhase = "Follicular"
    elseif data.CycleDay < 16 then
        data.CyclePhase = "Ovulation"
    else
        data.CyclePhase = "Luteal"
    end
end

--- Set the player on contraceptives
--- @param status boolean
function WombClass:setContraceptive(status)
    self.data.OnContraceptive = status
    self:setFertility()
end

--- Get the player's contraceptive status
--- @return boolean Womb.data.OnContraceptive contraceptive status
function WombClass:getOnContraceptive()
    return self.data.OnContraceptive
end

--- Set the amount of sperm in the womb
--- @param amount number Sperm amount
function WombClass:setSpermAmount(amount)
    self.data.SpermAmount = amount
end

--- Get the amount of sperm in the womb
--- @return number Womb.data.SpermAmount sperm amount
function WombClass:getSpermAmount()
    return self.data.SpermAmount
end

--- Get the total amount of sperm in the womb
--- @return number Womb.data.SpermAmountTotal total sperm amount
function WombClass:getSpermAmountTotal()
    return self.data.SpermAmountTotal
end

--- Get the current Fertility
--- @return number Womb.data.Fertility fertility percentage
function WombClass:getFertility()
    return self.data.Fertility
end

--- Set fertility based on the current cycle phase and conditions like pregnancy and contraceptives
function WombClass:setFertility()
    local data = self.data
    local player = getPlayer()
    if (
            data.OnContraceptive or
                    player:HasTrait("Infertile")
    ) then
        data.Fertility = 0
    elseif Pregnancy:getIsPregnant() then
        data.Fertility = Pregnancy:getProgress() or 0
    else
        local fertility = {
            ["Recovery"] = 0,
            ["Menstruation"] = ZombRandFloat(0, 0.3),
            ["Follicular"] = ZombRandFloat(0, 0.4),
            ["Ovulation"] = ZombRandFloat(0.85, 1),
            ["Luteal"] = ZombRandFloat(0, 0.3),
        }
        data.Fertility = fertility[data.CyclePhase] or 0;
        if (data.Fertility > 0 and player:HasTrait("Fertile")) then
            data.Fertility = data.Fertility * (1 + (self.SBvars.FertilityBonus / 100))
        end
    end
end

function WombClass:setAnimationDelta(delta)
    -- print("ZWBF - Womb - Set Animation Delta - " .. delta)
    self.Animation.delta = delta
end
function WombClass:getAnimationDelta()
    -- print("ZWBF - Womb - Get Animation Delta")
    return self.Animation.delta
end

function WombClass:setAnimationDuration(duration)
    self.Animation.duration = duration
end

function WombClass:getAnimationDuration()
    return self.Animation.duration
end

--- Returns the Womb image depending on Womb's conditions
--- @return string
function WombClass:getImage()
    -- check if the player is in a scene
    if (self:getIsAnimation()) then
        return self:sceneWomb()
    end
    return self:normalWomb() -- If not in a scene, the normal womb will be shown
end

-- DEBUG --
--- (DEBUG) Set player Pregnancy
--- @param status boolean Pregnancy status
function WombClass:setPregnancy(status)
    if status then
        Pregnancy:start()
    else
        Pregnancy:stop()
    end
    self:addCycleDay()
end

--- (DEBUG) Advance the player's pregnancy by 24h
function WombClass:advancePregnancy()
    Pregnancy:advancePregnancy(24)
    self:setFertility()
end

local Womb = WombClass:new()

--- Hook up event listeners
Events.OnCreatePlayer.Add(function()
    Womb:onCreatePlayer()
end)

Events.EveryOneMinute.Add(function()
    Womb:onCheckContraceptive()
    Womb:onCheckPregnancy()
end)

Events.EveryTenMinutes.Add(function()
    Womb:onRunDown()
end)

Events.EveryDays.Add(function()
    Womb:addCycleDay()
end)

-- TODO: add menstruation debuffs


return Womb
