local mod = require("IconsInventory/mod")
local Action = require("IconsInventory/Action")
local CellRender = require("IconsInventory/CellRender")

---@class IconsInventory_Cell: IconsInventory_GridLayout_Located
---@field pane IconsInventory_IconsPane
---@field item InventoryItem
---@field index integer
---@field stack ContextMenuItemStack
---@field category IconsInventory_Cell
---@field player IsoPlayer
--- Current render loop's state:
---@field x number
---@field y number
---@field padSubIcon number
local Cell = {}

for k, v in pairs(CellRender) do Cell[k] = v end
Cell.__index = Cell

local iconFonts = { UIFont.NewSmall, UIFont.NewMedium, UIFont.NewLarge }

function Cell._init()
    local userSize = mod.option.iconSize:getValue()
    local font = iconFonts[userSize]
    Cell.scaling = mod.getBaseScaling() + 0.5 * (userSize - 1)
    Cell.iconSize = math.floor(mod.NATIVE_SIZE * Cell.scaling)
    Cell.padding = math.floor(4 * Cell.scaling)
    Cell.size = Cell.iconSize + 2 * Cell.padding
    -- Offset to which sub-infos center should be aligned
    Cell.subAlign = math.floor(Cell.padding / 2 + 6 * mod.getBaseScaling())

    -- Without touching scaling, reduce font if it seems too big
    while userSize > 1 and getTextManager():MeasureStringYReal(font, "I") > Cell.iconSize / 3 do
        userSize = userSize - 1
        font = iconFonts[userSize]
    end
    Cell.font = font
end

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
    self.layoutGroup = 0
    self.layoutRow = 0
    self.layoutCol = 0
    self.layoutAbsRow = 0
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
    return not self.stack.equipped and not self.stack.inHotbar and mod.option.alwaysCollapseOver:getValue() > 0 and (
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

function Cell:isBeingSelected()
    local isTooEarlyToDisplay = mod.option.enableSmartDrag:getValue() and not isShiftKeyDown() and (
        self.pane.mouseDown and self.pane:isMouseOver()
        and getTimestampMs() - self.pane.mouseDown.dragStartTime < 200
    )
    return self.pane.beingSelected[self] and not isTooEarlyToDisplay
end

---@param isSelected boolean?
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

---@cast Cell IconsInventory_Cell
return Cell
