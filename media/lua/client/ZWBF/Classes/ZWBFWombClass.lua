--- Localized global functions from PZ
local ZombRandFloat = ZombRandFloat
local ZombRand = ZombRand
local BodyPartType = BodyPartType
local HaloTextHelper = HaloTextHelper
local getText = getText
local SandboxVars = SandboxVars

local SBVars = SandboxVars.ZWBF

--- ZWBFWombClass
--- This class handles the womb system for ZomboWinBeingFemale
local WombClass = {}
WombClass.__index = WombClass

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
    },
    birth = {
        steps = {
            0, 1, 2, 3, 4,
            5, 6, 7, 8, 9,
            10, 11
        },
        loop = 1
    }
}

function WombClass:new(props)
    props = props or {}
    local instance = setmetatable({}, WombClass)

    instance.name = props.name or "Womb"
    instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")
    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
    return instance
end

--- Methods ---

--- Apply wetness to the groin
--- @param amount number | nil (optional) The amount of wetness to apply
function WombClass:applyWetness(amount)
    amount = amount or ZombRand(self.CONSTANTS.WETNESS.MIN, self.CONSTANTS.WETNESS.MAX)
    local player = self.player
    local Groin = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Groin"))
    Groin:setWetness(Groin:getWetness() + amount)
end


function WombClass:rollCycleChances()
    local chances = {
        ["Recovery"] = 0,
        ["Menstruation"] = ZombRandFloat(0, 0.3),
        ["Follicular"] = ZombRandFloat(0, 0.4),
        ["Ovulation"] = ZombRandFloat(0.85, 1),
        ["Luteal"] = ZombRandFloat(0, 0.3),
    }
    return chances
end

--- Add one day to the cycle
function WombClass:addCycleDay()
    local data = self.data

    data.OnContraceptive = false
    if not self.Pregnancy:getIsPregnant() then
        data.CycleDay = (data.CycleDay < 28) and (data.CycleDay + 1) or 1
    else
        data.cycleChances = self:rollCycleChances()
    end
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
    self:updateCyclePhase()
    self:updateFertility()
    self.player:getModData().ZWBFWomb = self.data
end

--- Modify the variables according to player Traits
function WombClass:applyTraits()
    local player = self.player
    -- Hyperfertile
    if player:HasTrait("Fertile") then
        -- +50% fertility
        self.SBvars.FertilityBonus = SBVars.FertilityBonus * 1.5
    elseif player:HasTrait("Hyperfertile") then
        -- +100% fertility
        self.SBvars.FertilityBonus = SBVars.FertilityBonus * 2
        -- Halves the time before being ready to get pregnant again after birth
        self.SBvars.PregnancyRecovery = math.floor(SBVars.PregnancyRecovery / 2)
    end
end


--- Events Listeners ---

--- Initialize the Womb when the player is created ---
function WombClass:onCreatePlayer(player)
    -- setup SandboxVars
    self.player = player
    self.SBvars.PregnancyRecovery = SBVars.PregnancyRecovery
    self.SBvars.WombMaxCapacity = SBVars.WombMaxCapacity
    self.SBvars.FertilityBonus = SBVars.FertilityBonus
    -- Apply Traits that are related to the Womb
    self:applyTraits()

    local data = self.player:getModData().ZWBFWomb or {}

    data.SpermAmount = data.SpermAmount or 0
    data.SpermAmountTotal = data.SpermAmountTotal or 0
    data.CycleDay = data.CycleDay or ZombRand(1, 28)
    data.OnContraceptive = data.OnContraceptive or false
    data.cycleChances = data.cycleChances or self:rollCycleChances()
    self.data = data
end

--- Check if the player is pregnant
function WombClass:onCheckPregnancy()
    local data = self.data
    if self.Pregnancy:getIsPregnant() then
        data.CycleDay = -self.SBvars.PregnancyRecovery
        if self.Pregnancy:getProgress() > 0.5 then
            data.SpermAmount = 0
        end
    end
