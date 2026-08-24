local Cell = require("IconsInventory/Cell")
local GridLayout = require("IconsInventory/GridLayout")

---@class IconsInventory_DragSelectionBox
---@field pane IconsInventory_IconsPane
---@field x0 number
---@field y0 number
---@field x1 number
---@field y1 number
local DragSelectionBox = {}
DragSelectionBox.__index = DragSelectionBox

---@param pane IconsInventory_IconsPane
---@param x number
---@param y number
function DragSelectionBox.new(pane, x, y)
    local self = setmetatable({}, DragSelectionBox)
    self.pane = pane
    self.x0, self.y0 = x, y
    self.x1, self.y1 = x, y
    return self
end

function DragSelectionBox:update()
    local mx, my = self.pane:getMouseX(), self.pane:getMouseY()
    self.x1 = math.max(0, math.min(self.pane.width, mx))
    self.y1 = math.max(0, math.min(self.pane.height, my))

    table.wipe(self.pane.beingSelected)

    local left = math.min(self.x0, self.x1) - self.pane.grid.x
    local right = math.max(self.x0, self.x1) - self.pane.grid.x
    local top = math.min(self.y0, self.y1) - self.pane.grid.y
    local bottom = math.max(self.y0, self.y1) - self.pane.grid.y

    local yOffset = 0
    for _, group in ipairs(self.pane.grid.cells) do
        for i, cell in ipairs(group) do
            if not cell:isSelected() then
                local cx = ((i - 1) % self.pane.grid.gridWidth) * Cell.size
                local cy = yOffset + math.floor((i - 1) / self.pane.grid.gridWidth) * Cell.size
                if cx < right and cx + Cell.size > left and cy < bottom and cy + Cell.size > top then
                    self.pane.beingSelected[cell] = true
                end
            end
        end
        yOffset = yOffset + math.ceil(#group / self.pane.grid.gridWidth) * Cell.size + GridLayout.groupSpace
    end

    local scroll = self.pane:getYScroll()
    if self.y1 + scroll < 0 then
        self.pane:setYScroll(-self.y1)
    elseif self.y1 + scroll > self.pane.height then
        self.pane:setYScroll(self.pane.height - self.y1)
    end
end

function DragSelectionBox:apply()
    self.pane.dragSelectionBox = nil
    for cell in pairs(self.pane.beingSelected) do
        cell:setSelected(true)
    end
    table.wipe(self.pane.beingSelected)
end

function DragSelectionBox:render()
    local x, y = math.min(self.x0, self.x1), math.min(self.y0, self.y1)
    local w, h = math.abs(self.x1 - self.x0), math.abs(self.y1 - self.y0)
    self.pane:drawRect(x, y, w, h, 0.1, 1, 1, 1)
    self.pane:drawRectBorder(x, y, w, h, 0.4, 1, 1, 1)
end

return DragSelectionBox
