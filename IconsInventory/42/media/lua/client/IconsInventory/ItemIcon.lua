local M = require("IconsInventory/mod")

local iconSize = 64
local padding = 8
local halfPadding = padding / 2
local cellSize = iconSize + 2 * padding
-- local conditionBarHeight = 2
-- local conditionBarPadding = 2
-- local conditionBarSeparatorSize = 2

local ringRadius = 10
---@type Texture[]
local ringGood = {}
---@type Texture[]
local ringBad = {}
for i = 1, 16 do
    ringGood[i] = getTexture("media/ui/IconsInventory/ring/ring-good-" .. tostring(i) .. ".png")
    ringBad[i] = getTexture("media/ui/IconsInventory/ring/ring-bad-" .. tostring(i) .. ".png")
end
local ringBg = getTexture("media/ui/IconsInventory/ring/ring-bg.png")
local ringSeparator = getTexture("media/ui/IconsInventory/ring/ring-separator.png")

local softBg = getTexture("media/ui/IconsInventory/soft-bg.png")

-- Added by Icons Inventory
-- local hotIcon = getTexture("media/ui/Entity/SlotStatus/hot_24.png")
local wetIcon = getTexture("media/ui/Entity/SlotStatus/wet_24.png")
local clockIcon = getTexture("media/ui/speedControls/Wait_Off.png")
local maggots = InventoryItem.new("", "", "Maggots", "Item_Insect_Maggots")

-- Adjusted variables from ISInventoryPane:renderdetails
local subIconSize = 16
local subIconRelPos = 1.25 * padding + iconSize
local subIconYPad = (2 * ringRadius - subIconSize) / 2

local equippedItemIcon = getTexture("media/ui/icon.png")
local equippedInHotbar = getTexture("media/ui/iconInHotbar.png")
local brokenItemIcon = getTexture("media/ui/icon_broken.png")
local frozenItemIcon = getTexture("media/ui/icon_frozen.png")
local poisonIcon = getTexture("media/ui/SkullPoison.png")
local favoriteStar = getTexture("media/ui/FavoriteStar.png")
local noFavoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/nocraft.png")
local favoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/craftok.png")
local favoriteRecipeInputStarSize = 16;

local function noop() end
local vanilla_drawText = ISInventoryPane.drawText
local vanilla_drawProgressBar = ISInventoryPane.drawProgressBar

---@type number
local fractionFromNative
---@type Texture[]
local ringFromNative

local function capture_drawProgressBar(self, x, y, w, h, f, fg)
    fractionFromNative = f
    ringFromNative = fg.r > fg.g and ringBad or ringGood
end

---@class IconsInventory_ItemIcon: ISUIElement
---@field player IsoPlayer
---@field ui ISUIElement
---@field item InventoryItem
---@field hovered? boolean
local ItemIcon = {}
ItemIcon.__index = ItemIcon
M.ItemIcon = ItemIcon

ItemIcon.cellSize = cellSize
ItemIcon.iconSize = iconSize
ItemIcon.padding = padding

---@param player IsoPlayer
---@param ui ISUIElement
---@param item InventoryItem
function ItemIcon.new(player, ui, item)
    ---@type IconsInventory_ItemIcon
    local self = setmetatable({}, ItemIcon)
    self.player = player
    self.ui = ui
    self.item = item
    return self
end

---@param xoff number
---@param yoff number
---@param scale? number
function ItemIcon:drawBase(xoff, yoff, scale)
    local size = (scale or 1) * iconSize
    local center = (cellSize - size) / 2

    -- Some icons are almost invisible (like Car keys)
    self.ui:drawTexture(softBg, xoff + padding, yoff + padding,
        1, 0.2, 0.2, 0.2)
    -- if self.item:getType() == "CarKey" then end

    ISInventoryItem.renderItemIcon(
        self.ui, self.item,
        xoff + center, yoff + center,
        1, size, size
    )
end

function ItemIcon:drawSubscript(xoff, yoff, str, scale)
    local fontSize = 30
    local size = (scale or 1) * iconSize
    local offset = (iconSize - size) / 2
    self.ui:drawTextRight(
        str,
        xoff + cellSize - halfPadding - offset,
        yoff + cellSize - halfPadding - fontSize - offset,
        1, 1, 1, 1, UIFont.Small
    )
end

