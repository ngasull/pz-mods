local Cell = require("IconsInventory/Cell")

---@class IconsInventory_CellPool
---@field store table<integer|string, IconsInventory_Cell>
---@field nextStore table<integer|string, IconsInventory_Cell>
---@field reused IconsInventory_Cell[]
local CellPool = {}
CellPool.__index = CellPool

CellPool._nextContainerID = 0
CellPool._containerIds = setmetatable({}, { __mode = "k" })

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

---@param stack ContextMenuItemStack
local function stackKey(stack)
    local container = stack.items[1]:getContainer()
    local id = CellPool._containerIds[container]
    if not id then
        -- Found no better to identify containers thus far
        id = tostring(CellPool._nextContainerID)
        CellPool._containerIds[container] = id
        CellPool._nextContainerID = CellPool._nextContainerID + 1
    end
    -- Do not trust access to the weak table here: use local variables (Drumz reported nil concat here)
    return id .. stack.name
end

---@param item InventoryItem
---@param pane IconsInventory_IconsPane
---@param index integer "Option" index in vanilla
---@param stack ContextMenuItemStack
---@param category? IconsInventory_Cell
function CellPool:cell(item, pane, index, stack, category)
    local key = category and item:getID() or stackKey(stack)
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
    local key = instanceof(itemOrStack, "InventoryItem") and itemOrStack:getID() or stackKey(itemOrStack)
    return self.nextStore[key]
end

return CellPool
