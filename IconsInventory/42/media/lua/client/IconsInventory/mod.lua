local M = {
    ---@class M_Pane: IconsInventory_Pane
    Pane = nil,

    ---@class M_GridLayout: IconsInventory_GridLayout
    GridLayout = nil,

    ---@class M_GridCell: IconsInventory_GridCell
    GridCell = nil,

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

-- ! -- Add mod last or don't load other mods in development
M.reload = function()
    table.wipe(applies)
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/DebugPanel.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/ItemIcon.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/GridCell.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/GridLayout.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/Pane.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/PaneOverride.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/PageOverride.lua")
end

M.isDebugEnabled = isDebugEnabled()

return M
