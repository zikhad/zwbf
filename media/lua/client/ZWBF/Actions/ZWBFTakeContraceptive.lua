require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
local getText = getText
local CharacterActionAnims = CharacterActionAnims

local Womb = require("ZWBF/ZWBFWomb")

--- This file creates the Timed Action for when contraceptive is taken
local ZWBFActionTakeContraceptive = ISBaseTimedAction:derive("ZWBFActionTakeContraceptive")

function ZWBFActionTakeContraceptive:isValid()
	return self.character:getInventory():contains(self.pills)
end

function ZWBFActionTakeContraceptive:update()
	self.pills:setJobDelta(self:getJobDelta())
end

function ZWBFActionTakeContraceptive:start()
	self.pills:setJobType(getText("ContextMenu_Take_Contraceptive"))
	self.pills:setJobDelta(0.0)
	self:setActionAnim(CharacterActionAnims.TakePills)
	self:setOverrideHandModels(nil, self.pills)
	self.character:playSound("Pills_A")
end

function ZWBFActionTakeContraceptive:stop()
	ISBaseTimedAction.stop(self)
	self.pills:setJobDelta(0.0)
end

function ZWBFActionTakeContraceptive:perform()
	self.pills:getContainer():setDrawDirty(true)
	self.pills:setJobDelta(0.0)
	self.pills:Use()
	ISBaseTimedAction.perform(self)
	Womb:setContraceptive(true)
end

function ZWBFActionTakeContraceptive:new(character, pills)
	local o = setmetatable({}, self)
	self.__index = self
	o.character = character
	o.pills = pills
	o.maxTime = 100
	o.stopOnWalk = false
	o.stopOnRun = false
	return o
end

return ZWBFActionTakeContraceptive
