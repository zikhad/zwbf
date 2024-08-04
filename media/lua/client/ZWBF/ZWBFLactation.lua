--- Localized global functions from PZ
local getPlayer = getPlayer
local Events = Events
local ZombRand = ZombRand
local isDebugEnabled = isDebugEnabled

--- VARIABLES
local Utils = require("ZWBF/ZWBFUtils")
local Pregnancy = require("ZWBF/ZWBFPregnancy")

local Lactation = {}
Lactation.data = {
	IsLactating = false,
	MilkAmount = 0,
	MilkMultiplier = 0,
	Expiration = 0,
}

--- CONSTANTS
Lactation.CONSTANTS = {
	AMOUNTS = {
		MIN = 0,
		MAX = 20
	},
	MAX_CAPACITY = 1000,
	MAX_LEVEL = 5,
	EXPIRATION = 7,
}

--- Updates the data
function Lactation:update()
	local player = getPlayer()
	local data = Lactation.data
	data.MilkAmount = (data.MilkAmount > 0) and data.MilkAmount or 0
	data.MilkMultiplier = (data.MilkMultiplier > 0) and data.MilkMultiplier or 0
	data.IsLactating = data.IsLactating or false
	data.Expiration = (data.Expiration > 0) and data.Expiration or 0

	player:getModData().ZWBFLactation = data
end

--- Add expiration to the lactation
--- @param days integer
function Lactation:addExpiration(days)
	local data = Lactation.data
	data.Expiration = 60 * 24 * days
end

--- Initializes the Lactation
function Lactation:init()
	local player = getPlayer()
	local data = player:getModData().ZWBFLactation or {}
	
	data.IsLactating = data.IsLactating or false
	data.MilkAmount = data.MilkAmount or 0
	data.MilkMultiplier = data.MilkMultiplier or 0
	data.Expiration = data.Expiration or 0
	
	Lactation.data = data
	
	Lactation:update()
end

--- Returns the milk amount
--- @return integer Womb.data.MilkAmount The amount of milk
function Lactation:getMilkAmount()
	local data = Lactation.data
	return data.MilkAmount
end

--- Returns the image for the boobs
--- @return string
function Lactation:getBoobImage()
	local data = Lactation.data
	local fullness = (data.MilkAmount > (Lactation.CONSTANTS.MAX_CAPACITY / 2)) and "full" or "empty"
	if Pregnancy:getIsPregnant() and Pregnancy:getProgress() > 0.4 then
		local stage = (Pregnancy:getProgress() < 0.7) and "early" or "late"
		return string.format("media/ui/lactation/boobs/pregnant_%s_%s.png", stage, fullness)
	end
	return string.format("media/ui/lactation/boobs/%s_%s.png", "normal", fullness)
end

--- Returns the image for the milk level
--- @return string
function Lactation:getMilkLevelImage()
	local data = Lactation.data
	local amount = (data.MilkAmount / Lactation.CONSTANTS.MAX_CAPACITY) * 100
	local index = Utils:percentageToNumber(amount, Lactation.CONSTANTS.MAX_LEVEL)
	return string.format("media/ui/lactation/level/milk_level_%s.png", index)
end

--- Returns if the player is lactating
--- @return boolean
function Lactation:getIsLactating()
	local data = Lactation.data
	return data.IsLactating
end

--- Add Milk to the player, useful for DEBUG
--- @param amount any
function Lactation:add(amount)
	local data = Lactation.data
	data.MilkAmount = data.MilkAmount + amount
end

--- Remove Milk from the player
--- @param amount any
function Lactation:remove(amount)
	local data = Lactation.data
	data.MilkAmount = data.MilkAmount - amount
	Lactation:update()
end

--- Get the amount needed to make a bottle
--- @return number
function Lactation:getBottleAmount()
	return Lactation.CONSTANTS.MAX_CAPACITY / Lactation.CONSTANTS.MAX_LEVEL
end

--- Clear the milk amount, useful for DEBUG
function Lactation:clear()
	local data = Lactation.data
	data.MilkAmount = 0
end

--- Set the lactation status
--- @param status boolean
function Lactation:set(status)
	local data = Lactation.data
	data.IsLactating = status
end

--- Set the multiplier for the milk
--- @param multiplier number
function Lactation:setMultiplier(multiplier)
	local data = Lactation.data
	data.MilkMultiplier = multiplier
end

--- Get The Milk Multiplier amount
--- @return number
function Lactation:getMultiplier()
	local data = Lactation.data
	return data.MilkMultiplier
end

--- Update that should occur every hour
local function onEveryHour()
	local data = Lactation.data
	if not data.IsLactating then return end
	
	local amount = ZombRand(Lactation.CONSTANTS.AMOUNTS.MIN, Lactation.CONSTANTS.AMOUNTS.MAX)
	local multiplier = 1 + data.MilkMultiplier
	data.MilkAmount = (data.MilkAmount + amount) * multiplier
	data.MilkMultiplier = data.MilkMultiplier - 0.1
	data.MilkAmount = (data.MilkAmount < 0) and 0 or data.MilkAmount
	if data.MilkAmount > Lactation.CONSTANTS.MAX_CAPACITY then
		data.MilkAmount = Lactation.CONSTANTS.MAX_CAPACITY
	end
end

--- Check if the player is pregnant and if the pregnancy is advanced enough to be lactating
local function onCheckPregnancy()
	local data = Lactation.data
	if Pregnancy:getIsPregnant() and Pregnancy:getProgress() > 0.4 then
		Lactation:set(true)
		Lactation:setMultiplier(1 + Pregnancy:getProgress())
		Lactation:addExpiration(Lactation.CONSTANTS.EXPIRATION)
		Lactation:set(true)
	end
end

--- Update that should occur every minute
local function onEveryMinute()
	Lactation:update()
	if isDebugEnabled() then
		local data = Lactation.data
		print("----------")
		print("ZWBF - Lactation - onEveryMinute")
		print("IsLactating: " .. tostring(data.IsLactating))
		print("MilkAmount: " .. tostring(data.MilkAmount))
		print("MilkMultiplier: " .. tostring(data.MilkMultiplier))
		print("Expiration: " .. tostring(data.Expiration))
	end
end

--- Check if the expiration is over and remove lactation if it is
local function onCheckExpiration()
	local data = Lactation.data
	if data.Expiration > 0 then
		data.Expiration = data.Expiration - 1
		if data.Expiration <= 0 then
			data.IsLactating = false
			data.MilkMultiplier = 0
			data.Expiration = 0
		end
	end
end

--- Hook up event listeners
Events.OnCreatePlayer.Add(Lactation.init)
Events.EveryHours.Add(onEveryHour)
Events.EveryHours.Add(onCheckExpiration)
Events.EveryOneMinute.Add(onEveryMinute)
Events.EveryOneMinute.Add(onCheckPregnancy)

return Lactation
