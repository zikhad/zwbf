local Events = Events
local getSpecificPlayer = getSpecificPlayer
local getText = getText
local ISContextMenu = ISContextMenu

local ZWBFDebugMenuClass = {}
ZWBFDebugMenuClass.__index = ZWBFDebugMenuClass

--- Constructor
function ZWBFDebugMenuClass:new(props)
    props = props or {}
    local instance = setmetatable({}, ZWBFDebugMenuClass)

    instance.name = props.name or "ZWBFDebugMenu"
    instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")
    instance.Womb = props.Womb or require("ZWBF/ZWBFWomb")
    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
    instance.Lactation = props.Lactation or require("ZWBF/ZWBFLactation")

    return instance
end

--- Creates the debug context menu for the player
function ZWBFDebugMenuClass:onCreateDebugContextMenu(player, context, items)
    local specificPlayer = getSpecificPlayer(player)
    if not specificPlayer:isFemale() or specificPlayer:isAsleep() or specificPlayer:getVehicle() then return end

    local option = context:addOption(getText("ContextMenu_ZWBF_Being_Female"))
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)

    self.Utils:addOption(submenu, getText("ContextMenu_Add_Sperm_Title"), getText("ContextMenu_Add_Description"), function() self.Womb:addSperm(100) end)
    self.Utils:addOption(submenu, getText("ContextMenu_Remove_Title"), getText("ContextMenu_Remove_Description"), function() self.Womb:setSpermAmount(0) end)
    self.Utils:addOption(submenu, getText("ContextMenu_Remove_Total_Title"), getText("ContextMenu_Remove_Total_Description"), function() self.Womb:clearAllSperm() end)
    self.Utils:addOption(submenu, getText("ContextMenu_Add_Pregnancy_Title"), getText("ContextMenu_Add_Pregnancy_Description"), function() self.Womb:setPregnancy(true) end)

    if self.Pregnancy:getIsPregnant() then
        self.Utils:addOption(submenu, getText("ContextMenu_Advance_Pregnancy_Title"), getText("ContextMenu_Advance_Pregnancy_Description"), function() self.Womb:advancePregnancy() end)
        self.Utils:addOption(submenu, getText("ContextMenu_Advance_Pregnancy_Labor_Title"), getText("ContextMenu_Advance_Pregnancy_Labor_Description"), function() self.Pregnancy:advanceToLabor() end)
        self.Utils:addOption(submenu, getText("ContextMenu_Remove_Pregnancy_Title"), getText("ContextMenu_Remove_Pregnancy_Description"), function() self.Womb:setPregnancy(false) end)
    else
        self.Utils:addOption(submenu, getText("ContextMenu_Add_Cycle_Day_Title"), getText("ContextMenu_Add_Cycle_Day_Description"), function() self.Womb:addCycleDay() end)
        self.Utils:addOption(submenu, getText("ContextMenu_Next_Cycle_Title"), getText("ContextMenu_Next_Cycle_Description"), function() self.Womb:nextCycle() end)
    end

    self.Utils:addOption(submenu, getText("ContextMenu_Milk_Toggle_Lactation_Title"), getText("ContextMenu_Milk_Toggle_Lactation_Description"), function() self.Lactation:set(not self.Lactation:getIsLactating()) end)
    if self.Lactation:getIsLactating() then
        self.Utils:addOption(submenu, getText("ContextMenu_Milk_Add_Milk_Title"), getText("ContextMenu_Milk_Add_Milk_Description"), function() self.Lactation:add(200) end)
        self.Utils:addOption(submenu, getText("ContextMenu_Milk_Clear_Milk_Title"), getText("ContextMenu_Milk_Clear_Milk_Description"), function() self.Lactation:clear() end)
    end
end

--- Registers the events for the debug menu
function ZWBFDebugMenuClass:registerEvents()
    if isDebugEnabled() then
        Events.OnFillWorldObjectContextMenu.Add(
            function(player, context, items)
                self:onCreateDebugContextMenu(player, context, items)
            end
        )
    end
end

return ZWBFDebugMenuClass
