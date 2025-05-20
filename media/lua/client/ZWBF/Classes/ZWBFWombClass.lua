--- Localized global functions from PZ
local ZombRandFloat = ZombRandFloat
local ZombRand = ZombRand
local BodyPartType = BodyPartType
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events
local SandboxVars = SandboxVars
local SBVars = SandboxVars.ZWBF
local triggerEvent = triggerEvent
local LuaEventManager = LuaEventManager


--- This class handles the womb system
--- @class WombClass
--- @field SBvars table Sandbox variables for the womb
--- @field data table Womb data
--- @field CONSTANTS table Constants for the womb
--- @field Animation table Animation settings
--- @field AnimationsSettings table Animation settings for different states
--- @field Utils table ZWBFUtils
--- @field Pregnancy table ZWBFPregnancy
local WombClass = {}
WombClass.__index = WombClass

WombClass.SBvars = {
    PregnancyRecovery = 7,  -- Number of days to recover after pregnancy,
    WombMaxCapacity = 1000, -- Maximum amount of sperm the womb can hold
    FertilityBonus = 50     -- Fertility Bonus of Fertile Trait
}

-- CONSTANTS
WombClass.CONSTANTS = {
    SPERM_LEVEL = 17, -- Number of sperm levels (For UI)
    WETNESS = {       -- Wetness range for the groin
        MIN = 30,
        MAX = 100
    }
}

