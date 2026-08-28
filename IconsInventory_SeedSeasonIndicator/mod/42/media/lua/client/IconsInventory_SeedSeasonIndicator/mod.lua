local Cell = require("IconsInventory/Cell")
local SeedSeasonIndicator = require("SeedSeasonIndicator")

local BASE_SIZE = 11
local TARGET_SIZE = 16 -- Otherwise too small on higher scalings
local tickMarkName = getTexture("media/ui/Tick_Mark-10.png"):getName()

---@class IconsInventory_Cell
local vanilla = {}

---@class IconsInventory_Cell
local Override = {}

function Override:renderItem(x, y, w, h, gray)
    local res = vanilla.renderItem(self, x, y, w, h, gray)

    local seasonIcon = SeedSeasonIndicator.getIconForItem(self.player, self.item)
    if seasonIcon then
        self:renderSupIcon(seasonIcon, TARGET_SIZE)
        self._IconsInventory_SeedSeasonIndicator = true
    end

    return res
end

function Override:renderSubIcon(icon, ...)
    if not (self._IconsInventory_SeedSeasonIndicator and icon:getName() == tickMarkName) then
        return vanilla.renderSubIcon(self, icon, ...)
    end
end

local Prev
if isDebugEnabled() then
    Prev = _G._IconsInventory_SeedSeasonIndicator
    _G._IconsInventory_SeedSeasonIndicator = Prev or Override
    Override._vanilla = vanilla
end
for k, v in pairs(Override) do
    if Prev then
        vanilla[k] = Prev._vanilla[k]
        Prev[k] = v
    else
        vanilla[k] = Cell[k]
        Cell[k] = isDebugEnabled() and function(...) return Override[k](...) end or v
    end
end
