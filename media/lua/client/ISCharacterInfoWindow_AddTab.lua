--- Localized global functions from PZ
local ISCharacterInfoWindow = ISCharacterInfoWindow
local ISWindow = ISWindow
local ISLayoutManager = ISLayoutManager
local getText = getText

-- TODO: Maybe move it to Utils?
--- Adds a new tab to the Character Info Window
---@param tabName string The name of the tab
---@param ui unknown The UI to be added to the tab
function AddCharacterPageTab(tabName, ui)

    local viewName = tabName.."View"

    -- Create the tab
    local original_ISCharacterInfoWindow_createChildren = ISCharacterInfoWindow.createChildren
    function ISCharacterInfoWindow:createChildren()
        original_ISCharacterInfoWindow_createChildren(self)

        self[viewName] = ui
        self[viewName]:setPositionPixel(0,0)
        -- self[viewName]:setWidthPixel(self.width,self.height)
        self[viewName].infoText = getText("UI_"..tabName.."Panel");
        self[viewName].closeButton:setVisible(false)

        -- Prevent the tab content from being dragged
        self[viewName].onMouseDown = function()
            self[viewName]:setX(0)
            self[viewName]:setY(ISWindow.TitleBarHeight)
        end

        self.panel:addView(getText("UI_"..tabName), self[viewName])
    end

    -- Controls tab switching
    local original_ISCharacterInfoWindow_onTabTornOff = ISCharacterInfoWindow.onTabTornOff
    function ISCharacterInfoWindow:onTabTornOff(view, window)
        if self.playerNum == 0 and view == self[viewName] then
            ISLayoutManager.RegisterWindow('charinfowindow.'..tabName, ISCharacterInfoWindow, window)
        end
        original_ISCharacterInfoWindow_onTabTornOff(self, view, window)
    end

    local original_ISCharacterInfoWindow_prerender = ISCharacterInfoWindow.prerender
    function ISCharacterInfoWindow:prerender()
        original_ISCharacterInfoWindow_prerender(self)
        if (self[viewName] == self.panel:getActiveView()) then
            self:setWidth(self[viewName]:getWidth())
            self:setHeight((ISWindow.TitleBarHeight * 2) + self[viewName]:getHeight())
        end
    end

    -- Make sure the tab exists in the panel
    local original_ISCharacterInfoWindow_SaveLayout = ISCharacterInfoWindow.SaveLayout
    function ISCharacterInfoWindow:SaveLayout(name, layout)
        original_ISCharacterInfoWindow_SaveLayout(self,name,layout)

        local addTabName = false
        local subSelf = self[viewName]
        if subSelf and subSelf.parent == self.panel then
            addTabName = true
            if subSelf == self.panel:getActiveView() then
                layout.current = tabName
            end
        end
        if addTabName then
            if not layout.tabs then
                layout.tabs = tabName
            else
                layout.tabs = layout.tabs .. ',' .. tabName
            end
        end
    end
end

