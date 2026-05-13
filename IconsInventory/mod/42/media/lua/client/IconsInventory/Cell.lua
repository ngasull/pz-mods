local mod = require("IconsInventory/mod")
local Action = require("IconsInventory/Action")
local ItemIcon = require("IconsInventory/ItemIcon")

---@class IconsInventory_Cell: IconsInventory_ItemIcon
---@field pane IconsInventory_IconsPane
---@field item InventoryItem
---@field index integer
---@field stack ContextMenuItemStack
---@field category IconsInventory_Cell
---@field player IsoPlayer
local Cell = {}
Cell.__index = Cell

---@param item InventoryItem
---@param ... any
function Cell.new(item, ...)
    ---@type IconsInventory_Cell
    local self = setmetatable({}, Cell)
    self.item = item
    self:init(...)
    return self
end

---@param pane IconsInventory_IconsPane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function Cell:init(pane, index, stack, category)
    self.pane = pane
    self.index = index
    self.stack = stack
    self.category = category or self
    self.player = getSpecificPlayer(pane.native.player)
end

function Cell:getStackSize()
    return #self.stack.items - 1
end

-- Gets the matching object in vanilla list
function Cell:getListItem()
    return self.category == self and self.stack or self.item
end

function Cell:isCategory()
    return self.category == self
end

function Cell:isCollapsable()
    local stackSize = #self.stack.items - 1
    return not self.stack.equipped and not self.stack.inHotbar and mod.option.alwaysCollapseOver:getValue() > 1 and (
        stackSize > mod.option.alwaysCollapseOver:getValue()
        or stackSize > 1 and self.stack.weight / stackSize < mod.option.collapseItemsUnder:getValue()
    )
end

function Cell:isEquipped()
    return self.player:isEquipped(self.item)
end

function Cell:isInEquippedGroup()
    return self.stack.equipped
end

function Cell:isInHotbar()
    local hotbar = not self.player:isEquipped(self.item) and getPlayerHotbar(self.player:getIndex());
    return hotbar and hotbar:isInHotbar(self.item) or false
end

function Cell:isCollapsed()
    if not self:isCategory() or self:getStackSize() < 2 then return false end
    return not self.pane.expanded[self.stack.name] and self:isCollapsable()
end

function Cell:isFocused()
    return self.pane.focusedCell == self
end

function Cell:isSelected()
    local selected = self.pane.native.selected
    return not not (selected and selected[self.index])
end

---@param isSelected boolean
function Cell:setSelected(isSelected)
    if self:isCategory() then
        -- Sync all items with category
        for i = 0, #self.stack.items - 1 do
            self.pane.native.selected[self.index + i] = isSelected and self.pane.native.items[self.index + i] or nil
        end
    else
        self.pane.native.selected[self.index] = isSelected and self.pane.native.items[self.index] or nil

        -- Unselect category if it has unselected elements (=> non-vanilla)
        local category = self.category
        self.pane.native.selected[category.index] = self.pane.native.items[category.index]
        for i = 1, #category.stack.items - 1 do
            if not self.pane.native.selected[category.index + i] then
                self.pane.native.selected[category.index] = nil
                break
            end
        end
    end
end

function Cell:isQueuedForTransfer()
    if self:isCategory() then
        if not self:isCollapsed() then return false end
        for _, item in ipairs(self.stack.items) do
            if not Action.isQueuedForTransfer(item) then
                return false
            end
        end
        return true
    else
        return Action.isQueuedForTransfer(self.item)
    end
end

function Cell:isCleanUIHighlighted()
    return self.stack.matchesSearch
end

---@param x number
---@param y number
function Cell:render(x, y)
    local cellSize = ItemIcon.cellSize

    self:drawBackground(x, y)

    local job = self.item:getJobDelta()
    if job > 0 and (not self:isCategory() or self:isCollapsed()) then
        self.pane:drawRect(x, y + (1 - job) * cellSize, cellSize, job * cellSize,
            0.2, 0.4, 1.0, 0.3);
    elseif self:isQueuedForTransfer() then
        local animDuration = 1000
        local animDelta = math.fmod(getTimeInMillis(), animDuration) / animDuration;
        local blinkStrength = 2 * math.abs(animDelta - 0.5)
        self.pane:drawRect(x, y, cellSize, cellSize,
            0.1 + blinkStrength * 0.05, 0.4, 1.0, 0.3);
    end

    if self:isCategory() then
        if self:isCollapsed() then
            ItemIcon.drawBase(self, x, y)
            ItemIcon.drawSubscript(self, x, y, tostring(self:getStackSize()))
        else
            ItemIcon.drawBase(self, x, y, 0.5)
            ItemIcon.drawSubscript(self, x, y, tostring(self:getStackSize()), 0.6)
        end
    else
        ItemIcon.drawBase(self, x, y)
        ItemIcon.drawDetails(self, x, y)
    end
end

-- See ISInventoryPane:renderdetails
---@param x number
---@param y number
function Cell:drawBackground(x, y)
    local cellSize = ItemIcon.cellSize
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
                self.pane:drawRect(x, y, cellSize, cellSize, 0.20, 1.0, 0.0, 0.0)
            end
        else
            self.pane:drawRect(x, y, cellSize - 1, cellSize - 1, 0.20, 1.0, 1.0, 1.0)
            self.pane:drawRectBorder(x, y, cellSize, cellSize, 0.10, 1.0, 1.0, 1.0)
        end
    elseif self:isFocused() and heat == 1 and not self:isCleanUIHighlighted() then
        if native.doController then
            self.pane:drawRect(x, y, cellSize, cellSize, 0.2, 0.2, 1.0, 1.0)
        else
            self.pane:drawRect(x, y, cellSize, cellSize, 0.05, 1.0, 1.0, 1.0)
        end
    elseif native.highlightItem and native.highlightItem == item:getType() then
        if not native.blinkAlpha then native.blinkAlpha = 0.5; end
        self.pane:drawRect(x, y, cellSize, cellSize, native.blinkAlpha, 1, 1, 1)
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
    elseif self:isCleanUIHighlighted() then
        self.pane:drawRect(x, y, cellSize, cellSize, self:isFocused() and 0.45 or 0.3, 0.5, 0.3, 0.1)
    elseif heat ~= 1 then
        local alpha = self:isFocused() and 0.45 or 0.3
        if heat > 1 then
            self.pane:drawRect(x, y, cellSize, cellSize, alpha, math.abs(item:getInvHeat()), 0.0, 0.0)
        else
            self.pane:drawRect(x, y, cellSize, cellSize, alpha, 0.0, 0.0, math.abs(item:getInvHeat()))
        end
    end

    if native.doController and self:isFocused() then
        self.pane:drawRectBorder(x, y, cellSize, cellSize, 0.2, 1, 1, 1)
    end

    if native.itemsToHighlight ~= nil and native.itemsToHighlight[item] == true then
        self.pane:drawRect(x, y, cellSize, cellSize, 0.2, 1.0, 1.0, 1.0)
    end
end

return Cell
