local M = require("IconsInventory/mod")

local iconSize = 64
local padding = 8
local halfPadding = padding / 2
local cellSize = iconSize + 2 * padding

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

---@class IconsInventory_ItemIcon
local ItemIcon = {}
M.ItemIcon = ItemIcon

ItemIcon.cellSize = cellSize
ItemIcon.iconSize = iconSize
ItemIcon.padding = padding

---@param cell IconsInventory_Cell
---@param xoff number
---@param yoff number
---@param scale? number
function ItemIcon.drawBase(cell, xoff, yoff, scale)
    local size = (scale or 1) * iconSize
    local center = (cellSize - size) / 2

    -- Some icons are almost invisible (like Car keys)
    cell.pane.native:drawTexture(softBg, xoff + padding, yoff + padding,
        1, 0.2, 0.2, 0.2)

    ISInventoryItem.renderItemIcon(
        cell.pane.native, cell.item,
        xoff + center, yoff + center,
        1, size, size
    )
end

---@param cell IconsInventory_Cell
function ItemIcon.drawSubscript(cell, xoff, yoff, str, scale)
    local fontSize = 30
    local size = (scale or 1) * iconSize
    local offset = (iconSize - size) / 2
    cell.pane.native:drawTextRight(
        str,
        xoff + cellSize - halfPadding - offset,
        yoff + cellSize - halfPadding - fontSize - offset,
        1, 1, 1, 1, UIFont.Small
    )
end

