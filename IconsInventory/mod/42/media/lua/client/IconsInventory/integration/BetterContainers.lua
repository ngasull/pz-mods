local BetterContainers = {}

---@param page IconsInventory_ISInventoryPageOverride
local function removeBetterSearch(page)
    if page._IconsInventory_bcSearchStrip and page._IconsInventory_bcSearchEntry then
        page._IconsInventory_bcSearchStrip:removeChild(page._IconsInventory_bcSearchEntry)
        page:removeChild(page._IconsInventory_bcSearchStrip)
        page._IconsInventory_bcSearchStrip:removeFromUIManager()
        page._IconsInventory_bcSearchEntry:removeFromUIManager()
        page._IconsInventory_bcSearchStrip = nil
        page._IconsInventory_bcSearchEntry = nil
        page._IconsInventory:setY(page:titleBarHeight())
    end
end

---@param page IconsInventory_ISInventoryPageOverride
function BetterContainers.stealBetterSearch(page)
    local pane = page._IconsInventory
    local native = page.inventoryPane

    if not page._IconsInventory_bcSyncOk then
        removeBetterSearch(page)

        if native.bcSearchStrip and native.bcSearchEntry then
            page._IconsInventory_bcSearchStrip = native.bcSearchStrip
            page._IconsInventory_bcSearchEntry = native.bcSearchEntry

            native:removeChild(native.bcSearchStrip)
            native.bcSearchStrip = nil
            native.bcSearchEntry = nil
            native.headerHgt = native._bcBaseHeaderHgt or getTextManager():getFontHeight(UIFont.Small) + 1
            if native.expandAll then native.expandAll:setY(0) end
            if native.collapseAll then native.collapseAll:setY(0) end
            if native.filterMenu then native.filterMenu:setY(0) end
            if native.nameHeader then native.nameHeader:setY(0) end
            if native.typeHeader then native.typeHeader:setY(0) end
            native._bcSearchApplied = false

            page:addChild(page._IconsInventory_bcSearchStrip)
            page._IconsInventory_bcSearchStrip:setY(pane.y + page._IconsInventory_bcSearchStrip.y)
            pane:setY(pane.y + page._IconsInventory_bcSearchStrip:getHeight())
            pane:setHeight(pane:getHeight() - page._IconsInventory_bcSearchStrip:getHeight())
        end

        page._IconsInventory_bcSyncOk = true
    end

    if page._IconsInventory_bcSearchStrip and page._IconsInventory_bcSearchStrip.x ~= pane.x then
        page._IconsInventory_bcSearchStrip:setX(pane.x)
    end
end

return BetterContainers
