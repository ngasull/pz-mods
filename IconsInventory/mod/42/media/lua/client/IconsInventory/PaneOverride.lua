local M = require("IconsInventory/mod")

---@param self IconsInventory_ISInventoryPaneOverride
local function removeHeader(self)
    if self.headerHgt ~= self._IconsInventory_headerHgt then
        -- If any mod increases headerHgt, we keep the difference
        local vanillaHeaderHgt = getTextManager():getFontHeight(UIFont.Small) + 1
        self.headerHgt = math.max(0, self.headerHgt - vanillaHeaderHgt)
        self._IconsInventory_headerHgt = self.headerHgt
    end
end

---@param self IconsInventory_ISInventoryPaneOverride
---@param cell IconsInventory_Cell
local function toggleExpanded(self, cell)
    local mod = self._IconsInventory
    local stackName = cell.stack.name
    mod.expanded[stackName] = not mod.expanded[stackName]
    mod._dirty = true
end

---@class IconsInventory_ISInventoryPane: ISInventoryPane
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: ISInventoryPane
---@field parent ISInventoryPage
---@field _IconsInventory IconsInventory_Pane
---@field _IconsInventory_headerHgt? number
local Override = {}

function Override.new(...)
    ---@type IconsInventory_ISInventoryPaneOverride
    local self = vanilla.new(...)
    self._IconsInventory = M.Pane.new(self)
    return self
end

function Override:createChildren()
    vanilla.createChildren(self)
    removeHeader(self)
    self:removeChild(self.expandAll)
    self:removeChild(self.collapseAll)
    self:removeChild(self.filterMenu)
    self:removeChild(self.nameHeader)
    self:removeChild(self.typeHeader)
    self.expandAll:removeFromUIManager()
    self.collapseAll:removeFromUIManager()
    self.filterMenu:removeFromUIManager()
    self.nameHeader:removeFromUIManager()
    self.typeHeader:removeFromUIManager()
end

function Override:refreshContainer()
    vanilla.refreshContainer(self)
    self._IconsInventory:refreshContainer()
end

function Override:update()
    local mod = self._IconsInventory
    mod:stubMouse()
    vanilla.update(self)
    mod:restoreMouse()

    if self.doController and self.toolRender and self.toolRender.anchorBottomLeft then
        self.toolRender.anchorBottomLeft.x = self:getAbsoluteX() + mod.grid.x
    end
end

function Override:prerender()
    local mod = self._IconsInventory

    if self:getWidth() ~= mod:desiredWidth() then
        self.parent:onResize()
    end

    if self.inventory:isDrawDirty() then
        self:refreshContainer()
    end

    if mod._dirty then
        mod:refresh()
        mod._dirty = false
    end

    if self.dragging ~= nil and self.dragStarted then
        self.draggedItems:update()
    end

    -- Render regular content

    -- See ISScrollBar.lua: they are not sure themselves
    local realVScrollWidth = self.vscroll.width - 2
    -- -2 to overlap/merge outer border
    local visibleScrollBarWidth = self:isVScrollBarVisible() and realVScrollWidth - 2 or 0
    self.vscroll:setX(self:getWidth() - realVScrollWidth)

    self:setStencilRect(0, 0, self:getWidth() - visibleScrollBarWidth, self.height);
    mod:render()
    self:clearStencilRect()

    self:updateSmoothScrolling()
end

function Override:render()
    local mod = self._IconsInventory
    mod:renderDragged()
    self:updateWorldObjectHighlight();
end

function Override:onMouseMove(dx, dy)
    local mod = self._IconsInventory

    if self.doController then
        mod:setFocusedCell(nil)
    else
        mod:setFocusedCell(mod.grid:hitTest(
            self:getMouseX(),
            self:getMouseY()
        ))
    end

    -- Only forward on drag: hover is handled by this pane
    if mod.mouseDown and self.downX and self.downY then
        mod:stubMouse(
            self.downX + self:getMouseX() - mod.mouseDown.x,
            self.downY + self:getMouseY() - mod.mouseDown.y
        )
        local handled = vanilla.onMouseMove(self, dx, dy)
        mod:restoreMouse()
        if self.draggingMarquis then self.draggingMarquis = false end
        return handled
    end
end

function Override:onMouseMoveOutside(dx, dy)
    if not self.doController then
        self._IconsInventory:setFocusedCell(nil)
    end
    return vanilla.onMouseMoveOutside(self, dx, dy)
