require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
local getText = getText
local CharacterActionAnims = CharacterActionAnims

local Womb = require("ZWBF/ZWBFWomb")


ZWBFActionVaginalDouche = ISBaseTimedAction:derive("ZWBFActionVaginalDouche")

function ZWBFActionVaginalDouche:isValid()
	return self.character:getInventory():contains(self.douche)
end

function ZWBFActionVaginalDouche:update()
	self.douche:setJobDelta(self:getJobDelta())
end

function ZWBFActionVaginalDouche:start()
	self.douche:setJobType(getText("ContextMenu_Clean_Sperm"))
	self.douche:setJobDelta(0.0)
	self:setActionAnim(CharacterActionAnims.Bandage)
	self:setOverrideHandModels(nil, self.douche)
end

function ZWBFActionVaginalDouche:stop()
	ISBaseTimedAction.stop(self)
	self.douche:setJobDelta(0.0)
end

function ZWBFActionVaginalDouche:perform()
	self.douche:getContainer():setDrawDirty(true)
	self.douche:setJobDelta(0.0)
	ISBaseTimedAction.perform(self)
	Womb:setSpermAmount(0);
end

function ZWBFActionVaginalDouche:new(character, item)
	local o = setmetatable({}, self)
	self.__index = self
	o.character = character
	o.douche = item
	o.maxTime = 1000
	o.stopOnWalk = true
	o.stopOnRun = true
	return o
end
