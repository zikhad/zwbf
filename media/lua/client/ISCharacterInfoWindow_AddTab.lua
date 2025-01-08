--- Localized global functions from PZ
local ISCharacterInfoWindow = ISCharacterInfoWindow
local ISWindow = ISWindow
local ISLayoutManager = ISLayoutManager
local ISCollapsableWindow = ISCollapsableWindow
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
        self[viewName]:setWidthPixel(self.width,self.height)
        self[viewName].infoText = getText("UI_"..tabName.."Panel");--UI_<tabName>Panel is full text of tooltip
        self[viewName].closeButton:setVisible(false)
        
        -- TODO: set the height, the following is not working
        self.panel:setHeightAndParentHeight(ISWindow.TitleBarHeight + self[viewName]:getHeight())
        self.panel:setScrollHeight(ISWindow.TitleBarHeight + self[viewName]:getHeight())
        
        -- Prevent the tab content from being dragged
        self[viewName].onMouseDown = function()
            self[viewName]:setX(0)
            self[viewName]:setY(ISWindow.TitleBarHeight)
        end

        self.panel:addView(getText("UI_"..tabName), self[viewName]) --UI_<tabName> is short text of tab
    end

    -- Controls tab switching
    local original_ISCharacterInfoWindow_onTabTornOff = ISCharacterInfoWindow.onTabTornOff
    function ISCharacterInfoWindow:onTabTornOff(view, window)
        if self.playerNum == 0 and view == self[viewName] then
            ISLayoutManager.RegisterWindow('charinfowindow.'..tabName, ISCollapsableWindow, window)
        end
        original_ISCharacterInfoWindow_onTabTornOff(self, view, window)
    end

    -- Make sure the table exists in the panel
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

