local mod = require("IconsInventory/mod")

---@class IconsInventory_ISInventoryPane: ISInventoryPane
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: IconsInventory_ISInventoryPane
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

function Override:getMouseX()
    local pane = self.parent._IconsInventory
    if pane and pane:isVisible() and not pane._mouseOut then
        if pane._fakeX then
            return pane._fakeX
        elseif pane.focusedCell then
            return self.column2 + 1 -- To the right of collapse area
        else
            return -1
        end
    else
        return ISUIElement.getMouseX(self)
    end
end

function Override:getMouseY()
    local pane = self.parent._IconsInventory
    if pane and pane:isVisible() and not pane._mouseOut then
        if pane._fakeY then
            return pane._fakeY
        elseif pane.focusedCell then
            return self.headerHgt + (pane.focusedCell.index - 1) * self.itemHgt + 2
        else
            return -1
        end
    else
        return ISUIElement.getMouseY(self)
    end
end

function Override:isMouseOver()
    local pane = self.parent._IconsInventory
    if pane and pane:isVisible() then
        return not pane._mouseOut
    else
        return ISUIElement.isMouseOver(self)
    end
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPane[k]
        ISInventoryPane[k] = v
    end
end

local Prev = require("IconsInventory/PaneOverride")
if Prev then Prev._clean() end
install()

return {
    _clean = function()
        for k, v in pairs(vanilla) do
            ISInventoryPane[k] = v
        end
    end
}
