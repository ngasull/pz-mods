local M = require("SideBySideContainers/mod")

---@param self ISInventoryPage
local function shallMoveLeft(self)
    return self.onCharacter and M.option.playerLeft:getValue()
        or not self.onCharacter and M.option.lootLeft:getValue()
end

local function setXZero(self)
    ISUIElement.setX(self, 0)
end

---@param self ISInventoryPage
local function initPage(self)
    if shallMoveLeft(self) then
        if self.containerButtonPanel.anchorRight then
            self.inventoryPane:setX(self.buttonSize)
            self.containerButtonPanel:setAnchorLeft(true)
            self.containerButtonPanel:setAnchorRight(false)
            -- Yep :D this allows reacting to onInventoryContainerSizeChanged
            self.containerButtonPanel.setX = setXZero
            self.containerButtonPanel:setX(0)
        end
    else
        if self.containerButtonPanel.anchorLeft then
            self.inventoryPane:setX(0)
            self.containerButtonPanel:setAnchorLeft(false)
            self.containerButtonPanel:setAnchorRight(true)
            self.containerButtonPanel.setX = ISUIElement.setX
            self.containerButtonPanel:setX(self:getWidth() - self.buttonSize)
        end
    end
end

---@class SideBySideContainers_ISInventoryPage_override: ISInventoryPage
local Override = {}
---@class SideBySideContainers_ISInventoryPage: ISInventoryPage
local vanilla = {}

-- Intercept drawRect and drawRectBorder for container button panel
function Override:drawRect(x, y, w, h, a, r, g, b)
    if shallMoveLeft(self) and w == self.buttonSize and x == self:getWidth() - self.buttonSize then
        return vanilla.drawRect(self, 0, y, w, h, a, r, g, b)
    else
        return vanilla.drawRect(self, x, y, w, h, a, r, g, b)
    end
end

function Override:drawRectBorder(x, y, w, h, a, r, g, b)
    if shallMoveLeft(self) and w == self.buttonSize and x == self:getWidth() - self.buttonSize then
        return vanilla.drawRectBorder(self, 0, y, w, h, a, r, g, b)
    else
        return vanilla.drawRectBorder(self, x, y, w, h, a, r, g, b)
    end
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] = v
    end

    M.clean = function()
        for k, v in pairs(vanilla) do
            ISInventoryPage[k] = v
        end
    end
end

M.options.apply = function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            initPage(pd.playerInventory)
            initPage(pd.lootInventory)
        end
    end
end

if M.clean then
    M.clean()
    install()
    M.options.apply()
else
    Events.OnGameStart.Add(function()
        install()
        M.options.apply()
    end)
end
