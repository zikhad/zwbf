--- Localized global functions from PZ
local getText = getText
local getPlayer = getPlayer
local getSpecificPlayer = getSpecificPlayer
local isDebugEnabled = isDebugEnabled
local Events = Events
local ISContextMenu = ISContextMenu


local NewUI = NewUI

local CharacterInfoTabManager = require("ZWBF/ZWBFCharacterInfoTabManager")

-- VARIABLES
local UI
local Utils = require("ZWBF/ZWBFUtils")
local Womb = require("ZWBF/ZWBFWomb")
local Pregnancy = require("ZWBF/ZWBFPregnancy")
local Lactation = require("ZWBF/ZWBFLactation")

local CharacterInfoTabManager = CharacterInfoTabManager:new()

--- Creates the UI for the Womb Handler
local function onCreateUI()
	UI = NewUI()
	UI:setWidthPercent(0.10)
	UI:setTitle(getText("IGUI_ZWBF_UI_Panel"))

	--- Milk ---
	-- title
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Milk_title")), _, "Center")
	UI:nextLine()

	-- image
	UI:addImage("boobs-image", "media/ui/lactation/boobs/color-0/normal_empty.png")
    UI:nextLine()
	
	-- level
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Milk_Amount")), _, "Center")
	UI:addImage("milk-level-image", "media/ui/lactation/level/milk_level_0.png")
	UI:nextLine()
	
	--- Womb ---
	-- Title
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Womb_title")), _, "Center")
	UI:nextLine()
	
	-- Image
	UI:addImage("womb-image", "media/ui/womb/normal/womb_normal_0.png")
	UI:nextLine()

	-- current
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Current")), _, "Center")
	UI:addText("womb-sperm-amount", "0 ml", _, "Center")
	UI:nextLine()

	-- total
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Total")), _, "Center")
	UI:addText("womb-sperm-total-amount", "0 ml", _, "Center")
	UI:nextLine()

	-- Cycle Information
	UI:addText("", getText("IGUI_ZWBF_UI_Cycle"), _, "Center")
	UI:nextLine()

	-- Phase
	UI:addText("", string.format("%s:", getText("IGUI_ZWBF_UI_Phase")), _, "Center")
	UI:addText("womb-cycle-info", "", _, "Center")
	UI:nextLine()

	if not getPlayer():HasTrait("Infertile") then
		-- Conception Chance
		UI:addText("womb-pregnancy-chance", string.format("%s:", getText("IGUI_ZWBF_UI_Fertility")), _, "Center")
		UI:addProgressBar("womb-pregnancy-bar", 0, 0, 1)
		UI:addText("womb-pregnancy-info", "", _, "Center")
		UI:nextLine()
	end	

	UI:saveLayout()
	UI:setBorderToAllElements(true)

	CharacterInfoTabManager:addTab("HPanel", UI)
end

--- Handles the UI update
local function onUpdateUI()
	if not UI.isUIVisible then return end

	-- Milk
    UI["boobs-image"]:setPath(Lactation:getBoobImage())
	UI["milk-level-image"]:setPath(Lactation:getMilkLevelImage())

	-- Womb
	UI["womb-sperm-amount"]:setText(string.format("%s ml", Womb:getSpermAmount()))
	UI["womb-sperm-total-amount"]:setText(string.format("%s ml", Womb:getSpermAmountTotal()))
	UI["womb-image"]:setPath(Womb:getImage())
	UI["womb-cycle-info"]:setText(getText(Womb:getCyclePhase()))
	if not getPlayer():HasTrait("Infertile") then
		UI["womb-pregnancy-chance"]:setText(getText(Pregnancy:getIsPregnant() and "IGUI_ZWBF_UI_Pregnancy" or "IGUI_ZWBF_UI_Fertility"))
		UI["womb-pregnancy-bar"]:setValue(Womb:getFertility())
		UI["womb-pregnancy-info"]:setText(math.floor(Womb:getFertility() * 100) .. "%")
	end
