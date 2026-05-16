local mod = require("IconsInventory/mod")

local mods = getActivatedMods()
if mods:contains("P4HasBeenRead") and not mods:contains("IconsInventory_P4HasBeenRead") then
    local option = mod.options:addTickBox("HasBeenReadNotifDiscard", "Don't warn me about Has Been Read", false,
        "Has Been Read is still supported but you need to install a dedicated mod. See Icons Inventory workshop page for more details.")

    Events.OnGameStart.Add(function()
        if not option:getValue() then
            local lh = 32
            local lines = {
                "Has Been Read x Icons Inventory",
                "now works with a dedicated mod.",
                "Please check Icons Inventory's",
                "workshop page to add it back.",
            }
            local linesHeight = 0
            local maxW = 0
            for _, line in ipairs(lines) do
                linesHeight = linesHeight + lh
                maxW = math.max(maxW, getTextManager():MeasureStringX(UIFont.Small, line))
            end
            linesHeight = linesHeight + lh

            local btnH = 32
            local w = maxW + 10
            local h = ISCollapsableWindow.TitleBarHeight() + linesHeight + btnH
                + ISCollapsableWindow:resizeWidgetHeight()
            local notif = ISCollapsableWindow:new(
                getCore():getScreenWidth() / 2 - w / 2,
                getCore():getScreenHeight() / 2 - h / 2,
                w, h)
            notif.minimumWidth = w
            notif.minimumHeight = h
            notif:setTitle("Integration moved")

            local btn = ISButton:new(4, notif:titleBarHeight() + linesHeight, maxW, btnH, "Ok", nil, function()
                option:setValue(true)
                PZAPI.ModOptions:save()
                notif:setVisible(false)
                notif:removeFromUIManager()
            end)

            notif:addChild(btn)
            notif:addToUIManager()

            notif.render = function()
                local y = notif:titleBarHeight()
                for _, line in ipairs(lines) do
                    notif:drawText(line, 4, y, 1, 1, 1, 1, UIFont.Small)
                    y = y + lh
                end
            end
        end
    end)
end
