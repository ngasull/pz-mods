local M = require("IconsInventory/mod")

local function False() return false end

---@class IconsInventory_IconsPane: ISPanel
---@field parent IconsInventory_ISInventoryPageOverride
---@field native IconsInventory_ISInventoryPaneOverride
---@field grid IconsInventory_GridLayout<IconsInventory_Cell>
---@field focusedCell? IconsInventory_Cell
---@field prevContainer? ItemContainer
---@field expanded table<string, boolean>
---@field pool IconsInventory_CellPool
---@field mouseDown? { x: number, y: number, cell?: IconsInventory_Cell }
---@field _fakeX? number
---@field _fakeY? number
---@field _cancelMouseUp? true
local IconsPane = ISPanel:derive("IconsInventory_IconsPane")
IconsPane.__index = IconsPane
M.IconsPane = IconsPane

---@param emptyPage IconsInventory_ISInventoryPageOverride
function IconsPane.new(emptyPage)
    local self = setmetatable(ISPanel:new(0, 0, 1, 1), IconsPane)
    self.parent = emptyPage
    self.anchorBottom = true
    self.anchorLeft = true
    self.anchorRight = true
    self.anchorTop = true

    self.grid = M.GridLayout.new(2 * M.ItemIcon.padding)
    self.expanded = {}
    self.pool = M.CellPool:new()
    self.minXPadding = 2 * M.ItemIcon.padding
    self.yPadding = M.ItemIcon.padding

    return self
end

function IconsPane:createChildren()
    self:addScrollBars();
end

---@param stack ContextMenuItemStack
function IconsPane.isCollapsable(stack)
    local stackSize = #stack.items - 1
    return not stack.equipped and not stack.inHotbar and M.option.alwaysCollapseOver:getValue() > 1 and (
        stackSize > M.option.alwaysCollapseOver:getValue()
        or stackSize > 1 and stack.weight / stackSize < M.option.collapseItemsUnder:getValue()
    )
end

function IconsPane:refreshContainer()
    local containersWidth = self.parent.buttonSize

    self:setX(self.native.x)
    self:setY(self.native.y)
    self:setWidth(self.parent:getWidth() - containersWidth)
    self:setHeight(1 + self.parent:getHeight()
        - self.parent:titleBarHeight()
        - self.parent.controlsUI:getHeight()
        - ISCollapsableWindow:resizeWidgetHeight())

    if self.parent.containerButtonPanel.anchorLeft then
        self:setX(containersWidth)
    else
        self:setX(0)
    end

    if self.native.inventory ~= self.prevContainer then
        self.prevContainer = self.native.inventory
        table.wipe(self.expanded)
    end

    self._dirty = true
end

