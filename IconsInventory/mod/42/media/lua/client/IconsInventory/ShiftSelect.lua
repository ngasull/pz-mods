local Cell = require("IconsInventory/Cell")

---@class IconsInventory_ShiftSelect
---@field pane IconsInventory_IconsPane
---@field from IconsInventory_Cell
---@field to IconsInventory_Cell
local ShiftSelect = {}
ShiftSelect.__index = ShiftSelect

---@param pane IconsInventory_IconsPane
---@param start IconsInventory_Cell
function ShiftSelect.new(pane, start)
    local self = setmetatable({}, ShiftSelect)
    self.pane = pane
    self.from = start
    self.to = start
    return self
end

---@param last IconsInventory_Cell
function ShiftSelect:setTo(last)
    self.to = last

    table.wipe(self.pane.beingSelected)
    self.pane.beingSelected[self.from] = true
    self.pane.beingSelected[self.to] = true

    local isSelecting
    local yOffset = 0
    for _, group in ipairs(self.pane.grid.cells) do
        for i, cell in ipairs(group) do
            if cell == self.from then isSelecting = not isSelecting end
            if cell == self.to then isSelecting = not isSelecting end
            if isSelecting == false then break end
            if isSelecting then
                self.pane.beingSelected[cell] = true
            end
        end
        if isSelecting == false then break end
        yOffset = yOffset + math.ceil(#group / self.pane.grid.gridWidth) * Cell.size + self.pane.grid.groupSpace
    end

    local my = self.pane:getMouseY()
    local scroll = self.pane:getYScroll()
    if my + scroll < 0 then
        self.pane:setYScroll(math.max(0, my))
    elseif my + scroll > self.pane:getHeight() then
        self.pane:setYScroll(math.min(self.pane:getHeight(), my))
    end
end

function ShiftSelect:apply()
    self.pane.shiftSelect = nil
    for cell in pairs(self.pane.beingSelected) do
        cell:setSelected(true)
    end
    table.wipe(self.pane.beingSelected)
end

return ShiftSelect
