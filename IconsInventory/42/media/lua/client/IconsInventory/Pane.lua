local M = require("IconsInventory/mod")

local putHotbarInEquipped = true
local collapseItemsUnder = 0.3
local alwaysCollapseOver = 3
local showSmallCategory = false
local autoResize = true
local maxRows = 3
local yPadding = 8
local xPadding = 16

local pt = getTextManager():getFontHeight(UIFont.Small) + 1

---@class IconsInventory_Pane
---@field page ISInventoryPage
---@field native IconsInventory_ISInventoryPaneOverride
---@field grid IconsInventory_GridLayout<IconsInventory_GridCell>
---@field hoveredCell? IconsInventory_GridCell
---@field prevContainer? ItemContainer
---@field touched table<string, boolean>
---@field mouseDown? { x: integer, y: integer }
---@field fakeX? number
---@field fakeY? number
local Pane = {}
Pane.__index = Pane
M.Pane = Pane

-- Relies on page override
---@param native IconsInventory_ISInventoryPaneOverride
function Pane.init(native)
    local self = setmetatable({}, Pane)
    self.native = native
    native._IconsInventory = self
    self.page = native.parent
    self.grid = M.GridLayout.new(yPadding * 2)
    return self
end

---@param stack ContextMenuItemStack
function Pane.shouldCollapse(stack)
    local stackSize = #stack.items - 1
    return stackSize > alwaysCollapseOver
        or stackSize > 1 and stack.weight / stackSize < collapseItemsUnder
end

function Pane:refreshContainer()
    if self.native.inventory ~= self.prevContainer then
        self.prevContainer = self.native.inventory
        self.touched = {}
        self.native.collapsed = {}
        for _, stack in ipairs(self.native.itemslist) do
            self.native.collapsed[stack.name] = Pane.shouldCollapse(stack)
        end
    else
        for _, stack in pairs(self.native.itemslist) do
            if not self.touched[stack.name] then
                self.native.collapsed[stack.name] = Pane.shouldCollapse(stack)
            end
        end
    end

    self._dirty = true
end

