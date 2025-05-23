--- Localized global functions from PZ
local getActivatedMods = getActivatedMods
local getPlayer = getPlayer
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events
local BodyPartType = BodyPartType
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent
local getTexture = getTexture

local Lactation = require("ZWBF/ZWBFLactation")

--- EngorgementClass
--- This class will handle the Engorgement moodle and pain infliction
EngorgementClass = {}
EngorgementClass.__index = EngorgementClass

--- EngorgementClass Constructor
--- This method will initialize the MoodleFramework if applicable
--- @param name string | nil Instance name
function EngorgementClass:new(name)
    local instance = setmetatable({}, EngorgementClass)
    instance.name = name or "Engorgement"
	instance.Lactation = Lactation
	instance.isMF = false
	
	if getActivatedMods():contains("MoodleFramework") == true then
		require "MF_ISMoodle"
		instance.isMF = true
		MF.createMoodle("Engorgement")
	end

    return instance
end

--- Fallback method that will handle the moodle text when there is no MoodleFramework
--- @param lvl number The level for the moodle text
function EngorgementClass:noMoodleFramework(lvl)
	if lvl == 0.5 then
		return
	end
	
	local player = getPlayer()
	local parseLvl = {
		["0.5"] = "1",
		["0.4"] = "1",
		["0.3"] = "2",
		["0.2"] = "3",
		["0.1"] = "4"
	}

	HaloTextHelper.addText(
		player,
		getText("Moodles_Engorgement_Bad_desc_lvl3" .. parseLvl[tostring(lvl)]),
		HaloTextHelper.getColorRed()
	)
end

--- Get the fullness level from the percentage.
--- This will determine the moodle AND the amount of additional pain
--- @param percentage number
--- @return number moodleLevel 0.5 | 0.4 | 0.3 | 0.2 | 0.1
function EngorgementClass:getLevelFromPercentage(percentage)
	 -- Make sure percentage is in acceptable range
	 percentage = percentage > 1 and 1 or percentage
	 percentage = percentage < 0 and 0 or percentage
	
	 -- Define level mapping
	local levelMapping = {
		{0.5, 0.5},
		{0.6, 0.4},
		{0.7, 0.3},
		{0.8, 0.2},
		{1, 0.1}
	}

	-- Determine level
	local lvl = 0.5
	for _, mapping in ipairs(levelMapping) do
		if percentage <= mapping[1] then
			lvl = mapping[2]
			break
		end
	end

	return lvl
end

--- This method will handle the moodle text with MoodleFramework
--- otherwise it will call the fallback
--- @param level number The percentage for the moodle text
function EngorgementClass:moodle(level)
    -- Update moodle based on framework availability
	if not self.isMF then
        self:noMoodleFramework(level)
        return
    end

    local moodle = MF.getMoodle("Engorgement")
    moodle:setValue(level)
	moodle:setPicture(
	moodle:getGoodBadNeutral(),
		moodle:getLevel(),
		getTexture("media/ui/Moodles/Engorgement.png")
	);
end

--- Inflict Pain in Upper Torso based on fullness
--- @param level number Percentage of Milk fullness
function EngorgementClass:inflictPain(level)
	-- Get the player and torso
	local player = getPlayer()
	local torso = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Torso_Upper"))
	
	-- Define pain level mapping
	local painLevel = {
		["0.5"] = 0,
		["0.4"] = 0.25,
		["0.3"] = 0.5,
		["0.2"] = 0.75,
	   	["0.1"] = 1
	}
	
	-- inflict pain until the limit of 50 (pain)
	if (torso:getAdditionalPain() < 50)
	then
		torso:setAdditionalPain(torso:getAdditionalPain() + painLevel[tostring(level)])
	end
end

--- Update engorgement
--- This method should be called periodically
function EngorgementClass:update()
	local player = getPlayer()
	if (
		player:isNPC()
		or not player:isFemale()
		or not self.Lactation:getIsLactating()
	)  then return end

	local fullness = self.Lactation:getMilkAmountPercentage()
	local level = self:getLevelFromPercentage(fullness)
	self:moodle(level)
	self:inflictPain(level)
	
	--- Trigger the event for other mods to listen
	triggerEvent("ZWBFEngorgementUpdate", level, fullness);

end

--- ZWBFEngorgement Events API
--- This will allow other mods to listen to the Engorgement pain infliction
LuaEventManager.AddEvent("ZWBFEngorgementUpdate")
--[[
	-- Example usage:
	Events.ZWBFEngorgementUpdate.Add(function(level, fullness)
		print("Engorgement Pain inflicted with level: " .. level .. " fullness: " .. fullness)
	end)
]]

local Engorgement = EngorgementClass:new()

function OnEveryMinute()
	Engorgement:update()
end

-- Hook up event listeners
Events.EveryOneMinute.Add(OnEveryMinute)