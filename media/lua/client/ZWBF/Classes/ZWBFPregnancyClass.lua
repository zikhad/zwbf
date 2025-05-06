-- Localized global functions from PZ
-- local getPlayer = getPlayer
local SandboxVars = SandboxVars
local Events = Events
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent
local ZombRand = ZombRand
local ISTimedActionQueue = ISTimedActionQueue
local getActivatedMods = getActivatedMods
local getTexture = getTexture
local Perks = Perks
local getText = getText
local BodyPartType = BodyPartType

-- Sandbox Variables
local SBVars = SandboxVars.ZWBF

local ZWBFActionBirth = require("ZWBF/Actions/ZWBFBirth")

-- Constants
local SCREAM_CHANCE = 5
local BABY_LIST = {
    "Baby_01_b", "Baby_02", "Baby_02_b", "Baby_03", "Baby_03_b", "Baby_07",
    "Baby_07_b", "Baby_08", "Baby_08_b", "Baby_09", "Baby_09_b", "Baby_10",
    "Baby_10_b", "Baby_11", "Baby_11_b", "Baby_12", "Baby_12_b", "Baby_13",
    "Baby_14"
}

-- Pregnancy Class
-- This class will handle the pregnancy system
local PregnancyClass = {}
PregnancyClass.__index = PregnancyClass
PregnancyClass.LaborAnimationTime = 5500

--- Constructor
--- @param props table | nil Properties for the class.
function PregnancyClass:new(props)
    props = props or {}
    local instance = setmetatable({}, PregnancyClass)
    instance.name = props.name or "Pregnancy"
    instance.isMF = false

    if getActivatedMods():contains("MoodleFramework") then
        require "MF_ISMoodle"
        instance.isMF = true
        MF.createMoodle("Pregnancy")
    end
    return instance
end

--- Resets pregnancy-related variables.
function PregnancyClass:resetVariables()
    self.data = self.data or {}
    self.data.InLabor = false
    self.data.PregnancyCurrent = 0
    self.data.LaborProgress = 0
    self.data.PregnancyDuration = SBVars.PregnancyDuration * 24 * 60
end

--- Updates pregnancy data in the player's mod data.
function PregnancyClass:update()
    self.player:getModData().ZWBFPregnancy = self.data
end

--- Initializes the pregnancy system for the player.
function PregnancyClass:onCreatePlayer(player)
    self.player = player
    local modData = self.player:getModData()
    modData.ZWBFPregnancy = modData.ZWBFPregnancy or {}
    self.data = modData.ZWBFPregnancy
    self.data.PregnancyDuration = self.data.PregnancyDuration or (SBVars.PregnancyDuration * 24 * 60)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent or 0
    self.data.InLabor = self.data.InLabor or false
    self.data.LaborProgress = self.data.LaborProgress or 0
end

--- Checks if the player is pregnant.
--- @return boolean True if the player is pregnant, false otherwise.
function PregnancyClass:getIsPregnant()
    return self.player:HasTrait("Pregnancy")
end

--- Gets pregnancy progress as a percentage.
--- @return number Progress (0-1).
function PregnancyClass:getProgress()
    return self.data.PregnancyCurrent / self.data.PregnancyDuration
end

--- Checks if the player is in labor.
--- @return boolean True if in labor, false otherwise.
function PregnancyClass:getInLabor()
    return self.data.InLabor
end

--- Handles MoodleFramework updates.
--- @param level number | nil Progress level.
function PregnancyClass:moodle(level)
    if not self.isMF then return end
    level = level or self:getProgress()

    local moodle = MF.getMoodle("Pregnancy")
    moodle:setThresholds(nil, nil, nil, nil, 0.3, 0.6, 0.9, 0.98)
    moodle:setPicture(
            moodle:getGoodBadNeutral(),
            moodle:getLevel(),
            getTexture("media/ui/Moodles/Pregnancy.png")
    )
    moodle:setValue(level)
end

--- Make player consume extra calories during pregnancy.
function PregnancyClass:consumeExtraCalories()
    local calories = (600 * self:getProgress()) / 1440
    local nutrition = self.player:getNutrition()
    nutrition:setCalories(math.max(-2200, nutrition:getCalories() - calories))
end

--- Make player consume extra water during pregnancy.
function PregnancyClass:consumeExtraWater()
    local water = (0.5 * self:getProgress()) / 1440
    local stats = self.player:getStats()
    stats:setThirst(math.min(1, stats:getThirst() + water))
end

--- Adjusts max weight carried by the player during pregnancy.
function PregnancyClass:setBodyWeightChanges()
    local progress = self:getProgress()
    self.player:setMaxWeightBase(8 * (1 - (progress / 2)))
end

--- Resets body weight changes to default.
function PregnancyClass:resetBodyWeightChanges()
    self.player:setMaxWeightBase(8)
end

--- Handles periodic labor checks.
function PregnancyClass:onCheckLabor()
    if not self:getIsPregnant() then return end

    if self:getProgress() >= 1 then
        self:onLaborStart()
    else
        self.data.PregnancyCurrent = self.data.PregnancyCurrent + 1
    end
    self:update()
end

