local V2026_08_17 = 1

local mod = {
    data = {},
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
    local smallHeightReal = getTextManager():MeasureStringYReal(UIFont.NewSmall, "I")
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

mod.option.iconSize = mod.options:addComboBox("iconSize", getText("UI_IconsInventory_options_iconSize"))
mod.option.iconSize:addItem(
    getText("UI_optionscreen_Small") .. (baseFrac == 0 and " (pixel perfect)" or ""),
    preferredSize == 1
)
mod.option.iconSize:addItem(
    getText("UI_optionscreen_Medium") .. (baseFrac ~= 0 and " (pixel perfect)" or ""),
    preferredSize == 2
)
mod.option.iconSize:addItem(
    getText("UI_optionscreen_Large") .. (baseFrac == 0 and " (pixel perfect)" or ""),
    preferredSize == 3
)

mod.options:addDescription(getText("UI_IconsInventory_options_smallerHint"))

mod.option.enableSmartDrag = mod.options:addTickBox(
    "enableSmartDrag",
    getText("UI_IconsInventory_options_enableSmartDrag"),
    true,
    getText("UI_IconsInventory_options_enableSmartDrag_hint")
)

mod.option.enableSmartScroll = mod.options:addTickBox(
    "enableSmartScroll",
    getText("UI_IconsInventory_options_enableSmartScroll"),
    true,
    getText("UI_IconsInventory_options_enableSmartScroll_hint")
)

mod.option.enableFastRightClick = mod.options:addTickBox(
    "enableFastRightClick",
    getText("UI_IconsInventory_options_enableFastRightClick"),
    false,
    getText("UI_IconsInventory_options_enableFastRightClick_hint")
)

mod.option.hideEquipped = mod.options:addTickBox(
    "hideEquipped",
    getText("UI_IconsInventory_options_hideEquipped"),
    false,
    "Warning: only enable if you really need this"
)

mod.option.clickSend = mod.options:addComboBox("clickSend", getText("UI_IconsInventory_options_clickSend"))
mod.option.clickSend:addItem(getText("UI_IconsInventory_options_clickSend_off"))
mod.option.clickSend_off = 1
mod.option.clickSend:addItem(getText("UI_IconsInventory_options_clickSend_loot"), true)
mod.option.clickSend_loot = 2
mod.option.clickSend:addItem(getText("UI_IconsInventory_options_clickSend_safe"))
mod.option.clickSend_safe = 3
mod.option.clickSend:addItem(getText("UI_IconsInventory_options_clickSend_send"))
mod.option.clickSend_send = 4

mod.option.hungerMode = mod.options:addComboBox("hungerMode", getText("UI_IconsInventory_options_hungerMode"))
mod.option.hungerMode:addItem(getText("UI_IconsInventory_options_hungerMode_portion"), true)
mod.option.hungerMode_portion = 1
mod.option.hungerMode:addItem(getText("UI_IconsInventory_options_hungerMode_numbers"))
mod.option.hungerMode_numbers = 2

mod.options:addTitle(getText("UI_IconsInventory_options_smartStacking_title"))

mod.options:addDescription(getText("UI_IconsInventory_options_smartStacking_desc"))

mod.option.collapseItemsUnder = mod.options:addSlider(
    "collapseItemsUnder",
    getText("UI_IconsInventory_options_collapseItemsUnder") .. tostring(default.collapseItemsUnder),
    0, 1, 0.05, default.collapseItemsUnder
)

mod.option.alwaysCollapseOver = mod.options:addSlider(
    "alwaysCollapseOver",
    getText("UI_IconsInventory_options_alwaysCollapseOver") .. tostring(default.alwaysCollapseOver),
    0, 20, 1, default.alwaysCollapseOver
)

mod.options:addTitle(getText("UI_IconsInventory_options_gamepad"))

mod.option.maxJoypadColumns = mod.options:addSlider(
    "maxJoypadColumns",
    getText("UI_IconsInventory_options_maxJoypadColumns") .. tostring(default.maxJoypadColumns),
    4, 20, 1, default.maxJoypadColumns
)

mod.writeData = function()
    local writer = getFileWriter("IconsInventory/data.cfg", true, false) ---@cast writer -nil
    writer:write(serialize(mod.data))
    writer:close()
end

local reader = getFileReader("IconsInventory/data.cfg", false)
if reader then
    local ok, res = pcall(deserialize, reader:readAllAsString())
    reader:close()
    if ok then
        mod.data = res

        -- Migrations
        local prevVersion = mod.version

        if not mod.data.version then
            -- Track if the mod has run already
            mod.data.version = V2026_08_17
        end

        if mod.version ~= prevVersion then
            mod.writeData()
        end
    else
        print("Couldn't read Icons Inventory data!")
    end
end

if isDebugEnabled() then
    local modules = {
        "integration/BetterContainers",
        "util/texture",
        "Onboarding",
        "Action",
        "DragSelectionBox",
        "MultiSelect",
        "CellRender",
        "Cell",
        "CellPool",
        "GridLayout",
        "IconsPane",
        "PaneOverride",
        "JoypadPageOverride",
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
