--- WombFill Events
--- These events will be triggered when ZomboWin Action is performed
--- @autor Zikhad 2024

--- CONSTANTS
local MIN_AMOUNT = 10
local MAX_AMOUNT = 50

--- Localized global functions from PZ
local getText = getText
local HaloTextHelper = HaloTextHelper
local getPlayer = getPlayer
local ZombRand = ZombRand
local ZombRandFloat = ZombRandFloat

--- ZomboWin Variables
local ZomboWin = require("ZomboWin/ZomboWin")
local ActionEvents = ZomboWin.AnimationHandler.ActionEvents

local Utils = require("ZWBF/ZWBFUtils")

--- VARIABLES
local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Womb = require("ZWBF/ZWBFWomb")

--- LOCAL FUNCTIONS

--- Handles impregnation
local function impregnate()
	local character = getPlayer()
	if (
		Pregnancy:getIsPregnant() or
		Womb:getOnContraceptive() or
		character:HasTrait("Infertile")
	) then return end
	
	local fertility = Womb:getFertility()
	if ZombRandFloat(0, 1) > (1 - fertility) then
		local text = getText("IGUI_ZWBF_UI_Fertilized")
		HaloTextHelper.addText(character, text, HaloTextHelper.getColorGreen())
		Pregnancy:start()
	end
end

--- Inject sperm into the player's womb
local function injectSperm()

	local character = getPlayer()
	
	if not character:isFemale() then return end

	local amount = ZombRand(MIN_AMOUNT, MAX_AMOUNT) -- Random amount between MIN and MAX
		
	-- show a Halo Text with the amount of sperm injected
	local text = string.format("%s %sml", getText("IGUI_ZWBF_UI_Sperm"), amount)
	HaloTextHelper.addTextWithArrow(character, text, true, HaloTextHelper.getColorGreen())

	-- TODO: test this!
	if (Utils.Iventory:hasItem("Condom", character)) then
		local iventory = character:getIventory()
		iventory:Remove("Condom")
		iventory:AddItem("CondomUsed", 1)
	else
		Womb:addSperm(amount)
		impregnate()
	end


end

--- Add the event to the ActionEvents
table.insert(
	ActionEvents.Perform,
	function(action)
		local character = action.character
		if not character:isFemale() then return end
		if Utils.Animation:isAllowed(character) then
			injectSperm()
		end
	end
)
