local mod = require("IconsInventory/mod")

if isDebugEnabled() and mod.data.debug then
    local w = 450
    local h = 120

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
        local btn = ISButton:new(0, th, w, h - th - rh, "Reload", self, mod.reload)

        self:addChild(btn)
    end

    Events.OnGameStart.Add(function()
        DebugPanel:new():addToUIManager()
    end)
end
