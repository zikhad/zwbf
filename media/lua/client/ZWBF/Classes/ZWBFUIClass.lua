local Events = Events

local ZWBFCharacterInfoTabManagerClass = require("ZWBF/Classes/ZWBFCharacterInfoTabManagerClass")
local ZWBFDebugMenuClass = require("ZWBF/Classes/ZWBFDebugMenuClass")

--- utility function to get the text for a label
--- @param text string The text to be formatted
local function label(text)
    return string.format("%s:", getText(text))
end

--- This class handles the UI for the ZWBF mod, including the lactation and womb panels.
--- @class ZWBFUIClass
--- @field UI table UIElement
--- @field CharacterInfoTabManager table ZWBFCharacterInfoTabManagerClass
--- @field Utils table ZWBFUtilsClass
--- @field Womb table ZWBFWomb
--- @field Pregnancy table ZWBFPregnancy
--- @field Lactation table ZWBFLactation
--- @field DebugMenu table ZWBFDebugMenu
--- @field UI table The UI object
--- @field activePanels table A table to track the visibility of the panels
--- @field heights table A table to track the heights of the panels
--- @field UIElements table A table to track the UI elements
local ZWBFUIClass = {}
ZWBFUIClass.__index = ZWBFUIClass

--- Constructor
function ZWBFUIClass:new(props)
    props = props or {}
    local instance = setmetatable({}, ZWBFUIClass)


    instance.CharacterInfoTabManager = props.CharacterInfoTabManager or ZWBFCharacterInfoTabManagerClass:new()
    instance.Utils = props.Utils or require("ZWBF/ZWBFUtils")
    instance.Womb = props.Womb or require("ZWBF/ZWBFWomb")
    instance.Pregnancy = props.Pregnancy or require("ZWBF/ZWBFPregnancy")
    instance.Lactation = props.Lactation or require("ZWBF/ZWBFLactation")
    instance.DebugMenu = props.DebugMenu or ZWBFDebugMenuClass:new(props)

    instance.UI = nil
    instance.activePanels = {
        lactation = true,
        womb = true
    }
    instance.heights = {
        lactation = 0,
        womb = 0
    }
    instance.UIElements = {
        lactation = {
            image = "lactation-image",
            title = "lactation-level-title",
            level = "lactation-level-image"
        },
        womb = {
            title = "womb-title",
            image = "womb-image",
            sperm = {
                current = {
                    title = "womb-sperm-current-title",
                    amount = "womb-sperm-current-amount",
                },
                total = {
                    title = "womb-sperm-total-title",
                    amount = "womb-sperm-total-amount",
                }
            },
            cycle = {
                title = "womb-cycle-title",
                phase = {
                    title = "womb-cycle-phase-title",
                    value = "womb-cycle-phase-value",
                }
            },
            fertility = {
                title = "womb-fertility-title",
                bar = "womb-fertility-bar",
                value = "womb-fertility-value"
            }
        }
    }

    return instance
end

