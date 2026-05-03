local M = require("IconsInventory/mod")

---@class IconsInventory_Cell
---@field pane IconsInventory_Pane
---@field item InventoryItem
---@field index integer
---@field stack ContextMenuItemStack
---@field category IconsInventory_Cell
---@field player IsoPlayer
local Cell = {}
Cell.__index = Cell
M.Cell = Cell

---@param pane IconsInventory_Pane
---@param item InventoryItem
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function Cell.new(pane, item, index, stack, category)
    ---@type IconsInventory_Cell
    local self = setmetatable({}, Cell)
    self.pane = pane
    self.item = item
    self.index = index
    self.stack = stack
    self.category = category or self

    if pane.focusedCell and self:isCategory() == pane.focusedCell:isCategory() and item:getID() == pane.focusedCell.item:getID() then
        pane:setFocusedCell(self)
    end

    self.player = getSpecificPlayer(pane.native.player)
    return self
end

function Cell:getStackSize()
    return #self.stack.items - 1
end

function Cell:isInHotbar()
    local hotbar = getPlayerHotbar(self.pane.native.player)
    -- Double check: inHotbar is not reliable
    return self.stack.inHotbar or hotbar and hotbar:isInHotbar(self.item) and not self.stack.equipped
end

function Cell:isCategory()
    return self.category == self
end

function Cell:isCollapsed()
    if not self:isCategory() or self:getStackSize() < 2 then return false end
    return not self.pane.expanded[self.stack.name] and M.Pane.isCollapsable(self.stack)
end

function Cell:isFocused()
    return self.pane.focusedCell == self
end

function Cell:isSelected()
    local selected = self.pane.native.selected
    return selected and selected[self.index]
end

---@param x number
---@param y number
function Cell:render(x, y)
    local cellSize = M.ItemIcon.cellSize

    self:drawBackground(x, y)

    local job = self.item:getJobDelta()
    if job > 0 and (not self:isCategory() or self:isCollapsed()) then
        self.pane.native:drawRect(x, y + (1 - job) * cellSize, cellSize, job * cellSize,
            0.2, 0.4, 1.0, 0.3);
    end

    if self:isCategory() then
        if self:isCollapsed() then
            M.ItemIcon.drawBase(self, x, y)
            M.ItemIcon.drawSubscript(self, x, y, tostring(self:getStackSize()))
        else
            M.ItemIcon.drawBase(self, x, y, 0.5)
            M.ItemIcon.drawSubscript(self, x, y, tostring(self:getStackSize()), 0.6)
        end
    else
        M.ItemIcon.drawBase(self, x, y)
        M.ItemIcon.drawDetails(self, x, y)
    end
end

-- See ISInventoryPane:renderdetails
---@param x number
---@param y number
function Cell:drawBackground(x, y)
    local cellSize = M.ItemIcon.cellSize
    local item = self.item
    local native = self.pane.native
    local heat = (
        (instanceof(item, "Food") or instanceof(item, "DrainableComboItem")) and item:getHeat()
    ) or item:getItemHeat()

    if instanceof(item, 'InventoryItem') then
        item:updateAge()
    end
    if instanceof(item, 'Clothing') then
        item:updateWetness()
    end

    if self:isSelected() then
        if native.dragging ~= nil and native.dragStarted then
            if self:isCollapsed() and native.draggedItems:cannotDropAnyItem()
                or not self:isCollapsed() and native.draggedItems:cannotDropItem(item)
            then
                native:drawRect(x, y, cellSize, cellSize, 0.20, 1.0, 0.0, 0.0)
            end
        else
            native:drawRect(x, y, cellSize - 1, cellSize - 1, 0.20, 1.0, 1.0, 1.0)
            native:drawRectBorder(x, y, cellSize, cellSize, 0.10, 1.0, 1.0, 1.0)
        end
    elseif self:isFocused() and heat == 1 then
        if native.doController then
            native:drawRect(x, y, cellSize, cellSize, 0.2, 0.2, 1.0, 1.0)
        else
            native:drawRect(x, y, cellSize, cellSize, 0.05, 1.0, 1.0, 1.0)
        end
    elseif native.highlightItem and native.highlightItem == item:getType() then
        if not native.blinkAlpha then native.blinkAlpha = 0.5; end
        native:drawRect(x, y, cellSize, cellSize, native.blinkAlpha, 1, 1, 1)
        if not native.blinkAlphaIncrease then
            native.blinkAlpha = native.blinkAlpha - 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
            if native.blinkAlpha < 0 then
                native.blinkAlpha = 0;
                native.blinkAlphaIncrease = true
            end
        else
            native.blinkAlpha = native.blinkAlpha + 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
            if native.blinkAlpha > 0.5 then
                native.blinkAlpha = 0.5;
                native.blinkAlphaIncrease = false
            end
        end
    elseif heat ~= 1 then
        local alpha = self:isFocused() and 0.45 or 0.3
        if heat > 1 then
            native:drawRect(x, y, cellSize, cellSize, alpha, math.abs(item:getInvHeat()), 0.0, 0.0)
        else
            native:drawRect(x, y, cellSize, cellSize, alpha, 0.0, 0.0, math.abs(item:getInvHeat()))
        end
    end

    if native.doController and self:isFocused() then
        native:drawRectBorder(x, y, cellSize, cellSize, 0.2, 1, 1, 1)
    end

    if native.itemsToHighlight ~= nil and native.itemsToHighlight[item] == true then
        native:drawRect(x, y, cellSize, cellSize, 0.2, 1.0, 1.0, 1.0)
    end
end
