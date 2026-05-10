local M = require("IconsInventory/mod")

local iconSize ---@type integer
local padding ---@type integer
local subIconSize ---@type integer
local equippedIconSize ---@type integer
local fontSize ---@type integer
local ringRadius ---@type integer
local ringDiameter ---@type integer
local halfPadding ---@type number
local cellSize ---@type  integer
local subIconRelPos ---@type  number
local subIconYPad ---@type number

local ringGood = {} ---@type Texture[]
local ringBad = {} ---@type Texture[]
local ringSeparator
local ringBg = getTexture("media/ui/IconsInventory/ring/ring-bg.png")

local softBg = getTexture("media/ui/IconsInventory/soft-bg.png")

-- Added by Icons Inventory
local wetIcon = getTexture("media/ui/Entity/SlotStatus/wet_24.png")
local clockIcon = getTexture("media/ui/speedControls/Wait_Off.png")
local maggots = InventoryItem.new("", "", "Maggots", "Item_Insect_Maggots")

local equippedItemIcon = getTexture("media/ui/icon.png")
local equippedInHotbar = getTexture("media/ui/iconInHotbar.png")
local brokenItemIcon = getTexture("media/ui/icon_broken.png")
local frozenItemIcon = getTexture("media/ui/icon_frozen.png")
local poisonIcon = getTexture("media/ui/SkullPoison.png")
local favoriteStar = getTexture("media/ui/FavoriteStar.png")
local noFavoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/nocraft.png")
local favoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/craftok.png")

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

---@param cell IconsInventory_Cell
---@param xoff number
---@param yoff number
---@param scale? number
function ItemIcon.drawBase(cell, xoff, yoff, scale)
    local size = (scale or 1) * iconSize
    local center = (cellSize - size) / 2

    -- Some icons are almost invisible (like Car keys)
    cell.pane:drawTextureScaled(softBg, xoff + padding, yoff + padding,
        iconSize, iconSize,
        1, 0.2, 0.2, 0.2)

    ISInventoryItem.renderItemIcon(
        cell.pane, cell.item,
        xoff + center, yoff + center,
        1, size, size
    )
end

---@param cell IconsInventory_Cell
function ItemIcon.drawSubscript(cell, xoff, yoff, str, scale)
    local size = (scale or 1) * iconSize
    local offset = (iconSize - size) / 2
    cell.pane:drawTextRight(
        str,
        xoff + cellSize - halfPadding - offset,
        yoff + cellSize - halfPadding - fontSize - offset,
        1, 1, 1, 1, UIFont.Small
    )
end

---@param cell IconsInventory_Cell
function ItemIcon.drawDetails(cell, xoff, yoff)
    local item = cell.item
    local ui = cell.pane

    -- This section is copy/pastadapted from ISInventoryPane:renderdetails

    local padBR = -4
    if cell:isEquipped() then
        padBR = padBR + 4
        ui:drawTextureScaled(equippedItemIcon,
            xoff + subIconRelPos - equippedIconSize - padBR, yoff + subIconRelPos - equippedIconSize - subIconYPad + 1,
            equippedIconSize, equippedIconSize,
            1, 1, 1, 1);
        padBR = padBR + equippedIconSize
    end

    if cell:isInHotbar() then
        padBR = padBR + 4
        ui:drawTextureScaled(equippedInHotbar,
            xoff + subIconRelPos - equippedIconSize - padBR, yoff + subIconRelPos - equippedIconSize - subIconYPad + 1,
            equippedIconSize, equippedIconSize,
            1, 1, 1, 1);
        padBR = padBR + equippedIconSize + 4
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
        local isBeingCooked = item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6
        local isNourishing = item:getHungerChange() < 0 and not (
            item:getScriptItem():isCantEat()
            or item:isBurnt()
            or item:isRotten()
            or cell.player:isKnownPoison(item)
            or (item:isbDangerousUncooked() and not item:isCooked())
        )

        local displayNumbers = false
        if not isBeingCooked and isNourishing and M.option.hungerMode:getValue() == M.option.hungerMode_numbers
            and not item:isSpice()
            and item:getUnhappyChange() < 30 -- Frozen good food seem to give 30 unhappy
        then
            displayNumbers = true
            padBR = padBR + 4
            local str = tostring(math.floor(0.5 - item:getHungerChange() * 100))
            ui:drawTextRight(
                str,
                xoff + cellSize - halfPadding - padBR,
                yoff + cellSize - halfPadding - fontSize,
                item:isFresh() and 0 or 0.75,
                item:isFresh() and 1 or 0.75,
                0,
                0.7, UIFont.Small
            )
            padBR = padBR + getTextManager():MeasureStringX(UIFont.Small, str)
        end

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
            elseif not displayNumbers then
                padBR = padBR + 4
                ui:drawTextureScaled(clockIcon,
                    xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
                    subIconSize, subIconSize,
                    0.5, 0.75, 0.75, 0)
                padBR = padBR + subIconSize
            end
        end

        if not isBeingCooked then
            -- Remaining portion ring
            -- `getHungChange` is an internal value, `getHungerChange` is displayed value
            if not displayNumbers and item:getBaseHunger() ~= 0.0 and item:getHungChange() ~= 0.0 then
                ItemIcon.drawRing(cell, ringGood, xoff, yoff, item:getHungChange() / item:getBaseHunger())
                return
            end

            -- Return early to avoid the ring as well
            if isNourishing then return end
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
            subIconSize, subIconSize, 1, 1, 1, 1);
    elseif item:isFavouriteRecipeInput(cell.player) then
        padBR = padBR + 4
        ui:drawTextureScaled(favoriteRecipeInputStar,
            xoff + subIconRelPos - subIconSize - padBR, yoff + subIconRelPos - subIconSize,
            subIconSize, subIconSize, 1, 1, 1, 1);
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
        cell.pane.native:drawItemDetails(item, 0, 0, 0)
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

    cell.pane:drawTextureScaled(ringBg,
        centerX - ringRadius, centerY - ringRadius,
        ringDiameter, ringDiameter,
        1)

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
    local ui = cell.pane
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

local function refreshResolution()
    -- NB: Makes 2K render as 4K because PZ decides 2K text is at 4K size
    local scaling = math.max(1, math.min(2, math.floor(0.7 + getCore():getScreenHeight() / 1080)))
    iconSize = 32 * scaling
    padding = 4 * scaling
    subIconSize = 8 * scaling
    equippedIconSize = 7 * scaling
    fontSize = 15 * scaling -- Estimated

    ringRadius = 5 * scaling
    ringDiameter = ringRadius * 2

    halfPadding = padding / 2
    cellSize = iconSize + 2 * padding
    subIconRelPos = 1.25 * padding + iconSize
    subIconYPad = (2 * ringRadius - subIconSize) / 2

    ItemIcon.scaling = scaling
    ItemIcon.cellSize = cellSize
    ItemIcon.iconSize = iconSize
    ItemIcon.padding = padding

    local scalingStr = tostring(scaling)
    for i = 1, 16 do
        ringGood[i] = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-good-" .. tostring(i) .. ".png")
        ringBad[i] = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-bad-" .. tostring(i) .. ".png")
    end
    ringSeparator = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-separator.png")
end

refreshResolution()
-- ! -- Not reliably called
-- Events.OnResolutionChange.Add(refreshResolution)
