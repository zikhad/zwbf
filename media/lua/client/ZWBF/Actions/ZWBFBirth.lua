require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
-- local getText = getText
-- local CharacterActionAnims = CharacterActionAnims
local triggerEvent = triggerEvent

-- local Womb = require("ZWBF/ZWBFWomb")

--- This file creates the Timed Action for when Birth occurs
ZWBFActionBirth = ISBaseTimedAction:derive("ZWBFActionBirth")

function ZWBFActionBirth:isValid()
	return true
end

function ZWBFActionBirth:update()
    self.pregnancy:setLaborProgress(self:getJobDelta())
	self.pregnancy:onLaborUpdate()
end

function ZWBFActionBirth:start()
	self:setActionAnim("blabla_Birthing")
end

function ZWBFActionBirth:stop()
	ISBaseTimedAction.stop(self)
end

function ZWBFActionBirth:perform()
	ISBaseTimedAction.perform(self)
	self.pregnancy:onBirth()
end

--- comment
--- @param pregnancy any
--- @return table
function ZWBFActionBirth:new(pregnancy)
    print("ZWBFActionBirth:new()")
	local instance = setmetatable({}, self)
	self.__index = self
	instance.character = pregnancy.player
    instance.pregnancy = pregnancy
	instance.maxTime = 5500
	instance.stopOnWalk = false
	instance.stopOnRun = false
	return instance
end
