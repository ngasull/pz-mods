local M = require("IconsInventory/mod")

---@class IconsInventory_GridLayout<T>
---@field width number
---@field groupSpace number
---@field cells T[][]
---@field gridWidth integer
---@field height number
local GridLayout = {}
GridLayout.__index = GridLayout
M.GridLayout = GridLayout

---@param groupSpace number
function GridLayout.new(groupSpace)
    ---@type IconsInventory_GridLayout
    local self = setmetatable({}, GridLayout)
    self.width = 0
    self.height = 0
    self.gridWidth = 1
    self.groupSpace = groupSpace
    self.cells = {}
    return self
end

---@return T?, integer, integer
function GridLayout:hitTest(mx, my)
    if mx >= 0 and my >= 0 then
        local candidateColumn = math.floor(mx / M.ItemIcon.cellSize)

        if candidateColumn < self.gridWidth then
            for i, group in ipairs(self.cells) do
                local candidateRow = math.floor(my / M.ItemIcon.cellSize)
                local groupRowCount = math.ceil(#group / self.gridWidth)
                if candidateRow < groupRowCount then
                    local candidate = candidateRow * self.gridWidth + candidateColumn
                    if candidate < #group then
                        return group[candidate + 1], i, candidate + 1
                    else
                        return
                    end
                end
                my = my - groupRowCount * M.ItemIcon.cellSize - self.groupSpace
            end
        end
    end
end

---@param cells T[][]
---@param width number
function GridLayout:set(cells, width)
    self.cells = cells
    self.width = width
    self:refresh()
end

function GridLayout:refresh()
    self.gridWidth = math.max(1, math.floor(self.width / M.ItemIcon.cellSize))

    self.height = (#self.cells - 1) * self.groupSpace
    for _, group in ipairs(self.cells) do
        self.height = self.height + self:calcGroupHeight(#group)
    end
end

---@param nRows integer
function GridLayout:calcGroupHeight(nRows)
    return M.ItemIcon.cellSize * math.ceil(nRows / self.gridWidth)
end
