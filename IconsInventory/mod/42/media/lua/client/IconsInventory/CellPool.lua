local Cell = require("IconsInventory/Cell")

---@class IconsInventory_CellPool
---@field player IsoPlayer
---@field store table<integer|string|ContextMenuItemStack, IconsInventory_Cell>
---@field nextStore table<integer|string, IconsInventory_Cell>
---@field reused IconsInventory_Cell[]
local CellPool = {}
CellPool.__index = CellPool

---@param player IsoPlayer
function CellPool.new(player)
    ---@type IconsInventory_CellPool
    local self = setmetatable({}, CellPool)
    self.player = player
    self.nextStore = {}
    return self
end

function CellPool:prepare()
    self.store = self.nextStore
    self.nextStore = {}
end

-- Stack key with many fallbacks
---@param player IsoPlayer
---@param stack ContextMenuItemStack
---@param item? InventoryItem
---@return string | ContextMenuItemStack
local function stackKey(player, stack, item)
    if stack.name then return stack.name end
    if not item then item = stack.items[1] end
    return item and item:getName(player) or stack
end

---@param item InventoryItem
---@param pane IconsInventory_IconsPane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
---@return IconsInventory_Cell
function CellPool:cell(item, pane, index, stack, category)
    local key = category and item:getID() or stackKey(self.player, stack, item)
    local cell = self.store[key]
    if cell then
        cell:init(pane, index, stack, category)
    else
        cell = Cell.new(item, pane, index, stack, category)
    end
    self.nextStore[key] = cell
    return cell
end

---@param itemOrStack InventoryItem | ContextMenuItemStack
---@return IconsInventory_Cell?
function CellPool:get(itemOrStack)
    local key = instanceof(itemOrStack, "InventoryItem") and itemOrStack:getID()
        ---@cast itemOrStack ContextMenuItemStack
        or stackKey(self.player, itemOrStack)
    return self.nextStore[key]
end

return CellPool
