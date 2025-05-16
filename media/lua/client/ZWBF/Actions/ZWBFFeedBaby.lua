require "TimedActions/ISBaseTimedAction"

--- Localized global functions from PZ
local ISBaseTimedAction = ISBaseTimedAction
local getText = getText
local GameTime = GameTime
local getGametimeTimestamp = getGametimeTimestamp
local ZombRandFloat = ZombRandFloat

local Lactation = require("ZWBF/ZWBFLactation")

local ZWBFActionFeedBaby = ISBaseTimedAction:derive("ZWBFActionFeedBaby")

function ZWBFActionFeedBaby:isValid()
	return self.character:getInventory():contains(self.baby)
end

function ZWBFActionFeedBaby:update()
	self.baby:setJobDelta(self:getJobDelta())
end

function ZWBFActionFeedBaby:start()
	self.baby:setJobType(getText("ContextMenu_BreastFeed_Baby"))
	self.baby:setJobDelta(0.0)
	self:setActionAnim("FeedBaby")
	self:setOverrideHandModels(nil, self.baby)
	self.character:playSound("BreastfeedBaby")

    self:stopCrying()

end

function ZWBFActionFeedBaby:stop()
	ISBaseTimedAction.stop(self)
	self.baby:setJobDelta(0.0)
end

function ZWBFActionFeedBaby:stopCrying()
    local player = self.character

    local soundEmitter = player:getEmitter()
    if soundEmitter:isPlaying("Cry") then
        soundEmitter:stopSoundByName("Cry")
    end
end

function ZWBFActionFeedBaby:feedBaby()
    local player = self.character
    local item = self.baby

    local soundEmitter = player:getEmitter()
    local gameTime = GameTime.getInstance()
    local hour = gameTime:getHour()
    local currentTimestamp = getGametimeTimestamp()
    local feedTime = item:getModData().feedTime
    local isFirstFeeding = not feedTime

    if isFirstFeeding then
        item:getModData().feedTime = currentTimestamp
        if item:isRinging() then
            item:stopRinging()
        end
    else
        local timeSinceLastFeed = currentTimestamp - feedTime
        if timeSinceLastFeed < 14400 then -- 14400 = 4 hours
            player:Say(getText("IGUI_ZWBF_UI_Baby_Vomits"))
            return
        end
        item:setHour((hour + 6) % 24)
        item:getModData().feedTime = currentTimestamp
    end

    if not item:isAlarmSet() then
        item:setAlarmSet(true)
    end

    if soundEmitter:isPlaying("BreastfeedBaby") then
        soundEmitter:stopSoundByName("BreastfeedBaby")
    end

    -- self:stopCrying()

    if item:isRinging() then
        item:stopRinging()
    end
end

function ZWBFActionFeedBaby:perform()
	self.baby:getContainer():setDrawDirty(true)
	self.baby:setJobDelta(0.0)
	ISBaseTimedAction.perform(self)
	self:feedBaby()
    
    Lactation:useMilk(
        Lactation:getBottleAmount(),
        ZombRandFloat(0.1, 0.3)
    )
end

function ZWBFActionFeedBaby:new(character, baby)
	local o = setmetatable({}, self)
	self.__index = self
	o.character = character
	o.baby = baby
	o.maxTime = 1500
	o.stopOnWalk = false
	o.stopOnRun = false
	return o
end

return ZWBFActionFeedBaby
