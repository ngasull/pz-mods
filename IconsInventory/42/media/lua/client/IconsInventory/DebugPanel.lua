local M = require("IconsInventory/mod")

if M.isDebugEnabled then
    local options = PZAPI.ModOptions:create("IconsInventory", "Icons Inventory")
    local debugOption = options:addTickBox("debug", "Debug", false)

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
        self:setVisible(debugOption:getValue())

        local th = self:titleBarHeight()
        local rh = self:resizeWidgetHeight()
        local btn = ISButton:new(0, th, w, h - th - rh, "Reload", self, M.reload)

        self:addChild(btn)
    end

    ---@type ISCollapsableWindow?
    local debugPanel

    local function init()
        if debugOption:getValue() and not debugPanel then
            debugPanel = DebugPanel:new()
            debugPanel:addToUIManager()
        elseif not debugOption:getValue() and debugPanel then
            debugPanel:setVisible(false)
            debugPanel:removeFromUIManager()
            debugPanel = nil
        end
    end

    Events.OnCreatePlayer.Add(init)
    options.apply = init
end
