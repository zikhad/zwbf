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
local zombRand = ZombRand
local getText = getText

-- Sandbox Variables
local SBVars = SandboxVars.ZWBF

-- ZWBF PregnancyClass
--- Class responsible for handling pregnancy mechanics in the game.
PregnancyClass = {}
PregnancyClass.__index = PregnancyClass
PregnancyClass.SCREAM_CHANCE = 5

-- TODO: Add pregnancy-related moodles

--- Constructor
--- Creates a new PregnancyClass instance.
--- @param name string | nil Name of the pregnancy system instance (default: "Pregnancy").
function PregnancyClass:new(name)
    local instance = setmetatable({}, PregnancyClass)
    instance.name = name or "Pregnancy"
    instance.isMF = false
    if getActivatedMods():contains("MoodleFramework") == true then
        require "MF_ISMoodle"
        instance.isMF = true
        MF.createMoodle("Pregnancy")
    end
    return instance
end

--- Initializes pregnancy data and hooks event listeners as needed.
function PregnancyClass:init()
    self.data = self.player:getModData().ZWBFPregnancy or {}
    self.data.PregnancyDuration = self.data.PregnancyDuration or (SBVars.PregnancyDuration * 24 * 60) -- MINUTES
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

--- Called when a player is created, initializes the pregnancy system for that player.
function PregnancyClass:onCreatePlayer()
    self.player = getPlayer()
    self:init()
end

--- Checks if the player is pregnant.
--- @return boolean pregnancy True if the player is pregnant, false otherwise.
function PregnancyClass:getIsPregnant()
    return self.player:HasTrait("Pregnancy")
end

--- Gets the current pregnancy progress as a percentage.
--- @return number Pregnancy progress (0-1).
function PregnancyClass:getProgress()
    return self.data.PregnancyCurrent / self.data.PregnancyDuration
end

--- Checks if the player is in labor.
--- @return boolean True if in labor, false otherwise.
function PregnancyClass:getInLabor()
    return self.data.InLabor
end

--- Checks if the pregnancy duration has been reached, triggers labor if so.
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

--- Handles the start of labor.
function PregnancyClass:onLaborStart()
    self.data.InLabor = true
    self.data.PregnancyCurrent = 0
    ISTimedActionQueue.add(ZWBFActionBirth:new(self.player, self))
end

function PregnancyClass:onLaborUpdate()
    local player = self.player
    local stats = player:getStats()

    -- Add pain to the labor
    stats:setPain(math.min(100, stats:getPain() + 5));
    
    -- scream depending on parks and chance
    local modifier = (
        player:getPerkLevel(Perks.Strength) +
        player:getPerkLevel(Perks.Fitness) +
        player:getPerkLevel(Perks.Sneak)
    ) * 3
    local chanceToScream = self.SCREAM_CHANCE + math.floor(stats:getPain() / self.SCREAM_CHANCE)
    local chance = math.floor(self.SCREAM_CHANCE * (1 - (modifier / 100)))
    if (zombRand(100) <= chance) then
        player:SayShout(getText('IGUI_ZWBF_UI_Scream'))
    end
end

function PregnancyClass:onProgressUpate()
    -- Update moodle
    self:moodle()
    -- TODO: consume extra calories and water
end

--- Handles the birth process, removes pregnancy trait, and gives the player a baby item.
function PregnancyClass:onBirth()
    self.data.InLabor = false
    self.data.LaborProgress = 0
    local babies = {
        "Baby_01_b", "Baby_02", "Baby_02_b", "Baby_03", "Baby_03_b", "Baby_07",
        "Baby_07_b", "Baby_08", "Baby_08_b", "Baby_09", "Baby_09_b", "Baby_10",
        "Baby_10_b", "Baby_11", "Baby_11_b", "Baby_12", "Baby_12_b", "Baby_13",
        "Baby_14"
    }
    local baby = babies[ZombRand(1, #babies)]
    self.player:getInventory():AddItem("Babies." .. baby)
    self.player:getTraits():remove("Pregnancy")
end

--- Handler the Dawn event
function PregnancyClass:onDawn()
    -- Morning sickness
    if not self:getIsPregnant() then return end
    if self:getProgress() >= 0.05 and self:getProgress() <= 0.33 then
        self.player:getBodyDamage():setFoodSicknessLevel(50 + ZombRand(50))
    end
end

--- Starts the pregnancy process, adding the "Pregnancy" trait and initializing the system.
function PregnancyClass:start()
    self.player:getTraits():add("Pregnancy")
    self:init()
    Events.EveryOneMinute.Add(OnCheckLabor)
end

--- Stops the pregnancy process, resetting all related data.
function PregnancyClass:stop()
    self.player:getTraits():remove("Pregnancy")
    self.data.PregnancyCurrent = 0
    self.data.InLabor = false
    self.data.LaborProgress = 0
    self:update()
    Events.EveryOneMinute.Remove(OnCheckLabor)
end

--- (DEBUG) Advances pregnancy progress by a specified number of hours.
--- @param hours number Number of hours to advance.
function PregnancyClass:advancePregnancy(hours)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + hours
end

--- (DEBUG) Advances pregnancy progress to just before labor.
function PregnancyClass:advanceToLabor()
    self.data.PregnancyCurrent = self.data.PregnancyDuration - 1
end

--- Sets labor progress.
--- @param progress number Labor progress (0-1).
function PregnancyClass:setLaborProgress(progress)
    self.data.LaborProgress = progress
end

--- Gets labor progress.
--- @return number Labor progress (0-1).
function PregnancyClass:getLaborProgress()
    return self.data.LaborProgress
end

--- Handle the MoodleFramework
---@param level number | nil
function PregnancyClass:moodle(level)
    level = level or self:getProgress()
    if not self.isMF then
        -- TODO: Add no moodle framework support
        return
    end
    local moodle = MF.getMoodle("Pregnancy")
    moodle:setThresholds(nil, nil, nil, nil, 0.3, 0.6, 0.9, 0.98)
    moodle:setPicture(
        moodle:getGoodBadNeutral(),
        moodle:getLevel(),
        getTexture("media/ui/Moodles/Pregnancy.png")
    );
    moodle:setValue(level)
end

-- Instantiate Pregnancy class
local Pregnancy = PregnancyClass:new()

-- Local Functions
--- Checks labor status periodically.
function OnCheckLabor()
    Pregnancy:onCheckLabor()
end

-- Hookup Events
Events.OnCreatePlayer.Add(function()
    Pregnancy:onCreatePlayer()
end)

Events.OnDawn.Add(function ()
    Pregnancy:onDawn()
end)

-- Pregnancy Events
LuaEventManager.AddEvent("ZWBFPregnancyProgress")
Events.ZWBFPregnancyProgress.Add(function(pregnancy)
    print("Pregnancy Progress: " .. pregnancy:getProgress())
    pregnancy:onProgressUpate()
    -- TODO: add logic to consume extra calories and water here
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
