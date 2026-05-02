local M = require("IconsInventory/mod")

---@class IconsInventory_GridLayout<T>
---@field groupSpace number
---@field cells T[][]
---@field gridWidth integer
---@field width number
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
---@param gridWidth integer
function GridLayout:set(cells, gridWidth)
    self.cells = cells
    self._locateCell_mem = nil
    self._locateCell_rows = nil

    self.gridWidth = math.max(1, gridWidth)
    self.width = self.gridWidth * M.ItemIcon.cellSize

    self.height = (#self.cells - 1) * self.groupSpace
    for _, group in ipairs(self.cells) do
        self.height = self.height + self:calcGroupHeight(#group)
    end
end

---@param nRows integer
function GridLayout:calcGroupHeight(nRows)
    return M.ItemIcon.cellSize * math.ceil(nRows / self.gridWidth)
end

---@param row integer
---@param col integer
function GridLayout:getCellAt(row, col)
    for _, group in ipairs(self.cells) do
        local groupRows = math.ceil(#group / self.gridWidth)
        if groupRows >= row then
            return group[(row - 1) * self.gridWidth + col]
        end
        row = row - groupRows
    end
end

---@param cell? T
---@return_overload T[][], integer, integer
---@return_overload T[][]
function GridLayout:locateCell(cell)
    if not self._locateCell_mem then
        self._locateCell_mem = {}
        self._locateCell_rows = {}

        local rows = self._locateCell_rows
        local row
        for _, group in ipairs(self.cells) do
            for _, gcell in ipairs(group) do
                if not row then row = {} end

                table.insert(row, gcell)
                local r = #rows + 1
                local c = #row
                self._locateCell_mem[gcell] = { r, c }

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

    local ij = self._locateCell_mem[cell]
    if ij then
        return self._locateCell_rows, ij[1], ij[2]
    else
        return self._locateCell_rows
    end
end

---@param cell? T
function GridLayout:getCellRight(cell)
    local rows, row, col = self:locateCell(cell)
    if row and col then
        local cols = rows[row]
        return cols[(col % #cols) + 1]
    else
        -- Find first leftmost cell if any
        for r = 1, #rows do
            for c = 1, #rows[r] do
                return rows[r][c]
            end
        end
    end
end

---@param cell? T
function GridLayout:getCellLeft(cell)
    local rows, row, col = self:locateCell(cell)
    if row and col then
        local cols = rows[row]
        return cols[((col - 2 + #cols) % #cols) + 1]
    else
        -- Find first rightmost cell if any
        for r = 1, #rows do
            for c = #rows[r], 1 do
                return rows[r][c]
            end
        end
    end
end

---@param cell? T
function GridLayout:getCellDown(cell)
    local rows, row, col = self:locateCell(cell)
    if row and col then
        local nextRow = rows[(row % #rows) + 1]
        return nextRow[math.min(#nextRow, col)]
    else
        -- Find first upmost cell if any
        for r = 1, #rows do
            for c = 1, #rows[r] do
                return rows[r][c]
            end
        end
    end
end

---@param cell? T
function GridLayout:getCellUp(cell)
    local rows, row, col = self:locateCell(cell)
    if row and col then
        local prevRow = rows[((row - 2 + #rows) % #rows) + 1]
        return prevRow[math.min(#prevRow, col)]
    else
        -- Find first downmost cell if any
        for r = #rows, 1 do
            for c = 1, #rows[r] do
                return rows[r][c]
            end
        end
    end
end