function IconsPane:refresh()
    local vanillaItems = {}
    self.native.items = vanillaItems

    -- Matters on joypad after refreshes
    local prevFocused = self.focusedCell
    local prevRow, prevCol = self.grid:locateCell(prevFocused)

    self.pool:prepare()
    local cells = {}
    local hotbarCells ---@type IconsInventory_Cell[]?
    local equippedCells ---@type IconsInventory_Cell[]?
    for _, stack in ipairs(self.native.itemslist) do
        -- We work on a fully expanded backend
        self.native.collapsed[stack.name] = false
        table.insert(vanillaItems, stack)
        local category = self.pool:get(stack.items[1], self, #vanillaItems, stack)

        if category:isCollapsed() or IconsPane.isCollapsable(stack) then
            table.insert(cells, category)
        end

        for i = 2, #stack.items do
            local item = stack.items[i]
            table.insert(vanillaItems, item)

            if not category:isCollapsed() then
                local cell = self.pool:get(item, self, #vanillaItems, stack, category)

                if stack.equipped then
                    if not equippedCells then equippedCells = {} end
                    table.insert(equippedCells, cell)
                elseif stack.inHotbar then
                    if not hotbarCells then hotbarCells = {} end
                    table.insert(hotbarCells, cell)
                else
                    table.insert(cells, cell)
                end
            end
        end
    end

    local groups = { cells }
    if hotbarCells then
        table.insert(groups, hotbarCells)
    end
    if equippedCells then
        table.insert(groups, equippedCells)
    end

    local maxWidth = self.width - 2 * self.minXPadding
    local gridWidth = math.floor(maxWidth / M.ItemIcon.cellSize)
    if getSpecificPlayer(self.native.player):getJoypadBind() ~= -1 then
        gridWidth = math.min(M.option.maxJoypadColumns:getValue(), gridWidth) ---@cast gridWidth integer
    end

    self.grid:set(groups, gridWidth)
    -- Make sure it's an integer to avoid half-pixel renders
    self.grid.x = math.floor(0.49 + (self:getWidth() - self.grid.width) / 2)
    self.grid.y = self.yPadding

    -- If focusedCell is has not been forwarded (by Cell.new)
    if self.focusedCell == prevFocused then
        self:setFocusedCell(nil)
    end
    if not self.focusedCell and prevRow and prevCol then
        for i = prevCol, 1, -1 do
            local fallback = self.grid:getCellAt(prevRow, i)
            if fallback then
                self:setFocusedCell(fallback)
                break
            end
        end
    end
    -- NB: doController check if current pane is *active*
    if self.native.doController and not self.focusedCell then
        self:setFocusedCell(self.grid:getCellAt(1, 1))
    end

    self:setScrollHeight(self.grid.y + self.grid.height + self.yPadding)
    self.vscroll:setHeight(self:getHeight())
    self:updateScrollbars()
end

---@param focusedCell IconsInventory_Cell?
function IconsPane:setFocusedCell(focusedCell)
    self.focusedCell = focusedCell
    self.native.joyselection = focusedCell and focusedCell.index - 1 or nil
end

function IconsPane:isDragging()
    return self.mouseDown and self.native.dragging ~= nil and self.native.dragStarted
        and math.abs(getMouseX() - self.mouseDown.x) + math.abs(getMouseY() - self.mouseDown.y) > 6
end

function IconsPane:renderBase()
    local isDragging = self:isDragging()
    local yOffset = self.grid.y

    for g, group in ipairs(self.grid.cells) do
        local groupHeight = self.yPadding * 2 + M.ItemIcon.cellSize * math.ceil(#group / self.grid.gridWidth)

        -- Make held items view stand out
        if #self.grid.cells > 1 and g == 1 and self.parent.onCharacter then
            self:drawRect(
                1, self.grid.y - self.yPadding,
                self:getWidth() - 2, groupHeight - 1,
                0.5, 0, 0, 0)
        end

        for i, cell in ipairs(group) do
            if not (cell:isSelected() and isDragging) then
                local x = self.grid.x + ((i - 1) % self.grid.gridWidth) * M.ItemIcon.cellSize
                local y = yOffset + math.floor((i - 1) / self.grid.gridWidth) * M.ItemIcon.cellSize
                cell:render(x, y)
            end
        end

        yOffset = yOffset + groupHeight

        if #group > 0 and g < #self.grid.cells and #self.grid.cells[g + 1] > 0 then
            self:drawRect(1, yOffset - self.yPadding, self.width - 2, 1, 0.2, 1, 1, 1)
        end
    end

    -- Draw static header above drawable area for mods (ie: BetterContainers) pushing down the grid (clipped by stencil otherwise)
    local headerHgt = self.grid.y - self.yPadding
    if headerHgt > 0 then
        self:drawRect(1, -self:getYScroll(),
            self.width - 2, headerHgt,
            1, 0, 0, 0)
        self:drawRect(
            1, headerHgt - self:getYScroll(),
            self.width - 2, 1,
            0.2, 1, 1, 1)
    end
end

function IconsPane:renderDragged()
    local isDragging = self:isDragging()
    local draggedCells = {}

    for _, group in ipairs(self.grid.cells) do
        for _, cell in ipairs(group) do
            if cell:isSelected() and isDragging then
                table.insert(draggedCells, cell)
            end
        end
    end

    local cursorOffset = -M.ItemIcon.padding
    -- Deduce scroll as draw functions automatically take it into account
    local centerX = getMouseX() - self:getAbsoluteX() - self:getXScroll() + cursorOffset
    local centerY = getMouseY() - self:getAbsoluteY() - self:getYScroll() + cursorOffset
    local dragStackPad = 10
    self:suspendStencil()
    for i, cell in ipairs(draggedCells) do
        self.native:getAbsoluteX()
        cell:render(
            centerX - (i - #draggedCells / 2) * dragStackPad,
            centerY + (i - #draggedCells / 2) * dragStackPad
        )
    end
    self:resumeStencil()
end

function IconsPane:setSort(itemSortFunc)
    self.native.itemSortFunc = itemSortFunc
    self.native:refreshContainer()
end

local vanilla_createMenu = ISInventoryPaneContextMenu.createMenu

local _stubContextMenu_calcXY
local function _stubContextMenu(player, isInPlayerInventory, items, _x, _y, ...)
    local x, y = _stubContextMenu_calcXY()
    return vanilla_createMenu(player, isInPlayerInventory, items, x, y, ...)
end

---@generic R
---@param calcXY fun(): number, number
---@param cb fun(...): R
---@return R
function IconsPane.stubContextMenuXY(calcXY, cb, ...)
    _stubContextMenu_calcXY = calcXY
    ISInventoryPaneContextMenu.createMenu = _stubContextMenu
    local ok, result = pcall(cb, ...)
    ISInventoryPaneContextMenu.createMenu = vanilla_createMenu

    if ok then
        return result
    else
        error(result)
    end
end

---@param x? number
---@param y? number
function IconsPane:stubMouse(x, y)
    self._fakeX = x
    self._fakeY = y
    self.native.getMouseX = self._mouseStubX
    self.native.getMouseY = self._mouseStubY
    return self.focusedCell or (x and y)
end

function IconsPane:restoreMouse()
    self.native.getMouseX = ISUIElement.getMouseX
    self.native.getMouseY = ISUIElement.getMouseY
    self._fakeX = nil
    self._fakeY = nil
end

---@param native IconsInventory_ISInventoryPaneOverride
function IconsPane._mouseStubX(native)
    local self = native.parent._IconsInventory
    if self._fakeX then
        return self._fakeX
    elseif self.focusedCell then
        return native.column2 + 1 -- To the right of collapse area
    else
        return -1
    end
end

---@param native IconsInventory_ISInventoryPaneOverride
function IconsPane._mouseStubY(native)
    local self = native.parent._IconsInventory
    if self._fakeY then
        return self._fakeY
    elseif self.focusedCell then
        return native.headerHgt + (self.focusedCell.index - 1) * native.itemHgt + 2
    else
        return -1
    end
end

---@param cell IconsInventory_Cell
function IconsPane:toggleExpanded(cell)
    local stackName = cell.stack.name
    self.expanded[stackName] = not self.expanded[stackName]
    self._dirty = true
end

function IconsPane:update()
    if not self.native then return end

    self:stubMouse()
    self.native:update()
    self:restoreMouse()

    if self.native.doController and self.native.toolRender and self.native.toolRender.anchorBottomLeft then
        self.native.toolRender.anchorBottomLeft.x = self:getAbsoluteX() + self.grid.x
    end
end

function IconsPane:prerender()
    if self.native.inventory:isDrawDirty() then
        self.native:refreshContainer()
    end

    if self._dirty then
        self:refresh()
        self._dirty = false
    end

    if self.native.dragging ~= nil and self.native.dragStarted then
        self.native.draggedItems:update()
    end

    -- Render regular content

    -- See ISScrollBar.lua: they are not sure themselves
    local realVScrollWidth = self.vscroll.width - 2
    -- -2 to overlap/merge outer border
    local visibleScrollBarWidth = self:isVScrollBarVisible() and realVScrollWidth - 2 or 0
    self.vscroll:setX(self:getWidth() - realVScrollWidth)

    self:setStencilRect(0, 0, self:getWidth() - visibleScrollBarWidth, self:getHeight());
    self:renderBase()
    self:clearStencilRect()

    self:updateSmoothScrolling()
end

function IconsPane:render()
    self:renderDragged()
    self.native:updateWorldObjectHighlight();
end

function IconsPane:onMouseMove(dx, dy)
    if self.native.doController then
        self:setFocusedCell(nil)
    else
        self:setFocusedCell(self.grid:hitTest(
            self:getMouseX(),
            self:getMouseY()
        ))
    end

    -- Only forward on drag: hover is handled by this pane
    if self.mouseDown and self.native.downX and self.native.downY then
        self:stubMouse(
            self.native.downX + self.native:getMouseX() - self.mouseDown.x,
            self.native.downY + self.native:getMouseY() - self.mouseDown.y
        )
        local handled = self.native:onMouseMove(dx, dy)
        self:restoreMouse()
        if self.native.draggingMarquis then self.native.draggingMarquis = false end
        return handled
    end
end

function IconsPane:onMouseMoveOutside(dx, dy)
    if not self.native.doController then
        self:setFocusedCell(nil)
    end
    return self.native:onMouseMoveOutside(dx, dy)
end

function IconsPane:onMouseDown(x, y)
    local handled

    if isShiftKeyDown() and not isCtrlKeyDown() and self.focusedCell then
        local target = self.parent.onCharacter and getPlayerLoot(self.native.player) or
            getPlayerInventory(self.native.player)
        ---@cast target -nil
        if self.focusedCell:isCategory() then
            local items = {}
            for i = 2, #self.focusedCell.stack.items do
                table.insert(items, self.focusedCell.stack.items[i])
            end
            self.native:transferItemsByWeight(items, target.inventory)
        else
            self.native:transferItemsByWeight({ self.focusedCell.item }, target.inventory)
        end
    elseif self:stubMouse() then
        self.mouseDown = { x = x, y = y, cell = self.focusedCell }
        self.native.mouseOverOption = self.focusedCell and self.focusedCell.index or 0

        local vanilla_isCtrlKeyDown = isCtrlKeyDown
        if isShiftKeyDown() and isCtrlKeyDown() then
            isCtrlKeyDown = False
        end
        local ok, res = pcall(self.native.onMouseDown, self.native, self.native:getMouseX(), self.native:getMouseY())
        isCtrlKeyDown = vanilla_isCtrlKeyDown

        if ok then
            handled = res
        else
            self:restoreMouse()
            error(handled)
        end

        if self.focusedCell then
            if self.focusedCell:isCategory() then
                -- Unselect items if category was unselected
                if not self.native.selected[self.focusedCell.index] then
                    for i = 1, #self.focusedCell.stack.items - 1 do
                        self.native.selected[self.focusedCell.index + i] = nil
                    end
                end
            else
                local category = self.focusedCell.category
                if self.native.selected[category.index] then
                    -- Unselect category if it has unselected elements (=> non-vanilla)
                    for i = 1, #category.stack.items - 1 do
                        if not self.native.selected[category.index + i] then
                            self.native.selected[category.index] = nil
                        end
                    end
                end
            end
        end
    end
    self:restoreMouse()
    return handled
end

function IconsPane:onMouseUp(x, y)
    local handled
    if self.focusedCell and self.focusedCell:isCategory()
        and self.mouseDown and self.mouseDown.cell == self.focusedCell
        and not self.native.dragStarted and not isCtrlKeyDown() and not isShiftKeyDown()
    then
        self:toggleExpanded(self.focusedCell)

        -- We don't want to select all on expand (first click of double click selected the category)
        for i in ipairs(self.focusedCell.stack.items) do
            self.native.selected[self.focusedCell.index + i - 1] = nil
        end
    else
        if self:stubMouse() then
            x = self.native:getMouseX()
            y = self.native:getMouseY()
        end
        self.native.mouseOverOption = self.focusedCell and self.focusedCell.index or 0
        handled = self.native:onMouseUp(self.native:getMouseX(), self.native:getMouseY())
        self:restoreMouse()
    end

    self.mouseDown = nil
    return handled
end

function IconsPane:onMouseUpOutside(x, y)
    self.mouseDown = nil
    return self.native:onMouseUpOutside(x, y)
end

function IconsPane:onRightMouseUp(x, y)
    local handled = true

    if self:stubMouse() then
        handled = M.IconsPane.stubContextMenuXY(
            function()
                local ctxX = self.native:getAbsoluteX() + x
                local ctxY = self.native:getAbsoluteY() + y + self.native:getYScroll()
                return ctxX, ctxY
            end,
            self.native.onRightMouseUp, self.native, self.native:getMouseX(), self.native:getMouseY()
        )
    else
        local context = ISContextMenu.get(self.native.player,
            self:getAbsoluteX() + x, self:getAbsoluteY() + y + self:getYScroll())
        context.origin = self.parent
        context.mouseOver = 1
        setJoypadFocus(self.native.player, context)

        local catOption = context:addOption(getText("IGUI_invpanel_Category"),
            self, M.IconsPane.setSort, ISInventoryPane.itemSortByCatInc)
        local weightOption = context:addOption(
            getText("IGUI_invpanel_weight") .. " " .. getText("IGUI_invpanel_descending"),
            self, M.IconsPane.setSort, ISInventoryPane.itemSortByWeightDesc)

        if self.native.itemSortFunc == ISInventoryPane.itemSortByCatInc then
            context:setOptionChecked(catOption, true)
        elseif self.native.itemSortFunc == ISInventoryPane.itemSortByWeightDesc then
            context:setOptionChecked(weightOption, true)
        end
    end

    self:restoreMouse()
    return handled
end

function IconsPane:onMouseDoubleClick(x, y)
    if self.vscroll and self:isVScrollBarVisible() and self.vscroll:isMouseOver() then
        self.vscroll:onMouseDoubleClick(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    elseif self:stubMouse() then
        self.native:onMouseDoubleClick(self.native:getMouseX(), self.native:getMouseY())
    end

    self:restoreMouse()
end

function IconsPane:onMouseWheel(del)
    if isShiftKeyDown() then
        return self.native:onMouseWheel(del)
    else
        if not self.smoothScrollTargetY then self.smoothScrollY = self:getYScroll() end
        self.smoothScrollTargetY = self:getYScroll() - (del * M.ItemIcon.cellSize / 2)
        return true;
    end
end

-- Copy/Pastadapted from ISInventoryPane
function IconsPane:updateSmoothScrolling()
    if not self.smoothScrollTargetY or #self.native.items == 0 then return end
    local dy = self.smoothScrollTargetY - self.smoothScrollY
    local maxYScroll = self:getScrollHeight() - self:getScrollAreaHeight()
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    local targetY = self.smoothScrollY + dy * math.min(0.5, 0.5 * frameRateFrac)
    if frameRateFrac > 1 then
        targetY = self.smoothScrollY +
            dy * math.min(1.0, math.min(0.5, 0.5 * frameRateFrac) * frameRateFrac)
    end
    if targetY > 0 then targetY = 0 end
    if targetY < -maxYScroll then targetY = -maxYScroll end
    if math.abs(targetY - self.smoothScrollY) > 0.1 then
        self:setYScroll(targetY)
        self.smoothScrollY = targetY
    else
        self:setYScroll(self.smoothScrollTargetY)
        self.smoothScrollTargetY = nil
        self.smoothScrollY = nil
    end
end

function IconsPane:onResize()
    ISPanel.onResize(self)
    self._dirty = true
end
