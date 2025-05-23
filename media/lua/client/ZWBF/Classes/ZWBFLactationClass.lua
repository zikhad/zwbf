--- Localized global functions from PZ
local Events = Events
local ZombRand = ZombRand
local SandboxVars = SandboxVars
local triggerEvent = triggerEvent
local LuaEventManager = LuaEventManager

local SBVars = SandboxVars.ZWBF

--- This class handles the lactation system
--- @class LactationClass
--- @field SBvars table Sandbox variables for lactation
--- @field player table The player
--- @field data table Lactation data
--- @field CONSTANTS table Constants for lactation
--- @field Pregnancy table ZWBFPregnancy
--- @field Utils table ZWBFUtils
local LactationClass = {}
LactationClass.__index = LactationClass

LactationClass.SBvars = {
	MilkCapacity = 1000, -- Maximum amount of milk that can be stored
	MilkExpiration = 7,  -- Expiration in days
}

--- CONSTANTS
LactationClass.CONSTANTS = {
	AMOUNTS = {
		MIN = 0,   -- Minimum amount of milk produced
		MAX = 20   -- Maximum amount of milk produced
	},
	MAX_LEVEL = 5, -- Maximum level of milk
}

--- Initializes LactationClass
function LactationClass:new(props)
	props = props or {}
	local instance = setmetatable({}, LactationClass)

	instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
	instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")

	return instance
end

--- Updates the data on the player ModData
function LactationClass:update()
	self.player:getModData().ZWBFLactation = self.data
end

--- Remove Milk from the player
--- @param amount number the amount of milk to be removed from the player
function LactationClass:remove(amount)
	local data = self.data
	data.MilkAmount = math.max(0, data.MilkAmount - amount)
end

--- Set the lactation status
--- @param status boolean
function LactationClass:toggle(status)
	local data = self.data
	data.IsLactating = status
	if not data.IsLactating then
		data.MilkAmount = 0
		data.MilkMultiplier = 0
		data.Expiration = 0
	end
	triggerEvent("ZWBFLactationOnEveryToggle", self)
end

--- Use milk.
---
--- Handle milk usage (also affect multiplier and expiration)
--- @param amount number Amount of milk used
--- @param multiplier number | nil
--- @param expiration number | nil
function LactationClass:useMilk(amount, multiplier, expiration)
	local player = self.player
	local data = self.data

	-- Make sure to cap amount as the current Amount
	amount = math.max(amount, data.MilkAmount)
	data.MilkMultiplier = math.min(0, multiplier or 0)
	data.Expiration = 24 * (expiration or self.SBvars.MilkExpiration) -- (24h) * days

	-- Handle Player traits
	if player:HasTrait("DairyCow") then
		-- Add  25% of bonus to the multiplier if player has "Dairy cow" Trait
		data.MilkMultiplier = data.MilkMultiplier * 1.25;
		-- Add 25% of lactation time if player has "Dairy cow" Trait
		data.Expiration = data.Expiration * 1.25;
	end

	self:remove(amount)
	triggerEvent("ZWBFLactationUseMilk", self)
end

--- GETTERS & SETTERS ---
--- Returns the milk amount
--- @return number Womb.data.MilkAmount The amount of milk
function LactationClass:getMilkAmount()
	return self.data.MilkAmount
end

--- Returns the percentage 0-1 of current milk amount
function LactationClass:getMilkAmountPercentage()
	return self.data.MilkAmount / self.SBvars.MilkCapacity
end

--- Returns the image for lactation panel
--- @return string
function LactationClass:getImage()
	local isMilkFull = self.data.MilkAmount > (self.SBvars.MilkCapacity / 2)
	local fullness = isMilkFull and "full" or "empty"

	local imageName
	local isPregnant = self.Pregnancy:getIsPregnant()
	local progress = isPregnant and self.Pregnancy:getProgress() or 0

	if isPregnant and progress > 0.4 then
		local stage = (progress < 0.7) and "early" or "late"
		imageName = string.format("pregnant_%s_%s.png", stage, fullness)
	else
		imageName = string.format("normal_%s.png", fullness)
	end

	local skinColor = self.Utils:getSkinColor(self.player)
	return string.format("media/ui/lactation/boobs/color-%s/%s", skinColor, imageName)
