local mod = {
    option = {},
}

mod.options = PZAPI.ModOptions:create("IconsInventory", "Icons Inventory")

local applies = {}
mod.options.apply = function()
    for _, apply in ipairs(applies) do
        apply()
    end
end

---@param apply fun()
mod.addApply = function(apply)
    table.insert(applies, apply)
end

local default = {
    collapseItemsUnder = 0.3,
    alwaysCollapseOver = 3,
    maxJoypadColumns = 10,
}

mod.option.collapseItemsUnder = mod.options:addSlider(
    "collapseItemsUnder", "An item is \"small\" under this weight (excluded)",
    0, 1, 0.05, 0.3,
    "Small items always stack. Default: " .. tostring(default.collapseItemsUnder))
mod.options:addDescription("Small items always stack. Default: " .. tostring(default.collapseItemsUnder))

mod.option.alwaysCollapseOver = mod.options:addSlider(
    "alwaysCollapseOver", "Always collapse stacks bigger than",
    1, 20, 1, 3,
    "1 to never collapse. Default: " .. tostring(default.alwaysCollapseOver))
mod.options:addDescription("1 to never collapse. Default: " .. tostring(default.alwaysCollapseOver))

mod.option.hungerMode = mod.options:addComboBox("hungerMode", "Restored hunger display")
mod.option.hungerMode:addItem("Remaining portion indicator", true)
mod.option.hungerMode_portion = 1
mod.option.hungerMode:addItem("Restored hunger value")
mod.option.hungerMode_numbers = 2

mod.options:addTitle("Gamepad")

mod.option.maxJoypadColumns = mod.options:addSlider(
    "maxJoypadColumns", "Maximum columns",
    4, 20, 1, 10,
    "Default: " .. tostring(default.maxJoypadColumns))
mod.options:addDescription("Default: " .. tostring(default.maxJoypadColumns))

-- ! -- Add mod last or don't load other mods in development
mod.reload = function()
    table.wipe(applies)
    local modules = {
        "integration/BetterContainers",
        "integration/P4HasBeenRead",
        "DebugPanel",
        "Action",
        "ItemIcon",
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
