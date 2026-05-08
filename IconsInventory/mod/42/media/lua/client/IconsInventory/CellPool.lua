local M = require("IconsInventory/mod")

---@class IconsInventory_CellPool
---@field store table<InventoryItem|ContextMenuItemStack, IconsInventory_Cell>
---@field nextStore table<InventoryItem|ContextMenuItemStack, IconsInventory_Cell>
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
---@param pane IconsInventory_IconsPane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function CellPool:get(item, pane, index, stack, category)
    local key = category and item or stack
    local cell = self.store[key]
    if cell then
        self.store[key] = nil
        cell:init(pane, index, stack, category)
    else
        cell = M.Cell.new(item, pane, index, stack, category)
    end
    self.nextStore[key] = cell
    return cell
end