--- Creates the UI for the Womb Handler
function ZWBFUIClass:onCreateUI()
    local player = getPlayer()
    if not player:isFemale() then return end

    self.UI = NewUI()
    self.UI:setWidthPixel(200)
    self.UI:setTitle(getText("IGUI_ZWBF_UI_Panel"))

    --- Womb ---
    self.UI:addText(self.UIElements.womb.title, label("IGUI_ZWBF_UI_Womb_title"), _, "Center")
    self.UI:nextLine()
    self.UI:addImage(self.UIElements.womb.image, "media/ui/womb/normal/womb_normal_0.png")
    self.UI:nextLine()
    self.UI:addText(self.UIElements.womb.sperm.current.title, label("IGUI_ZWBF_UI_Current"), _, "Center")
    self.UI:addText(self.UIElements.womb.sperm.current.amount, "0 ml", _, "Center")
    self.UI:nextLine()
    self.UI:addText(self.UIElements.womb.sperm.total.title, label("IGUI_ZWBF_UI_Total"), _, "Center")
    self.UI:addText(self.UIElements.womb.sperm.total.amount, "0 ml", _, "Center")
    self.UI:nextLine()
    self.UI:addText(self.UIElements.womb.cycle.title, getText("IGUI_ZWBF_UI_Cycle"), _, "Center")
    self.UI:nextLine()
    self.UI:addText(self.UIElements.womb.cycle.phase.title, label("IGUI_ZWBF_UI_Phase"), _, "Center")
    self.UI:addText(self.UIElements.womb.cycle.phase.value, "", _, "Center")
    self.UI:nextLine()

    if not player:HasTrait("Infertile") then
        self.UI:addText(self.UIElements.womb.fertility.title, label("IGUI_ZWBF_UI_Fertility"), _, "Center")
        self.UI:addProgressBar(self.UIElements.womb.fertility.bar, 0, 0, 1)
        self.UI:addText(self.UIElements.womb.fertility.value, "", _, "Center")
        self.UI:nextLine()
    end

    -- The height of the womb UI needs to take in consideration the title bar height
    self.heights.womb = self.UI.yAct + self.UI:titleBarHeight()

    --- Milk ---
    --- controls
    self.UI:addText("", getText("IGUI_ZWBF_UI_Milk_title"), _, "Center")
    self.UI:addButton("", getText("IGUI_ZWBF_UI_Milk_toggle"),
            function()
                self:togglePanel("lactation")
            end
    )
    self.UI:nextLine()

    -- Lactation UI
    self.UI:addImage(self.UIElements.lactation.image, "media/ui/lactation/boobs/color-0/normal_empty.png")
    self.UI:nextLine()
    self.UI:addText(self.UIElements.lactation.title, label("IGUI_ZWBF_UI_Milk_Amount"), _, "Center")
    self.UI:addImage(self.UIElements.lactation.level, "media/ui/lactation/level/milk_level_0.png")

    -- The height of the lactation UI needs to take in consideration the title bar height
    self.heights.lactation = self.UI.yAct + (self.UI:titleBarHeight() * 2)

    self.UI:setBorderToAllElements(true)
    self.UI:saveLayout()

    self.CharacterInfoTabManager:addTab("HPanel", self.UI)
end

function ZWBFUIClass:onCreatePlayer(player)
    self.player = player
end

function ZWBFUIClass:togglePanel(selected)

    if selected == "lactation" then
        self.activePanels.lactation = not self.activePanels.lactation
    end

    -- Update UI visibility
    for _, element in pairs(self.UIElements.lactation) do
        if self.UI[element] then
            self.UI[element]:setVisible(self.activePanels.lactation)
        end
    end

    -- Update UI height (only lactation can be toggled)
    if self.activePanels.lactation then
        self.UI:setHeight(self.heights.lactation)
    else
        self.UI:setHeight(self.heights.womb)
    end
end

--- Handles the UI update
function ZWBFUIClass:onUpdateUI()
    if (
            not self.player or
            not self.player:isFemale() or
            not self.UI or
            not self.UI.isUIVisible
    ) then return end

    -- Milk --
    if self.activePanels.lactation then
        self.UI[self.UIElements.lactation.image]:setPath(self.Lactation:getBoobImage())
        self.UI[self.UIElements.lactation.level]:setPath(self.Lactation:getMilkLevelImage())
    end

    -- Womb
    self.UI[self.UIElements.womb.sperm.current.amount]:setText(string.format("%s ml", self.Womb:getSpermAmount()))
    self.UI[self.UIElements.womb.sperm.total.amount]:setText(string.format("%s ml", self.Womb:getSpermAmountTotal()))
    self.UI[self.UIElements.womb.image]:setPath(self.Womb:getImage())
    self.UI[self.UIElements.womb.cycle.phase.value]:setText(getText(self.Womb:getCyclePhaseTranslation()))
    if not self.player:HasTrait("Infertile") then
        self.UI[self.UIElements.womb.fertility.title]:setText(getText(self.Pregnancy:getIsPregnant() and "IGUI_ZWBF_UI_Pregnancy" or "IGUI_ZWBF_UI_Fertility"))
        self.UI[self.UIElements.womb.fertility.bar]:setValue(self.Womb:getFertility())
        self.UI[self.UIElements.womb.fertility.value]:setText(math.floor(self.Womb:getFertility() * 100) .. "%")
    end
end

--- Hook up event listeners
function ZWBFUIClass:registerEvents()
    -- if not getPlayer():isFemale() then return end
    Events.OnCreateUI.Add(function() self:onCreateUI() end)
    Events.OnCreatePlayer.Add(function(_, player) self:onCreatePlayer(player) end)
    Events.OnPostRender.Add(function() self:onUpdateUI() end)
    self.DebugMenu:registerEvents()
end

return ZWBFUIClass
