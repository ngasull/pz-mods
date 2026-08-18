local Cell = require("IconsInventory/Cell")

---@class IconsInventory_CellPool
---@field store table<integer|string, IconsInventory_Cell>
---@field nextStore table<integer|string, IconsInventory_Cell>
---@field reused IconsInventory_Cell[]
local CellPool = {}
CellPool.__index = CellPool

function CellPool.new()
    ---@type IconsInventory_CellPool
    local self = setmetatable({}, CellPool)
    self.nextStore = {}
    return self
end

function CellPool:prepare()
    self.store = self.nextStore
    self.nextStore = {}
end

---@param item InventoryItem
---@param pane IconsInventory_IconsPane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function CellPool:cell(item, pane, index, stack, category)
    local key = category and item:getID() or stack.name
    local cell = self.store[key]
    if cell then
        cell:init(pane, index, stack, category)
    else
        cell = Cell.new(item, pane, index, stack, category)
    end
    self.nextStore[key] = cell
    return cell
end

function CellPool:get(itemOrStack)
    return self.nextStore[instanceof(itemOrStack, "InventoryItem") and itemOrStack:getID() or itemOrStack.name]
end

return CellPool
