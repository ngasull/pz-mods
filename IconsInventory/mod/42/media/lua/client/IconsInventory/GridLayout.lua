local Cell = require("IconsInventory/Cell")

---@class IconsInventory_GridLayout_Located
---@field layoutGroup integer
---@field layoutGroupRow integer
---@field layoutCol integer
---@field layoutRow integer

---@generic T: IconsInventory_GridLayout_Located
---@class IconsInventory_GridLayout<T>
---@field cells T[][]
---@field gridWidth integer
---@field gridHeight integer
---@field x number
---@field y number
---@field _rows? T[][]
local GridLayout = {}
GridLayout.__index = GridLayout

function GridLayout._init()
    GridLayout.groupSpace = 2 * Cell.padding
end

function GridLayout.new()
    ---@type IconsInventory_GridLayout
    local self = setmetatable({}, GridLayout)
    self.x = 0
    self.y = 0
    self.gridWidth = 1
    self.cells = {}
    return self
end

---@param cells T[][]
---@param gridWidth integer
function GridLayout:set(cells, gridWidth)
    self.cells = cells
    self._rows = nil

    self.gridWidth = math.max(1, gridWidth)
    self.gridHeight = 0

    for g, group in ipairs(self.cells) do
        local lastRow = 0
        for i, cell in ipairs(group) do
            cell.layoutGroup = g
            cell.layoutGroupRow = 1 + math.floor((i - 1) / self.gridWidth)
            cell.layoutCol = 1 + ((i - 1) % self.gridWidth)

            if cell.layoutGroupRow ~= lastRow then
                self.gridHeight = self.gridHeight + 1
                lastRow = cell.layoutGroupRow
            end
            cell.layoutRow = self.gridHeight
        end
    end
end

function GridLayout:getRows()
    if not self._rows then
        self._rows = {}

        local rows = self._rows ---@cast rows -nil
        local row ---@type T[]?
        for _, group in ipairs(self.cells) do
            for _, cell in ipairs(group) do
                if not row then row = {} end

                table.insert(row, cell)

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

return GridLayout
