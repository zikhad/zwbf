require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
-- local getText = getText
local CharacterActionAnims = CharacterActionAnims
local triggerEvent = triggerEvent

-- local Womb = require("ZWBF/ZWBFWomb")

--- This file creates the Timed Action for when contraceptive is taken 
ZWBFActionBirth = ISBaseTimedAction:derive("ZWBFActionBirth")
    
function ZWBFActionBirth:isValid()
	return true
end

function ZWBFActionBirth:update()
    -- print("ZWBFActionBirth:update()" .. tostring())
	-- self.pregnancy:setJobDelta(self:getJobDelta())
    self.pregnancy:setLaborProgress(self:getJobDelta())
	triggerEvent("ZWBFPregnancyLaborUpdate", self.pregnancy)
end

function ZWBFActionBirth:start()
	-- self.pills:setJobType(getText("ContextMenu_Take_Contraceptive"))
	-- self.pregnancy:setJobDelta(0.0)
	-- TODO: Add custom animation here
	self:setActionAnim(--[[ CharacterActionAnims.TakePills]] "Yonchi_breastpump")
    -- TODO: Add the custom animation
	-- self:setOverrideHandModels(nil, self.pills)
	-- self.character:playSound("Pills_A")
end

function ZWBFActionBirth:stop()
	ISBaseTimedAction.stop(self)
	-- self.pregnancy:setJobDelta(0.0)
end

function ZWBFActionBirth:perform()
	-- self.pills:getContainer():setDrawDirty(true)
	-- self.pregnancy:setJobDelta(0.0)
	-- self.pills:Use()
	ISBaseTimedAction.perform(self)
    -- self.pregnancy:onBirth()
    triggerEvent("ZWBFPregnancyBirth", self.pregnancy)
	-- Womb:setContraceptive(true)
end

function ZWBFActionBirth:new(character, pregnancy)
    print("ZWBFActionBirth:new()")
	local o = setmetatable({}, self)
	self.__index = self
	o.character = character
    o.pregnancy = pregnancy
	-- o.pills = pills
	o.maxTime = 1000
	o.stopOnWalk = false
	o.stopOnRun = false
	return o
end
