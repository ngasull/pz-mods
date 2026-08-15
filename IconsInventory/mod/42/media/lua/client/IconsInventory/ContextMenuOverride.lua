---@class IconsInventory_ISContextMenu: ISContextMenu
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: IconsInventory_ISContextMenu
local Override = {}

local downX, downY = 0, 0

function Override.get(...)
    downX, downY = getMouseX(), getMouseY()
    return vanilla.get(...)
end

function Override:onRightMouseUp(...)
    if math.abs(getMouseX() - downX) + math.abs(getMouseY() - downY) > 6 then
        return self:onMouseUp(...)
    else
        return vanilla.onRightMouseUp(self, ...)
    end
end

function Override:onRightMouseUpOutside(...)
    if math.abs(getMouseX() - downX) + math.abs(getMouseY() - downY) > 6 then
        return self:hideSelf()
    else
        return vanilla.onRightMouseUpOutside(self, ...)
    end
end

-- Install --
Override._vanilla = vanilla
local Prev = require("IconsInventory/ContextMenuOverride")
for k in pairs(Override) do
    if not Prev then
        vanilla[k] = ISContextMenu[k]
        ISContextMenu[k] =
            isDebugEnabled() and function(...) return Override[k](...) end
            or Override[k]
    else
        vanilla[k] = Prev._vanilla[k]
    end
end

return Override
