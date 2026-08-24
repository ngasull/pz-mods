local Cell = require("IconsInventory/Cell")
local IconsPane = require("IconsInventory/IconsPane")

---@param self ISInventoryPage
---@param col? integer
local function focusTheOtherPage(self, col)
    local otherPage = self._IconsInventory:getTheOtherPage()
    local otherMod = otherPage._IconsInventory
    local otherCell = otherMod.grid:getCellAt(1, col or 1)
    otherMod:setFocusedCell(otherCell)
    setJoypadFocus(self.player, otherPage)
end

-- Logical gamepad action
local function isCancelAction(button)
    return button == (
        CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.CancelAction:getJoypadButton() or Joypad.BButton
    )
end

local function isCycleTabsLeftAction(button)
    return button == (
        CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.CycleTabsLeft:getJoypadButton() or Joypad.LBumper
    )
end

local function isCycleTabsRightAction(button)
    return button == (
        CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.CycleTabsRight:getJoypadButton() or Joypad.RBumper
    )
end

local function isInteractAction(button)
    return button == (
        CharacterJoypadButtonBinding and CharacterJoypadButtonBinding.Interact:getJoypadButton() or Joypad.AButton
    )
end

---@class ISInventoryPage
local vanilla = {}

---@class ISInventoryPage
---@field _IconsInventory_pressedBumper JoypadButton?
local Override = {}

function Override:update()
    vanilla.update(self)

    if self._IconsInventory_pressedBumper then
        local joypad = getSpecificPlayer(self.player):getJoypadBind()

        -- onJoypadUp is not working: do it manually
        if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
            self._IconsInventory_pressedBumper = nil
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
        end
    end
end

function Override:onJoypadDirRight()
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    elseif pane:isVisible() then
        local row, col = 1, 1 -- Find first leftmost cell if any
        if pane.focusedCell then
            row, col = pane.focusedCell.layoutRow, pane.focusedCell.layoutCol
        end

        pane:setFocusedCell(pane.grid:getCellAt(row, col + 1))

        if not pane.focusedCell then
            if self.onCharacter then
                focusTheOtherPage(self, 1)
            else
                pane:setFocusedCell(pane.grid:getCellAt(row, col))
            end
        end
    elseif self.onCharacter then
        focusTheOtherPage(self)
    end
end

function Override:onJoypadDirLeft()
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    elseif pane:isVisible() then
        local row, col = 1, -1 -- Find first rightmost cell if any
        if pane.focusedCell then
            row, col = pane.focusedCell.layoutRow, pane.focusedCell.layoutCol
        end

        pane:setFocusedCell(pane.grid:getCellAt(row, col - 1))

        if not pane.focusedCell then
            if not self.onCharacter then
                focusTheOtherPage(self, -1)
            else
                pane:setFocusedCell(pane.grid:getCellAt(row, col))
            end
        end
    elseif not self.onCharacter then
        focusTheOtherPage(self, -1)
    end
end

function Override:onJoypadDirDown(joypadData)
    local pane = self._IconsInventory
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
        if pane:isVisible() then
            if pane.focusedCell then
                local rows = pane.grid:getRows()
                local nextRow = rows[pane.focusedCell.layoutRow + 1]
                pane:setFocusedCell(nextRow and nextRow[math.min(#nextRow, pane.focusedCell.layoutCol)])
            else
                -- Find first upmost cell if any
                pane:setFocusedCell(pane.grid:getCellAt(1, 1))
            end

            if not pane.focusedCell then
                self:selectNextContainer()
            end
        else
            return vanilla.onJoypadDirDown(self, joypadData)
        end
    end
end

function Override:onJoypadDirUp(joypadData)
    local pane = self._IconsInventory
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
        if pane:isVisible() then
            if pane.focusedCell then
                local rows = pane.grid:getRows()
                local prevRow = rows[pane.focusedCell.layoutRow - 1]
                pane:setFocusedCell(prevRow and prevRow[math.min(#prevRow, pane.focusedCell.layoutCol)])
            else
                -- Get first downmost cell if any
                pane:setFocusedCell(pane.grid:getCellAt(-1, 1))
            end

            if not pane.focusedCell then
                self:selectPrevContainer()
            end
        else
            return vanilla.onJoypadDirUp(self, joypadData)
        end
    end
end

function Override:onJoypadDown(button)
    local pane = self._IconsInventory

    if isCycleTabsLeftAction(button) or isCycleTabsRightAction(button) then
        -- If re-pressed before update
        if self._IconsInventory_pressedBumper ~= nil then
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
        end

        self._IconsInventory_pressedBumper = button
    elseif isInteractAction(button) and pane.focusedCell and pane:isVisible() then
        IconsPane.stubContextMenuXY(
            function()
                local x = pane:getAbsoluteX() + pane.grid.x
                    + (pane.focusedCell.layoutCol - 1) * Cell.size
                local y = pane:getAbsoluteY() + pane.grid.y + pane.native:getYScroll()
                    + pane.focusedCell.layoutRow * Cell.size
                return x, y
            end,
            vanilla.onJoypadDown, self, button
        )
    elseif isCancelAction(button) and pane:isVisible() then
        local player = getSpecificPlayer(self.player)
        if isPlayerDoingActionThatCanBeCancelled(player) then
            stopDoingActionThatCanBeCancelled(player)
            return
        end
        if pane.focusedCell and pane.focusedCell:isCategory() then
            -- Call our own implementation of `doJoypadExpandCollapse` in PaneOverride
            self.inventoryPane:doJoypadExpandCollapse()
        end
    else
        return vanilla.onJoypadDown(self, button)
    end
end

-- Install --
local Prev = isDebugEnabled() and require("IconsInventory/JoypadPageOverride")
for k in pairs(Override) do
    if not Prev then
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] =
            isDebugEnabled() and function(...) return Override[k](...) end
            or Override[k]
    else
        vanilla[k] = Prev._vanilla[k]
    end
end

Override._vanilla = vanilla
return Override
