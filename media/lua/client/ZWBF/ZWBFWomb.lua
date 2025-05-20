-- Localized PZ variables
local Events = Events
local getActivatedMods = getActiveMods

local WombClass = require("ZWBF/Classes/ZWBFWombClass")

local Womb = WombClass:new()

Womb:registerEvents()

-- Add event listeners for ZomboWin Defeat
if getActivatedMods():contains("ZomboWinDefeatStrip") then
	-- Sexperiment trait, make infection 0 if there is sperm in the womb
	Events.ZWBFWombOnEveryHours.Add(function(womb, amount)
		local player = womb.player
		local data = womb.data
		if player:HasTrait("unblessing") and data.SpermAmount > 0 then
        	local bodyEffects = player:getBodyDamage();
        	bodyEffects:setInfectionLevel(0)
    	end
	end)
end

return Womb