end

--- Returns the image for the milk level
--- @return string
function LactationClass:getMilkLevelImage()
	local data = self.data
	local amount = (data.MilkAmount / self.SBvars.MilkCapacity) * 100
	local index = self.Utils:percentageToNumber(amount, self.CONSTANTS.MAX_LEVEL)
	return string.format("media/ui/lactation/level/milk_level_%s.png", index)
end

--- Returns if the player is lactating
--- @return boolean
function LactationClass:getIsLactating()
	return self.data.IsLactating
end

--- Get the amount needed to make a bottle
--- @return number
function LactationClass:getBottleAmount()
	return self.SBvars.MilkCapacity / self.CONSTANTS.MAX_LEVEL
end

--- Get The Milk Multiplier amount
--- @return number
function LactationClass:getMultiplier()
	return self.data.MilkMultiplier
end

--- EVENTS HANDLERS ---
LactationClass.Events = {}

--- Initializes Lactation when creating the player
--- @param player table The player Object
function LactationClass.Events:onCreatePlayer(player)
	local data = player:getModData().ZWBFLactation or {}

	-- setup SandboxVars
	self.SBvars.MilkCapacity = SBVars.MilkCapacity
	self.SBvars.MilkExpiration = SBVars.MilkExpiration

	-- setup data
	data.IsLactating = data.IsLactating or false
	data.MilkAmount = data.MilkAmount or 0
	data.MilkMultiplier = data.MilkMultiplier or 0
	data.Expiration = data.Expiration or 0

	self.player = player
	self.data = data
end

--- Update that should occur every hour
function LactationClass.Events:onEveryHours()
	local data = self.data
	if not data.IsLactating then return end

	local amount = ZombRand(self.CONSTANTS.AMOUNTS.MIN, self.CONSTANTS.AMOUNTS.MAX)
	local multiplier = 1 + data.MilkMultiplier

	data.MilkAmount = math.min(data.MilkAmount + (amount * multiplier), self.SBvars.MilkCapacity)
	data.MilkMultiplier = math.max(0, data.MilkMultiplier - 0.1)
	data.Expiration = math.max(0, data.Expiration - 1)

	if data.Expiration == 0 then
		self:toggle(false)
	end
end

--- Check if the player is pregnant and if the pregnancy is advanced enough to be lactating
function LactationClass.Events:onCheckPregnancy()
	if self.Pregnancy:getProgress() < 0.5 then return end

	self:toggle(true)
	self:useMilk(
		0,
		self.Pregnancy:getProgress()
	)
end

--- Register the events for LactationClass
function LactationClass.Events:register()
	-- Register custom Events Listeners
	LuaEventManager.AddEvent("ZWBFLactationOnEveryToggle")
	LuaEventManager.AddEvent("ZWBFLactationUseMilk")
	LuaEventManager.AddEvent("ZWBFLactationOnEveryHour")

	-- Add default Events Listeners
	Events.OnCreatePlayer.Add(function(_, player) self.Events:onCreatePlayer(player) end)
	Events.EveryOneMinute.Add(function() self:update() end)
	Events.EveryHours.Add(function() self.Events:onEveryHours() end)

	-- Add custom Events Listeners
	Events.ZWBFPregnancyProgressOneHour.Add(function(prenancy) self.Events:onCheckPregnancy() end)
end

--- DEBUG FUNCTIONS ---
LactationClass.Debug = {}

--- (DEBUG) Add Milk to the player
--- @param amount number amount to add (max of `MilkCapacity`)
function LactationClass.Debug:add(amount)
	local data = self.data
	data.MilkAmount = math.max(data.MilkAmount + amount, self.SBVars.MilkCapacity)
end

return LactationClass
