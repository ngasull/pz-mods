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

-- ! -- Add mod last or don't load other mods in development
M.reload = function()
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/ItemIcon.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/GridCell.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/GridLayout.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/Pane.lua")
    reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/PaneOverride.lua")
end

M.isDebugEnabled = true or isDebugEnabled()

return M
