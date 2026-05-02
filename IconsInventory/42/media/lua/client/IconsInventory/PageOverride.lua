local M = require("IconsInventory/mod")

---@param self ISInventoryPage
local function selectOtherPage(self)
    local other = self.onCharacter and getPlayerLoot(self.player) or getPlayerInventory(self.player)
    setJoypadFocus(self.player, other)
end

---@class IconsInventory_ISInventoryPage: ISInventoryPage
local vanilla = {}

---@class IconsInventory_ISInventoryPageOverride: ISInventoryPage
---@field parent ISInventoryPage
---@field inventoryPane IconsInventory_ISInventoryPaneOverride
---@field _IconsInventory_pressedBumper integer?
local Override = {}

function Override:update()
    if self._IconsInventory_pressedBumper then
        local joypad = getSpecificPlayer(self.player):getJoypadBind()

        -- onJoypadUp is not working: do it manually
        if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
            self._IconsInventory_pressedBumper = nil
        end
    end

    return vanilla.update(self)
end

function Override:onJoypadDirRight(...)
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        selectOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        self.inventoryPane._IconsInventory:joypadRight()
    end
end

function Override:onJoypadDirLeft(...)
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        selectOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        self.inventoryPane._IconsInventory:joypadLeft()
    end
end

function Override:onJoypadDirDown(...)
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) then
        getPlayerInventory(self.player):selectNextContainer()
        self._IconsInventory_pressedBumper = nil
    end
    if isJoypadRBPressed(joypad) then
        getPlayerLoot(self.player):selectNextContainer()
        self._IconsInventory_pressedBumper = nil
    end

    if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
        self.inventoryPane._IconsInventory:joypadDown()
    end
end

function Override:onJoypadDirUp(...)
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) then
        getPlayerInventory(self.player):selectPrevContainer()
        self._IconsInventory_pressedBumper = nil
    end
    if isJoypadRBPressed(joypad) then
        getPlayerLoot(self.player):selectPrevContainer()
        self._IconsInventory_pressedBumper = nil
    end

    if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
        self.inventoryPane._IconsInventory:joypadUp()
    end
end

function Override:onJoypadDown(button)
    local pane = self.inventoryPane
    local mod = pane._IconsInventory

    if button == Joypad.LBumper or button == Joypad.RBumper then
        -- If re-pressed before update
        if self._IconsInventory_pressedBumper ~= nil then
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
        end

        self._IconsInventory_pressedBumper = button
    elseif button == Joypad.AButton and mod.hoveredCell then
        local _, row, col = mod.grid:locateCell(mod.hoveredCell)

        if row and col then
            local vanilla_createMenu = ISInventoryPaneContextMenu.createMenu
            local vanilla_createMenuTutorial = Tutorial1.createInventoryContextMenu

            ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, _x, _y, ...)
                local x = pane:getAbsoluteX() + mod.xPadding + (col - 1) * M.ItemIcon.cellSize
                local y = pane:getAbsoluteY() + mod.yPadding + row * M.ItemIcon.cellSize + self:getYScroll()
                return vanilla_createMenu(player, isInPlayerInventory, items, x, y, ...)
            end
            Tutorial1.createInventoryContextMenu = ISInventoryPaneContextMenu.createMenu

            local ok, message = pcall(vanilla.onJoypadDown, self, button)

            ISInventoryPaneContextMenu.createMenu = vanilla_createMenu
            Tutorial1.createInventoryContextMenu = vanilla_createMenuTutorial
            if not ok then error(message) end
        else
            return vanilla.onJoypadDown(self, button)
        end
    else
        return vanilla.onJoypadDown(self, button)
    end
end

function Override:onResize()
    if vanilla.onResize then vanilla.onResize(self) end
    local pane = self.inventoryPane
    local mod = pane._IconsInventory

    pane:setWidth(mod:desiredWidth())
    pane:setHeight(2 + self:getHeight()
        - self:titleBarHeight()
        - self.controlsUI:getHeight()
        - ISCollapsableWindow:resizeWidgetHeight())

    mod._dirty = true
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] = v
    end

    M.cleanPage = function()
        for k, v in pairs(vanilla) do
            ISInventoryPage[k] = v
        end
    end
end

if M.cleanPage then M.cleanPage() end
install()
