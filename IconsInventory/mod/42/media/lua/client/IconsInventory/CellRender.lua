local mod = require("IconsInventory/mod")
local texture = require("IconsInventory/util/texture")

local font ---@type UIFont
local fontHeight ---@type integer
local scaling ---@type number
local iconSize ---@type integer
local padding ---@type integer
local subIconSize ---@type integer
local ringRadius ---@type number
local ringDiameter ---@type integer
local subAlign ---@type number
local subPadding ---@type number
local cellSize ---@type  integer

local ringSeparator = getTexture("media/ui/IconsInventory/ring/ring-separator.png")
local ring0 = getTexture("media/ui/IconsInventory/ring/ring-0.png")
local ring = {} ---@type Texture[]
for i = 1, 16 do
    ring[i] = getTexture("media/ui/IconsInventory/ring/ring-" .. tostring(i) .. ".png")
end

---@alias IconsInventory_Cell_RingColor { r: number, g: number, b: number }
local green = { r = 0, g = 1, b = 0 }
local stale = { r = 0.75, g = 0.75, b = 0 }

local cyan = { r = .5, g = .8, b = .8 }
local colorBuf = {} ---@type IconsInventory_Cell_RingColor

local softBg = getTexture("media/ui/IconsInventory/soft-bg.png")

---@param Cell IconsInventory_Cell
local function refreshDimensions(Cell)
    if font == Cell.font and scaling == Cell.scaling then return end

    font = Cell.font
    scaling = Cell.scaling
    iconSize = Cell.iconSize
    padding = Cell.padding
    cellSize = Cell.size
    subAlign = Cell.subAlign

    local tm = getTextManager()
    fontHeight = tm:MeasureStringY(Cell.font, "I")

    subPadding = padding / 2
    subIconSize = math.floor(12 * scaling + 0.5)

    ringRadius = math.max(7.5, ring[1]:getHeight() * scaling / 6) -- Can be fractional - Force a not-too-small ring
    ringDiameter = math.floor(0.49 + 2 * ringRadius)              -- Not fractional (pixel rendering)
end

-- Added by Icons Inventory
local wetIcon = getTexture("media/ui/Entity/SlotStatus/wet_24.png")
local clockIcon = getTexture("media/ui/speedControls/Wait_Off.png")
local maggots = InventoryItem.new("", "", "Maggots", "Item_Insect_Maggots")
local research16 = getTexture("media/ui/Properties/InventoryProperty_Research_16.png")
local research32 = getTexture("media/ui/Properties/InventoryProperty_Research.png")

local equippedIcon = getTexture("media/ui/icon.png")
local equippedInHotbar = getTexture("media/ui/iconInHotbar.png")
local equippedIconSize = equippedIcon:getHeight()
local brokenIcon = getTexture("media/ui/icon_broken.png")
local frozenIcon = getTexture("media/ui/icon_frozen.png")
local poisonIcon = getTexture("media/ui/SkullPoison.png")
local favoriteStar = getTexture("media/ui/FavoriteStar.png")
local noFavoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/nocraft.png")
local favoriteRecipeInputStar = getTexture("media/ui/inventoryPanes/craftok.png")
local tickMarkIcon = getTexture("media/ui/Tick_Mark-10.png")

local bookNumberByLvl = {
    [1] = "I",
    [3] = "II",
    [5] = "III",
    [7] = "IV",
    [9] = "V",
}

---@type number
local fractionFromNative
---@type IconsInventory_Cell_RingColor
local ringFromNative

local function capture_drawProgressBar(self, x, y, w, h, f, fg)
    fractionFromNative = f
    ringFromNative = fg
end

---@class IconsInventory_Cell
local CellRender = {}

CellRender.color = {
    cannotDrop = { 1, 0, 0 },
    selected = { 1, 1, 1 },
    beingSelected = { 0.6, 0.6, 0.6 },
    focus = { 0.25, 0.25, 0.25 },
    controllerFocus = { 0.2, 1, 1 },
}

