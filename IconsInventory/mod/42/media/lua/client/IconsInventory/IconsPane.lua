local mod = require("IconsInventory/mod")
local Cell = require("IconsInventory/Cell")
local CellPool = require("IconsInventory/CellPool")
local DragSelectionBox = require("IconsInventory/DragSelectionBox")
local GridLayout = require("IconsInventory/GridLayout")
local MultiSelect = require("IconsInventory/MultiSelect")

local function True()
    return true
end

-- Directly from ISInventoryPane
local function isSelectAllPossible(page)
    if not page then return false end
    if not page:isVisible() then return false end
    if page.isCollapsed then return false end
    if not page:isMouseOver() then return false end
    -- for _, v in pairs(page.inventoryPane.selected) do
    -- return true
    -- end
    return true
end

---@param page ISInventoryPage
---@return IconsInventory_ISInventoryPageOverride
local function getTheOtherPage(page)
    return page.onCharacter and getPlayerLoot(page.player) or getPlayerInventory(page.player)
end

---@alias IconsInventory_IconsPane_CellDown { cell: IconsInventory_Cell, vx: number, vy: number  }
---@alias IconsInventory_IconsPane_MouseDown { x: number, y: number, ctrl: boolean, shift: boolean, focused?: IconsInventory_IconsPane_CellDown }

---@class IconsInventory_IconsPane: ISPanel
---@field parent IconsInventory_ISInventoryPageOverrideIconsInventory_ISInventoryPageOverride
---@field native IconsInventory_ISInventoryPaneOverride
---@field grid IconsInventory_GridLayout<IconsInventory_Cell>
---@field focusedCell? IconsInventory_Cell
---@field prevContainer? ItemContainer
---@field expanded table<string, boolean>
---@field pool IconsInventory_CellPool
---@field isMouseAllowed boolean
---@field beingSelected table<IconsInventory_Cell, boolean>
---@field mouseDown? IconsInventory_IconsPane_MouseDown
---@field dragSelectionBox? IconsInventory_DragSelectionBox
---@field multiSelect? IconsInventory_MultiSelect
---@field overscrollTime integer
---@field _mouseOut? boolean
---@field _cancelMouseUp? true
---@field _fakeX? number
---@field _fakeY? number
local IconsPane = ISPanel:derive("IconsInventory_IconsPane")
IconsPane.__index = IconsPane

function IconsPane._init()
    IconsPane.minXPadding = 2 * Cell.padding
    IconsPane.yPadding = Cell.padding
end

---@param emptyPage IconsInventory_ISInventoryPageOverride
function IconsPane.new(emptyPage)
    local self = setmetatable(ISPanel:new(0, emptyPage:titleBarHeight(), 1, 1), IconsPane)
    self.parent = emptyPage
    self.anchorBottom = true
    self.anchorLeft = true
    self.anchorRight = true
    self.anchorTop = true

    self.grid = GridLayout.new()
    self.expanded = {}
    self.pool = CellPool:new()
    self.isMouseAllowed = getNumActivePlayers() == 1 or getSpecificPlayer(emptyPage.player):getJoypadBind() < 0
    self.beingSelected = {}
    self.overscrollTime = 0

    return self
end

function IconsPane:createChildren()
    self:addScrollBars()
end