end

--- Run down logic to eventually empty the womb
--- @param chance number | nil (optional) The chance of running down
function WombClass:onRunDown(chance)
    chance = chance or 50
    if ZombRand(100) > 50 then return end -- chance of not doing anything
    local player = self.player
    local amount = ZombRand(50)
    local data = self.data
    if data.SpermAmount > 0 then
        local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
        HaloTextHelper.addTextWithArrow(player, text, false, HaloTextHelper.getColorWhite())
        self:applyWetness()
    end
    data.SpermAmount = data.SpermAmount - amount
end

function WombClass:onEveryOneMinute()
    self:onCheckPregnancy()
    self:update()
end

function WombClass:onEveryTenMinutes()
    self:onRunDown()
end

function WombClass:onEveryHours()
    self.data.cycleChances = self:rollCycleChances()
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
function WombClass:stillImage()
    local data = self.data
    local percentage = math.floor((data.SpermAmount / self.SBvars.WombMaxCapacity) * 100)
    local imageIndex = self.Utils:percentageToNumber(percentage, self.CONSTANTS.SPERM_LEVEL)
    local status = "normal"

    -- If any amount of sperm is present, give the first image
    if imageIndex == 0 and data.SpermAmount > 0 then
        imageIndex = 1
    end

    if self.Pregnancy:getIsPregnant() then
        status = "conception"
        if self.Pregnancy:getProgress() > 0.05 then
            status = "pregnant"
            local progress = (self.Pregnancy:getProgress() < 0.9) and (self.Pregnancy:getProgress() * 100) or 100
            imageIndex = self.Utils:percentageToNumber(progress, 6)
        end
    end

    return string.format("media/ui/womb/%s/womb_%s_%s.png", status, status, imageIndex)
end

--- Get the animation setting based on current conditions
--- @return table Animation settings
function WombClass:getAnimationSetting()

    local isPregnant = self.Pregnancy:getIsPregnant()
    if isPregnant then
        local isInLabor = self.Pregnancy:getInLabor()
        if isInLabor then
            return self.AnimationsSettings.birth, "birth"
        end

        local pregnancyProgress = self.Pregnancy:getProgress()
        if pregnancyProgress > 0.5 then
            return self.AnimationsSettings.pregnant, "pregnant"
        elseif pregnancyProgress > 0.25 then
            return self.AnimationsSettings.condom, "condom"
        end
    end

    local isCondom = self.Utils.Inventory:hasItem("ZWBF.Condom")
    if isCondom then
        return self.AnimationsSettings.condom, "condom"
    end

    return self.AnimationsSettings.normal, "normal"
end

function WombClass:sceneImage()
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

    local fullness = (type == "normal") and ("/" .. self:getFullness()) or ""
    return string.format("media/ui/animation/%s%s/%s.png", type, fullness, step)
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
--- @return string `Womb.data.cyclePhase` cycle phase
function WombClass:getCyclePhaseTranslation()
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
function WombClass:updateCyclePhase()
    local data = self.data
    if self.Pregnancy:getIsPregnant() then
        data.CyclePhase = "Pregnant"
    elseif data.CycleDay < 1 then
        data.CyclePhase = "Recovery"
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

--- Returns true if the player is in recovery
--- @return boolean `true` if the player is in recovery
function WombClass:getInRecovery()
    return self.data.CyclePhase == "Recovery"
end

--- Set the player on contraceptives
--- @param status boolean
function WombClass:setContraceptive(status)
    self.data.OnContraceptive = status
end

--- Get the player's contraceptive status
--- @return boolean `Womb.data.OnContraceptive` contraceptive status
function WombClass:getOnContraceptive()
    return self.data.OnContraceptive
end

--- Set the amount of sperm in the womb
--- @param amount number Sperm amount
function WombClass:setSpermAmount(amount)
    self.data.SpermAmount = amount
