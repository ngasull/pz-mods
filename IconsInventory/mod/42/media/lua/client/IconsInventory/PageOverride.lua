local M = require("IconsInventory/mod")

---@param self ISInventoryPage
---@return IconsInventory_ISInventoryPageOverride
local function getTheOtherPage(self)
    return self.onCharacter and getPlayerLoot(self.player) or getPlayerInventory(self.player)
end

---@param self IconsInventory_ISInventoryPageOverride
---@param col? integer
local function focusTheOtherPage(self, col)
    local otherPage = getTheOtherPage(self)
    local otherMod = otherPage.inventoryPane._IconsInventory
    local otherCell = otherMod.grid:getCellAt(1, col or 1)
    otherMod:setFocusedCell(otherCell)
    setJoypadFocus(self.player, otherPage)
end

---@class IconsInventory_ISInventoryPage: ISInventoryPage
local vanilla = {}

---@class IconsInventory_ISInventoryPageOverride: ISInventoryPage
---@field parent ISInventoryPage
---@field inventoryPane IconsInventory_ISInventoryPaneOverride
---@field _IconsInventory_init? true
---@field _IconsInventory_pressedBumper integer?
local Override = {}

function Override:update()
    if not self._IconsInventory_init then
        if getSpecificPlayer(self.player):getJoypadBind() ~= -1 then
            local h = math.max(
                math.floor(self:getHeight() / 2),
                math.floor(getCore():getScreenHeight() / 4))
            self:setHeight(h)
            self:setY(getCore():getScreenHeight() - h)
        end
        self._IconsInventory_init = true
    end

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
    local pane = self.inventoryPane
    local mod = pane._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        local row, col = mod.grid:locateCell(mod.focusedCell)
        if not row or not col then
            -- Find first leftmost cell if any
            row = 1
            col = 1
        end

        mod:setFocusedCell(mod.grid:getCellAt(row, col + 1))

        if not mod.focusedCell then
            if self.onCharacter then
                focusTheOtherPage(self, 1)
            else
                mod:setFocusedCell(mod.grid:getCellAt(row, col))
            end
        end
    end
end

function Override:onJoypadDirLeft(...)
    local pane = self.inventoryPane
    local mod = pane._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        local row, col = mod.grid:locateCell(mod.focusedCell)
        if not row or not col then
            -- Find first rightmost cell if any
            row = 1
            col = -1
        end

        mod:setFocusedCell(mod.grid:getCellAt(row, col - 1))

        if not mod.focusedCell then
            if not self.onCharacter then
                focusTheOtherPage(self, -1)
            else
                mod:setFocusedCell(mod.grid:getCellAt(row, col))
            end
        end
    end
end

function Override:onJoypadDirDown(...)
    local pane = self.inventoryPane
    local mod = pane._IconsInventory
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
        local rows = mod.grid:getRows()
        local row, col = mod.grid:locateCell(mod.focusedCell)

        if row and col then
            local nextRow = rows[row + 1]
            mod:setFocusedCell(nextRow and nextRow[math.min(#nextRow, col)])
        else
            -- Find first upmost cell if any
            mod:setFocusedCell(mod.grid:getCellAt(1, 1))
        end

        if not mod.focusedCell then
            self:selectNextContainer()
        end
    end
end

function Override:onJoypadDirUp(...)
    local pane = self.inventoryPane
    local mod = pane._IconsInventory
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
        local rows = mod.grid:getRows()
        local row, col = mod.grid:locateCell(mod.focusedCell)

        if row and col then
            local prevRow = rows[row - 1]
            mod:setFocusedCell(prevRow and prevRow[math.min(#prevRow, col)])
        else
            -- Get first downmost cell if any
            mod:setFocusedCell(mod.grid:getCellAt(-1, 1))
        end

        if not mod.focusedCell then
            self:selectPrevContainer()
        end
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
    elseif button == Joypad.AButton and mod.focusedCell then
        local row, col = mod.grid:locateCell(mod.focusedCell)

        if row and col then
            M.Pane.stubContextMenuXY(
                function()
                    local x = pane:getAbsoluteX() + mod.grid.x + (col - 1) * M.ItemIcon.cellSize
                    local y = pane:getAbsoluteY() + mod.grid.y + row * M.ItemIcon.cellSize + mod.native:getYScroll()
                    return x, y
                end,
                vanilla.onJoypadDown, self, button
            )
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
