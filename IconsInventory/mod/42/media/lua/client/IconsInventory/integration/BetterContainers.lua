local BetterContainers = {}

---@class IconsInventory_IconsPane
---@field _bcSearchStrip? ISPanel
---@field _bcSearchEntry? ISTextEntryBox
---@field _bcSyncOk? true

---@class ISInventoryPane
---@field bcSearchStrip? ISPanel BetterContainers-managed strip
---@field bcSearchEntry? ISTextEntryBox BetterContainers-managed search
---@field _bcBaseHeaderHgt? number
---@field _bcSearchApplied? boolean

---@param pane IconsInventory_IconsPane
local function removeBetterSearch(pane)
    if pane._bcSearchStrip and pane._bcSearchEntry then
        pane.modsHeaderHeight = pane.modsHeaderHeight - pane._bcSearchStrip.height
        pane._bcSearchStrip:removeChild(pane._bcSearchEntry)
        pane:removeChild(pane._bcSearchStrip)
        pane._bcSearchStrip:removeFromUIManager()
        pane._bcSearchEntry:removeFromUIManager()
        pane._bcSearchStrip = nil
        pane._bcSearchEntry = nil
    end
end

---@param pane IconsInventory_IconsPane
function BetterContainers.stealBetterSearch(pane)
    local native = pane.native

    -- if not pane._bcSyncOk or not native.bcSearchStrip ~= not pane._bcSearchStrip then
    if not pane._bcSyncOk then
        removeBetterSearch(pane)

        if native.bcSearchStrip and native.bcSearchEntry then
            pane._bcSearchStrip = native.bcSearchStrip
            pane._bcSearchEntry = native.bcSearchEntry

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

            pane:addChild(pane._bcSearchStrip)
            pane._bcSearchStrip:setX(0)
            pane._bcSearchStrip:setY(pane.modsHeaderHeight)
            pane.modsHeaderHeight = pane.modsHeaderHeight + pane._bcSearchStrip.height
            pane:refreshContainer()
        end

        pane._bcSyncOk = true
    end

    if pane._bcSearchStrip and pane._bcSearchStrip.x ~= pane.grid.x then
        pane._bcSearchStrip:setX(pane.grid.x)
    end
end

return BetterContainers
