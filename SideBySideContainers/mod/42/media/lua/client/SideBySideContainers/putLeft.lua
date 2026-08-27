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
            self.inventoryPane:setX(self.containerButtonPanel.width)
            self.containerButtonPanel:setAnchorLeft(true)
            self.containerButtonPanel:setAnchorRight(false)
            -- Yep :D this allows reacting to onInventoryContainerSizeChanged
            self.containerButtonPanel.setX = setXZero
            self.containerButtonPanel:setX(0)
            self.onMouseWheel = function(...)
                local prev_getWidth = self.getWidth
                self.getWidth = function()
                    self.getWidth = prev_getWidth -- getWidth is used elsewhere right after
                    return self.buttonSize + 1
                end
                local ok, res = pcall(ISInventoryPage.onMouseWheel, ...)
                self.getWidth = prev_getWidth
                return ok and res
            end
        end
    else
        if self.containerButtonPanel.anchorLeft then
            self.inventoryPane:setX(0)
            self.containerButtonPanel:setAnchorLeft(false)
            self.containerButtonPanel:setAnchorRight(true)
            self.containerButtonPanel.setX = ISUIElement.setX
            self.containerButtonPanel:setX(self.width - self.containerButtonPanel.width)
            self.onMouseWheel = ISInventoryPage.onMouseWheel
        end
    end
end

---@class ISInventoryPage
local Override = {}
---@class ISInventoryPage
local vanilla = {}

function Override:prerender()
    -- More reliable to hook on prerender to react to structural changes like plugged controller
    if self.SBS_needsRefresh then
        self:refreshBackpacks()
        self.SBS_needsRefresh = false
    end
    if not self.SBS_isInit then
        self:onInventoryContainerSizeChanged()
        self.SBS_isInit = true
    end
    vanilla.prerender(self)
end

-- Intercept drawRect and drawRectBorder for container button panel
function Override:drawRect(x, y, w, h, a, r, g, b)
    local sidePanelWidth = self.containerButtonPanel.width
    if shallMoveLeft(self) and w == sidePanelWidth and x == self.width - sidePanelWidth then
        return vanilla.drawRect(self, 0, y, w, h, a, r, g, b)
    else
        return vanilla.drawRect(self, x, y, w, h, a, r, g, b)
    end
end

function Override:drawRectBorder(x, y, w, h, a, r, g, b)
    local sidePanelWidth = self.containerButtonPanel.width
    if shallMoveLeft(self) and w == sidePanelWidth and x == self.width - sidePanelWidth then
        return vanilla.drawRectBorder(self, 0, y, w, h, a, r, g, b)
    else
        return vanilla.drawRectBorder(self, x, y, w, h, a, r, g, b)
    end
end

function Override:onInventoryContainerSizeChanged()
    local bigger = M.option.biggerButtons:getValue()
    local prev_setWidth = self.inventoryPane.setWidth

    if bigger then
        self.inventoryPane.setWidth = function()
            local sizes = { 38, 56, 78 }
            self.buttonSize = sizes[getCore():getOptionInventoryContainerSize()]
            self.minimumWidth = 256 + self.buttonSize
            self.inventoryPane.setWidth = prev_setWidth
            return prev_setWidth(self.inventoryPane, self.width - self.buttonSize)
        end
    end

    local ok, res = pcall(vanilla.onInventoryContainerSizeChanged, self)
    self.inventoryPane.setWidth = prev_setWidth

    if not ok then
        error(res)
    else
        if bigger then
            -- Make it crisp
            local containerIconSize = self.buttonSize - self.buttonSize % 16
            for _, button in ipairs(self.buttonPool) do
                button:forceImageSize(containerIconSize, containerIconSize)
            end
            for _, button in ipairs(self.backpacks) do
                button:forceImageSize(containerIconSize, containerIconSize)
            end
        end
    end

    initPage(self)
    self.SBS_needsRefresh = true -- Refresh on next cycle to avoid buggy init
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

if M.clean then M.clean() end
install()

M.options.apply = function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            pd.playerInventory:onInventoryContainerSizeChanged()
            pd.lootInventory:onInventoryContainerSizeChanged()
        end
    end
end