---@param cell IconsInventory_Cell
function ItemIcon.drawDetails(cell, xoff, yoff)
    local item = cell.item
    local ui = cell.pane.native

    -- This section is copy/pastadapted from ISInventoryPane:renderdetails

    local padBR = -4
    if cell.player:isEquipped(item) then
        padBR = padBR + 4
        local size = subIconSize / 2
        ui:drawTextureScaled(equippedItemIcon,
            xoff + subIconRelPos - size - padBR, yoff + subIconRelPos - size - subIconYPad / 2,
            size, size,
            1, 1, 1, 1);
        padBR = padBR + size
    end

    local hotbar = getPlayerHotbar(cell.player:getIndex());
    if not cell.player:isEquipped(item) and hotbar and hotbar:isInHotbar(item) then
        padBR = padBR + 4
        local size = subIconSize / 2
        ui:drawTextureScaled(equippedInHotbar,
            xoff + subIconRelPos - size - padBR, yoff + subIconRelPos - size - subIconYPad / 2,
            size, size,
            1, 1, 1, 1);
        padBR = padBR + size + 4
    end

    if item:isBroken() then
        padBR = padBR + 4
        ui:drawTextureScaled(brokenItemIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    if instanceof(item, "Food") then
        if item:isFrozen() then
            padBR = padBR + 4
            ui:drawTextureScaled(frozenItemIcon,
                xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                subIconSize, subIconSize,
                1, 1, 1, 1);
            padBR = padBR + subIconSize
        end

        if (item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or cell.player:isKnownPoison(item) then
            padBR = padBR + 4
            ui:drawTextureScaled(poisonIcon,
                xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                subIconSize,
                1, 1, 1, 1);
            padBR = padBR + subIconSize
        elseif not item:isFresh() then
            if item:isRotten() then
                padBR = padBR + 4
                ISInventoryItem.renderItemIcon(
                    ui, maggots,
                    xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                    0.8, subIconSize, subIconSize)
                padBR = padBR + subIconSize
            else
                padBR = padBR + 4
                ui:drawTextureScaled(clockIcon,
                    xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                    subIconSize, subIconSize,
                    0.5, 0.75, 0.75, 0)
                padBR = padBR + subIconSize
            end
        end
    elseif instanceof(item, "Clothing") and (
            item:getBodyLocation() == "Shoes" and item:getWetness() > 60
            or item:getWetness() > 10
        )
    then
        padBR = padBR + 4
        ui:drawTextureScaled(wetIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            0.6, 0.0, 0.6, 1);
        padBR = padBR + subIconSize
    end

    if ISInventoryPane:isLiteratureRead(cell.player, item) or item:hasBeenSeen(cell.player) or item:hasBeenHeard(cell.player) or cell.player:hasReadMap(item) then
        padBR = padBR + 4
        ui:drawTextureScaled(getTexture("media/ui/Tick_Mark-10.png"),
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize, 1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    local fluidContainer = item:getFluidContainer() or
        (item:getWorldItem() and item:getWorldItem():getFluidContainer());
    if fluidContainer ~= nil and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not fluidContainer:isEmpty()) and (fluidContainer:contains(Fluid.Bleach) or (fluidContainer:contains(Fluid.TaintedWater) and fluidContainer:getPoisonRatio() > 0.1)) then
        padBR = padBR + 4
        ui:drawTextureScaled(poisonIcon,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
        padBR = padBR + subIconSize
    end

    if item:isFavorite() then
        padBR = padBR + 4
        ui:drawTextureScaled(favoriteStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize,
            1, 1, 1, 1);
    elseif item:isNoRecipes(cell.player) then
        padBR = padBR + 4
        ui:drawTextureScaled(noFavoriteRecipeInputStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1, 1, 1, 1);
    elseif item:isFavouriteRecipeInput(cell.player) then
        padBR = padBR + 4
        ui:drawTextureScaled(favoriteRecipeInputStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            favoriteRecipeInputStarSize, favoriteRecipeInputStarSize, 1, 1, 1, 1);
    end

    local bookNumber = item:getCategory() == "Literature"
        and item:getLvlSkillTrained() > -1
        and ItemIcon.bookNumber[item:getLvlSkillTrained()]
    if bookNumber then
        ui:drawTextRight(
            bookNumber, xoff + cellSize - halfPadding, yoff + halfPadding,
            1, 1, 1, 0.7, UIFont.Small
        )
    end

    --- Condition circle
    fractionFromNative = nil
    ringFromNative = nil
    ---@diagnostic disable-next-line: undefined-global
    if not ItemConditionOverlay then -- Opt-out for this specific mod (keep literature)
        ISInventoryPane.drawText = noop
        ISInventoryPane.drawProgressBar = capture_drawProgressBar
        ui:drawItemDetails(item, 0, 0, 0)
        ISInventoryPane.drawText = vanilla_drawText
        ISInventoryPane.drawProgressBar = vanilla_drawProgressBar
    end

    if fractionFromNative then
        if instanceof(item, "Drainable") and not item:hasTag(ItemTag.HIDE_REMAINING) then
            ItemIcon.drawRingUses(cell, ringFromNative or ringGood, xoff, yoff, item:getCurrentUses(),
                item:getMaxUses())
        else
            ItemIcon.drawRing(cell, ringFromNative or ringGood, xoff, yoff, fractionFromNative)
        end
    elseif item:getCategory() == "Literature" and item:getNumberOfPages() > 0 and item:getAlreadyReadPages() > 0 then
        local skillBook = SkillBook[item:getSkillTrained()]
        if skillBook and cell.player:getPerkLevel(skillBook.perk) < item:getMaxLevelTrained()
        then -- Not a skill book or player has level low enough to read it
            ItemIcon.drawRing(cell, ringGood, xoff, yoff, item:getAlreadyReadPages() / item:getNumberOfPages())
        end
    end
end

---@param cell IconsInventory_Cell
---@param ring Texture[]
---@param xoff number
---@param yoff number
---@param fraction number
function ItemIcon.drawRing(cell, ring, xoff, yoff, fraction)
    if fraction >= 1 then return false end

    local centerX = xoff + halfPadding + ringRadius
    local centerY = yoff + cellSize - ringRadius - halfPadding

    cell.pane.native:drawTexture(ringBg, centerX - ringRadius, centerY - ringRadius, 1)

    local angle = 0
    while fraction >= 0.25 do
        ItemIcon.drawTextureAngle(cell, ring[#ringGood], centerX, centerY, angle)
        fraction = fraction - 0.25
        angle = angle - 90
    end

    local step = math.floor(fraction * 4 * #ringGood + 0.499)
    if step > 0 then
        ItemIcon.drawTextureAngle(cell, ring[step], centerX, centerY, angle)
    end
    return true
end

---@param cell IconsInventory_Cell
---@param ring Texture[]
---@param xoff number
---@param yoff number
---@param current number
---@param max number
function ItemIcon.drawRingUses(cell, ring, xoff, yoff, current, max)
    if ItemIcon.drawRing(cell, ring, xoff, yoff, current / max) and max < 20 then
        local centerX = xoff + halfPadding + ringRadius
        local centerY = yoff + cellSize - ringRadius - halfPadding
        local step = 360 / max
        for i = 0, current - 1 do
            ItemIcon.drawTextureAngle(cell, ringSeparator, centerX, centerY, -i * step)
        end
    end
end

---@param cell IconsInventory_Cell
---@param tex Texture
---@param centerX number
---@param centerY number
---@param angle number
function ItemIcon.drawTextureAngle(cell, tex, centerX, centerY, angle)
    local ui = cell.pane.native
    -- DrawTextureAngle somehow doesn't take scroll into account
    ui:DrawTextureAngle(tex, centerX + ui:getXScroll(), centerY + ui:getYScroll(), angle)
end

ItemIcon.bookNumber = {
    [1] = "I",
    [3] = "II",
    [5] = "III",
    [7] = "IV",
    [9] = "V",
}
