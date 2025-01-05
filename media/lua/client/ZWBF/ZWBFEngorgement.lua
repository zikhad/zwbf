--- Localized global functions from PZ
local getActivatedMods = getActivatedMods
local getPlayer = getPlayer
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events
local BodyPartType = BodyPartType
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent

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
--- @return number
function EngorgementClass:getLevelFromPercentage(percentage)
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
--- @param percentage number The percentage for the moodle text
function EngorgementClass:moodle(percentage)
    -- Make sure percentage is in acceptable range
    percentage = percentage > 1 and 1 or percentage
	percentage = percentage < 0 and 0 or percentage

	-- Get the level from the percentage
	local lvl = self:getLevelFromPercentage(percentage)

    -- Log the moodle update
    print("Updating moodle with percentage: " .. percentage .. ", level: " .. lvl)

    -- Update moodle based on framework availability
	if not self.isMF then
        self:noMoodleFramework(lvl)
        return
    end

    local moodle = MF.getMoodle("Engorgement")
    moodle:setValue(lvl)
end

--- Inflict Pain in Upper Torso based on fullness
--- @param fullness number Percentage of Milk fullness
function EngorgementClass:inflictPain(fullness)
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
	
	local lvl = self:getLevelFromPercentage(fullness)
	
	torso:setAdditionalPain(torso:getAdditionalPain() + painLevel[tostring(lvl)])
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
	self:moodle(fullness)
	self:inflictPain(fullness);
	
	--- Trigger the event for other mods to listen
	triggerEvent("ZWBFEngorgementUpdate", fullness);

end

--- ZWBFEngorgement Events API
--- This will allow other mods to listen to the Engorgement pain infliction
LuaEventManager.AddEvent("ZWBFEngorgementUpdate")

--[[
	-- Example usage:
	Events.ZWBFEngorgementUpdate.Add(function(fullness)
		print("Engorgement Pain inflicted with fullness: " .. fullness)
	end)
]]

local Engorgement = EngorgementClass:new()

function OnEveryMinute()
	Engorgement:update()
end

-- Hook up event listeners
Events.EveryOneMinute.Add(OnEveryMinute)