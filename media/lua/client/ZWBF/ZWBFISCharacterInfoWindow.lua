--- Localized global functions from PZ
local ISCharacterInfoWindow = ISCharacterInfoWindow
local ISWindow = ISWindow
local ISLayoutManager = ISLayoutManager
local getText = getText

local CharacterInfoTabManager = {}
CharacterInfoTabManager.__index = CharacterInfoTabManager

-- Static table to store tabs
CharacterInfoTabManager.tabs = {}

-- Constructor
function CharacterInfoTabManager:new()
    local instance = setmetatable({}, self)
    return instance
end

-- Adds a new tab
function CharacterInfoTabManager:addTab(tabName, ui)
    local viewName = tabName .. "View"

    -- Store tab information
    CharacterInfoTabManager.tabs[tabName] = {
        viewName = viewName,
        ui = ui,
    }

    -- Override methods only once
    if not CharacterInfoTabManager.methodsOverridden then
        self:overrideISCharacterInfoWindowMethods()
        CharacterInfoTabManager.methodsOverridden = true
    end
end

-- Overrides necessary methods in ISCharacterInfoWindow
function CharacterInfoTabManager:overrideISCharacterInfoWindowMethods()
    local originalCreateChildren = ISCharacterInfoWindow.createChildren
    local originalOnTabTornOff = ISCharacterInfoWindow.onTabTornOff
    local originalPrerender = ISCharacterInfoWindow.prerender
    local originalSaveLayout = ISCharacterInfoWindow.SaveLayout

    -- Extend createChildren
    function ISCharacterInfoWindow:createChildren()
        originalCreateChildren(self)

        for tabName, tabInfo in pairs(CharacterInfoTabManager.tabs) do
            local viewName = tabInfo.viewName
            local ui = tabInfo.ui

            self[viewName] = ui
            self[viewName]:setPositionPixel(0, 0)
            self[viewName].infoText = getText("UI_" .. tabName .. "Panel")
            self[viewName].closeButton:setVisible(false)

            -- Prevent the tab content from being dragged
            self[viewName].onMouseDown = function()
                self[viewName]:setX(0)
                self[viewName]:setY(ISWindow.TitleBarHeight)
            end

            self.panel:addView(getText("UI_" .. tabName), self[viewName])
        end
    end

    -- Extend onTabTornOff
    function ISCharacterInfoWindow:onTabTornOff(view, window)
        for tabName, tabInfo in pairs(CharacterInfoTabManager.tabs) do
            if self.playerNum == 0 and view == self[tabInfo.viewName] then
                ISLayoutManager.RegisterWindow('charinfowindow.' .. tabName, ISCharacterInfoWindow, window)
            end
        end
        originalOnTabTornOff(self, view, window)
    end

    -- Extend prerender
    function ISCharacterInfoWindow:prerender()
        originalPrerender(self)
        for _, tabInfo in pairs(CharacterInfoTabManager.tabs) do
            local viewName = tabInfo.viewName
            if self[viewName] == self.panel:getActiveView() then
                self:setWidth(self[viewName]:getWidth())
                self:setHeight((ISWindow.TitleBarHeight * 2) + self[viewName]:getHeight())
            end
        end
    end

    -- Extend SaveLayout
    function ISCharacterInfoWindow:SaveLayout(name, layout)
        originalSaveLayout(self, name, layout)

        for tabName, tabInfo in pairs(CharacterInfoTabManager.tabs) do
            local subSelf = self[tabInfo.viewName]
            if subSelf and subSelf.parent == self.panel then
                if not layout.tabs then
                    layout.tabs = tabName
                else
                    layout.tabs = layout.tabs .. ',' .. tabName
                end
                if subSelf == self.panel:getActiveView() then
                    layout.current = tabName
                end
            end
        end
    end
end

return CharacterInfoTabManager
