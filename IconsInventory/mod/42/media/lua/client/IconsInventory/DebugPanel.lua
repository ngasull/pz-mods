local mod = require("IconsInventory/mod")

if isDebugEnabled() and mod.data.debug then
    local w = 450
    local h = 180

    local DebugPanel = ISCollapsableWindow:derive("IconsInventory_DebugPanel")

    function DebugPanel:new()
        local o = setmetatable(ISCollapsableWindow:new(
            getCore():getScreenWidth() - w,
            getCore():getScreenHeight() - h - 450,
            w,
            h
        ), self)
        self.__index = self
        return o
    end

    function DebugPanel:createChildren()
        ISCollapsableWindow.createChildren(self)
        self.minimumWidth = self.width
        self.minimumHeight = self.height
        self:setTitle("Icons Inventory debug")
        self:setVisible(true)

        local th = self:titleBarHeight()
        local rh = self:resizeWidgetHeight()
        local bodyHeight = h - th - rh
        local eh = bodyHeight / 3

        local button = ISButton:new(0, th, w, eh, "Reload", self, mod.reload)
        self:addChild(button)

        local scalingLabel = ISLabel:new(0, button.y + button.height, eh, "", 1, 1, 1, 1, UIFont.NewSmall, true)
        self:addChild(scalingLabel)

        local function handleScaling(_, scaling)
            if scaling < 1 then
                scalingLabel:setName("Scaling normal")
                mod.forcedScaling = nil
            else
                scalingLabel:setName("Scaling x" .. tostring(mod.forcedScaling))
                mod.forcedScaling = scaling
            end
            mod.init(true)
        end
        local scalingSlider = ISSliderPanel:new(0, scalingLabel.y + eh + eh / 4, w, eh / 2, self, handleScaling)
        scalingSlider:setValues(.5, 3, .5)
        scalingSlider:setCurrentValue(.5)
        self:addChild(scalingSlider)
    end

    Events.OnGameStart.Add(function()
        DebugPanel:new():addToUIManager()
    end)
end
