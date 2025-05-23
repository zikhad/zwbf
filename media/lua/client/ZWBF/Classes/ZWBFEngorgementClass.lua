--- Localized global functions from PZ
local getActivatedMods = getActivatedMods
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events
local BodyPartType = BodyPartType
local LuaEventManager = LuaEventManager
local triggerEvent = triggerEvent
local getTexture = getTexture

--- This class handles the engorgement system
--- @class EngorgementClass
--- @field player table The player
--- @field Lactation table ZWBFLactation
--- @field isMF boolean Flag to check if MoodleFramework is activated
local EngorgementClass = {}
EngorgementClass.__index = EngorgementClass

--- EngorgementClass Constructor
--- This method will initialize the MoodleFramework if applicable
--- @param props table | nil The properties for the class
function EngorgementClass:new(props)
	props = props or {}
    local instance = setmetatable({}, EngorgementClass)
	instance.Lactation = props.Lactation or require("ZWBF/ZWBFLactation")
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

	local player = self.player
	local parseLvl = {
		["0.5"] = "1",
		["0.4"] = "1",
		["0.3"] = "2",
		["0.2"] = "3",
		["0.1"] = "4"
	}

	HaloTextHelper.addText(
		player,
		getText(string.format("Moodles_Engorgement_Bad_lvl%s", parseLvl[tostring(lvl)])),
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
	local player = self.player
	local torso = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Torso_Upper"))

	-- Define pain level mapping
	local painLevel = {
		["0.5"] = 0,
		["0.4"] = 0.25,
		["0.3"] = 0.5,
		["0.2"] = 0.75,
	   	["0.1"] = 1
	}

	-- inflict pain until the limit of 25 (minor pain)
	if torso:getAdditionalPain() < 25 then
		torso:setAdditionalPain(torso:getAdditionalPain() + painLevel[tostring(level)])
	end
end

--- EVENTS HANDLERS ---
EngorgementClass.Events = {}

--- Initializes Lactation when creating the player
--- @param player table The player Object
function EngorgementClass.Events:OnCreatePlayer(player)
	self.player = player
end

--- Update that should occur Ever Ten Minutes
function EngorgementClass.Events:EveryTenMinutes()
	local player = self.player
	if (
		not player:isFemale()
		or not self.Lactation:getIsLactating()
	)  then return end

	local fullness = self.Lactation:getMilkAmountPercentage()
	local level = self:getLevelFromPercentage(fullness)
	self:moodle(level)
	self:inflictPain(level)
	triggerEvent("ZWBFEngorgementEveryTenMinutes", self)
end

--- Register Events for EngorgementClass
function EngorgementClass.Events:register()
	-- Register default Events
	Events.OnCreatePlayer.Add(function(_, player) self.Events:OnCreatePlayer(player) end)
	Events.EveryTenMinutes.Add(function() self.Events:EveryTenMinutes() end)
	-- Register custom Events Listeners
	LuaEventManager.AddEvent("ZWBFEngorgementEveryTenMinutes")
end

return EngorgementClass
