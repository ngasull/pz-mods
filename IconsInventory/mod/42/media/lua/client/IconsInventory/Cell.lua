local mod = require("IconsInventory/mod")
local Action = require("IconsInventory/Action")
local CellRender = require("IconsInventory/CellRender")

---@class IconsInventory_Cell: IconsInventory_CellBase, IconsInventory_CellRender

---@class IconsInventory_CellBase
---@field pane IconsInventory_IconsPane
---@field item InventoryItem
---@field index integer
---@field stack ContextMenuItemStack
---@field category IconsInventory_CellBase
---@field player IsoPlayer
--- Current render loop's state:
---@field x number
---@field y number
local Cell = {}

for k, v in pairs(CellRender) do Cell[k] = v end
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
---@param category? IconsInventory_CellBase
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

local function refreshResolution()
    -- NB: Makes 2K render as 4K because PZ decides 2K text is at 4K size
    Cell.scaling = math.max(1, math.min(2, math.floor(0.7 + getCore():getScreenHeight() / 1080)))
    Cell.iconSize = 32 * Cell.scaling
    Cell.padding = 4 * Cell.scaling
    Cell.size = Cell.iconSize + 2 * Cell.padding
end

refreshResolution()
-- ! -- Not reliably called
-- Events.OnResolutionChange.Add(refreshResolution)

return Cell
