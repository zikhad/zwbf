require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
local getText = getText
local CharacterActionAnims = CharacterActionAnims
local ZombRandFloat = ZombRandFloat

local Lactation = require("ZWBF/ZWBFLactation")

--- This file creates the Timed Action for when lactaid is taken
local ZWBFActionTakeLactaid = ISBaseTimedAction:derive("ZWBFActionTakeLactaid")

function ZWBFActionTakeLactaid:new(character, pills)
	local instance = setmetatable({}, self)
	self.__index = self
	instance.character = character
	instance.pills = pills
	instance.maxTime = 100
	instance.stopOnWalk = false
	instance.stopOnRun = false
	return instance
end

function ZWBFActionTakeLactaid:isValid()
	return self.character:getInventory():contains(self.pills)
end

function ZWBFActionTakeLactaid:update()
	self.pills:setJobDelta(self:getJobDelta())
end

function ZWBFActionTakeLactaid:start()
	self.pills:setJobType(getText("ContextMenu_Take_Lactaid"))
	self.pills:setJobDelta(0.0)
	self:setActionAnim(CharacterActionAnims.TakePills)
	self:setOverrideHandModels(nil, self.pills)
	self.character:playSound("Pills_A")
end

function ZWBFActionTakeLactaid:stop()
	ISBaseTimedAction.stop(self)
	self.pills:setJobDelta(0.0)
end

function ZWBFActionTakeLactaid:perform()
	self.pills:getContainer():setDrawDirty(true)
	self.pills:setJobDelta(0.0)
	self.pills:Use()

	ISBaseTimedAction.perform(self)
	if not Lactation:getIsLactating() then
		Lactation:set(true)
	end

	Lactation:useMilk(
		0,
		Lactation:getMultiplier() + ZombRandFloat(0, 0.3)
	)
end

return ZWBFActionTakeLactaid