-- Internal rendering API
---@param x number
---@param y number
function CellRender:renderAt(x, y)
    refreshDimensions(self)
    self.x = x
    self.y = y
    self.padSubIcon = subPadding
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
        if self.pane:isDraggingItems() then
            if self:isCollapsed() and native.draggedItems:cannotDropAnyItem()
                or not self:isCollapsed() and native.draggedItems:cannotDropItem(item)
            then
                self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.2, unpack(CellRender.color.cannotDrop))
                drewColoredBg = true
            end
        else
            local r, g, b = unpack(CellRender.color.selected)
            self.pane:drawRect(self.x, self.y, cellSize - 1, cellSize - 1, 0.2, r, g, b)
            self.pane:drawRectBorder(self.x, self.y, cellSize, cellSize, 0.1, r, g, b)
        end
    elseif self:isBeingSelected() then
        local r, g, b = unpack(CellRender.color.beingSelected)
        self.pane:drawRect(self.x, self.y, cellSize - 1, cellSize - 1, 0.2, r, g, b)
        self.pane:drawRectBorder(self.x, self.y, cellSize, cellSize, 0.1, r, g, b)
    elseif self:isFocused() and heat == 1 and not self:isCleanUIHighlighted() then
        local r, g, b = unpack(native.doController and CellRender.color.controllerFocus or CellRender.color.focus)
        self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.2, r, g, b)
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
        self.pane:drawRect(self.x, self.y, cellSize, cellSize, 0.2, 1, 1, 1)
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

---@param x number
---@param y number
---@param w number
---@param h number
---@param gray? boolean
function CellRender:renderItem(x, y, w, h, gray)
    ISInventoryItem.renderItemIcon(self.pane, self.item, x, y, gray and 0.5 or 1, w, h)
end

function CellRender:renderStack()
    local ratio = self:isCollapsed() and 1 or 0.5
    local scaledIconSize = ratio * iconSize
    local scaledPadding = padding + (iconSize - scaledIconSize) / 2

    local unwanted = self.item:isUnwanted(self.player)
    local trgb, ta = 1.0, 1.0
    if unwanted then trgb, ta = 0.5, 0.65 end -- vanilla's unwantedTextColor

    self:renderContrast()

    self:renderItem(
        self.x + scaledPadding, self.y + scaledPadding,
        scaledIconSize, scaledIconSize, unwanted
    )

    self.pane:drawTextRight(
        tostring(self:getStackSize()),
        self.x + cellSize - scaledPadding / 2 - self.padSubIcon,
        self.y + cellSize - subAlign - fontHeight * 0.5, -- Font isn't perfectly centered
        trgb, trgb, trgb, ta, font
    )
end

