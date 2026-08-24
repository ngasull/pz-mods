local mod = require("IconsInventory/mod")

---@class ISContextMenu
local vanilla = {}

---@class ISContextMenu
local Override = {}

local downX, downY = 0, 0

function Override.get(...)
    downX, downY = getMouseX(), getMouseY()
    return vanilla.get(...)
end

function Override:onRightMouseUp(...)
    if mod.option.enableFastRightClick:getValue() and math.abs(getMouseX() - downX) + math.abs(getMouseY() - downY) > 6 * mod.getBaseScaling() then
        return self:onMouseUp(...)
    else
        return vanilla.onRightMouseUp(self, ...)
    end
end

function Override:onRightMouseUpOutside(...)
    if mod.option.enableFastRightClick:getValue() and math.abs(getMouseX() - downX) + math.abs(getMouseY() - downY) > 6 * mod.getBaseScaling() then
        return self:hideSelf()
    else
        return vanilla.onRightMouseUpOutside(self, ...)
    end
end

-- Install --
local Prev = isDebugEnabled() and require("IconsInventory/ContextMenuOverride")
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

Override._vanilla = vanilla
return Override
