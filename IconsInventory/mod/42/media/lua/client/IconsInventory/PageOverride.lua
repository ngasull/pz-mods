local M = require("IconsInventory/mod")

---@param self ISInventoryPage
---@return IconsInventory_ISInventoryPageOverride
local function getTheOtherPage(self)
    return self.onCharacter and getPlayerLoot(self.player) or getPlayerInventory(self.player)
end

---@param self IconsInventory_ISInventoryPageOverride
---@param col? integer
local function focusTheOtherPage(self, col)
    local otherPage = getTheOtherPage(self)
    local otherMod = otherPage._IconsInventory
    local otherCell = otherMod.grid:getCellAt(1, col or 1)
    otherMod:setFocusedCell(otherCell)
    setJoypadFocus(self.player, otherPage)
end

---@class IconsInventory_ISInventoryPage: ISInventoryPage
local vanilla = {}

---@class IconsInventory_ISInventoryPageOverride: IconsInventory_ISInventoryPage
---@field parent ISInventoryPage
---@field inventoryPane IconsInventory_ISInventoryPaneOverride
---@field _IconsInventory IconsInventory_IconsPane
---@field _IconsInventory_init? true
---@field _IconsInventory_pressedBumper integer?
---@field _IconsInventory_bcSearchStrip? ISPanel
---@field _IconsInventory_bcSearchEntry? ISTextBox
---@field _IconsInventory_bcSyncOk? true
local Override = {}

---@param self IconsInventory_ISInventoryPageOverride
local function initPage(self)
    local prevPane = self._IconsInventory
    self._IconsInventory = M.IconsPane.new(self)
    self:addChild(self._IconsInventory)

    if prevPane then
        self._IconsInventory:setY(prevPane:getY())
        self._IconsInventory:setVisible(prevPane:isVisible())
        self._IconsInventory:setEnabled(prevPane:isEnabled())
    end
end

function Override:createChildren()
    initPage(self)
    vanilla.createChildren(self)
    self:removeChild(self.inventoryPane)
    self.inventoryPane:removeFromUIManager()
end

function Override:update()
    vanilla.update(self)

    if not self._IconsInventory_init then
        if getSpecificPlayer(self.player):getJoypadBind() ~= -1 then
            local h = math.max(
                math.floor(self:getHeight() / 2),
                math.floor(getCore():getScreenHeight() / 4))
            self:setHeight(h)
            self:setY(getCore():getScreenHeight() - h)

            if self.inventoryPane.toolRender then
                self.inventoryPane.toolRender:setOwner(self._IconsInventory)
            end
        end

        self._IconsInventory_init = true
    end

    -- Support CleanUI (keep checking, they init randomly on controller connect)
    if self.controlsUI:getY() < self.inventoryPane:getY() and self._IconsInventory:getY() ~= self.inventoryPane:getY() then
        self._IconsInventory:setY(self.inventoryPane:getY())
    end

    if self._IconsInventory_pressedBumper then
        local joypad = getSpecificPlayer(self.player):getJoypadBind()

        -- onJoypadUp is not working: do it manually
        if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
            self._IconsInventory_pressedBumper = nil
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
        end
    end

    M.BC.stealBetterSearch(self)
end

function Override:prerender()
    local pane = self._IconsInventory

    -- Draw static header above drawable area for mods (ie: BetterContainers) pushing down the grid (clipped by stencil otherwise)
    if pane.y > self:titleBarHeight() then
        self:drawRect(1, self:titleBarHeight(),
            self.width - 2, pane.y - self:titleBarHeight(),
            1, 0, 0, 0)
        self:drawRect(
            1, pane.y - 1,
            self.width - 2, 1,
            0.2, 1, 1, 1)
    end

    vanilla.prerender(self)
end

---@param self IconsInventory_ISInventoryPageOverride
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
        self.inventoryPane:setWidth(self._IconsInventory:getWidth())
        ISInventoryPane.collapseAll(self.inventoryPane, self.inventoryPane.collapseAll)
        self:addChild(self.inventoryPane)
    end
end

---@param self IconsInventory_ISInventoryPageOverride
local function switchToIcons(self)
    if not self._IconsInventory:isVisible() then
        self:removeChild(self.inventoryPane)
        self.inventoryPane:setYScroll(0) -- Impacts stubbed mouse
        self.inventoryPane:setVisible(false)
        self.inventoryPane:removeFromUIManager()

        self._IconsInventory:setVisible(true)
        self._IconsInventory:setEnabled(true)
        self._IconsInventory:refreshContainer()
        self:addChild(self._IconsInventory)
    end
end

function Override:onRightMouseUp(x, y)
    if vanilla.onRightMouseUp then vanilla.onRightMouseUp(self, x, y) end

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

function Override:onJoypadDirRight(...)
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        local row, col = pane.grid:locateCell(pane.focusedCell)
        if not row or not col then
            -- Find first leftmost cell if any
            row = 1
            col = 1
        end

        pane:setFocusedCell(pane.grid:getCellAt(row, col + 1))

        if not pane.focusedCell then
            if self.onCharacter then
                focusTheOtherPage(self, 1)
            else
                pane:setFocusedCell(pane.grid:getCellAt(row, col))
            end
        end
    end
