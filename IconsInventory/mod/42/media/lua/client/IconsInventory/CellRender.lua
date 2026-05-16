local mod = require("IconsInventory/mod")

local scaling ---@type integer
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
local dotIconYPad ---@type number

local ringGood = {} ---@type Texture[]
local ringBad = {} ---@type Texture[]
local ringSeparator ---@type Texture
local ringBg = getTexture("media/ui/IconsInventory/ring/ring-bg.png")

local softBg = getTexture("media/ui/IconsInventory/soft-bg.png")

---@param Cell IconsInventory_Cell
local function refreshDimensions(Cell)
    if scaling == Cell.scaling then return end

    scaling = Cell.scaling
    iconSize = Cell.iconSize
    padding = Cell.padding
    cellSize = Cell.size

    subIconSize = 8 * scaling
    equippedIconSize = 7 * scaling
    fontSize = 15 * scaling -- Estimated

    ringRadius = 5 * scaling
    ringDiameter = ringRadius * 2

    halfPadding = padding / 2
    subIconRelPos = 1.25 * padding + iconSize
    dotIconYPad = (2 * ringRadius - subIconSize) / 2

    local scalingStr = tostring(scaling)
    for i = 1, 16 do
        ringGood[i] = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-good-" .. tostring(i) .. ".png")
        ringBad[i] = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-bad-" .. tostring(i) .. ".png")
    end
    ringSeparator = getTexture("media/ui/IconsInventory/ring/ring-" .. scalingStr .. "-separator.png")
end

-- Added by Icons Inventory
local wetIcon = getTexture("media/ui/Entity/SlotStatus/wet_24.png")
local clockIcon = getTexture("media/ui/speedControls/Wait_Off.png")
local maggots = InventoryItem.new("", "", "Maggots", "Item_Insect_Maggots")

local equippedIcon = getTexture("media/ui/icon.png")
local equippedInHotbar = getTexture("media/ui/iconInHotbar.png")
local brokenIcon = getTexture("media/ui/icon_broken.png")
local frozenIcon = getTexture("media/ui/icon_frozen.png")
local poisonIcon = getTexture("media/ui/SkullPoison.png")
local favoriteStar = getTexture("media/ui/FavoriteStar.png")
local noFavoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/nocraft.png")
local favoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/craftok.png")

local bookNumberByLvl = {
    [1] = "I",
    [3] = "II",
    [5] = "III",
    [7] = "IV",
    [9] = "V",
}

local function noop() end

---@type number
local fractionFromNative
---@type Texture[]
local ringFromNative

local function capture_drawProgressBar(self, x, y, w, h, f, fg)
    fractionFromNative = f
    ringFromNative = fg.r > fg.g and ringBad or ringGood
end

---@class IconsInventory_CellRender: IconsInventory_CellBase
local CellRender = {}

-- Internal rendering API
---@param x number
---@param y number
function CellRender:renderAt(x, y)
    refreshDimensions(self)
    self.x = x
    self.y = y
    self.padSubIcon = 0
    self:render()
end

-- Moddable rendering API
function CellRender:render()
    self:renderBackground()

    if self:isCategory() then
        self:renderStack()
    else
        self:renderDetails()
    end
end

