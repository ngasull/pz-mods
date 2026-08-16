local mod = require("IconsInventory/mod")
local Cell = require("IconsInventory/Cell")
local GridLayout = require("IconsInventory/GridLayout")

---@class IconsInventory_MultiSelect
---@field pane IconsInventory_IconsPane
---@field from IconsInventory_Cell
---@field to IconsInventory_Cell
---@field startTime integer
local MultiSelect = {}
MultiSelect.__index = MultiSelect

---@param pane IconsInventory_IconsPane
---@param mouseDown IconsInventory_IconsPane_MouseDown
---@param focused IconsInventory_IconsPane_CellDown
function MultiSelect.handleDrag(pane, mouseDown, focused)
    if not pane.multiSelect then
        if not mouseDown.ctrl and not mod.option.enableSmartDrag:getValue() then
            table.wipe(pane.native.selected)
        end
        pane.multiSelect = MultiSelect.new(pane, focused.cell)
    elseif pane.focusedCell then
        pane.multiSelect:setTo(pane.focusedCell)
    end
end

---@param pane IconsInventory_IconsPane
---@param start IconsInventory_Cell
function MultiSelect.new(pane, start)
    local self = setmetatable({}, MultiSelect)
    self.pane = pane
    self.from = start
    self.to = start
    self.startTime = getTimestampMs()
    return self
end

---@param last IconsInventory_Cell
function MultiSelect:setTo(last)
    self.to = last

    table.wipe(self.pane.beingSelected)
    self.pane.beingSelected[self.from] = true
    self.pane.beingSelected[self.to] = true

    local isSelecting
    local yOffset = 0
    for _, group in ipairs(self.pane.grid.cells) do
        for _, cell in ipairs(group) do
            if cell == self.from then isSelecting = not isSelecting end
            if cell == self.to then isSelecting = not isSelecting end
            if isSelecting == false then break end
            if isSelecting then
                self.pane.beingSelected[cell] = true
            end
        end
        if isSelecting == false then break end
        yOffset = yOffset + math.ceil(#group / self.pane.grid.gridWidth) * Cell.size + GridLayout.groupSpace
    end

    local my = self.pane:getMouseY()
    local scroll = self.pane:getYScroll()
    if my + scroll < 0 then
        self.pane:setYScroll(math.max(0, my))
    elseif my + scroll > self.pane:getHeight() then
        self.pane:setYScroll(math.min(self.pane:getHeight(), my))
    end
end

function MultiSelect:apply()
    for cell in pairs(self.pane.beingSelected) do
        cell:setSelected(true)
    end
    self:reset()
end

function MultiSelect:reset()
    self.pane.multiSelect = nil
    table.wipe(self.pane.beingSelected)
end

return MultiSelect
