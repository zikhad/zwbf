-- Localized global functions from PZ
local getPlayer = getPlayer
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

-- Sandbox Variables
local SBVars = SandboxVars.ZWBF

-- Constants
local SCREAM_CHANCE = 5
local BABY_LIST = {
    "Baby_01_b", "Baby_02", "Baby_02_b", "Baby_03", "Baby_03_b", "Baby_07",
    "Baby_07_b", "Baby_08", "Baby_08_b", "Baby_09", "Baby_09_b", "Baby_10",
    "Baby_10_b", "Baby_11", "Baby_11_b", "Baby_12", "Baby_12_b", "Baby_13",
    "Baby_14"
}

-- Pregnancy Class
PregnancyClass = {}
PregnancyClass.__index = PregnancyClass

--- Constructor
--- @param name string | nil Name of the pregnancy system instance (default: "Pregnancy").
function PregnancyClass:new(name)
    local instance = setmetatable({}, PregnancyClass)
    instance.name = name or "Pregnancy"
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
    self.data.InLabor = false
    self.data.PregnancyCurrent = 0
    self.data.LaborProgress = 0
    self.data.PregnancyDuration = SBVars.PregnancyDuration * 24 * 60
end

--- Initializes pregnancy data.
function PregnancyClass:init()
    self.data = self.player:getModData().ZWBFPregnancy or {}
    self.data.PregnancyDuration = self.data.PregnancyDuration or (SBVars.PregnancyDuration * 24 * 60)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent or 0
    self.data.InLabor = self.data.InLabor or false
    self.data.LaborProgress = 0

    if self.player:HasTrait("Pregnancy") then
        Events.EveryOneMinute.Add(OnCheckLabor)
    end
end

--- Updates pregnancy data in the player's mod data.
function PregnancyClass:update()
    self.player:getModData().ZWBFPregnancy = self.data
end

--- Initializes the pregnancy system for the player.
function PregnancyClass:onCreatePlayer()
    self.player = getPlayer()
    self:init()
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

--- Handles periodic labor checks.
function PregnancyClass:onCheckLabor()
    if not self.data then return end
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + 1

    if self:getProgress() >= 1 then
        Events.EveryOneMinute.Remove(OnCheckLabor)
        triggerEvent("ZWBFPregnancyLaborStart", self)
    else
        triggerEvent("ZWBFPregnancyProgress", self)
    end
    self:update()
end

--- Handles labor start.
function PregnancyClass:onLaborStart()
    self.data.InLabor = true
    self.data.PregnancyCurrent = 0
    ISTimedActionQueue.add(ZWBFActionBirth:new(self))
end

--- Updates labor progress and handles pain/screaming mechanics.
function PregnancyClass:onLaborUpdate()
    local player = self.player
    local stats = player:getStats()

    stats:setPain(math.min(100, stats:getPain() + 5))

    local modifier = (
        player:getPerkLevel(Perks.Strength) +
        player:getPerkLevel(Perks.Fitness) +
        player:getPerkLevel(Perks.Sneak)
    ) * 3
    local chanceToScream = SCREAM_CHANCE + math.floor(stats:getPain() / SCREAM_CHANCE)
    local chance = math.floor(chanceToScream * (1 - (modifier / 100)))

    if ZombRand(100) <= chance then
        player:SayShout(getText("IGUI_ZWBF_UI_Scream"))
    end
end

--- Updates pregnancy progress.
function PregnancyClass:onProgressUpdate()
    -- self:moodle()
    -- TODO: Consume extra calories and water here.
end

--- Handles the birth process.
function PregnancyClass:onBirth()
    self:resetVariables()
    local baby = BABY_LIST[ZombRand(1, #BABY_LIST)]
    self.player:getInventory():AddItem("Babies." .. baby)
    self.player:getTraits():remove("Pregnancy")
    self.data.PregnancyCurrent = 0
    self:moodle(nil)
end

--- Handles morning sickness during early pregnancy.
function PregnancyClass:onDawn()
    if not self:getIsPregnant() then return end

    local progress = self:getProgress()
    if progress >= 0.05 and progress <= 0.33 then
        self.player:getBodyDamage():setFoodSicknessLevel(50 + ZombRand(50))
    end
end

--- Starts the pregnancy process.
function PregnancyClass:start()
    self.player:getTraits():add("Pregnancy")
    self:init()
    self.data.PregnancyCurrent = 0
    self.data.PregnancyDuration = (SBVars.PregnancyDuration * 24 * 60) -- MINUTES
    self.data.InLabor = false
    self.data.LaborProgress = 0
    self:update()
    Events.EveryOneMinute.Add(OnCheckLabor)
end

--- Stops the pregnancy process and resets related data.
function PregnancyClass:stop()
    self.player:getTraits():remove("Pregnancy")
    self:resetVariables()
    self:update()
    Events.EveryOneMinute.Remove(OnCheckLabor)
end

--- Advances pregnancy progress by a specified number of hours (DEBUG).
function PregnancyClass:advancePregnancy(hours)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + (hours * 60)
end

--- Advances pregnancy to just before labor (DEBUG).
function PregnancyClass:advanceToLabor()
    self.data.PregnancyCurrent = self.data.PregnancyDuration - 60
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

--- Handles MoodleFramework updates.
--- @param level number | nil Progress level.
function PregnancyClass:moodle(level)
    level = level or self:getProgress()
    if not self.isMF then return end

    local moodle = MF.getMoodle("Pregnancy")
    moodle:setThresholds(nil, nil, nil, nil, 0.3, 0.6, 0.9, 0.98)
    moodle:setPicture(
        moodle:getGoodBadNeutral(),
        moodle:getLevel(),
        getTexture("media/ui/Moodles/Pregnancy.png")
    )
    moodle:setValue(level)
end

-- Instantiate Pregnancy class
local Pregnancy = PregnancyClass:new()

-- Local Functions
function OnCheckLabor()
    Pregnancy:onCheckLabor()
end

-- Hook Events
Events.OnCreatePlayer.Add(function()
    Pregnancy:onCreatePlayer()
end)

Events.OnDawn.Add(function()
    Pregnancy:onDawn()
end)

LuaEventManager.AddEvent("ZWBFPregnancyProgress")
Events.ZWBFPregnancyProgress.Add(function(pregnancy)
    pregnancy:onProgressUpdate()
end)

LuaEventManager.AddEvent("ZWBFPregnancyLaborStart")
Events.ZWBFPregnancyLaborStart.Add(function(pregnancy)
    pregnancy:onLaborStart()
end)

LuaEventManager.AddEvent("ZWBFPregnancyLaborUpdate")
Events.ZWBFPregnancyLaborUpdate.Add(function(pregnancy)
    pregnancy:onLaborUpdate()
end)

LuaEventManager.AddEvent("ZWBFPregnancyBirth")
Events.ZWBFPregnancyBirth.Add(function(pregnancy)
    pregnancy:onBirth()
end)


return Pregnancy
