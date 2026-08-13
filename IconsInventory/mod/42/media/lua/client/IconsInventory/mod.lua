local mod = {
    option = {},
}

local isInit = false
mod.init = function()
    if not isInit then
        require("IconsInventory/Cell")._init()
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

mod.option.iconSize = mod.options:addComboBox("iconSize", "Icon size")
mod.option.iconSize:addItem("Normal", true)
mod.option.iconSize:addItem("Big")
mod.option.iconSize:addItem("Huge")

mod.options:addDescription(
    "For smaller size go in UI/Interface menu and reduce the game's main font size. Needs relaunching the game."
)

mod.option.hungerMode = mod.options:addComboBox("hungerMode", "Restored hunger display")
mod.option.hungerMode:addItem("Remaining portion indicator", true)
mod.option.hungerMode_portion = 1
mod.option.hungerMode:addItem("Restored hunger value")
mod.option.hungerMode_numbers = 2

mod.option.hideEquipped = mod.options:addTickBox(
    "hideEquipped",
    "Hide equipped items (needs equipment mod)",
    false
)

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

-- ! -- Add mod last or don't load other mods in development
mod.reload = function()
    isInit = false
    table.wipe(applies)
    local modules = {
        "integration/BetterContainers",
        "integration/P4HasBeenRead",
        "DebugPanel",
        "Action",
        "Band",
        "CellRender",
        "Cell",
        "CellPool",
        "GridLayout",
        "IconsPane",
        "PaneOverride",
        "PageOverride",
    }
    for _, m in ipairs(modules) do
        local PrevMod = require("IconsInventory/" .. m)
        local NewMod = reloadLuaFile("IconsInventory/42/media/lua/client/IconsInventory/" .. m .. ".lua")
        if PrevMod and NewMod then
            for k, v in pairs(NewMod) do
                PrevMod[k] = v
            end
        end
    end
end

mod.isDebugEnabled = isDebugEnabled()

return mod
