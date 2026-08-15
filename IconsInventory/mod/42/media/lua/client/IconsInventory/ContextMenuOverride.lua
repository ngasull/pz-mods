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
local Prev = require("IconsInventory/ContextMenuOverride")
if Prev then Prev._clean() end
for k, v in pairs(Override) do
    vanilla[k] = ISContextMenu[k]
    ISContextMenu[k] = v
end

return {
    _clean = function()
        for k, v in pairs(vanilla) do
            ISContextMenu[k] = v
        end
    end
}