-- See ISInventoryPane:renderdetails
function CellRender:renderBackground()
    local drewColoredBg = false
    local item = self.item
    local native = self.pane.native
    local heat = (
        (instanceof(item, "Food") or instanceof(item, "DrainableComboItem")) and item:getHeat()
    ) or item:getItemHeat()

    if instanceof(item, 'InventoryItem') then
        item:updateAge()
    end
    if instanceof(item, 'Clothing') then
        item:updateWetness()
    end

    if self:isSelected() then
        if native.dragging ~= nil and native.dragStarted then
            if self:isCollapsed() and native.draggedItems:cannotDropAnyItem()
                or not self:isCollapsed() and native.draggedItems:cannotDropItem(item)
            then
                self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.20, 1.0, 0.0, 0.0)
                drewColoredBg = true
            end
        else
            self.pane:drawRect(self.x, self.y, cellSize - 1, cellSize - 1, 0.20, 1.0, 1.0, 1.0)
            self.pane:drawRectBorder(self.x, self.y, cellSize, cellSize, 0.10, 1.0, 1.0, 1.0)
        end
    elseif self:isFocused() and heat == 1 and not self:isCleanUIHighlighted() then
        if native.doController then
            self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.2, 0.2, 1.0, 1.0)
        else
            self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.05, 1.0, 1.0, 1.0)
        end
    elseif native.highlightItem and native.highlightItem == item:getType() then
        if not native.blinkAlpha then native.blinkAlpha = 0.5; end
        self.pane:drawRect(self.x, self.y, cellSize, cellSize, native.blinkAlpha, 1, 1, 1)
        if not native.blinkAlphaIncrease then
            native.blinkAlpha = native.blinkAlpha - 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
            if native.blinkAlpha < 0 then
                native.blinkAlpha = 0;
                native.blinkAlphaIncrease = true
            end
        else
            native.blinkAlpha = native.blinkAlpha + 0.05 * (UIManager.getMillisSinceLastRender() / 33.3)
            if native.blinkAlpha > 0.5 then
                native.blinkAlpha = 0.5;
                native.blinkAlphaIncrease = false
            end
        end
    elseif self:isCleanUIHighlighted() then
        self.pane:drawRect(self.x, self.y, cellSize, cellSize, self:isFocused() and 0.45 or 0.3, 0.5, 0.3, 0.1)
        drewColoredBg = true
    elseif heat ~= 1 then
        local alpha = self:isFocused() and 0.45 or 0.3
        if heat > 1 then
            self.pane:drawRect(self.x, self.y, cellSize, cellSize, alpha, math.abs(item:getInvHeat()), 0.0, 0.0)
        else
            self.pane:drawRect(self.x, self.y, cellSize, cellSize, alpha, 0.0, 0.0, math.abs(item:getInvHeat()))
        end
        drewColoredBg = true
    end

    if native.doController and self:isFocused() then
        self.pane:drawRectBorder(self.x, self.y, cellSize, cellSize, 0.2, 1, 1, 1)
    end

    if native.itemsToHighlight ~= nil and native.itemsToHighlight[item] == true then
        self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.2, 1.0, 1.0, 1.0)
    end

    local job = item:getJobDelta()
    if job > 0 and (not self:isCategory() or self:isCollapsed()) then
        self:renderJob(job)
        drewColoredBg = true
    elseif self:isQueuedForTransfer() then
        self:renderQueued()
        drewColoredBg = true
    end

    return drewColoredBg
end

---@param delta number
function CellRender:renderJob(delta)
    self.pane:drawRect(self.x, self.y + (1 - delta) * cellSize, cellSize, delta * cellSize,
        0.2, 0.4, 1.0, 0.3);
end

function CellRender:renderQueued()
    local animDuration = 1000
    local animDelta = math.fmod(getTimeInMillis(), animDuration) / animDuration;
    local blinkStrength = 2 * math.abs(animDelta - 0.5)
    self.pane:drawRect(self.x, self.y, cellSize, cellSize,
        0.1 + blinkStrength * 0.05, 0.4, 1.0, 0.3);
end

-- Some icons are almost invisible (like Car keys)
function CellRender:renderContrast()
    self.pane:drawTextureScaled(softBg, self.x + padding, self.y + padding, iconSize, iconSize, 1, 0.2, 0.2, 0.2)
end

function CellRender:renderStack()
    local scaledIconSize = self:isCollapsed() and iconSize or 0.5 * iconSize
    local scaledPadding = (cellSize - scaledIconSize) / 2
    local scaledHalfPadding = scaledPadding / 2

    self:renderContrast()

    ISInventoryItem.renderItemIcon(
        self.pane, self.item,
        self.x + scaledPadding, self.y + scaledPadding,
        1, scaledIconSize, scaledIconSize
    )
    self.pane:drawTextRight(
        tostring(self:getStackSize()),
        self.x + cellSize - scaledHalfPadding - self.padSubIcon,
        self.y + cellSize - scaledHalfPadding - fontSize,
        1, 1, 1, 1, UIFont.Small
    )
end