function CellRender:renderDetails()
    local item = self.item
    local ui = self.pane
    local fluidContainer = item:getFluidContainer()

    self:renderContrast()
    self:renderItem(
        self.x + padding, self.y + padding,
        iconSize, iconSize,
        item:isUnwanted(self.player)
    )

    -- This section is copy/pastadapted from ISInventoryPane:renderdetails

    if self:isEquipped() then
        self:renderSubIcon(equippedIcon, equippedIconSize * (scaling > 1 and 1.5 or 1.25))
    end

    if self:isInHotbar() then
        self:renderSubIcon(equippedInHotbar, equippedIconSize * (scaling > 1 and 1.5 or 1.25));
    end

    if item:isBroken() then
        self:renderSubIcon(brokenIcon)
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

        local displayNumbers = not isBeingCooked and isNourishing
            and mod.option.hungerMode:getValue() == mod.option.hungerMode_numbers
            and not item:isSpice()
            and item:getUnhappyChange() < 30 -- Frozen good food seem to give 30 unhappy

        if item:isFrozen() then
            self:renderSubIcon(frozenIcon)
        end

        if (item:isTainted() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue()) or self.player:isKnownPoison(item) then
            self:renderSubIcon(poisonIcon)
        elseif not item:isFresh() then
            if item:isRotten() then
                ISInventoryItem.renderItemIcon(
                    ui, maggots,
                    self.x + cellSize - subAlign - subIconSize / 2 - self.padSubIcon,
                    self.y + cellSize - subAlign - subIconSize / 2,
                    0.8, subIconSize, subIconSize)
                self.padSubIcon = self.padSubIcon + subIconSize + subPadding
            elseif not displayNumbers then
                self:renderSubIcon(clockIcon, 16, 0.5, unpack(stale))
            end
        end

        if not isBeingCooked then
            if displayNumbers then
                ui:drawText(
                    tostring(math.floor(0.5 - item:getHungerChange() * 100)),
                    self.x + subPadding,
                    self.y + cellSize - subAlign - fontHeight / 2,
                    item:isFresh() and 0 or 0.75,
                    item:isFresh() and 1 or 0.75,
                    0,
                    0.7, font
                )
            elseif item:getBaseHunger() ~= 0.0 and item:getHungChange() ~= 0.0 then
                -- Remaining portion ring
                -- `getHungChange` is an internal value, `getHungerChange` is displayed value
                local ratio = item:getHungChange() / item:getBaseHunger()
                if ratio < 1 then self:renderRing(green, ratio) end
                return
            end

            -- Return early to avoid the ring as well
            if isNourishing then return end
        end
    elseif fluidContainer and fluidContainer:getFilledRatio() > 0 then
        local color = cyan
        local c = fluidContainer:getColor()
        if c then
            local r, g, b = c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat()
            local sum, min = r + g + b, 1
            if sum < min then
                local enhance = (min - sum) / 3
                r = r + enhance
                g = g + enhance
                b = b + enhance
            end
            colorBuf.r, colorBuf.g, colorBuf.b = r, g, b
            color = colorBuf
        end
        self:renderRing(color, fluidContainer:getFilledRatio())
    elseif instanceof(item, "Clothing") and (
            item:getBodyLocation() == "Shoes" and item:getWetness() > 60
            or item:getWetness() > 10
        )
    then
        self:renderSubIcon(wetIcon, 12, 0.6, 0.0, 0.6, 1);
    end

    if ISInventoryPane:isLiteratureRead(self.player, item) or item:hasBeenSeen(self.player) or item:hasBeenHeard(self.player) or self.player:hasReadMap(item) then
        self:renderSubIcon(tickMarkIcon);
    end

    if fluidContainer ~= nil and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() and (not fluidContainer:isEmpty()) and (fluidContainer:contains(Fluid.Bleach) or (fluidContainer:contains(Fluid.TaintedWater) and fluidContainer:getPoisonRatio() > 0.1)) then
        self:renderSubIcon(poisonIcon);
    end

    if item:isFavorite() then
        self:renderSubIcon(favoriteStar)
    elseif item:isNoRecipes(self.player) then
        self:renderSubIcon(noFavoriteRecipeInputStar, 16)
    elseif item:isFavouriteRecipeInput(self.player) then
        self:renderSubIcon(favoriteRecipeInputStar, 16)
    end

    local bookNumber = item:getCategory() == "Literature"
        and item:getLvlSkillTrained() > -1
        and bookNumberByLvl[item:getLvlSkillTrained()]
    if bookNumber then
        ui:drawTextRight(bookNumber,
            self.x + cellSize - subPadding,
            self.y + subAlign - fontHeight / 2,
            1, 1, 1, 0.7, font
        )
    end

    if mod.option.showResearchable.value then
        local scriptItem = item:getScriptItem()
        if scriptItem and item:hasResearchableRecipes() and scriptItem:getResearchableRecipes(self.player, true):size() > 0 then
            local icon = scaling > 1 and research32 or research16
            self:renderSupIcon(icon, 16, 0.7)
        end
    end

    --- Condition circle
    fractionFromNative = nil
    ringFromNative = nil
    ---@diagnostic disable-next-line: undefined-global
    if not ItemConditionOverlay then -- Opt-out for this specific mod (keep literature)
        local javaObject = ui.native.javaObject
        local vanilla_drawProgressBar = ui.native.drawProgressBar
        ui.native.javaObject = nil -- Block any rendering action
        ui.native.drawProgressBar = capture_drawProgressBar
        pcall(ui.native.drawItemDetails, ui.native, item, 0, 0, 0)
        ui.native.javaObject = javaObject
        ui.native.drawProgressBar = vanilla_drawProgressBar
    end

    if fractionFromNative then
        if instanceof(item, "Drainable") and not item:hasTag(ItemTag.HIDE_REMAINING) then
            self:renderRingUses(ringFromNative or green, item:getCurrentUses(), item:getMaxUses())
        elseif fractionFromNative < 1 then
            self:renderRing(ringFromNative or green, fractionFromNative)
        end
    elseif item:getCategory() == "Literature" and item:getNumberOfPages() > 0 and item:getAlreadyReadPages() > 0 then
        local skillBook = SkillBook[item:getSkillTrained()]
        if skillBook and self.player:getPerkLevel(skillBook.perk) < item:getMaxLevelTrained()
        then -- Not a skill book or player has level low enough to read it
            local ratio = item:getAlreadyReadPages() / item:getNumberOfPages()
            if ratio < 1 then self:renderRing(green, ratio) end
        end
    end