WombClass.AnimationsSettings = {
    normal = {
        steps = {
            0, 1, 2, 3, 4, 3, 2, 1,
            0, 1, 2, 3, 4, 3, 2, 1,
            0, 1, 2, 3, 4, 3, 2, 1,
            0, 1, 2, 3, 4, 3, 2, 1,
            0, 1, 2, 3, 4,
            5, 6, 7, 8, 9
        },
        loop = 1
    },
    pregnant = {
        steps = {
            0, 1, 2, 3, 2, 1,
            0, 1, 2, 3, 2, 1,
            0, 1, 2, 3, 2, 1,
            0, 1, 2, 3, 2, 1,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
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

--- Constructor
function WombClass:new(props)
    props = props or {}
    local instance = setmetatable({}, WombClass)

    instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")
    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")

    -- animation control variables
    instance.Animation = {
        isAnimation = false, -- flag for when animation is playing
        delta = 0,           -- animatio delta (0-1) for the current animation
        duration = 0         -- max time of the duration
    }

    return instance
end

--- Update the Womb data
function WombClass:update()
    self:updateCyclePhase()
    self:updateFertility()
    self.player:getModData().ZWBFWomb = self.data
    triggerEvent("ZWBFWombUpdate", self)
end

--- Methods ---
--- @return table Groin return the groin to apply effects
function WombClass:getGroin()
    return self.player:getBodyDamage():getBodyPart(BodyPartType.Groin)
end

--- Apply wetness to the groin
--- @param amount number | nil (optional) The amount of wetness to apply
function WombClass:applyWetness(amount)
    amount = amount or ZombRand(self.CONSTANTS.WETNESS.MIN, self.CONSTANTS.WETNESS.MAX)
    local groin = self:getGroin()
    groin:setWetness(groin:getWetness() + amount)
end

--- Rolls the cycle chances
--- @return table chances table with the chances of each cycle phase
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
    end
    data.cycleChances = self:rollCycleChances()
end

--- Adds sperm to the womb
--- @param amount number
function WombClass:addSperm(amount)
    local data = self.data
    data.SpermAmount = data.SpermAmount + amount
    data.SpermAmountTotal = data.SpermAmountTotal + amount -- add to total
    triggerEvent("ZWBFWombAddSperm", amount)
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
    self.SBvars.PregnancyRecovery = SBVars.PregnancyRecovery
    self.SBvars.WombMaxCapacity = SBVars.WombMaxCapacity
    self.SBvars.FertilityBonus = SBVars.FertilityBonus

    -- Apply Traits that are related to the Womb
    self:applyTraits()

    local data = player:getModData().ZWBFWomb or {}

    -- setup data
    data.SpermAmount = data.SpermAmount or 0
    data.SpermAmountTotal = data.SpermAmountTotal or 0
    data.CycleDay = data.CycleDay or ZombRand(1, 28)
    data.cyclePhase = data.cyclePhase or ""
    data.Fertility = data.Fertility or 0
    data.OnContraceptive = data.OnContraceptive or false
    data.cycleChances = data.cycleChances or self:rollCycleChances()

    self.player = player
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
    if ZombRand(100) > chance then return end -- chance of not doing anything

    local data = self.data
    if data.SpermAmount > 0 then
        local amount = ZombRand(50)
        local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
        local newAmount = data.SpermAmount - amount
        data.SpermAmount = newAmount < 0 and 0 or newAmount
        self:applyWetness()
        HaloTextHelper.addTextWithArrow(self.player, text, false, HaloTextHelper.getColorWhite())
    end
end

-- Method to control menstruation effects
function WombClass:onMenstruationEffect(chance)
    local player = self.player
    -- If player has the NoMenstrualCramps trait, do nothing
    if player:HasTrait("NoMenstrualCramps") then return end

    chance = chance or 50
    local maxPain = self.player:HasTrait("StrongMenstrualCramps") and 50 or 25

    local groin = self:getGroin()

    -- Apply bleeding
    if ZombRand(100) > chance then
        local bleedTime = groin:getBleedingTime()
        groin:setBleedingTime((bleedTime < 10) and 10 or bleedTime)
    end

    -- Apply pain
    if (ZombRand(100) > chance) and (groin:getAdditionalPain() < maxPain) then
        groin:setAdditionalPain(groin:getAdditionalPain() + ZombRand(maxPain))
    end
end

--- On Every One Minute update handler
function WombClass:onEveryOneMinute()
    self:onCheckPregnancy()
    self:update()
end

--- On Every Ten Minutes update handler
function WombClass:onEveryTenMinutes()
    self:onRunDown()
end

--- On Every Hours update handler
function WombClass:onEveryHours()
    self.data.cycleChances = self:rollCycleChances()
end

-- On Every Dawn
function WombClass:onDawn()
    local data = self.data
    -- Apply different effects dependin on cycle phase
    if data.CyclePhase == "Menstruation" then
        self:onMenstruationEffect()
    end
end

--- This function will control if player will get pregnant
function WombClass:impregnate()
    local player = self.player
    -- Do nothing if any of the following is true
    if (
            player:HasTrait("Infertile") or
            self:getOnContraceptive() or
            self.Pregnancy:getIsPregnant() or
            self:getFertility() <= 0
        ) then
        return
    end
    -- Random chance of becoming pregnant
    if ZombRandFloat(0, 1) > (1 - self:getFertility()) then
        local text = getText("IGUI_ZWBF_UI_Fertilized")
        HaloTextHelper.addText(player, text, HaloTextHelper.getColorGreen())
        self.Pregnancy:start()
    end
end

--- This function should be called at the end of an intercourse animation
function WombClass:intercourse()
    local player = self.player
    -- Remove condom, if player has any in the main inventory
    if self.Utils.Inventory:hasItem("ZWBF.Condom", player) then
        local inventory = player:getInventory()
        inventory:Remove("Condom")
        inventory:AddItem("ZWBF.CondomUsed", 1)
    else
        local amount = ZombRand(10, 50)
        local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
        HaloTextHelper.addTextWithArrow(player, text, true, HaloTextHelper.getColorGreen())
        self:addSperm(amount)
        self:impregnate()
    end
end

--- Scenes ---

--- Determines fullness based on sperm amount in Womb data
--- @return string "full" if the womb is above half capacity, "empty" otherwise.
function WombClass:getFullness()
    -- Checks if sperm amount is above half the womb's max capacity
    return (self.data.SpermAmount > (self.SBvars.WombMaxCapacity / 2)) and "full" or "empty"
end

--- Get the animation setting based on current conditions
--- @return table setting, string type animation setting and type
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

    local hasCondom = self.Utils.Inventory:hasItem("ZWBF.Condom")
    if hasCondom then
        return self.AnimationsSettings.condom, "condom"
    end

    return self.AnimationsSettings.normal, "normal"
end

--- Returns the normal Womb image depending on Womb's conditions
--- @return string
function WombClass:stillImage()
    local data = self.data
    local percentage = math.floor((data.SpermAmount / self.SBvars.WombMaxCapacity) * 100)
    local imageIndex = self.Utils:percentageToNumber(percentage, self.CONSTANTS.SPERM_LEVEL)
    local status = "normal"

    if self.Pregnancy:getIsPregnant() then
        status = "conception"
        if self.Pregnancy:getProgress() > 0.05 then
            status = "pregnant"
            local progress = (self.Pregnancy:getProgress() < 0.9) and (self.Pregnancy:getProgress() * 100) or 100
            imageIndex = self.Utils:percentageToNumber(progress, 6)
        end
    elseif imageIndex == 0 and data.SpermAmount > 0 then
        -- If any amount of sperm is present, give the first image
        imageIndex = 1
    end

    return string.format("media/ui/womb/%s/womb_%s_%s.png", status, status, imageIndex)
end

--- Get the animation image based on current conditions
--- @return string Animation image path
function WombClass:sceneImage()
    local animation, type = self:getAnimationSetting()
    local steps = animation.steps
    local loop = animation.loop
    local duration = self.Animation.duration
    local delta = self.Animation.delta

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

--- Getters and Setters ---

--- Set if it is in animation state
--- @param status boolean Animation status
function WombClass:setIsAnimation(status)
    self.Animation.isAnimation = status
end

--- Get the current cycle phase to be used in the UI
--- @return string Cycle phase translation
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

--- Returns true if the player is in recovery
--- @return boolean inRecovery Returns true if player is in recovery
function WombClass:getInRecovery()
    return self.data.CyclePhase == "Recovery"
end

--- Set the player on contraceptives
--- @param status boolean
function WombClass:setContraceptive(status)
    self.data.OnContraceptive = status
end

--- Get the player's contraceptive status
--- @return boolean Contraceptive status
function WombClass:getOnContraceptive()
    return self.data.OnContraceptive
end

--- Set the amount of sperm in the womb
--- @param amount number Sperm amount
function WombClass:setSpermAmount(amount)
    self.data.SpermAmount = amount
end

--- Get the amount of sperm in the womb
--- @return number Sperm amount
function WombClass:getSpermAmount()
    return self.data.SpermAmount
end

--- Get the total amount of sperm in the womb
--- @return number Total sperm amount
function WombClass:getSpermAmountTotal()
    return self.data.SpermAmountTotal
end

--- Get the current Fertility
--- @return number Fertility percentage
function WombClass:getFertility()
    return self.data.Fertility
end

--- Set animation delta, the progress of animation 0-1
--- @param delta boolean Animation status
function WombClass:setAnimationDelta(delta)
    self.Animation.delta = delta
end

--- Set animation duration
--- @param duration number Animation duration
function WombClass:setAnimationDuration(duration)
    self.Animation.duration = duration
end

--- Returns the Womb image depending on Womb's conditions
--- @return string image image path for UI panel
function WombClass:getImage()
    -- check if the player is in a scene
    if (self.Animation.isAnimation) then
        return self:sceneImage()
    end
    -- If not in a scene, a still image will be shown
    return self:stillImage()
end

--- DEBUG FUNCTIONS ---
WombClass.Debug = {}

--- (DEBUG) This function is used to clear All the sperm in the Womb
function WombClass.Debug:clearAllSperm()
    local data = self.data
    data.SpermAmount = 0
    data.SpermAmountTotal = 0
end

--- (DEBUG) Advance the player's menstrual cycle to the next phase
function WombClass.Debug:nextCycle()
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
	-- Register default Events
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

        Events.OnDawn.Add(function()
            self:onDawn()
        end)
    end
	-- Register custom Events Listeners
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
        LuaEventManager.AddEvent("ZWBFWombUpdate")
        LuaEventManager.AddEvent("ZWBFWombAddSperm")
    end
    defaultEvents()
    customEvents()
end

return WombClass
