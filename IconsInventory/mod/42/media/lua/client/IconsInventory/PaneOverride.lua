local mod = require("IconsInventory/mod")

---@class IconsInventory_ISInventoryPane: ISInventoryPane
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: IconsInventory_ISInventoryPane
---@field parent IconsInventory_ISInventoryPageOverride
---@field _IconsInventory_headerHgt? number
local Override = {}

function Override:refreshContainer()
    local pane = self.parent._IconsInventory
    if pane then
        if not pane.native then
            pane.native = self.parent.inventoryPane
            self.itemSortFunc = self.itemSortFunc or ISInventoryPane.itemSortByCatInc
        end
        vanilla.refreshContainer(self)
        pane:refreshContainer()
    else
        vanilla.refreshContainer(self)
    end
end

function Override:getMouseX()
    local pane = self.parent._IconsInventory
    if pane and pane:isVisible() and pane:isMouseOver() then
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
    if pane and pane:isVisible() and pane:isMouseOver() then
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
        return pane:isMouseOver()
    else
        return ISUIElement.isMouseOver(self)
    end
end

function Override:onRightMouseDown(...)
    if mod.option.enableFastRightClick:getValue() then
        return vanilla.onRightMouseUp(self, ...)
    end
end

function Override:onRightMouseUp(...)
    if not mod.option.enableFastRightClick:getValue() then
        return vanilla.onRightMouseUp(self, ...)
    end
end

-- Install --
Override._vanilla = vanilla
local Prev = require("IconsInventory/PaneOverride")
for k in pairs(Override) do
    if not Prev then
        vanilla[k] = ISInventoryPane[k]
        ISInventoryPane[k] =
            isDebugEnabled() and function(...) return Override[k](...) end
            or Override[k]
    else
        vanilla[k] = Prev._vanilla[k]
    end
end

return Override