end

---@param icon Texture
---@param size? number
---@param a? number
---@param r? number
---@param g? number
---@param b? number
function CellRender:renderSubIcon(icon, size, a, r, g, b)
    size = (size or icon:getHeight()) * scaling
    if scaling > 1 then size = size * .75 end
    local w, h = texture.fitInSquare(icon, size)

    self.pane:drawTextureScaled(icon,
        self.x + cellSize - w - self.padSubIcon,
        self.y + cellSize - subAlign - h / 2,
        w, h, a or 1, r or 1, g or 1, b or 1
    )
    self.padSubIcon = self.padSubIcon + w + subPadding
end

---@param icon Texture
---@param size? integer
---@param a? number
---@param r? number
---@param g? number
---@param b? number
function CellRender:renderSupIcon(icon, size, a, r, g, b)
    size = (size or icon:getHeight()) * scaling
    if scaling > 1 then size = size * .75 end
    local w, h = texture.fitInSquare(icon, size)

    local iconRatio = 1
    self.pane:drawTextureScaled(
        icon,
        self.x + cellSize - subAlign * iconRatio - w / 2,
        self.y + subAlign * iconRatio - h / 2,
        w, h, a or 1, r or 1, g or 1, b or 1
    )
end

---@param color IconsInventory_Cell_RingColor
---@param fraction number
function CellRender:renderRing(color, fraction)
    if fraction <= 0 then return end

    local centerX = self.x + subAlign
    local centerY = self.y + cellSize - subAlign

    for angle = 0, -270, -90 do
        local step = fraction >= 0.25 and #ring
            or math.floor(fraction * 4 * #ring + 0.499)
        texture.drawAngle(
            self.pane, step > 0 and ring[step] or ring0,
            centerX, centerY, angle, ringDiameter, ringDiameter,
            color.r, color.g, color.b
        )
        fraction = math.max(0, fraction - 0.25)
    end
end

---@param current number
---@param max number
---@param color IconsInventory_Cell_RingColor
function CellRender:renderRingUses(color, current, max)
    if current >= max then return end

    self:renderRing(color, current / max)
    if max < 20 then
        local centerX = self.x + subAlign
        local centerY = self.y + cellSize - subAlign
        local step = 360 / max
        for i = 0, current - 1 do
            texture.drawAngle(self.pane, ringSeparator, centerX, centerY, -i * step, ringDiameter, ringDiameter)
        end
    end
end

return CellRender
