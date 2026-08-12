local Cell = require("IconsInventory/Cell")

---@class IconsInventory_GridLayout<T>
---@field groupSpace number
---@field cells T[][]
---@field gridWidth integer
---@field x number
---@field y number
---@field width number
---@field height number
---@field _rows? T[][]
local GridLayout = {}
GridLayout.__index = GridLayout

---@param groupSpace number
function GridLayout.new(groupSpace)
    ---@type IconsInventory_GridLayout
    local self = setmetatable({}, GridLayout)
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.gridWidth = 1
    self.groupSpace = groupSpace
    self.cells = {}
    return self
end

---@return T?, integer, integer
function GridLayout:hitTest(mx, my)
    mx = mx - self.x
    my = my - self.y
    if mx >= 0 and my >= 0 then
        local candidateColumn = math.floor(mx / Cell.size)

        if candidateColumn < self.gridWidth then
            for i, group in ipairs(self.cells) do
                local candidateRow = math.floor(my / Cell.size)
                local groupRowCount = math.ceil(#group / self.gridWidth)
                if candidateRow < groupRowCount then
                    local candidate = candidateRow * self.gridWidth + candidateColumn
                    if candidate < #group then
                        return group[candidate + 1], i, candidate + 1
                    else
                        return
                    end
                end
                my = my - groupRowCount * Cell.size - self.groupSpace
            end
        end
    end
end

---@param cells T[][]
---@param gridWidth integer
function GridLayout:set(cells, gridWidth)
    self.cells = cells
    self._rows = nil

    self.gridWidth = math.max(1, gridWidth)
    self.width = self.gridWidth * Cell.size

    self.height = (#self.cells - 1) * self.groupSpace
    for _, group in ipairs(self.cells) do
        self.height = self.height + self:calcGroupHeight(#group)
    end
end

function GridLayout:getRows()
    if not self._rows then
        self._rows = {}

        local rows = self._rows
        local row ---@type T[]?
        for _, group in ipairs(self.cells) do
            for _, cell in ipairs(group) do
                if not row then row = {} end

                table.insert(row, cell)
                local r = #rows + 1
                local c = #row

                if #row == self.gridWidth then
                    table.insert(rows, row)
                    row = nil
                end
            end

            if row and #row > 0 then
                table.insert(rows, row)
                row = nil
            end
        end
    end
    return self._rows
end

---@param nRows integer
function GridLayout:calcGroupHeight(nRows)
    return Cell.size * math.ceil(nRows / self.gridWidth)
end

---@param row integer
---@param col integer
function GridLayout:getCellAt(row, col)
    local rows = self:getRows()
    if row < 0 then row = #rows + row + 1 end

    local cols = rows[row]
    if cols then
        if col < 0 then col = #cols + col + 1 end
        return cols[col]
    end
end

---@param cell? T
---@return_overload integer, integer
---@return_overload nil
function GridLayout:locateCell(cell)
    for r, cols in ipairs(self:getRows()) do
        for c, rcell in ipairs(cols) do
            if rcell == cell then
                return r, c
            end
        end
    end
end

return GridLayout
