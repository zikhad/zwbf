-- Localized PZ variables
local Events = Events
local getActivatedMods = getActivatedMods


-- Add event listeners for ZomboWin Defeat
if getActivatedMods():contains("ZomboWinDefeatStrip") then
	Events.ZWBFWombOnEveryHours.Add(function(womb, amount)
		local player = womb.player
		local data = womb.data
		local storedAmount = data.SpermAmount

		-- Sexperiment trait, make infection 0 if there is sperm in the womb
		if player:HasTrait("unblessing") and storedAmount > 0 then
        	local bodyEffects = player:getBodyDamage();
        	bodyEffects:setInfectionLevel(0)
    	end

		-- Succucbus trait, if sperm is present in the womb, decrease hunger & fatigue, increase endurance
		if player:HasTrait("succubus") and storedAmount > 0 then
			local maxModifier = 0.2
			local scale = storedAmount / (data.SBVars.WombMaxCapacity * 10)
			local modifier = math.min(scale, maxModifier)
			local stats = player:getStats()

			stats:setHunger(stats:getHunger() - modifier)
			stats:setFatigue(stats:getFatigue() - modifier)
			stats:setEndurance(stats:getEndurance() + modifier)
		end
	end)
end