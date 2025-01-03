--- Localized global functions from PZ
local getActivatedMods = getActivatedMods
local getPlayer = getPlayer
local HaloTextHelper = HaloTextHelper
local getText = getText
local Events = Events

local Lactation = require("ZWBF/ZWBFLactation")

--- EngorgementClass
EngorgementClass = {}
EngorgementClass.__index = EngorgementClass
EngorgementClass.Lactation = Lactation
EngorgementClass.isMF = false

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

function EngorgementClass:noMoodleFramework(amount)
	local player = getPlayer()
	local milkPercentage = self.Lactation:getMilkAmountPercentage()
	if milkPercentage < 0.1 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl1"), HaloTextHelper.getColorRed());
	elseif milkPercentage < 0.5 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl2"), HaloTextHelper.getColorRed());
	elseif milkPercentage < 0.75 then
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl3"), HaloTextHelper.getColorRed());
	else
		HaloTextHelper.addText(player, getText("Moodles_Engorged_Bad_desc__lvl4"), HaloTextHelper.getColorRed());
	end
end

function EngorgementClass:moodle(amount)
	if not self.isMF then
		self:noMoodleFramework(amount)
		return
	end
	local moodle = MF.getMoodle("Engorgement")
	moodle:setValue(amount)
end

function EngorgementClass:update()
	local player = getPlayer();
	if (
		player:isNPC()
		or not player:isFemale()
		or not self.Lactation:getIsLactating()
	)  then return end
	
	self:moodle(
		self.Lactation:getMilkAmountPercentage()
	)

end

local Engorgement = EngorgementClass:new()

-- Events.OnCreatePlayer.Add()
Events.EveryHours.Add(Engorgement.update)