function CellRender:renderDetails()
    local item = self.item
    local ui = self.pane

    self:renderContrast()
    ISInventoryItem.renderItemIcon(
        ui, item,
        self.x + padding, self.y + padding,
        1, iconSize, iconSize
    )

    -- This section is copy/pastadapted from ISInventoryPane:renderdetails

    if self:isEquipped() then
        self:renderSubIcon(equippedIcon, equippedIconSize, equippedIconSize)
    end

    if self:isInHotbar() then
        self:renderSubIcon(equippedInHotbar, equippedIconSize, equippedIconSize);
    end

    if item:isBroken() then
        self:renderSubIcon(brokenIcon, subIconSize, subIconSize)
    end

    if instanceof(item, "Food") then
        local isBeingCooked = item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6
        local isNourishing = item:getHungerChange() < 0 and not (
            item:getScriptItem():isCantEat()
            or item:isBurnt()
            or item:isRotten()
            or self.player:isKnownPoison(item)
            or (item:isbDangerousUncooked() and not item:isCooked())
        )

        local displayNumbers = false
        if not isBeingCooked and isNourishing and mod.option.hungerMode:getValue() == mod.option.hungerMode_numbers
            and not item:isSpice()
            and item:getUnhappyChange() < 30 -- Frozen good food seem to give 30 unhappy
        then
            displayNumbers = true
            local str = tostring(math.floor(0.5 - item:getHungerChange() * 100))
            ui:drawTextRight(
                str,
                self.x + cellSize - halfPadding - self.padSubIcon,
                self.y + cellSize - halfPadding - fontSize,
                item:isFresh() and 0 or 0.75,
                item:isFresh() and 1 or 0.75,
                0,
                0.7, UIFont.Small
            )
            self.padSubIcon = self.padSubIcon + getTextManager():MeasureStringX(UIFont.Small, str) + 4
        end

        if item:isFrozen() then
            self:renderSubIcon(frozenIcon, subIconSize, subIconSize)
        end

        if (item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or self.player:isKnownPoison(item) then
            self:renderSubIcon(poisonIcon, subIconSize, subIconSize)
        elseif not item:isFresh() then
            if item:isRotten() then
                ISInventoryItem.renderItemIcon(
                    ui, maggots,
                    self.x + subIconRelPos - subIconSize - self.padSubIcon, self.y + subIconRelPos - subIconSize,
                    0.8, subIconSize, subIconSize)
                self.padSubIcon = self.padSubIcon + subIconSize + 4
            elseif not displayNumbers then
                self:renderSubIcon(clockIcon, subIconSize, subIconSize, 0.5, 0.75, 0.75, 0)
            end
        end

        if not isBeingCooked then
            -- Remaining portion ring
            -- `getHungChange` is an internal value, `getHungerChange` is displayed value
            if not displayNumbers and item:getBaseHunger() ~= 0.0 and item:getHungChange() ~= 0.0 then
                self:renderRing(ringGood, item:getHungChange() / item:getBaseHunger())
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
        self:renderSubIcon(wetIcon, subIconSize, subIconSize, 0.6, 0.0, 0.6, 1);
    end

    if ISInventoryPane:isLiteratureRead(self.player, item) or item:hasBeenSeen(self.player) or item:hasBeenHeard(self.player) or self.player:hasReadMap(item) then
        self:renderSubIcon(getTexture("media/ui/Tick_Mark-10.png"), subIconSize, subIconSize);
    end

    local fluidContainer = item:getFluidContainer() or
        (item:getWorldItem() and item:getWorldItem():getFluidContainer());
    if fluidContainer ~= nil and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not fluidContainer:isEmpty()) and (fluidContainer:contains(Fluid.Bleach) or (fluidContainer:contains(Fluid.TaintedWater) and fluidContainer:getPoisonRatio() > 0.1)) then
        self:renderSubIcon(poisonIcon, subIconSize, subIconSize);
    end

    if item:isFavorite() then
        self:renderSubIcon(favoriteStar, subIconSize, subIconSize)
    elseif item:isNoRecipes(self.player) then
        self:renderSubIcon(noFavoriteRecipeInputStar, subIconSize, subIconSize)
    elseif item:isFavouriteRecipeInput(self.player) then
        self:renderSubIcon(favoriteRecipeInputStar, subIconSize, subIconSize)
    end

    local bookNumber = item:getCategory() == "Literature"
        and item:getLvlSkillTrained() > -1
        and bookNumberByLvl[item:getLvlSkillTrained()]
    if bookNumber then
        ui:drawTextRight(
            bookNumber, self.x + cellSize - halfPadding, self.y + halfPadding,
            1, 1, 1, 0.7, UIFont.Small
        )
    end

    --- Condition circle
    fractionFromNative = nil
    ringFromNative = nil
    ---@diagnostic disable-next-line: undefined-global
    if not ItemConditionOverlay then -- Opt-out for this specific mod (keep literature)
        local vanilla_drawText = ISInventoryPane.drawText
        local vanilla_drawProgressBar = ISInventoryPane.drawProgressBar
        ISInventoryPane.drawText = noop
        ISInventoryPane.drawProgressBar = capture_drawProgressBar
        self.pane.native:drawItemDetails(item, 0, 0, 0)
        ISInventoryPane.drawText = vanilla_drawText
        ISInventoryPane.drawProgressBar = vanilla_drawProgressBar
    end

    if fractionFromNative then
        if instanceof(item, "Drainable") and not item:hasTag(ItemTag.HIDE_REMAINING) then
            self:renderRingUses(ringFromNative or ringGood, item:getCurrentUses(),
                item:getMaxUses())
        else
            self:renderRing(ringFromNative or ringGood, fractionFromNative)
        end
    elseif item:getCategory() == "Literature" and item:getNumberOfPages() > 0 and item:getAlreadyReadPages() > 0 then
        local skillBook = SkillBook[item:getSkillTrained()]
        if skillBook and self.player:getPerkLevel(skillBook.perk) < item:getMaxLevelTrained()
        then -- Not a skill book or player has level low enough to read it
            self:renderRing(ringGood, item:getAlreadyReadPages() / item:getNumberOfPages())
        end
    end