end

--- Get the amount of sperm in the womb
--- @return number `Womb.data.SpermAmount` sperm amount
function WombClass:getSpermAmount()
    return self.data.SpermAmount
end

--- Get the total amount of sperm in the womb
--- @return number `Womb.data.SpermAmountTotal` total sperm amount
function WombClass:getSpermAmountTotal()
    return self.data.SpermAmountTotal
end

--- Get the current Fertility
--- @return number `Womb.data.Fertility` fertility percentage
function WombClass:getFertility()
    return self.data.Fertility
end

--- Set fertility based on the current cycle phase and conditions like pregnancy and contraceptives
function WombClass:updateFertility()
    local data = self.data
    local player = self.player

    if data.OnContraceptive or player:HasTrait("Infertile") then
        data.Fertility = 0
    elseif self.Pregnancy:getIsPregnant() then
        data.Fertility = self.Pregnancy:getProgress() or 0
    else
        data.Fertility = data.cycleChances[data.CyclePhase] or 0;
        if (data.Fertility > 0) and (player:HasTrait("Fertile") or player:HasTrait("Hyperfertile")) then
            data.Fertility = data.Fertility * (1 + (self.SBvars.FertilityBonus / 100))
        end
    end
end

--- Set animation delta, the progress of animation 0-1
--- @param delta boolean Animation status
function WombClass:setAnimationDelta(delta)
    self.Animation.delta = delta
end

--- Get animation delta, the progress of animation 0-1
--- @return number `Womb.Animation.delta` animation delta
function WombClass:getAnimationDelta()
    return self.Animation.delta
end

--- Set animation duration
--- @param duration number Animation duration
function WombClass:setAnimationDuration(duration)
    self.Animation.duration = duration
end

--- Get animation duration
--- @return number `Womb.Animation.duration` animation duration
function WombClass:getAnimationDuration()
    return self.Animation.duration
end

--- Returns the Womb image depending on Womb's conditions
--- @return string
function WombClass:getImage()
    -- check if the player is in a scene
    if (self:getIsAnimation()) then
        return self:sceneImage()
    end
    -- If not in a scene, the normal womb will be shown
    return self:stillImage()
end

--- (DEBUG) Advance the player's menstrual cycle to the next phase
function WombClass:nextCycle()
    if self.Pregnancy:getIsPregnant() then return end
    local data = self.data

    if data.CycleDay < 1 then
        data.CycleDay = 1
    elseif data.CycleDay < 6 then
        data.CycleDay = 6
    elseif data.CycleDay < 13 then
        data.CycleDay = 13
    elseif data.CycleDay < 16 then
        data.CycleDay = 16
    elseif data.CycleDay < 28 then
        data.CycleDay = 28
    else
        data.CycleDay = 1
    end
end

--- Register Events
function WombClass:registerEvents()
    local function defaultEvents()
        Events.OnCreatePlayer.Add(function(_, player)
            self:onCreatePlayer(player)
        end)

        Events.EveryOneMinute.Add(function()
            self:onEveryOneMinute()
        end)

        Events.EveryTenMinutes.Add(function()
            self:onEveryTenMinutes()
        end)

        Events.EveryHours.Add(function()
            self:onEveryHours()
        end)

        Events.EveryDays.Add(function()
            self:addCycleDay()
        end)
    end
    local function customEvents()
        Events.ZWBFPregnancyLaborStart.Add(function(pregnancy)
            self:setIsAnimation(true)
            self:setAnimationDuration(pregnancy.LaborAnimationTime)
        end)

        Events.ZWBFPregnancyLaborUpdate.Add(function(pregnancy)
            self:setAnimationDelta(pregnancy:getLaborProgress())
        end)

        Events.ZWBFPregnancyLaborEnd.Add(function()
            self:setIsAnimation(false)
        end)
    end
    defaultEvents()
    customEvents()
end

return WombClass
