--- Localized global functions from PZ
local getActivatedMods = getActivatedMods
local getPlayer = getPlayer
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events
local BodyPartType = BodyPartType

local Lactation = require("ZWBF/ZWBFLactation")

--- EngorgementClass
EngorgementClass = {}
EngorgementClass.__index = EngorgementClass
-- Reference to Lactation
EngorgementClass.Lactation = Lactation
-- Flag for MoodleFramework usage
EngorgementClass.isMF = false

--- EngorgementClass Constructor
--- This method will initialize the MoodleFramework if applicable
--- @param name string | nil Instance name
function EngorgementClass:new(name)
    local instance = setmetatable({}, EngorgementClass)
    instance.name = name or "Engorgement"
	
	if getActivatedMods():contains("MoodleFramework") == true then
		require "MF_ISMoodle"
		self.isMF = true
		MF.createMoodle("Engorgement")
	end

    return instance
end

--- Fallback method that will handle the moodle text when there is no MoodleFramework
--- @param percentage number The percentage for the moodle text
function EngorgementClass:noMoodleFramework(percentage)
	local player = getPlayer()
	if percentage < 0.1 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl1"), HaloTextHelper.getColorRed());
	elseif percentage < 0.5 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl2"), HaloTextHelper.getColorRed());
	elseif percentage < 0.75 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl3"), HaloTextHelper.getColorRed());
	else
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl4"), HaloTextHelper.getColorRed());
	end
end

--- This method will handle the moodle text with MoodleFramework
--- otherwise it will call the fallback
--- @param percentage number The percentage for the moodle text
function EngorgementClass:moodle(percentage)
	if not self.isMF then
		self:noMoodleFramework(percentage)
		return
	end
	local moodle = MF.getMoodle("Engorgement")
	moodle:setValue(percentage)
end

--- Inflict Pain in Upper Torso based on fullness
--- @param fullness number Percentage of Milk fullness
function EngorgementClass:inflictPain(fullness)
	local player = getPlayer()
	-- TODO: Apply some kind of pain on Torso_Upper
	local torso = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Torso_Upper"))
	local pain = 0
	if fullness < 0.25 then
		pain = 0
	elseif fullness < 0.25 then
		pain = 0.06
	elseif fullness < 0.75 then
		pain = 0.08
	else
		pain = 0.1
	end
	torso:setAdditionalPain(torso:getAdditionalPain() +pain)
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

end

local Engorgement = EngorgementClass:new()

-- Events.OnCreatePlayer.Add()
Events.EveryHours.Add(Engorgement.update)