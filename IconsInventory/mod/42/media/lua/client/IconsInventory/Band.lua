local Cell = require("IconsInventory/Cell")

---@class IconsInventory_Band
---@field pane IconsInventory_IconsPane
---@field x0 number
---@field y0 number
---@field x1 number
---@field y1 number
---@field active? boolean
local Band = {}
Band.__index = Band

---@param pane IconsInventory_IconsPane
function Band.new(pane)
    local self = setmetatable({}, Band)
    self.pane = pane
    self.x0 = pane:getMouseX()
    self.y0 = pane:getMouseY()
    self.x1 = self.x0
    self.y1 = self.y0
    return self
end

function Band:update()
    local mx, my = self.pane:getMouseX(), self.pane:getMouseY()
    self.x1 = math.max(0, math.min(self.pane:getWidth(), mx))
    self.y1 = math.max(0, math.min(self.pane:getHeight(), my))
    self.active = self.active or math.abs(self.x1 - self.x0) + math.abs(self.y1 - self.y0) > 6

    if self.active then
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
            yOffset = yOffset + math.ceil(#group / self.pane.grid.gridWidth) * Cell.size + self.pane.grid.groupSpace
        end

        local scroll = self.pane:getYScroll()
        if self.y1 + scroll < 0 then
            self.pane:setYScroll(-self.y1)
        elseif self.y1 + scroll > self.pane:getHeight() then
            self.pane:setYScroll(self.pane:getHeight() - self.y1)
        end
    end
end

function Band:apply()
    self.pane.band = nil
    for cell in pairs(self.pane.beingSelected) do
        cell:setSelected(true)
    end
    table.wipe(self.pane.beingSelected)
end

function Band:render()
    if self.active then
        local x, y = math.min(self.x0, self.x1), math.min(self.y0, self.y1)
        local w, h = math.abs(self.x1 - self.x0), math.abs(self.y1 - self.y0)
        self.pane:drawRect(x, y, w, h, 0.1, 1, 1, 1)
        self.pane:drawRectBorder(x, y, w, h, 0.4, 1, 1, 1)
    end
end

return Band
