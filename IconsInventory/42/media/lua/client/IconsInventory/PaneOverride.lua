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
    local prevSelected = {}
    for k, v in pairs(self.selected) do
        prevSelected[v] = k
    end

    vanilla.refreshContainer(self)

    -- Vanilla refreshContainer sadly is not to be trusted to preserve selection
    table.wipe(self.selected)
    for k, v in ipairs(self.items) do
        if prevSelected[v] then
            self.selected[k] = v
        end
    end

    self._IconsInventory:refreshContainer()
end

function Override:doJoypadExpandCollapse()
    local mod = self._IconsInventory
    if mod.hoveredCell then
        mod.touched[mod.hoveredCell.stack.name] = true
    end
    return vanilla.doJoypadExpandCollapse(self)
end

function Override:update()
    local mod = self._IconsInventory
    mod:_stubMouse()
    vanilla.update(self)
    mod:_restoreMouse()

    if self.doController and self.toolRender and self.toolRender.anchorBottomLeft then
        self.toolRender.anchorBottomLeft.x = self:getAbsoluteX() + mod.xPadding
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

    mod:syncMouse()

    -- Only forward on drag: hover is handled by this pane
    if mod.mouseDown and self.downX and self.downY then
        mod:_stubMouse(
            self.downX + self:getMouseX() - mod.mouseDown.x,
            self.downY + self:getMouseY() - mod.mouseDown.y
        )
        local handled = vanilla.onMouseMove(self, dx, dy)
        mod:_restoreMouse()
        if self.draggingMarquis then self.draggingMarquis = false end
        return handled
    end
end

function Override:onMouseMoveOutside(dx, dy)
    if not self.doController then
        self._IconsInventory.hoveredCell = nil
    end
    return vanilla.onMouseMoveOutside(self, dx, dy)
end

function Override:onMouseDown(x, y)
    local mod = self._IconsInventory

    if mod:_stubMouse() then
        mod.mouseDown = { x = x, y = y }
        local handled = vanilla.onMouseDown(self, self:getMouseX(), self:getMouseY())
        mod:_restoreMouse()

        if mod.hoveredCell and not mod.hoveredCell:isCategory() then
            local category = mod.hoveredCell.category

            if self.selected[category.index] then
                -- Unselect category if it has unselected elements (=> non-vanilla)
                for i = 1, #category.stack.items - 1 do
                    if not self.selected[category.index + i] then
                        self.selected[category.index] = nil
                    end
                end
            end
        end

        mod._dirty = true
        return handled
    end
end

function Override:onMouseUp(x, y)
    local mod = self._IconsInventory

    mod.mouseDown = nil
    mod._dirty = true

    if mod:_stubMouse() then
        x = self:getMouseX()
        y = self:getMouseY()
    end

    local handled = vanilla.onMouseUp(self, self:getMouseX(), self:getMouseY())
    mod:_restoreMouse()
    return handled
end

function Override:onMouseUpOutside(x, y)
    local mod = self._IconsInventory
    mod.mouseDown = nil
    return vanilla.onMouseUpOutside(self, x, y)
end

function Override:onRightMouseUp(x, y)
    local mod = self._IconsInventory

    if mod:_stubMouse() then
        local handled = M.Pane.stubContextMenuXY(
            function()
                local ctxX = self:getAbsoluteX() + x
                local ctxY = self:getAbsoluteY() + y + self:getYScroll()
                return ctxX, ctxY
            end,
            vanilla.onRightMouseUp, self, self:getMouseX(), self:getMouseY()
        )
        mod:_restoreMouse()
        mod._dirty = true
        return handled
    end

    return true
end

function Override:onMouseDoubleClick(x, y)
    local mod = self._IconsInventory

    if self.vscroll and self:isMouseOverScrollBar() then
        return self.vscroll:onMouseDoubleClick(x - self.vscroll.x, y + self:getYScroll() - self.vscroll.y)
    elseif -- Expand/collapse
        not self.dragStarted and mod.hoveredCell and mod.hoveredCell:isCategory()
    then
        local stackName = mod.hoveredCell.stack.name
        self.collapsed[stackName] = not self.collapsed[stackName];
        mod.touched[stackName] = true
        self:refreshContainer();
        -- Vanilla will interpret leftmost clicks as expand/collapse hovered option
        -- vanilla.onMouseDown(self, 1, -1)
        -- return vanilla.onMouseUp(self, 1, -1)
    elseif mod:_stubMouse() then
        local handled = vanilla.onMouseDoubleClick(self, self:getMouseX(), self:getMouseY())
        mod:_restoreMouse()
        return handled
    end
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