end

---@param icon Texture
---@param w? integer
---@param h? integer
---@param a? number
---@param r? number
---@param g? number
---@param b? number
function CellRender:renderSubIcon(icon, w, h, a, r, g, b)
    if not w then w = icon:getWidth() end
    if not h then h = icon:getHeight() end
    self.pane:drawTextureScaled(icon,
        self.x + subIconRelPos - self.padSubIcon - w, self.y + subIconRelPos - subIconSize + (subIconSize - h) / 2,
        w, h, a or 1, r or 1, g or 1, b or 1);
    self.padSubIcon = self.padSubIcon + w + 4
end

---@param ui ISUIElement
---@param tex Texture
---@param centerX number
---@param centerY number
---@param angle number
local function drawTextureAngle(ui, tex, centerX, centerY, angle)
    -- DrawTextureAngle somehow doesn't take scroll into account
    ui:DrawTextureAngle(tex, centerX + ui:getXScroll(), centerY + ui:getYScroll(), angle)
end

---@param ring Texture[]
---@param fraction number
function CellRender:renderRing(ring, fraction)
    if fraction >= 1 then return false end

    local centerX = self.x + halfPadding + ringRadius
    local centerY = self.y + cellSize - ringRadius - halfPadding

    self.pane:drawTextureScaled(ringBg,
        centerX - ringRadius, centerY - ringRadius,
        ringDiameter, ringDiameter,
        1)

    local angle = 0
    while fraction >= 0.25 do
        drawTextureAngle(self.pane, ring[#ringGood], centerX, centerY, angle)
        fraction = fraction - 0.25
        angle = angle - 90
    end

    local step = math.floor(fraction * 4 * #ringGood + 0.499)
    if step > 0 then
        drawTextureAngle(self.pane, ring[step], centerX, centerY, angle)
    end
    return true
end

---@param ring Texture[]
---@param current number
---@param max number
function CellRender:renderRingUses(ring, current, max)
    if self:renderRing(ring, current / max) and max < 20 then
        local centerX = self.x + halfPadding + ringRadius
        local centerY = self.y + cellSize - ringRadius - halfPadding
        local step = 360 / max
        for i = 0, current - 1 do
            drawTextureAngle(self.pane, ringSeparator, centerX, centerY, -i * step)
        end
    end
end

return CellRender