end

function Override:onJoypadDirLeft(...)
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad) then
        focusTheOtherPage(self)
        self._IconsInventory_pressedBumper = nil
    else
        local row, col = pane.grid:locateCell(pane.focusedCell)
        if not row or not col then
            -- Find first rightmost cell if any
            row = 1
            col = -1
        end

        pane:setFocusedCell(pane.grid:getCellAt(row, col - 1))

        if not pane.focusedCell then
            if not self.onCharacter then
                focusTheOtherPage(self, -1)
            else
                pane:setFocusedCell(pane.grid:getCellAt(row, col))
            end
        end
    end
end

function Override:onJoypadDirDown(...)
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) then
        getPlayerInventory(self.player):selectNextContainer()
        self._IconsInventory_pressedBumper = nil
    end
    if isJoypadRBPressed(joypad) then
        getPlayerLoot(self.player):selectNextContainer()
        self._IconsInventory_pressedBumper = nil
    end

    if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
        local rows = pane.grid:getRows()
        local row, col = pane.grid:locateCell(pane.focusedCell)

        if row and col then
            local nextRow = rows[row + 1]
            pane:setFocusedCell(nextRow and nextRow[math.min(#nextRow, col)])
        else
            -- Find first upmost cell if any
            pane:setFocusedCell(pane.grid:getCellAt(1, 1))
        end

        if not pane.focusedCell then
            self:selectNextContainer()
        end
    end
end

function Override:onJoypadDirUp(...)
    local pane = self._IconsInventory
    local joypad = getSpecificPlayer(self.player):getJoypadBind()

    if isJoypadLBPressed(joypad) then
        getPlayerInventory(self.player):selectPrevContainer()
        self._IconsInventory_pressedBumper = nil
    end
    if isJoypadRBPressed(joypad) then
        getPlayerLoot(self.player):selectPrevContainer()
        self._IconsInventory_pressedBumper = nil
    end

    if not (isJoypadLBPressed(joypad) or isJoypadRBPressed(joypad)) then
        local rows = pane.grid:getRows()
        local row, col = pane.grid:locateCell(pane.focusedCell)

        if row and col then
            local prevRow = rows[row - 1]
            pane:setFocusedCell(prevRow and prevRow[math.min(#prevRow, col)])
        else
            -- Get first downmost cell if any
            pane:setFocusedCell(pane.grid:getCellAt(-1, 1))
        end

        if not pane.focusedCell then
            self:selectPrevContainer()
        end
    end
end

function Override:onJoypadDown(button)
    local pane = self._IconsInventory

    if button == Joypad.LBumper or button == Joypad.RBumper then
        -- If re-pressed before update
        if self._IconsInventory_pressedBumper ~= nil then
            vanilla.onJoypadDown(self, self._IconsInventory_pressedBumper)
        end

        self._IconsInventory_pressedBumper = button
    elseif button == Joypad.AButton and pane.focusedCell then
        local row, col = pane.grid:locateCell(pane.focusedCell)

        if row and col then
            M.IconsPane.stubContextMenuXY(
                function()
                    local x = pane:getAbsoluteX() + pane.grid.x + (col - 1) * M.ItemIcon.cellSize
                    local y = pane:getAbsoluteY() + pane.grid.y + row * M.ItemIcon.cellSize + pane.native:getYScroll()
                    return x, y
                end,
                vanilla.onJoypadDown, self, button
            )
        else
            return vanilla.onJoypadDown(self, button)
        end
    elseif button == Joypad.BButton then
        local player = getSpecificPlayer(self.player)
        if isPlayerDoingActionThatCanBeCancelled(player) then
            stopDoingActionThatCanBeCancelled(player)
            return
        end
        if pane.focusedCell and pane.focusedCell:isCategory() then
            pane:toggleExpanded(pane.focusedCell)
        end
    else
        return vanilla.onJoypadDown(self, button)
    end
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPage[k]
        ISInventoryPage[k] = v
    end

    M.cleanPage = function()
        for k, v in pairs(vanilla) do
            ISInventoryPage[k] = v
        end
    end
end

local isReload
if M.cleanPage then
    M.cleanPage()
    isReload = true
end

install()

---@param page IconsInventory_ISInventoryPageOverride
local function applyPage(page)
    if page._IconsInventory then -- More resilient to what other mods might do
        page:removeChild(page._IconsInventory)
        page._IconsInventory:removeFromUIManager()
        initPage(page)
        page.inventoryPane:refreshContainer()

        if not isReload then
            page._IconsInventory_bcSyncOk = nil
        end
    else
        initPage(page)
        page:removeChild(page.inventoryPane)
        page.inventoryPane:removeFromUIManager()
    end
end

local apply = function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            applyPage(pd.playerInventory)
            applyPage(pd.lootInventory)
        end
    end
end

M.addApply(apply)
if isReload then
    apply()
    isReload = false
end
