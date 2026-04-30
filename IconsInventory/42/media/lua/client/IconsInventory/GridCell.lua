local M = require("IconsInventory/mod")

---@class IconsInventory_GridCell
---@field pane IconsInventory_Pane
---@field item InventoryItem
---@field index integer
---@field stack ContextMenuItemStack
---@field category IconsInventory_GridCell
---@field icon IconsInventory_ItemIcon
local GridCell = {}
GridCell.__index = GridCell
M.GridCell = GridCell

---@param pane IconsInventory_Pane
---@param item InventoryItem
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_GridCell
function GridCell.new(pane, item, index, stack, category)
    ---@type IconsInventory_GridCell
    local self = setmetatable({}, GridCell)
    self.pane = pane
    self.item = item
    self.index = index
    self.stack = stack
    self.category = category or self

    local player = getSpecificPlayer(pane.native.player)
    self.icon = M.ItemIcon.new(player, pane.native, item)
    return self
end

function GridCell:getStackSize()
    return #self.stack.items - 1
end

function GridCell:isInHotbar()
    local hotbar = getPlayerHotbar(self.pane.native.player)
    -- Double check: inHotbar is not reliable
    return self.stack.inHotbar or hotbar and hotbar:isInHotbar(self.item) and not self.stack.equipped
end

function GridCell:isCategory()
    return self.category == self
end

function GridCell:isCollapsed()
    return self:isCategory() and self.pane.native.collapsed[self.stack.name] and self:getStackSize() > 1
end

function GridCell:isHovered()
    return self.pane.native.mouseOverOption == self.index
end

function GridCell:isSelected()
    local selected = self.pane.native.selected
    return selected and selected[self.index]
end

---@param x number
---@param y number
function GridCell:render(x, y)
    local cellSize = M.ItemIcon.cellSize

    self:drawBackground(x, y)

    local job = self.item:getJobDelta()
    if job > 0 and (not self:isCategory() or self:isCollapsed()) then
        self.pane.native:drawRect(x, y + (1 - job) * cellSize, cellSize, job * cellSize,
            0.2, 0.4, 1.0, 0.3);
    end

    if self:isCategory() then
        if self:isCollapsed() then
            self.icon:drawBase(x, y)
            self.icon:drawSubscript(x, y, tostring(self:getStackSize()))
        else
            self.icon:drawBase(x, y, 0.5)
            self.icon:drawSubscript(x, y, tostring(self:getStackSize()), 0.6)
        end
    else
        self.icon:drawBase(x, y)
        self.icon:drawDetails(x, y)
    end
end

-- See ISInventoryPane:renderdetails
---@param x number
---@param y number
function GridCell:drawBackground(x, y)
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
                native:drawRect(x, y, cellSize, cellSize, 0.20, 1.0, 0.0, 0.0);
                -- else -- Vanilla background
                --     native:drawRect(x, y, cellSize, cellSize, 0.025, 1.0, 1.0, 1.0);
            end
        else
            native:drawRect(x, y, cellSize - 1, cellSize - 1, 0.20, 1.0, 1.0, 1.0);
            native:drawRectBorder(x, y, cellSize, cellSize, 0.10, 1.0, 1.0, 1.0);
        end
    elseif self:isHovered() and heat == 1 then
        native:drawRect(x, y, cellSize, cellSize, 0.05, 1.0, 1.0, 1.0);
    elseif native.highlightItem and native.highlightItem == item:getType() then
        if not native.blinkAlpha then native.blinkAlpha = 0.5; end
        native:drawRect(x, y, cellSize, cellSize, native.blinkAlpha, 1, 1, 1);
        if not native.blinkAlphaIncrease then
            native.blinkAlpha = native.blinkAlpha - 0.05 * (UIManager.getMillisSinceLastRender() / 33.3);
            if native.blinkAlpha < 0 then
                native.blinkAlpha = 0;
                native.blinkAlphaIncrease = true;
            end
        else
            native.blinkAlpha = native.blinkAlpha + 0.05 * (UIManager.getMillisSinceLastRender() / 33.3);
            if native.blinkAlpha > 0.5 then
                native.blinkAlpha = 0.5;
                native.blinkAlphaIncrease = false;
            end
        end
    elseif heat ~= 1 then
        local alpha = self:isHovered() and 0.45 or 0.3
        if heat > 1 then
            native:drawRect(x, y, cellSize, cellSize, alpha, math.abs(item:getInvHeat()), 0.0, 0.0);
        else
            native:drawRect(x, y, cellSize, cellSize, alpha, 0.0, 0.0, math.abs(item:getInvHeat()));
            -- elseif instanceof(item, "Clothing") and (
            --         item:getBodyLocation() == "Shoes" and item:getWetness() > 60
            --         or item:getWetness() > 10
            --     )
            -- then
            --     native:drawRect(x, y, cellSize, cellSize, 0.2, 0.0, 0.6, 1);
            -- elseif instanceof(item, "Food") and not item:isFresh() then
            --     if item:isRotten() then
            --         native:drawRect(x, y, cellSize, cellSize, 0.8, 0.25, 0.1, 0);
            --     else
            --         native:drawRect(x, y, cellSize, cellSize, 0.4, 0.25, 0.25, 0);
        end
    end

    if native.itemsToHighlight ~= nil and native.itemsToHighlight[item] == true then
        native:drawRect(x, y, cellSize, cellSize, 0.2, 1.0, 1.0, 1.0);
    end
end
