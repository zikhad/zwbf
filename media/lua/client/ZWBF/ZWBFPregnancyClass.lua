-- Localized global functions from PZ
local getPlayer = getPlayer
local SandboxVars = SandboxVars
local Events = Events
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent

local SBVars = SandboxVars.ZWBF

PregnancyClass = {}
PregnancyClass.__index = PregnancyClass

function PregnancyClass:new(name)
    local instance = setmetatable({}, PregnancyClass)
    instance.name = name or "Pregnancy"
    instance.player = getPlayer()

    instance.data = instance.player:getModData().ZWBFPregnancy or {}
    instance.data.IsPregnant = instance.data.IsPregnant or false
    instance.data.PregnancyDuration = instance.data.PregnancyDuration or SBVars.PregnancyDuration * 24 -- HOURS
    instance.data.PregnancyCurrent = instance.data.PregnancyCurrent or 0
    -- instance.data.LaborDuration = instance.data.LaborDuration or SBVars.LaborMinimumDuration * 60 -- MINUTES
    -- instance.data.LaborDuration = instance.data.LaborDuration or 0
    return instance
end

function PregnancyClass:getIsPregnant()
    return self.player:HasTrait("Pregnancy")
end

function PregnancyClass:getProgress()
    return self.data.PregnancyCurrent / self.data.PregnancyDuration
end

function PregnancyClass:onCheckLabor()
    if self.data.PregnancyCurrent > self.data.PregnancyDuration then
        self.player:getTraits():remove("Pregnancy")
        Events.EveryHours.Remove(self.onCheckLabor)
        triggerEvent("ZWBFPregnancyLabor", self)
    end
end

function PregnancyClass:onLabor()
    print("PregnancyClass:onLabor()")
end

function PregnancyClass:start()
    self.player:getTraits():add("Pregnancy")
    Events.EveryHours.Add(self.onCheckLabor)
end

function PregnancyClass:stop()
    self.player:getTraits():remove("Pregnancy")
    Events.EveryHours.Remove(self.onCheckLabor)
end

function PregnancyClass:advancePregnancy(hours)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + hours
end

function PregnancyClass:advanceToLabor()
    self.data.PregnancyCurrent = self.data.PregnancyDuration - 1
end

-- TODO: remove?
function PregnancyClass:getLaborProgress()
    return 0
end

-- TODO: remove?
function PregnancyClass:onFinishRecovery()
    print("REMOVE")
end

local Pregnancy = {}
Events.OnCreatePlayer.Add(
    function ()
        Pregnancy = PregnancyClass:new()
    end
)

LuaEventManager.AddEvent("ZWBFPregnancyLabor")
Events.ZWBFPregnancyLabor.Add(
    function(pregnancy)
        pregnancy:onLabor()
    end
)

return Pregnancy