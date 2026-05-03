local M = require("IconsInventory/mod")

---@class IconsInventory_ISInventoryPane: ISInventoryPane
local vanilla = {}

---@class IconsInventory_ISInventoryPaneOverride: ISInventoryPane
---@field parent ISInventoryPage
---@field _IconsInventory IconsInventory_Pane
local Override = {}

function Override.new(...)
    ---@type IconsInventory_ISInventoryPaneOverride
    local self = vanilla.new(...)
    self._IconsInventory = M.Pane.new(self)
    return self
end

function Override:createChildren()
    vanilla.createChildren(self)
    self.headerHgt = 0
    self:removeChild(self.expandAll)
    self:removeChild(self.collapseAll)
    self:removeChild(self.filterMenu)
    self:removeChild(self.nameHeader)
    self:removeChild(self.typeHeader)
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
    local vscrollBarWidth = self.vscroll.barwidth and self.vscroll.barwidth > 0 and self.vscroll.barwidth + 4 or 0
    self:setStencilRect(1, 1, self.width - 2 - vscrollBarWidth, self.height - 2);
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
        mod.mouseDown = { x = x, y = y }
        handled = vanilla.onMouseDown(self, self:getMouseX(), self:getMouseY())

        if mod.focusedCell and not mod.focusedCell:isCategory() then
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
    mod:restoreMouse()
    return handled
end

function Override:onMouseUp(x, y)
    local mod = self._IconsInventory
    mod.mouseDown = nil

    if mod._cancelMouseUp then
        mod._cancelMouseUp = nil
        return
    end

    if mod:stubMouse() then
        x = self:getMouseX()
        y = self:getMouseY()
    end
    local handled = vanilla.onMouseUp(self, self:getMouseX(), self:getMouseY())
    mod:restoreMouse()
    return handled
end

function Override:onMouseUpOutside(x, y)
    local mod = self._IconsInventory
    mod.mouseDown = nil
    mod._cancelMouseUp = nil
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

---@param self IconsInventory_ISInventoryPaneOverride
---@param cell IconsInventory_Cell
local function toggleExpanded(self, cell)
    local mod = self._IconsInventory
    local stackName = cell.stack.name
    mod.expanded[stackName] = not mod.expanded[stackName]
    mod._dirty = true
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
    elseif not self.dragStarted and mod.focusedCell and mod.focusedCell:isCategory() then
        toggleExpanded(self, mod.focusedCell)

        -- We don't want to select all on expand (first click of double click selected the category)
        for i in ipairs(mod.focusedCell.stack.items) do
            self.selected[mod.focusedCell.index + i - 1] = nil
        end
        -- Also cancel up to avoid re-selecting
        mod._cancelMouseUp = true
    elseif mod:stubMouse() then
        handled = vanilla.onMouseDoubleClick(self, self:getMouseX(), self:getMouseY())
    end

    mod:restoreMouse()
    return handled
end

function Override:onMouseWheel(del)
    return vanilla.onMouseWheel(self, del)
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

if isReload then
    for i = 0, getNumActivePlayers() - 1 do
        local pd = getPlayerData(i)
        if pd then
            local ppane = pd.playerInventory.inventoryPane
            local lpane = pd.lootInventory.inventoryPane
            ppane._IconsInventory = M.Pane.new(ppane)
            lpane._IconsInventory = M.Pane.new(lpane)
            ppane:refreshContainer()
            lpane:refreshContainer()
        end
    end
end