--- Handles labor start.
function PregnancyClass:onLaborStart()
    self.data.InLabor = true
    self.data.PregnancyCurrent = 0
    self.player:setBlockMovement(true)
    ISTimedActionQueue.add(ZWBFActionBirth:new(self))
    triggerEvent("ZWBFPregnancyLaborStart", self)
end

--- Updates labor progress and handles pain/screaming mechanics.
function PregnancyClass:onLaborUpdate()
    local stats = self.player:getStats()
    local groin = self.player:getBodyDamage():getBodyPart(BodyPartType.Groin)

    -- set chance for scream
    local modifier = (
            self.player:getPerkLevel(Perks.Strength) +
            self.player:getPerkLevel(Perks.Fitness) +
            self.player:getPerkLevel(Perks.Sneak)
    ) * 3

    local chanceToScream = SCREAM_CHANCE + math.floor(stats:getPain() / SCREAM_CHANCE)
    local chance = math.floor(chanceToScream * (1 - (modifier / 100)))

    if ZombRand(100) <= chance then
        self.player:SayShout(getText("IGUI_ZWBF_UI_Scream"))
    end

    -- set pain
    if (groin:getAdditionalPain() < 75) then
        groin:setAdditionalPain(math.min(100, groin:getAdditionalPain() + 5))
    end

    -- set Fatigue
    if (self:getLaborProgress() > stats:getFatigue()) then
        stats:setFatigue(self:getLaborProgress())
    end

    triggerEvent("ZWBFPregnancyLaborUpdate", self)
end

--- Called every in-game minute.
function PregnancyClass:onProgressUpdateOneMinute()
    if not self:getIsPregnant() then return end
    self:moodle()
    triggerEvent("ZWBFPregnancyProgressOneMinute", self)
end

--- Called every in-game hour.
function PregnancyClass:onProgressUpdateOneHour()
    if not self:getIsPregnant() then return end

    local progress = self:getProgress()
    if progress >= 0.25 then
        self:consumeExtraCalories()
        self:consumeExtraWater()
        self:setBodyWeightChanges()
    end
    triggerEvent("ZWBFPregnancyProgressOneHour", self)
end

--- Handles morning sickness during early pregnancy.
function PregnancyClass:onDawn()
    if not self:getIsPregnant() then return end

    local progress = self:getProgress()
    if progress >= 0.05 and progress <= 0.33 then
        self.player:getBodyDamage():setFoodSicknessLevel(50 + ZombRand(50))
    end
end

--- Handles the birth process.
function PregnancyClass:onBirth()
    local baby = BABY_LIST[ZombRand(1, #BABY_LIST)]
    self.player:getInventory():AddItem("Babies." .. baby)
    self.player:setBlockMovement(false)
    self:resetBodyWeightChanges()
    self:moodle(nil)
    self:stop()
    triggerEvent("ZWBFPregnancyLaborEnd", self)
end

--- Starts the pregnancy process.
function PregnancyClass:start()
    self.player:getTraits():add("Pregnancy")
    self.data.PregnancyCurrent = 0
    self.data.PregnancyDuration = SBVars.PregnancyDuration * 24 * 60
    self.data.InLabor = false
    self.data.LaborProgress = 0
    self:update()
end

--- Stops the pregnancy process and resets related data.
function PregnancyClass:stop()
    self.player:getTraits():remove("Pregnancy")
    self:resetVariables()
    self:update()
end

--- Advances pregnancy progress by a specified number of hours (DEBUG).
function PregnancyClass:advancePregnancy(hours)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + (hours * 60)
end

--- Advances pregnancy to just before labor (DEBUG).
function PregnancyClass:advanceToLabor()
    self.data.PregnancyCurrent = self.data.PregnancyDuration - 1
end

--- Sets labor progress.
function PregnancyClass:setLaborProgress(progress)
    self.data.LaborProgress = progress
end

--- Gets labor progress.
--- @return number Labor progress (0-1).
function PregnancyClass:getLaborProgress()
    return self.data.LaborProgress
end

function PregnancyClass:registerEvents()
   local function defaultEvents()
       Events.OnCreatePlayer.Add(function(_, player)
           self:onCreatePlayer(player)
       end)

       Events.EveryOneMinute.Add(function()
           self:onCheckLabor()
           self:onProgressUpdateOneMinute()
       end)

       Events.EveryHours.Add(function()
           self:onProgressUpdateOneHour()
       end)

       Events.OnDawn.Add(function()
           self:onDawn()
       end)
   end
    local function customEvents()
        LuaEventManager.AddEvent("ZWBFPregnancyProgressOneMinute")
        LuaEventManager.AddEvent("ZWBFPregnancyProgressOneHour")
        LuaEventManager.AddEvent("ZWBFPregnancyLaborStart")
        LuaEventManager.AddEvent("ZWBFPregnancyLaborUpdate")
        LuaEventManager.AddEvent("ZWBFPregnancyLaborEnd")
    end
    defaultEvents()
    customEvents()
end

-- Instantiate Pregnancy class
-- local Pregnancy = PregnancyClass:new()

-- Hook Events


--- Register events to be used by other mods through LuaEventManager


return PregnancyClass
