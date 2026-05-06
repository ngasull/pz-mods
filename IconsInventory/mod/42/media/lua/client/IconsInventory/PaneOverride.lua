local M = require("IconsInventory/mod")

---@class IconsInventory_ISInventoryPane: ISInventoryPane
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: ISInventoryPane
---@field parent IconsInventory_ISInventoryPageOverride
---@field _IconsInventory_headerHgt? number
local Override = {}

function Override:refreshContainer()
    local pane = self.parent._IconsInventory

    if not pane.native then
        pane.native = self.parent.inventoryPane
        self.itemSortFunc = self.itemSortFunc or ISInventoryPane.itemSortByCatInc
    end

    vanilla.refreshContainer(self)
    pane:refreshContainer()
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPane[k]
        ISInventoryPane[k] = v
    end

    M.cleanPane = function()
        for k, v in pairs(vanilla) do
            ISInventoryPane[k] = v
        end
    end
end

if M.cleanPane then M.cleanPane() end
install()