end

function Override:onMouseDown(x, y)
    local mod = self._IconsInventory
    local handled

    if mod:stubMouse() then
        mod.mouseDown = { x = x, y = y, cell = mod.focusedCell }
        handled = vanilla.onMouseDown(self, self:getMouseX(), self:getMouseY())

        if mod.focusedCell then
            if mod.focusedCell:isCategory() then
                -- Unselect items if category was unselected
                if not self.selected[mod.focusedCell.index] then
                    for i = 1, #mod.focusedCell.stack.items - 1 do
                        self.selected[mod.focusedCell.index + i] = nil
                    end
                end
            else
                local category = mod.focusedCell.category
                if self.selected[category.index] then
                    -- Unselect category if it has unselected elements (=> non-vanilla)
                    for i = 1, #category.stack.items - 1 do
                        if not self.selected[category.index + i] then
                            self.selected[category.index] = nil
                        end
                    end
                end
            end
        end
    end
    mod:restoreMouse()
    return handled
end

function Override:onMouseUp(x, y)
    local mod = self._IconsInventory

    local handled
    if mod.focusedCell and mod.focusedCell:isCategory()
        and mod.mouseDown and mod.mouseDown.cell == mod.focusedCell
        and not self.dragStarted and not isCtrlKeyDown() and not isShiftKeyDown()
    then
        toggleExpanded(self, mod.focusedCell)

        -- We don't want to select all on expand (first click of double click selected the category)
        for i in ipairs(mod.focusedCell.stack.items) do
            self.selected[mod.focusedCell.index + i - 1] = nil
        end
    else
        if mod:stubMouse() then
            x = self:getMouseX()
            y = self:getMouseY()
        end
        handled = vanilla.onMouseUp(self, self:getMouseX(), self:getMouseY())
        mod:restoreMouse()
    end

    mod.mouseDown = nil
    return handled
end

function Override:onMouseUpOutside(x, y)
    local mod = self._IconsInventory
    mod.mouseDown = nil
    return vanilla.onMouseUpOutside(self, x, y)
end

function Override:onRightMouseUp(x, y)
    local mod = self._IconsInventory
    local handled = true

    if mod:stubMouse() then
        handled = M.Pane.stubContextMenuXY(
            function()
                local ctxX = self:getAbsoluteX() + x
                local ctxY = self:getAbsoluteY() + y + self:getYScroll()
                return ctxX, ctxY
            end,
            vanilla.onRightMouseUp, self, self:getMouseX(), self:getMouseY()
        )
    end

    mod:restoreMouse()
    return handled
end

function Override:doJoypadExpandCollapse()
    local mod = self._IconsInventory
    if mod.focusedCell and mod.focusedCell:isCategory() then
        toggleExpanded(self, mod.focusedCell)
    end
end

function Override:onMouseDoubleClick(x, y)
    local mod = self._IconsInventory
    local handled

    if self.vscroll and self:isMouseOverScrollBar() then
        return self.vscroll:onMouseDoubleClick(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    elseif mod:stubMouse() then
        handled = vanilla.onMouseDoubleClick(self, self:getMouseX(), self:getMouseY())
    end

    mod:restoreMouse()
    return handled
end

function Override:onMouseWheel(del)
    return vanilla.onMouseWheel(self, del)
end

function Override:onResize()
    vanilla.onResize(self)
    -- Mods may reset header on resize (ie: Better Containers)
    removeHeader(self)
end

local function install()
    for k, v in pairs(Override) do
        vanilla[k] = ISInventoryPane[k]
        ISInventoryPane[k] = v
    end

    M.cleanPane = function()
        for k, v in pairs(vanilla) do
            ISInventoryPane[k] = v
        end
    end
end

local isReload
if M.cleanPane then
    M.cleanPane()
    isReload = true
end

install()

local apply = function()
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            local ppane = pd.playerInventory.inventoryPane
            local lpane = pd.lootInventory.inventoryPane
            ppane._IconsInventory = M.Pane.new(ppane)
            lpane._IconsInventory = M.Pane.new(lpane)
            removeHeader(ppane)
            removeHeader(lpane)
            ppane:refreshContainer()
            lpane:refreshContainer()
        end
    end
end

M.addApply(apply)
if isReload then apply() end
