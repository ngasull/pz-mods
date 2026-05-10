local M = {
    option = {},

    ---@class M_IconsPane: IconsInventory_IconsPane
    IconsPane = nil,

    ---@class M_GridLayout: IconsInventory_GridLayout
    GridLayout = nil,

    ---@class M_CellPool: IconsInventory_CellPool
    CellPool = nil,

    ---@class M_Cell: IconsInventory_Cell
    Cell = nil,

    ---@class M_ItemIcon: IconsInventory_ItemIcon
    ItemIcon = nil,
}

M.options = PZAPI.ModOptions:create("IconsInventory", "Icons Inventory")

local applies = {}
M.options.apply = function()
    for _, apply in ipairs(applies) do
        apply()
    end
end

---@param apply fun()
M.addApply = function(apply)
    table.insert(applies, apply)
end

local default = {
    collapseItemsUnder = 0.3,
    alwaysCollapseOver = 3,
    maxJoypadColumns = 10,
}

M.option.collapseItemsUnder = M.options:addSlider(
    "collapseItemsUnder", "An item is \"small\" under this weight (excluded)",
    0, 1, 0.05, 0.3,
    "Small items always stack. Default: " .. tostring(default.collapseItemsUnder))
M.options:addDescription("Small items always stack. Default: " .. tostring(default.collapseItemsUnder))

M.option.alwaysCollapseOver = M.options:addSlider(
    "alwaysCollapseOver", "Always collapse stacks bigger than",
    1, 20, 1, 3,
    "1 to never collapse. Default: " .. tostring(default.alwaysCollapseOver))
M.options:addDescription("1 to never collapse. Default: " .. tostring(default.alwaysCollapseOver))

M.option.hungerMode = M.options:addComboBox("hungerMode", "Restored hunger display")
M.option.hungerMode:addItem("Remaining portion indicator", true)
M.option.hungerMode_portion = 1
M.option.hungerMode:addItem("Restored hunger value")
M.option.hungerMode_numbers = 2

M.options:addTitle("Gamepad")

M.option.maxJoypadColumns = M.options:addSlider(
    "maxJoypadColumns", "Maximum columns",
    4, 20, 1, 10,
    "Default: " .. tostring(default.maxJoypadColumns))
M.options:addDescription("Default: " .. tostring(default.maxJoypadColumns))

-- ! -- Add mod last or don't load other mods in development
M.reload = function()
    table.wipe(applies)
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/integration/BetterContainers.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/integration/P4HasBeenRead.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/DebugPanel.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/ActionQueueOverride.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/ItemIcon.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/Cell.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/CellPool.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/GridLayout.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/IconsPane.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/PaneOverride.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/PageOverride.lua")
end

M.isDebugEnabled = isDebugEnabled()

return M
