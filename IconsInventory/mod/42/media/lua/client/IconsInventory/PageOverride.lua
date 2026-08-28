local mod = require("IconsInventory/mod")
local IconsPane = require("IconsInventory/IconsPane")

---@class ISInventoryPage
local vanilla = {}

---@class ISInventoryPage
---@field parent ISInventoryPage
---@field player integer De facto player ID (not in Umbrella)
---@field _IconsInventory IconsInventory_IconsPane
---@field _IconsInventory_init? true
local Override = {}

function Override:addChild(otherElement)
    if getmetatable(otherElement) == ISInventoryPane then
        -- Allow re-adding inventoryPane as an apply hook
        local wasListMode = false
        if self._IconsInventory then
            wasListMode = not self._IconsInventory:isVisible()
            self:removeChild(self._IconsInventory)
            self._IconsInventory:removeFromUIManager()
        end

        self._IconsInventory = IconsPane.new(self, otherElement)
        self._IconsInventory.parent = self

        if wasListMode then
            self._IconsInventory:setVisible(false)
            self._IconsInventory:setEnabled(false)
        else
            vanilla.addChild(self, self._IconsInventory)
            otherElement.parent = self
            otherElement:setVisible(false)
            otherElement:setEnabled(false)
        end

        if getSpecificPlayer(self.player):getJoypadBind() ~= -1 then
            local h = math.max(
                math.floor(self.height / 2),
                math.floor(getCore():getScreenHeight() / 4))
            self:setHeight(h)
            self:setY(getCore():getScreenHeight() - h)
        end

        return otherElement
    else
        return vanilla.addChild(self, otherElement)
    end
end

function Override:update()
    vanilla.update(self)

    -- Support CleanUI (keep checking, they init randomly on controller connect)
    if self._IconsInventory.y ~= self.inventoryPane.y then
        self._IconsInventory:setY(self.inventoryPane.y)
    end
end

function Override:prerender()
    local pane = self._IconsInventory

    -- Draw static header above drawable area for mods (ie: BetterContainers)
    local th = self:titleBarHeight()
    local pageModHeight = pane.y - th
    local mh = pageModHeight + pane.modsHeaderHeight
    if mh > 0 then
        self:drawRect(1, th, self.width - 2, mh, 1, 0, 0, 0)
        self:drawRect(1, th + mh - 1, self.width - 2, 1, 0.2, 1, 1, 1)
    end

    vanilla.prerender(self)
end

-- Vanilla collapses unpinned windows on any outside click; drags were exempt via ISMouseDrag.
-- Icons interactions are clicks, so exempt the sibling window too. (thanks @armaku)
function Override:onMouseDownOutside(...)
    local other = self._IconsInventory:getTheOtherPage()
    if other and other:isReallyVisible() and other:isMouseOver() then return end
    return vanilla.onMouseDownOutside(self, ...)
end

function Override:onRightMouseDownOutside(...)
    local other = self._IconsInventory:getTheOtherPage()
    if other and other:isReallyVisible() and other:isMouseOver() then return end
    return vanilla.onRightMouseDownOutside(self, ...)
end

---@param self ISInventoryPage
local function switchToList(self)
    if self._IconsInventory:isVisible() then
        self:removeChild(self._IconsInventory)
        self._IconsInventory:setVisible(false)
        self._IconsInventory:removeFromUIManager()
        self._IconsInventory:setEnabled(false)

        if self.inventoryPane.toolRender then
            self.inventoryPane.toolRender:setOwner(self.inventoryPane)
        end
        self.inventoryPane:setVisible(true)
        self.inventoryPane:setEnabled(true)
        self.inventoryPane:setWidth(self._IconsInventory.width)
        ISInventoryPane.collapseAll(self.inventoryPane, self.inventoryPane.collapseAll)
        vanilla.addChild(self, self.inventoryPane)
    end
end

---@param self ISInventoryPage
local function switchToIcons(self)
    if not self._IconsInventory:isVisible() then
        self:removeChild(self.inventoryPane)
        self.inventoryPane:setYScroll(0) -- Impacts stubbed mouse
        self.inventoryPane:setVisible(false)
        self.inventoryPane:removeFromUIManager()
        self.inventoryPane:setEnabled(false)

        self._IconsInventory:setVisible(true)
        self._IconsInventory:setEnabled(true)
        self._IconsInventory:refreshContainer()
        vanilla.addChild(self, self._IconsInventory)
    end
end

function Override:onRightMouseDown(x, y)
    if vanilla.onRightMouseDown then vanilla.onRightMouseDown(self, x, y) end

    local context = ISContextMenu.get(self.inventoryPane.player,
        self:getAbsoluteX() + x, self:getAbsoluteY() + y + self:getYScroll())
    context.origin = self
    context.mouseOver = 1
    setJoypadFocus(self.inventoryPane.player, context)

    local iconsOption = context:addOption(getText("IGUI_Controller_Inventory"), self, switchToIcons)
    local listOption = context:addOption(getText("IGUI_AdminPanel_ItemList"), self, switchToList)

    if self._IconsInventory:isVisible() then
        context:setOptionChecked(iconsOption, true)
    else
        context:setOptionChecked(listOption, true)
    end
end

mod.addApply(function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            pd.playerInventory:addChild(pd.playerInventory.inventoryPane)
            pd.lootInventory:addChild(pd.lootInventory.inventoryPane)
        end
    end
end)

-- Install --
local Prev = isDebugEnabled() and require("IconsInventory/PageOverride")
for k in pairs(Override) do
    if not Prev then
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] =
            isDebugEnabled() and function(...) return Override[k](...) end
            or Override[k]
    else
        vanilla[k] = Prev._vanilla[k]
    end
end

Override._vanilla = vanilla
return Override
