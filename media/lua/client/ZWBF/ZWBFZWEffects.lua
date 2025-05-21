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
			local stats = player:getStats()
			-- TODO: increase the amount recovered based on the amount held
			-- local amount = ZombRand(15 + math.floor(storedAmount / 50)) * 0.01
			stats:setHunger(stats:getHunger() - 0.040)
			stats:setFatigue(stats:getFatigue() - 0.040)
			stats:setEndurance(stats:getEndurance() + 0.040)
		end

	end)
end