function ItemIcon:drawDetails(xoff, yoff)
    local item = self.item

    -- This section is copy/pastadapted from ISInventoryPane:renderdetails

    local padBR = -4
    if self.player:isEquipped(item) then
        padBR = padBR + 4
        local size = subIconSize / 2
        self.ui:drawTextureScaled(equippedItemIcon,
            xoff + subIconRelPos - size - padBR, yoff + subIconRelPos - size - subIconYPad / 2,
            size, size,
            1, 1, 1, 1);
        padBR = padBR + size
    end

    local hotbar = getPlayerHotbar(self.player:getIndex());
    if not self.player:isEquipped(item) and hotbar and hotbar:isInHotbar(item) then
        padBR = padBR + 4
        local size = subIconSize / 2
        self.ui:drawTextureScaled(equippedInHotbar,
            xoff + subIconRelPos - size - padBR, yoff + subIconRelPos - size - subIconYPad / 2,
            size, size,
            1, 1, 1, 1);
        padBR = padBR + size + 4
    end

    if item:isBroken() then
        padBR = padBR + 4
        self.ui:drawTextureScaled(brokenItemIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    if instanceof(item, "Food") then
        if item:isFrozen() then
            padBR = padBR + 4
            self.ui:drawTextureScaled(frozenItemIcon,
                xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                subIconSize, subIconSize,
                1, 1, 1, 1);
            padBR = padBR + subIconSize
        end

        if (item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or self.player:isKnownPoison(item) then
            padBR = padBR + 4
            self.ui:drawTextureScaled(poisonIcon,
                xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                subIconSize,
                1, 1, 1, 1);
            padBR = padBR + subIconSize
        elseif not item:isFresh() then
            if item:isRotten() then
                padBR = padBR + 4
                ISInventoryItem.renderItemIcon(
                    self.ui, maggots,
                    xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                    0.8, subIconSize, subIconSize)
                padBR = padBR + subIconSize
            else
                padBR = padBR + 4
                self.ui:drawTextureScaled(clockIcon,
                    xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                    subIconSize, subIconSize,
                    0.5, 0.75, 0.75, 0)
                padBR = padBR + subIconSize
            end
        end

        -- ISInventoryPaneContextMenu / Tooltip_food_BetterHot
        -- if item:getHeat() >= 1.3 then
        --     padBR = padBR + 4
        --     self.ui:drawTextureScaled(hotIcon,
        --         xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
        --         subIconSize, subIconSize,
        --         1, 0.8, 0, 0);
        --     padBR = padBR + subIconSize
        -- end
    elseif instanceof(item, "Clothing") and (
            item:getBodyLocation() == "Shoes" and item:getWetness() > 60
            or item:getWetness() > 10
        )
    then
        padBR = padBR + 4
        self.ui:drawTextureScaled(wetIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            0.6, 0.0, 0.6, 1);
        padBR = padBR + subIconSize
    end

    if ISInventoryPane:isLiteratureRead(self.player, item) or item:hasBeenSeen(self.player) or item:hasBeenHeard(self.player) or self.player:hasReadMap(item) then
        padBR = padBR + 4
        self.ui:drawTextureScaled(getTexture("media/ui/Tick_Mark-10.png"),
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize, 1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    local fluidContainer = item:getFluidContainer() or
        (item:getWorldItem() and item:getWorldItem():getFluidContainer());
    if fluidContainer ~= nil and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not fluidContainer:isEmpty()) and (fluidContainer:contains(Fluid.Bleach) or (fluidContainer:contains(Fluid.TaintedWater) and fluidContainer:getPoisonRatio() > 0.1)) then
        padBR = padBR + 4
        self.ui:drawTextureScaled(poisonIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    if item:isFavorite() then
        padBR = padBR + 4
        self.ui:drawTextureScaled(favoriteStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
    elseif item:isNoRecipes(self.player) then
        padBR = padBR + 4
        self.ui:drawTextureScaled(noFavoriteRecipeInputStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1, 1, 1, 1);
    elseif item:isFavouriteRecipeInput(self.player) then
        padBR = padBR + 4
        self.ui:drawTextureScaled(favoriteRecipeInputStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1, 1, 1, 1);
    end

    local bookNumber = item:getCategory() == "Literature"
        and item:getLvlSkillTrained() > -1
        and ItemIcon.bookNumber[item:getLvlSkillTrained()]
    if bookNumber then
        self.ui:drawTextRight(
            bookNumber, xoff + cellSize - halfPadding, yoff + halfPadding,
            1, 1, 1, 0.7, UIFont.Small
        )
    end

    --- Condition circle
    fractionFromNative = nil
    ringFromNative = nil
    ISInventoryPane.drawText = noop
    ISInventoryPane.drawProgressBar = capture_drawProgressBar
    self.ui:drawItemDetails(item, 0, 0, 0)
    ISInventoryPane.drawText = vanilla_drawText
    ISInventoryPane.drawProgressBar = vanilla_drawProgressBar

    if fractionFromNative then
        if instanceof(item, "Drainable") and not item:hasTag(ItemTag.HIDE_REMAINING) then
            self:drawRingUses(ringFromNative or ringGood, xoff, yoff, item:getCurrentUses(),
                item:getMaxUses())
        else
            self:drawRing(ringFromNative or ringGood, xoff, yoff, fractionFromNative)
        end
    elseif item:getCategory() == "Literature" and item:getNumberOfPages() > 0 and item:getAlreadyReadPages() > 0 then
        local skillBook = SkillBook[item:getSkillTrained()]
        if skillBook and self.player:getPerkLevel(skillBook.perk) < item:getMaxLevelTrained()
        then -- Not a skill book or player has level low enough to read it
            self:drawRing(ringGood, xoff, yoff, item:getAlreadyReadPages() / item:getNumberOfPages())
        end
    end
end

---@param ring Texture[]
---@param xoff number
---@param yoff number
---@param fraction number
function ItemIcon:drawRing(ring, xoff, yoff, fraction)
    if fraction >= 1 then return false end

    local centerX = xoff + halfPadding + ringRadius
    local centerY = yoff + cellSize - ringRadius - halfPadding

    self.ui:drawTexture(ringBg, centerX - ringRadius, centerY - ringRadius, 1)

    local angle = 0
    while fraction >= 0.25 do
        self:drawTextureAngle(ring[#ringGood], centerX, centerY, angle)
        fraction = fraction - 0.25
        angle = angle - 90
    end

    local step = math.floor(fraction * 4 * #ringGood + 0.499)
    if step > 0 then
        self:drawTextureAngle(ring[step], centerX, centerY, angle)
    end
    return true
end

---@param ring Texture[]
---@param xoff number
---@param yoff number
---@param current number
---@param max number
function ItemIcon:drawRingUses(ring, xoff, yoff, current, max)
    if self:drawRing(ring, xoff, yoff, current / max) and max < 20 then
        local centerX = xoff + halfPadding + ringRadius
        local centerY = yoff + cellSize - ringRadius - halfPadding
        local step = 360 / max
        for i = 0, current - 1 do
            self:drawTextureAngle(ringSeparator, centerX, centerY, -i * step)
        end
    end
end

function ItemIcon:drawTextureAngle(tex, centerX, centerY, angle)
    -- DrawTextureAngle somehow doesn't take scroll into account
    self.ui:DrawTextureAngle(tex, centerX + self.ui:getXScroll(), centerY + self.ui:getYScroll(), angle)
end

-- ---@param scale number
-- function ItemIcon:drawBarScale(scale)
--     self.pane.native:drawRect(xoff + conditionBarPadding, yoff + cellSize - 2 * conditionBarHeight,
--         cellSize * scale - 2 * conditionBarPadding, conditionBarHeight, 1, 0, 1,
--         0)
-- end

-- ---@param current number
-- ---@param max number
-- function ItemIcon:drawBarUses(current, max)
--     local useWidth = (cellSize - 2 * conditionBarPadding - conditionBarSeparatorSize * (max - 1)) / max

--     if useWidth > 2 then
--         for i = 0, current - 1 do
--             self.pane.native:drawRect(xoff + conditionBarPadding + i * (useWidth + conditionBarSeparatorSize),
--                 yoff + cellSize - 2 * conditionBarHeight, useWidth, conditionBarHeight, 1, 0, 1, 0)
--         end
--     else
--         self:drawBarScale(current / max)
--     end
-- end

ItemIcon.bookNumber = {
    [1] = "I",
    [3] = "II",
    [5] = "III",
    [7] = "IV",
    [9] = "V",
}
