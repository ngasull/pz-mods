local mod = {
    option = {},
}

local isInit = false
mod.init = function()
    if not isInit then
        require("IconsInventory/Cell")._init()
        require("IconsInventory/GridLayout")._init()
        require("IconsInventory/IconsPane")._init()
        isInit = true
    end
end

local applies = {}
---@param apply fun()
mod.addApply = function(apply)
    table.insert(applies, apply)
end

mod.options = PZAPI.ModOptions:create("IconsInventory", "Icons Inventory")

mod.options.apply = function()
    isInit = false
    mod.init()
    for _, apply in ipairs(applies) do
        apply()
    end
end

local default = {
    collapseItemsUnder = 0.3,
    alwaysCollapseOver = 3,
    maxJoypadColumns = 10,
}

mod.NATIVE_SIZE = 32 -- Native icon size

-- Evaluate base and default scaling from how the games scales text in this setup
mod.getBaseScaling = function()
    local smallHeightReal = getTextManager():MeasureStringYReal(UIFont.Small, "I")
    return math.max(1, math.floor(0.5 + smallHeightReal * 6 / mod.NATIVE_SIZE) / 2)
end

-- Preferred size logic:
-- - "Small" icon scaling == Base scaling
-- - Prefer first pixel-perfect option
-- - Increase it if resulting size is too small relatively to screen height
local function scaleRatio(scaling) return getCore():getScreenHeight() / (scaling * mod.NATIVE_SIZE) end
local baseScalingInt, baseFrac = math.modf(mod.getBaseScaling())
local preferredSize =
    baseFrac == 0 and ( -- Small is pixel perfect: prefer it or upscale if needed
        scaleRatio(baseScalingInt) > 40 and 2 or 1
    ) or (              -- Small is fractional: prefer pixel perfect "Medium" or upscale if needed
        scaleRatio(baseScalingInt + 1) > 40 and 3 or 2
    )

mod.option.iconSize = mod.options:addComboBox("iconSize", "Icon size")
mod.option.iconSize:addItem("Small" .. (baseFrac == 0 and " (pixel perfect)" or ""), preferredSize == 1)
mod.option.iconSize:addItem("Medium" .. (baseFrac ~= 0 and " (pixel perfect)" or ""), preferredSize == 2)
mod.option.iconSize:addItem("Large" .. (baseFrac == 0 and " (pixel perfect)" or ""), preferredSize == 3)

mod.options:addDescription(
    "For smaller size go in UI/Interface menu and reduce the game's main font size. Needs relaunching the game."
)

mod.option.enableSmartScroll = mod.options:addTickBox(
    "enableSmartScroll",
    "Smart container scrolling",
    true,
    "Scrolling from Icons Inventory cycles containers"
)

mod.option.hideEquipped = mod.options:addTickBox(
    "hideEquipped",
    "Hide equipped items",
    false,
    "Warning: only enable if you really need this"
)

mod.option.clickSend = mod.options:addComboBox("clickSend", "Click to quick-send")
mod.option.clickSend:addItem("Off")
mod.option.clickSend_off = 1
mod.option.clickSend:addItem("Safe - Send to loot container only if its window is open", true)
mod.option.clickSend_safe = 2
mod.option.clickSend:addItem("Send - Like Shift+Click, without shift. Except for stacks")
mod.option.clickSend_send = 3

mod.option.hungerMode = mod.options:addComboBox("hungerMode", "Restored hunger display")
mod.option.hungerMode:addItem("Remaining portion indicator", true)
mod.option.hungerMode_portion = 1
mod.option.hungerMode:addItem("Restored hunger value")
mod.option.hungerMode_numbers = 2

mod.options:addTitle("Smart Stacking")

mod.options:addDescription("Items stack depending on their weight. Small items always stack.")

mod.option.collapseItemsUnder = mod.options:addSlider(
    "collapseItemsUnder",
    "\"Small\" means under this weight (excluded). Default: " ..
    tostring(default.collapseItemsUnder),
    0, 1, 0.05, default.collapseItemsUnder
)

mod.option.alwaysCollapseOver = mod.options:addSlider(
    "alwaysCollapseOver",
    "Always stack above number (excluded). 0: never collapse. Default: " .. tostring(default.alwaysCollapseOver),
    0, 20, 1, default.alwaysCollapseOver
)

mod.options:addTitle("Gamepad")

mod.option.maxJoypadColumns = mod.options:addSlider(
    "maxJoypadColumns", "Maximum columns. Default: " .. tostring(default.maxJoypadColumns),
    4, 20, 1, default.maxJoypadColumns
)

if isDebugEnabled() then
    local modules = {
        "integration/BetterContainers",
        "util/texture",
        "DebugPanel",
        "Action",
        "DragSelectionBox",
        "MultiSelect",
        "CellRender",
        "Cell",
        "CellPool",
        "GridLayout",
        "IconsPane",
        "PaneOverride",
        "PageOverride",
        "ContextMenuOverride",
    }

    -- ! -- Add mod last or don't load other mods in development
    mod.reload = function()
        isInit = false
        table.wipe(applies)

        for _, m in ipairs(modules) do
            local PrevMod = require("IconsInventory/" .. m)
            local NewMod = reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/" .. m .. ".lua")
            if PrevMod and NewMod then
                for k, v in pairs(NewMod) do
                    PrevMod[k] = v
                end
            end
        end

        mod.init()
    end
end

return mod