function IconsPane:refreshContainer()
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
        if #stack.items > 0 then -- Check that other mods don't get crazy with items (CleanUI)
            -- We work on a fully expanded backend
            self.native.collapsed[stack.name] = false
            table.insert(vanillaItems, stack)
            local category = self.pool:get(stack.items[1], self, #vanillaItems, stack)

            if category:isCollapsed() or category:isCollapsable() then
                table.insert(cells, category)
            end

            for i = 2, #stack.items do
                local item = stack.items[i]
                table.insert(vanillaItems, item)

                if not category:isCollapsed() then
                    local cell = self.pool:get(item, self, #vanillaItems, stack, category)

                    -- stack.inHotbar may also be flagged as equipped by mods
                    if cell:isInHotbar() then
                        if not hotbarCells then
                            hotbarCells = {}
                        end
                        table.insert(hotbarCells, cell)
                    elseif stack.equipped then
                        if not equippedCells then
                            equippedCells = {}
                        end
                        table.insert(equippedCells, cell)
                    else
                        table.insert(cells, cell)
                    end
                end
            end
        end
    end

    -- Display-only: the native backend keeps every cell, so indices and selection stay intact
    local hideEquipped = self.parent.onCharacter and mod.option.hideEquipped:getValue()

    local groups = { cells }
    if hotbarCells and not hideEquipped then
        table.insert(groups, hotbarCells)
    end
    if equippedCells and not hideEquipped then
        table.insert(groups, equippedCells)
    end

    local maxWidth = self.width - 2 * IconsPane.minXPadding
    local gridWidth = math.floor(maxWidth / Cell.size)
    if getSpecificPlayer(self.native.player):getJoypadBind() ~= -1 then
        gridWidth = math.min(mod.option.maxJoypadColumns:getValue(), gridWidth) ---@cast gridWidth integer
    end

    self.grid:set(groups, gridWidth)
    -- Make sure it's an integer to avoid half-pixel renders
    self.grid.x = math.floor(0.49 + (self:getWidth() - self.grid.width) / 2)
    self.grid.y = IconsPane.yPadding

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

    self:setScrollHeight(self.grid.y + self.grid.height + IconsPane.yPadding)
    self.vscroll:setHeight(self:getHeight())
    self:updateScrollbars()
end

---@param focusedCell IconsInventory_Cell?
function IconsPane:setFocusedCell(focusedCell)
    self.focusedCell = focusedCell
    self.native.joyselection = focusedCell and focusedCell.index - 1 or nil
end

function IconsPane:isDragging()
    local x, y = self:getMouseX(), self:getMouseY()
    return self.mouseDown and math.abs(x - self.mouseDown.x) + math.abs(y - self.mouseDown.y) > 6
end

function IconsPane:isDraggingItems()
    return self.mouseDown and self.native.dragging ~= nil and self.native.dragStarted
end

function IconsPane:renderBase()
    local isDragging = self:isDraggingItems()
    local yOffset = self.grid.y

    for g, group in ipairs(self.grid.cells) do
        local groupHeight = IconsPane.yPadding * 2 + Cell.size * math.ceil(#group / self.grid.gridWidth)

        -- Make held items view stand out
        if #self.grid.cells > 1 and g == 1 and self.parent.onCharacter then
            self:drawRect(0, self.grid.y - IconsPane.yPadding, self:getWidth(), groupHeight - 1, 0.5, 0, 0, 0)
        end

        for i, cell in ipairs(group) do
            if not (cell:isSelected() and isDragging) then
                local x = self.grid.x + ((i - 1) % self.grid.gridWidth) * Cell.size
                local y = yOffset + math.floor((i - 1) / self.grid.gridWidth) * Cell.size
                cell:renderAt(x, y)
            end
        end

        yOffset = yOffset + groupHeight

        if #group > 0 and g < #self.grid.cells and #self.grid.cells[g + 1] > 0 then
            self:drawRect(0, yOffset - IconsPane.yPadding, self.width, 1, 0.2, 1, 1, 1)
        end
    end
end

function IconsPane:renderDragged()
    local isDragging = self:isDraggingItems()
    local draggedCells = {}

    for _, group in ipairs(self.grid.cells) do
        for _, cell in ipairs(group) do
            if cell:isSelected() and isDragging then
                table.insert(draggedCells, cell)
            end
        end
    end

    local cursorOffset = -Cell.padding
    -- Deduce scroll as draw functions automatically take it into account
    local centerX = getMouseX() - self:getAbsoluteX() - self:getXScroll() + cursorOffset
    local centerY = getMouseY() - self:getAbsoluteY() - self:getYScroll() + cursorOffset
    local dragStackPad = 10
    self:suspendStencil()
    for i, cell in ipairs(draggedCells) do
        self.native:getAbsoluteX()
        cell:renderAt(
            centerX - (i - #draggedCells / 2) * dragStackPad, centerY + (i - #draggedCells / 2) * dragStackPad
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
---@param cb     fun(...): R
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

---@param cell IconsInventory_Cell
function IconsPane:toggleExpanded(cell)
    local stackName = cell.stack.name
    self.expanded[stackName] = not self.expanded[stackName]
    self._dirty = true
end

IconsPane.sortOptions = {
    { func = ISInventoryPane.itemSortByCatInc, text = getText("IGUI_invpanel_Category") },
    {
        func = ISInventoryPane.itemSortByWeightDesc,
        text = getText("IGUI_invpanel_weight") .. " " .. getText("IGUI_invpanel_descending")
    }
}

function IconsPane:update()
    if not self.native then return end

    if self:isReallyVisible() then -- Avoids glitchy tooltip in game menu
        local vanilla_isReallyVisible = self.native.isReallyVisible
        self.native.isReallyVisible = True
        local ok, err = pcall(self.native.update, self.native)
        self.native.isReallyVisible = vanilla_isReallyVisible

        if not ok then error(err) end

        if self.native.toolRender then
            self.native.toolRender:setOwner(self)
        end
    end

    if isCtrlKeyDown() and isSelectAllPossible(self.parent) then
        getCore():setIsSelectingAll(true)
        if isKeyDown(Keyboard.KEY_A) then
            table.wipe(self.native.selected)
            for _, row in ipairs(self.grid.cells) do
                for _, cell in ipairs(row) do
                    if not (cell:isInEquippedGroup() or cell:isInHotbar()) then
                        self.native.selected[cell.index] = cell:getListItem()
                    end
                end
            end
        end
    else
        getCore():setIsSelectingAll(isCtrlKeyDown() and isSelectAllPossible(getTheOtherPage(self.parent)))
    end

    if self.native.doController and self.native.toolRender and self.native.toolRender.anchorBottomLeft then
        self.native.toolRender.anchorBottomLeft.x = self:getAbsoluteX() + self.grid.x
    end
end

function IconsPane:prerender()
    local containersWidth = self.parent.containerButtonPanel:getWidth()
    local y = self:getY()
    local controlsY = self.parent.controlsUI:getY()
    -- Round target dimensions: floating point fails comparisons afterwards
    local desiredWidth = math.floor(0.49 + self.parent:getWidth() - containersWidth)
    local desiredHeight = math.floor(0.49 + 1 + self.parent:getHeight() - y
        - (controlsY > y and self.parent.controlsUI:getHeight() or 0) - (self.parent.resizeWidget2
            and self.parent.resizeWidget2:getHeight()
            or 0))

    if self.x ~= self.native.x then self:setX(self.native.x) end

    if self:getWidth() ~= desiredWidth then
        self:setWidth(desiredWidth)
    end
    if self:getHeight() ~= desiredHeight then
        self:setHeight(desiredHeight)
    end

    -- Vanilla (ISLootWindowContainerControls) or mods (CleanUI for appliances) may use dimensions under the hood
    self.native.width = desiredWidth
    self.native.height = desiredHeight

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

    -- Height -1 to avoid removing controlsUI line
    self:setStencilRect(0, 0, self:getWidth() - visibleScrollBarWidth, self:getHeight() - 1)
    self:renderBase()
    if self.dragSelectionBox then self.dragSelectionBox:render() end
    self:clearStencilRect()

    self:updateSmoothScrolling()
end

function IconsPane:render()
    self:renderDragged()
    self.native:updateWorldObjectHighlight()
end

function IconsPane:onMouseDown(x, y)
    if not self.isMouseAllowed then return end
    self.mouseDown = {
        x = x,
        y = y,
        ctrl = isCtrlKeyDown(),
        shift = isShiftKeyDown(),
        focused = self.focusedCell and {
            cell = self.focusedCell,
            vx = self.native:getMouseX(),
            vy = self.native:getMouseY(),
        },
    }

    -- Init selection painting
    if self.focusedCell and self.mouseDown.ctrl then
        self.focusedCell:setSelected(not self.focusedCell:isSelected())
    end
end

function IconsPane:onMouseUp(x, y)
    if not self.isMouseAllowed then return end

    local wasDragging = self:isDraggingItems()
    local handledClick = false

    if self.mouseDown and not self:isDragging() then
        handledClick = self:handleClick(self.mouseDown)
    end

    -- Handle drop from other pane
    self.native.mouseOverOption = 0
    self.native:onMouseUp(x, y)

    if self.mouseDown
        and not self.mouseDown.ctrl
        and not self.mouseDown.shift
        and not handledClick
        and not wasDragging -- Do not clear aborted drags
    then
        table.wipe(self.native.selected)
    end

    if self.multiSelect then self.multiSelect:apply() end
    if self.dragSelectionBox then self.dragSelectionBox:apply() end

    self.mouseDown = nil
end

---@param mouseDown IconsInventory_IconsPane_MouseDown
function IconsPane:handleClick(mouseDown)
    if mouseDown.focused then
        self.native.dragging = nil

        if isShiftKeyDown() then
            self:handleQuickSend(mouseDown.focused.cell)
            return true
        elseif not isCtrlKeyDown() then
            local clickSend = mod.option.clickSend:getValue()
            local other = getTheOtherPage(self.parent)
            if mouseDown.focused.cell:isCategory()
                and (clickSend == mod.option.clickSend_off or not mouseDown.focused.cell:isSelected())
            then
                self:toggleExpanded(self.focusedCell)
                return true
            elseif
                clickSend == mod.option.clickSend_send
                or (clickSend == mod.option.clickSend_safe and not (
                    self.parent.onCharacter and other.isCollapsed
                ))
            then
                self:handleQuickSend(mouseDown.focused.cell)
                other.collapseCounter = 0
                return true
            end
        end
    elseif not isCtrlKeyDown() then
        table.wipe(self.native.selected)
    end
end

---@param cell IconsInventory_Cell
function IconsPane:handleQuickSend(cell)
    local target = self.parent.onCharacter and getPlayerLoot(self.native.player)
        or getPlayerInventory(self.native.player)
    ---@cast target - nil
    local itemsSet = {}

    if cell:isCategory() then
        for i = 2, #cell.stack.items do
            itemsSet[cell.stack.items[i]] = true
        end
    else
        itemsSet[cell.item] = true
    end

    -- Shift-Click on selection includes all of it (exclude it otherwise)
    if cell:isSelected() then
        for _, selected in pairs(self.native.selected) do
            if instanceof(selected, "InventoryItem") then
                itemsSet[selected] = true
            else
                for i = 2, #selected.items do
                    itemsSet[selected.items[i]] = true
                end
            end
        end
    end

    local items = {}
    for item in pairs(itemsSet) do
        table.insert(items, item)
    end

    self.native:transferItemsByWeight(items, target.inventory)
end

function IconsPane:onMouseMove()
    self._mouseOut = false
    self.native.mouseOverOption = 0

    if self.isMouseAllowed then
        local x, y = self:getMouseX(), self:getMouseY()
        self:setFocusedCell(self.grid:hitTest(x, y))
        if self:isDragging() then self:handleDrag(self.mouseDown) end
    end
end

function IconsPane:onMouseMoveOutside(dx, dy)
    self._mouseOut = true

    if self.isMouseAllowed then
        if not self.native.doController then
            self:setFocusedCell(nil)
        end
        if self.dragSelectionBox then self.dragSelectionBox:update() end
        self.native:onMouseMoveOutside(dx, dy)
    end
end

---@param mouseDown IconsInventory_IconsPane_MouseDown
function IconsPane:handleDrag(mouseDown)
    if mouseDown.focused and not self:isDraggingItems() then
        if mouseDown.shift then
            if not self.multiSelect then
                if not mouseDown.ctrl then
                    table.wipe(self.native.selected)
                end
                self.multiSelect = MultiSelect.new(self, mouseDown.focused.cell)
            elseif self.focusedCell then
                self.multiSelect:setTo(self.focusedCell)
            end
        elseif mouseDown.ctrl then
            if self.focusedCell and self.focusedCell:isSelected() ~= mouseDown.focused.cell:isSelected() then
                self.focusedCell:setSelected(mouseDown.focused.cell:isSelected())
            end
        else
            self.native.mouseOverOption = mouseDown.focused.cell.index
            self.native:onMouseDown(mouseDown.focused.vx, mouseDown.focused.vy)
            self.native.dragStarted = true
        end
    end

    if self.dragSelectionBox then
        self.dragSelectionBox:update()
    elseif not mouseDown.focused and not mouseDown.shift then
        self.dragSelectionBox = DragSelectionBox.new(self, mouseDown.x, mouseDown.y)
    end
end

function IconsPane:onMouseUpOutside(x, y)
    self.mouseDown = nil
    if self.multiSelect then
        self.multiSelect:apply()
    elseif self.dragSelectionBox then
        self.dragSelectionBox:apply()
    else
        return self.native:onMouseUpOutside(x, y)
    end
end

function IconsPane:onRightMouseDown(x, y)
    local handled = true

    if self.focusedCell then
        self.native.mouseOverOption = self.focusedCell and self.focusedCell.index or 0
        handled = IconsPane.stubContextMenuXY(function()
            local ctxX = self:getAbsoluteX() + x
            local ctxY = self:getAbsoluteY() + y + self:getYScroll()
            return ctxX, ctxY
        end, self.native.onRightMouseUp, self.native, self.native:getMouseX(), self.native:getMouseY())
    else
        local context = ISContextMenu.get(
            self.native.player, self:getAbsoluteX() + x, self:getAbsoluteY() + y + self:getYScroll()
        )
        context.origin = self.parent
        context.mouseOver = 1
        setJoypadFocus(self.native.player, context)

        for _, o in ipairs(IconsPane.sortOptions) do
            local option = context:addOption(o.text, self, IconsPane.setSort, o.func)
            if self.native.itemSortFunc == o.func then
                context:setOptionChecked(option, true)
            end
        end
    end

    return handled
end

function IconsPane:onMouseDoubleClick(x, y)
    if not self.isMouseAllowed then return end

    if self.vscroll and self:isVScrollBarVisible() and self.vscroll:isMouseOver() then
        self.vscroll:onMouseDoubleClick(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    elseif self.focusedCell and not self.focusedCell:isCategory() then
        self.native.previousMouseUp = self.focusedCell.index
        self.native.mouseOverOption = self.focusedCell.index
        self.native:onMouseDoubleClick(self.native:getMouseX(), self.native:getMouseY())
    end
end

function IconsPane:onMouseWheel(del)
    if not self.isMouseAllowed then return false end

    if self.parent.isCollapsed then return false end
    if self.parent:isCycleContainerKeyDown() then return false end

    local yScroll = self:getYScroll()
    local yScrollLimit = -math.max(0, self:getScrollHeight() - self:getScrollAreaHeight())
    local yScrollTarget = math.max(yScrollLimit, math.min(0, yScroll - (del * Cell.size)))

    if yScrollTarget ~= yScroll then
        if not self.smoothScrollTargetY then self.smoothScrollY = yScroll end
        self.smoothScrollTargetY = yScroll - (del * Cell.size)

        -- Just reached top or bottom
        if yScrollTarget == 0 or yScrollTarget == yScrollLimit then
            self.overscrollTime = getTimeInMillis()
        end
    elseif mod.option.enableSmartScroll:getValue()
        and (del < 0 and yScroll == 0 or del > 0 and yScrollLimit == yScroll)
    then -- Top or bottom overscroll
        local time = getTimeInMillis()
        if time - self.overscrollTime > 300 then
            local prev_isCycleContainerKeyDown = self.parent.isCycleContainerKeyDown
            self.parent.isCycleContainerKeyDown = True
            pcall(self.parent.onMouseWheel, self.parent, del)
            self.parent.isCycleContainerKeyDown = prev_isCycleContainerKeyDown
        else
            self.overscrollTime = time -- Refresh it - wheel has to stop for a while
        end
    end

    return true
end

-- Copy/Pastadapted from ISInventoryPane
function IconsPane:updateSmoothScrolling()
    if not self.smoothScrollTargetY or #self.native.items == 0 then return end
    local dy = self.smoothScrollTargetY - self.smoothScrollY
    local maxYScroll = self:getScrollHeight() - self:getScrollAreaHeight()
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    local targetY = self.smoothScrollY + dy * math.min(0.5, 0.5 * frameRateFrac)
    if frameRateFrac > 1 then
        targetY = self.smoothScrollY + dy * math.min(1.0, math.min(0.5, 0.5 * frameRateFrac) * frameRateFrac)
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

return IconsPane
