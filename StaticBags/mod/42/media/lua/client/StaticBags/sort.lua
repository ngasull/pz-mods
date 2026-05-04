local M = require("StaticBags/mod")

local locationOrder = {
    [ItemBodyLocation.HANDS_RIGHT] = M.option.rightHand,
    [ItemBodyLocation.HANDS_LEFT] = M.option.leftHand,
    [ItemBodyLocation.BACK] = M.option.back,
    [ItemBodyLocation.SATCHEL] = M.option.satchel,
    [ItemBodyLocation.FANNY_PACK_FRONT] = M.option.fannyPackFront,
    [ItemBodyLocation.FANNY_PACK_BACK] = M.option.fannyPackBack,
}

---@param item InventoryItem
---@param location ItemBodyLocation?
local function sortScore(item, location)
    if item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING) then
        return M.option.keyring:getValue()
    elseif location and locationOrder[location] then
        return locationOrder[location]:getValue()
    else
        return 42 + item:getID()
    end
end

---@class StaticBags_sort_ISInventoryPage_override: ISInventoryPage
local Override = {}
---@class StaticBags_sort_ISInventoryPage: ISInventoryPage
local vanilla = {}

-- Fix vanilla onBackpackMouseUp to avoid double-triggering the event
-- The double trigger messes with mutations in the buttonPool
function Override:onBackpackMouseUp()
    if not self.pressed and not ISMouseDrag.dragging then return end
    -- Disable: ISButton.onMouseUp(self, x, y)
    local page = self.parent.parent
    if page:dropItemsInContainer(self) then return end
    page:onBackpackClick(self)
end

function Override:refreshBackpacks()
    -- Restore choice as understood internally (only for joypad somehow)
    if self._StaticBags_overridenChoices then
        self.backpackChoice = self._StaticBags_overridenChoices[self.inventoryPane.inventory]
    end

    vanilla.refreshBackpacks(self)

    if self.onCharacter then
        self._StaticBags_overridenChoices = {}
        for i, button in ipairs(self.backpacks) do
            self._StaticBags_overridenChoices[button.inventory] = i
        end

        local y = self.backpacks[1]:getY()
        local player = getSpecificPlayer(self.player)
        local wornItems = player:getWornItems()
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()

        local equipped = {}
        for i = 1, wornItems:size() do
            local wornItem = wornItems:get(i - 1)
            equipped[wornItem:getItem()] = wornItem:getLocation()
        end
        if primary then equipped[primary] = ItemBodyLocation.HANDS_RIGHT end
        if secondary then equipped[secondary] = ItemBodyLocation.HANDS_LEFT end

        table.sort(self.backpacks, function(a, b)
            ---@type InventoryItem
            local aItem = a.inventory:getContainingItem()
            ---@type InventoryItem
            local bItem = b.inventory:getContainingItem()

            if aItem and bItem then
                return sortScore(aItem, equipped[aItem]) < sortScore(bItem, equipped[bItem])
            else
                return false
            end
        end)

        for _, button in ipairs(self.backpacks) do
            button:setY(y)
            y = y + button:getHeight()
        end
    end
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] = v
    end

    M.clean = function()
        for k, v in pairs(vanilla) do
            ISInventoryPage[k] = v
        end
    end
end

M.options.apply = function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd and pd.playerInventory then
            pd.playerInventory:refreshBackpacks()
        end
    end
end

if M.clean then M.clean() end
install()
M.options.apply()

Events.OnGameStart.Add(M.options.apply)
