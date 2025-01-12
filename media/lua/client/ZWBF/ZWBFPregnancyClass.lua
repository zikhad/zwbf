-- Localized global functions from PZ
local getPlayer = getPlayer
local SandboxVars = SandboxVars
local Events = Events
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent
local ZombRand = ZombRand
local ISTimedActionQueue = ISTimedActionQueue

-- local ZWBFActionGiveBirth = require("ZWBF/Actions/ZWBFActionGiveBirth")

local SBVars = SandboxVars.ZWBF



PregnancyClass = {}
PregnancyClass.__index = PregnancyClass

function PregnancyClass:new(name)
    local instance = setmetatable({}, PregnancyClass)
    local player = getPlayer()
    instance.name = name or "Pregnancy"
    -- instance.data.LaborProgress = instance.data.LaborProgress or SBVars.LaborMinimumDuration * 60 -- MINUTES
    -- instance.data.LaborProgress = instance.data.LaborProgress or 0
    -- player:getModData().ZWBFPregnancy = instance.data
    return instance
end

function PregnancyClass:init()
    print("ZWBF PregnancyClass:init()")
    if not self.player then
        print("why player does not exist?")
        return
     end

    self.data = self.player:getModData().ZWBFPregnancy or {}
    self.data.PregnancyDuration = self.data.PregnancyDuration or SBVars.PregnancyDuration * 24 -- HOURS
    self.data.PregnancyCurrent = self.data.PregnancyCurrent or 0
    self.data.InLabor = self.data.InLabor or false
    self.data.LaborProgress = 0
    if self.player:HasTrait("Pregnancy") then
        Events.EveryOneMinute.Add(OnCheckLabor)
    end
    print("ZWBF PregnancyClass:init() - END")
end

function PregnancyClass:update()
    self.player:getModData().ZWBFPregnancy = self.data
end

function PregnancyClass:onCreatePlayer()
    local player = getPlayer()
    self.player = player
    self:init()
end

function PregnancyClass:getIsPregnant()
    return self.player:HasTrait("Pregnancy")
end

function PregnancyClass:getProgress()
    return self.data.PregnancyCurrent / self.data.PregnancyDuration
end

function PregnancyClass:getInLabor()
    return self.data.InLabor;
end

function PregnancyClass:onCheckLabor()
    if not self.data then return end
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + 1

    if self.data.PregnancyCurrent > self.data.PregnancyDuration then
        Events.EveryOneMinute.Remove(OnCheckLabor)
        triggerEvent("ZWBFPregnancyLabor", self)
    end
    self:update()
end

function PregnancyClass:onLabor()
    self.data.InLabor = true
    self.data.PregnancyCurrent = 0
    -- triggerEvent("ZWBFPregnancyBirth", self)
    print("INFERNO!")
    ISTimedActionQueue.add(ZWBFActionBirth:new(self.player, self))
    print("ZWBF Pregnancy - PregnancyClass:onLabor() - animation should go here")
end

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
    print("ZWBF Pregnancy - PregnancyClass:onBirth() - birth should go here")
end

function PregnancyClass:start()
    print("PregnancyClass:start()")
    self.player:getTraits():add("Pregnancy")
    self:init()
    -- self.player:getModData().ZWBFPregnancy = self.data
    Events.EveryHours.Add(OnCheckLabor)
end

function PregnancyClass:stop()
    self.player:getTraits():remove("Pregnancy")
    self.data.PregnancyCurrent = 0
    self.data.InLabor = false
    self.data.LaborProgress = 0
    self:update()
    Events.EveryOneMinute.Remove(OnCheckLabor)
end

function PregnancyClass:advancePregnancy(hours)
    self.data.PregnancyCurrent = self.data.PregnancyCurrent + hours
end

function PregnancyClass:advanceToLabor()
    self.data.PregnancyCurrent = self.data.PregnancyDuration - 1
end

function PregnancyClass:setLaborProgress(progress)
    self.data.LaborProgress = progress
end

function PregnancyClass:getLaborProgress()
    return self.data.LaborProgress
end

-- TODO: remove?
function PregnancyClass:onFinishRecovery()
    print("ZWBF Pregnancy - REMOVE")
end

local Pregnancy = PregnancyClass:new()
function OnCheckLabor()
    Pregnancy:onCheckLabor()
end

Events.OnCreatePlayer.Add(
    function ()
        print("ZWBF Pregnancy - OnCreatePlayer")
        Pregnancy:onCreatePlayer()
    end
)

LuaEventManager.AddEvent("ZWBFPregnancyLabor")
Events.ZWBFPregnancyLabor.Add(
    function(pregnancy)
        print("ZWBF Pregnancy - ZWBFPregnancyLabor")
        pregnancy:onLabor()
    end
)

LuaEventManager.AddEvent("ZWBFPregnancyBirth")
Events.ZWBFPregnancyBirth.Add(
    function(pregnancy)
        print("ZWBF Pregnancy - ZWBFPregnancyBirth")
        pregnancy:onBirth()
    end
)

Events.EveryOneMinute.Add(
    function ()
        if not Pregnancy.data then return end
        print("Current: ", Pregnancy.data.PregnancyCurrent)
        print("Duration: ", Pregnancy.data.PregnancyDuration)
        print("InLabor: ", Pregnancy.data.InLabor)
        print("LaborProgress: ", Pregnancy.data.LaborProgress)
    end
)

return Pregnancy