function Pane:refresh()
    self.native:setWidth(self.native.parent:getWidth() - self.native.parent.buttonSize)
    self.native:setHeight(2 + self.native.parent:getHeight()
        - self.native.parent:titleBarHeight()
        - self.native.parent.controlsUI:getHeight()
        - ISCollapsableWindow:resizeWidgetHeight())

    local vanillaItems = {}
    self.native.items = vanillaItems

    local cells = {}
    local hotbarCells = {}
    local equippedCells = {}
    for _, stack in ipairs(self.native.itemslist) do
        -- table.insert(vanillaItems, stack)
        local category

        for _, item in ipairs(stack.items) do
            local isCategory = category == nil
            table.insert(vanillaItems, isCategory and stack or item)

            local cell = M.GridCell.new(self, item, #vanillaItems, stack, category)
            if cell:isCategory() then category = cell end

            if stack.equipped then
                if not isCategory then
                    table.insert(equippedCells, cell)
                end
            elseif putHotbarInEquipped and cell:isInHotbar() then
                if not isCategory then
                    table.insert(hotbarCells, cell)
                end
            elseif isCategory then
                if cell:isCollapsed() or Pane.shouldCollapse(stack) then
                    table.insert(cells, cell)
                end
                if cell:isCollapsed() then break end
            else
                table.insert(cells, cell)
            end
        end
    end

    local groups = { cells }
    if #hotbarCells > 0 then
        table.insert(groups, hotbarCells)
    end
    if #equippedCells > 0 then
        table.insert(groups, equippedCells)
    end

    self.grid:set(groups, self.native.width - 2 * xPadding)

    -- if autoResize then
    --     local groupSpace = (#groups - 1) * yPadding
    --     local maxHeight = maxRows * M.ItemIcon.cellSize + groupSpace
    --     local height = 2 * yPadding + math.max(
    --         M.ItemIcon.cellSize,
    --         self.grid:calcGroupHeight(#cells) + self.grid:calcGroupHeight(#equippedCells) + groupSpace
    --     )
    --     self.native:setHeight(math.min(maxHeight, height))
    --     self.native.parent:setHeight(
    --         self.native.parent:titleBarHeight()
    --         + height
    --         + self.native.parent.controlsUI:getHeight()
    --     )
    --     self.native.parent:onResize()
    -- end

    self.native:setScrollHeight(2 * yPadding + self.grid.height)
    self.native.vscroll:setHeight(self.native:getHeight())
    self.native:updateScrollbars()
end

function Pane:syncMouse()
    local hoveredCell = self.grid:hitTest(
        self.native:getMouseX() - xPadding,
        self.native:getMouseY() - yPadding
    )
    if hoveredCell then
        self.hoveredCell = hoveredCell
        self.native.mouseOverOption = self.hoveredCell.index
    else
        self.hoveredCell = nil
        self.native.mouseOverOption = 0
    end
end

function Pane:isDragging()
    return self.mouseDown and self.native.dragging ~= nil and self.native.dragStarted
        and math.abs(getMouseX() - self.mouseDown.x) + math.abs(getMouseY() - self.mouseDown.y) > 6
end

function Pane:render()
    local isDragging = self:isDragging()
    local yOffset = yPadding

    for g, group in ipairs(self.grid.cells) do
        local groupHeight = yPadding * 2 + M.ItemIcon.cellSize * math.ceil(#group / self.grid.gridWidth)

        -- Make held items view stand out
        if #self.grid.cells > 1 and g == 1 and self.native.parent.onCharacter then
            self.native:drawRect(
                1, 1,
                self.native.width - 2, groupHeight - 1,
                0.5, 0, 0, 0)
        end

        for i, cell in ipairs(group) do
            if not (cell:isSelected() and isDragging) then
                local x = xPadding + ((i - 1) % self.grid.gridWidth) * M.ItemIcon.cellSize
                local y = yOffset + math.floor((i - 1) / self.grid.gridWidth) * M.ItemIcon.cellSize
                cell:render(x, y)
            end
        end

        yOffset = yOffset + groupHeight

        if #group > 0 and g < #self.grid.cells and #self.grid.cells[g + 1] > 0 then
            self.native:drawRect(1, yOffset - yPadding, self.native.width - 2, 1, 0.2, 1, 1, 1)
        end
    end
end

function Pane:renderDragged()
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
    local centerX = getMouseX() - self.native:getAbsoluteX() - self.native:getXScroll() + cursorOffset
    local centerY = getMouseY() - self.native:getAbsoluteY() - self.native:getYScroll() + cursorOffset
    local dragStackPad = 10
    self.native:suspendStencil()
    for i, cell in ipairs(draggedCells) do
        self.native:getAbsoluteX()
        cell:render(
            centerX - (i - #draggedCells / 2) * dragStackPad,
            centerY + (i - #draggedCells / 2) * dragStackPad
        )
    end
    self.native:resumeStencil()
end

---@param x? number
---@param y? number
function Pane:_stubMouse(x, y)
    if self.native.mouseOverOption or (x and y) then
        if x and y then
            self.fakeX = x
            self.fakeY = y
        else
            self.fakeX = nil
            self.fakeY = nil
        end
        self.native.getMouseX = self._mouseStubX
        self.native.getMouseY = self._mouseStubY
        return true
    end
end

function Pane:_restoreMouse()
    self.native.getMouseX = ISUIElement.getMouseX
    self.native.getMouseY = ISUIElement.getMouseY
end

function Pane._mouseStubX(native)
    local mod = native._IconsInventory
    return mod.fakeX or native.column2 + 1 -- To the right of collapse area
end

function Pane._mouseStubY(native)
    local mod = native._IconsInventory
    return mod.fakeY or native.headerHgt + (native.mouseOverOption - 1) * native.itemHgt + 2
end
