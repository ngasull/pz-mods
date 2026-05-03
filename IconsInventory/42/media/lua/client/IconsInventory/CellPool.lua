local M = require("IconsInventory/mod")

---@class IconsInventory_CellPool
---@field store table<InventoryItem, IconsInventory_Cell>
---@field nextStore table<InventoryItem, IconsInventory_Cell>
---@field reused IconsInventory_Cell[]
local CellPool = {}
CellPool.__index = CellPool
M.CellPool = CellPool

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
---@param pane IconsInventory_Pane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function CellPool:get(item, pane, index, stack, category)
    local cell = self.store[item]
    if cell then
        self.store[item] = nil
        cell:init(pane, index, stack, category)
    else
        cell = M.Cell.new(item, pane, index, stack, category)
    end
    self.nextStore[item] = cell
    return cell
end
