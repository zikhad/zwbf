--- ZWBF UI Handler scripts
--- The logic here controls the Lactation panel
-- @ author Zikhad 2024

--- Localized global functions from PZ
local getText = getText
local Events = Events
local getSpecificPlayer = getSpecificPlayer
local ISContextMenu = ISContextMenu
local isDebugEnabled = isDebugEnabled

--- VARIABLES
local NewUI = NewUI
local Utils = require("ZWBF/ZWBFUtils")
local Lactation = require("ZWBF/ZWBFLactation")
local UI

--- Creates the UI for the Lactation
local function onCreateUI()
    UI = NewUI()
    UI:setWidthPercent(0.10)
    UI:setTitle(getText("IGUI_ZWBF_UI_Milk_title"))
    UI:addImage("boobs-image", "media/ui/lactation/boobs/color-0/normal_empty.png")
    UI:nextLine()
    UI:addImage("level-image", "media/ui/lactation/level/milk_level_0.png")
    UI:setBorderToAllElements(true)
    UI:saveLayout()
    UI:close()
end

--- Updates the UI for the Lactation
local function onUpdateUI()
    if not UI.isUIVisible then return end
    UI["level-image"]:setPath(Lactation:getMilkLevelImage())
    UI["boobs-image"]:setPath(Lactation:getBoobImage())
end

--- Creates the context menu for the Lactation
local function onCreateContextMenu(player, context)
    -- this mod is only applicable for Female characters
    local specificPlayer = getSpecificPlayer(player)
    if not specificPlayer:isFemale() or specificPlayer:isAsleep() or specificPlayer:getVehicle() then return end

    local option = context:addOption(getText("ContextMenu_Milk"))
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)
    
    Utils:addOption(
        submenu,
        getText("ContextMenu_Milk_Check_Title"),
        getText("ContextMenu_Milk_Check_Description"),
        function() UI:toggle() end
    )
    
    if isDebugEnabled() then
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
end

--- Hook up event listeners
Events.OnCreateUI.Add(onCreateUI)
Events.OnPostRender.Add(onUpdateUI)
Events.OnFillWorldObjectContextMenu.Add(onCreateContextMenu)
