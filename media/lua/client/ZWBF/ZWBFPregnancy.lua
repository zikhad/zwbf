--- Localized global functions from PZ
local getPlayer = getPlayer
local SandboxVars = SandboxVars
local Events = Events
local ZombRand = ZombRand
local isDebugEnabled = isDebugEnabled

--- VARIABLES
local SBvars = SandboxVars.Pregnancy
local Pregnancy = {}

local function pickRandomBaby()
	local babies = {
		"Baby_01_b", "Baby_02", "Baby_02_b", "Baby_03", "Baby_03_b", "Baby_07",
		"Baby_07_b", "Baby_08", "Baby_08_b", "Baby_09", "Baby_09_b", "Baby_10",
		"Baby_10_b", "Baby_11", "Baby_11_b", "Baby_12", "Baby_12_b", "Baby_13",
		"Baby_14"
	}
	return babies[ZombRand(1, #babies)]
end

--- PREGRNANCY MOD FUNCTIONS
--- These functions are used to manage the pregnancy mod.
--- Since that mod only apply itself in the game start
--- We need to replicate the needed values to enable the mod
--- until the next restart.

--- Pregnancy duration is randomized to a value between the PregnancyDuration and PregnancyDurationRandomization
--- @return number
local function randomizePregnancyDuration()
	local duration = SBvars.PregnancyDuration * 24
	if SBvars.PregnancyDuration <= SBvars.PregnancyDurationRandomization then
		return duration
	end
	duration = duration - SBvars.PregnancyDurationRandomization * 24
	local randomValue = ZombRand(SBvars.PregnancyDurationRandomization * 2 * 24)
	return duration + randomValue
end

--- Labor duration is randomized to a value between the LaborMinimumDuration and LaborMaximumDuration
--- @return number
local function randomizeLaborDuration()
	local duration = SBvars.LaborMinimumDuration * 60
	if SBvars.LaborMaximumDuration <= SBvars.LaborMinimumDuration then
		return duration
	end
	local randomDuration = SBvars.LaborMaximumDuration - SBvars.LaborMinimumDuration
	local randomValue = ZombRand(randomDuration * 60)
	return duration + randomValue
end

--- Labor second stage duration is randomized to a value between the LaborSecondStageMinimumDuration and LaborSecondStageMaximumDuration
--- @return number
local function randomizeLaborSecondStageDuration()
	local duration = SBvars.LaborSecondStageMinimumDuration
	if SBvars.LaborSecondStageMaximumDuration <= SBvars.LaborSecondStageMinimumDuration then
		return duration
	end
	local randomDuration = SBvars.LaborSecondStageMaximumDuration - SBvars.LaborSecondStageMinimumDuration
	local randomValue = ZombRand(randomDuration)
	return duration + randomValue
end

--- (DEBUG) Print the pregnancy mod data
local function info()
	if isDebugEnabled() then
		local player = getPlayer()
		local modData = player:getModData().Pregnancy or {}
		print("--------------")
		print("HoursToLabor:" .. (modData.HoursToLabor or 0))
		print("CurrentLaborDuration: " .. (modData.CurrentLaborDuration or 0))
		print("ExpectedLaborDuration: " .. (modData.ExpectedLaborDuration or 0))
		print("InitialPregnancyDuration: " .. (modData.InitialPregnancyDuration or 0))
		print("Progress: " .. 1 - (modData.HoursToLabor or 0) / (modData.InitialPregnancyDuration or 1))
	end
end

--- This function is called every hour to update the pregnancy mod data ultil the next restart
local function beforeRestartUpdate()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	if modData.HoursToLabor < 48 then
		modData.HoursToLabor = 48
	end
	modData.HoursToLabor = modData.HoursToLabor - 1
	info()
end

--- This function will check about the Birth outcome
--- This will be checked every minute ultil player receive the Traits "PregnancySuccess" or "PregnancyFail"
local function onBirthOutcome()
	local player = getPlayer()
	if player:HasTrait("PregnancySuccess") then
		player:getInventory():AddItem("Babies." .. pickRandomBaby())
		Events.EveryOneMinute.Remove(onBirthOutcome)
	elseif player:HasTrait("PregnancyFail") then
		Events.EveryOneMinute.Remove(onBirthOutcome)
	end
end

--- This function will check if the player is in labor
local function onCheckLabor()
	info()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	if modData.CurrentLaborDuration >= modData.ExpectedLaborDuration then
		Events.EveryOneMinute.Remove(onCheckLabor)
		Events.EveryOneMinute.Add(onBirthOutcome)
	end
end

--- This function will check if the player is in labor
--- @return boolean
function Pregnancy:getInLabor()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	return modData.InLabor
end

--- This function will return the labor progress (useful for UI changes)
--- @return number
function Pregnancy:getLaborProgress()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	return modData.CurrentLaborDuration / modData.ExpectedLaborDuration
end

--- This function will return the pregnancy progress (useful for UI changes)
--- @return number
function Pregnancy:getProgress()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy
	info()
	return 1 - modData.HoursToLabor / modData.InitialPregnancyDuration
end

--- This function will return if the player is pregnant
--- @return boolean
function Pregnancy:getIsPregnant()
	local player = getPlayer()
	return player:HasTrait("Pregnancy")
end

--- (DEBUG) Advance the pregnancy by x hours
--- @param hours integer
function Pregnancy:advancePregnancy(hours)
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	if modData.HoursToLabor > 24 then
		print("ZWBF - Pregnancy - Advance 24h")
		modData.HoursToLabor = modData.HoursToLabor - 24
	else
		print("ZWBF - Pregnancy - Too close to labor to advance 24h")
	end
end

--- (DEBUG) Advance the pregnancy to labor
function Pregnancy:advanceToLabor()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	modData.HoursToLabor = 1
	print("ZWBF - Pregnancy - Advanced to 24h prior labor")
end

--- This function will remove the Traits "PregnancySuccess" and "PregnancyFail" from the player
--- Should be called after the recovery time
function Pregnancy:onFinishRecovery()
	local player = getPlayer()
	if player:HasTrait("PregnancySuccess") or player:HasTrait("PregnancyFail") then
		player:getTraits():remove("PregnancyFail")
		player:getTraits():remove("PregnancySuccess")
	end
end

--- This function will start the Pregnancy
--- It is the same as Pregnancy Mod, since the mod only works in when the game starts
function Pregnancy:start()
	local player = getPlayer()
	local modData = player:getModData().Pregnancy or {}
	modData.HoursToLabor = randomizePregnancyDuration()
	modData.InitialPregnancyDuration = modData.HoursToLabor
	modData.InLabor = false
	modData.CurrentLaborDuration = 0
	modData.ExpectedLaborDuration = randomizeLaborDuration()
	modData.SecondStageStart = modData.ExpectedLaborDuration - randomizeLaborSecondStageDuration()
	
	modData.timeSinceLastScream = 0
	modData.chanceToScream = 5
	
	modData.MentalStateLastHour = {}
	modData.MentalStateLast24Hours = {}
	
	modData.ConsumedAlcohol = false
	modData.Smoked = false
	
	modData.DelayedFitnessHoursLeft = 24 * 14 + ZombRand(24 * 14)

	player:getTraits():add("Pregnancy")
	Events.EveryOneMinute.Add(onCheckLabor)
	Events.EveryHours.Add(beforeRestartUpdate)
	player:getModData().Pregnancy = modData
	print("ZWBF - Pregnancy - Trait added")
	info()
end

--- (DEBUG) This function will stop the Pregnancy
function Pregnancy:stop()
	local player = getPlayer()
	player:getTraits():remove("Pregnancy")
	Events.EveryHours.Remove(beforeRestartUpdate)
	Events.EveryOneMinute.Remove(onCheckLabor)
	print("ZWBF - Pregnancy - Trait removed")
end

--- Initialize the Pregnancy track for ZWBF
--- Useful if the Pregnancy:start is called or when the game starts
function Pregnancy:init()
	local player = getPlayer()
	if player:HasTrait("Pregnancy") then
		Events.EveryOneMinute.Add(onCheckLabor)
	end
end

--- Hook up event listeners
Events.OnCreatePlayer.Add(Pregnancy.init)

return Pregnancy