end

--- Create H-Status Context Menu Button
--- @param player any
--- @param context any
--- @param items any
local function onCreateWombDebugContextMenu(player, context, items)
	-- this mod is only applicable for Female characters
	local specificPlayer = getSpecificPlayer(player)
	if not specificPlayer:isFemale() or specificPlayer:isAsleep() or specificPlayer:getVehicle() then return end

	--- Create an option in the right-click menu
	local option = context:addOption(getText("ContextMenu_H_Status"))

	-- Create a submenu for that
	local submenu = ISContextMenu:getNew(context)
	context:addSubMenu(option, submenu)

	--- Debug options
	Utils:addOption(
			submenu,
			getText("ContextMenu_Add_Sperm_Title"),
			getText("ContextMenu_Add_Description"),
			function() Womb:addSperm(100) end
		)
		Utils:addOption(
			submenu,
			getText("ContextMenu_Remove_Title"),
			getText("ContextMenu_Remove_Description"),
			function() Womb:setSpermAmount(0) end
		)
		Utils:addOption(
			submenu,
			getText("ContextMenu_Remove_Total_Title"),
			getText("ContextMenu_Remove_Total_Description"),
			function() Womb:clearAllSperm() end
		)
		Utils:addOption(
			submenu,
			getText("ContextMenu_Add_Cycle_Day_Title"),
			getText("ContextMenu_Add_Cycle_Day_Description"),
			function() Womb:addCycleDay() end
		)
		Utils:addOption(
			submenu,
			getText("ContextMenu_Add_Pregnancy_Title"),
			getText("ContextMenu_Add_Pregnancy_Description"),
			function() Womb:setPregnancy(true) end
		)
		if Pregnancy:getIsPregnant() then
			Utils:addOption(
				submenu,
				getText("ContextMenu_Advance_Pregnancy_Title"),
				getText("ContextMenu_Advance_Pregnancy_Description"),
				function() Womb:advancePregnancy() end
			)
			Utils:addOption(
				submenu,
				getText("ContextMenu_Advance_Pregnancy_Labor_Title"),
				getText("ContextMenu_Advance_Pregnancy_Labor_Description"),
				function() Pregnancy:advanceToLabor() end
			)
			Utils:addOption(
				submenu,
				getText("ContextMenu_Remove_Pregnancy_Title"),
				getText("ContextMenu_Remove_Pregnancy_Description"),
				function() Womb:setPregnancy(false) end
			)
		end
end

--- Create Milk Context Menu Button
local function onCreateMilkDebugContextMenu(player, context)
    -- this mod is only applicable for Female characters
    local specificPlayer = getSpecificPlayer(player)
    if not specificPlayer:isFemale() or specificPlayer:isAsleep() or specificPlayer:getVehicle() then return end

    local option = context:addOption(getText("ContextMenu_Milk"))
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)
    
    Utils:addOption(
            submenu,
            getText("ContextMenu_Milk_Toggle_Lactation_Title"),
            getText("ContextMenu_Milk_Toggle_Lactation_Description"),
            function() Lactation:set(not Lactation:getIsLactating()) end
        )
        if Lactation:getIsLactating() then
            Utils:addOption(
                submenu,
                getText("ContextMenu_Milk_Add_Milk_Title"),
                getText("ContextMenu_Milk_Add_Milk_Description"),
                function() Lactation:add(200) end
            )
            Utils:addOption(
                submenu,
                getText("ContextMenu_Milk_Clear_Milk_Title"),
                getText("ContextMenu_Milk_Clear_Milk_Description"),
                function() Lactation:clear() end
            )
        end
end

--- Hook up event listeners
Events.OnCreateUI.Add(onCreateUI)
Events.OnPostRender.Add(onUpdateUI)
if isDebugEnabled() then
	Events.OnFillWorldObjectContextMenu.Add(onCreateWombDebugContextMenu)
	Events.OnFillWorldObjectContextMenu.Add(onCreateMilkDebugContextMenu)
end
