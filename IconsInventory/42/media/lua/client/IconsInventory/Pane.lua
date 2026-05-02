local M = require("IconsInventory/mod")

local putHotbarInEquipped = true
local collapseItemsUnder = 0.3
local alwaysCollapseOver = 3
local showSmallCategory = false
local maxColumns = 10
local minXPadding = 16
local minYPadding = 8

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

Pane.yPadding = minYPadding

-- Relies on page override
---@param native IconsInventory_ISInventoryPaneOverride
function Pane.new(native)
    local self = setmetatable({}, Pane)
    self.native = native
    self.page = native.parent
    self.grid = M.GridLayout.new(minYPadding * 2)
    self.xPadding = minXPadding
    self.yPadding = minYPadding
    self.touched = {}
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
        table.wipe(self.touched)
        table.wipe(self.native.collapsed)
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
    local vanillaItems = {}
    self.native.items = vanillaItems

    -- Matters on joypad after refreshes
    local prevHovered = self.hoveredCell
    local _, prevRow, prevCol = self.grid:locateCell(prevHovered)

    local cells = {}
    local hotbarCells ---@type IconsInventory_GridCell[]?
    local equippedCells ---@type IconsInventory_GridCell[]?
    for _, stack in ipairs(self.native.itemslist) do
        table.insert(vanillaItems, stack)
        local category = M.GridCell.new(self, stack.items[1], #vanillaItems, stack)

        if category:isCollapsed() or Pane.shouldCollapse(stack) then
            table.insert(cells, category)
        end

        for i = 2, #stack.items do
            local item = stack.items[i]
            table.insert(vanillaItems, item)

            if not category:isCollapsed() then
                local cell = M.GridCell.new(self, item, #vanillaItems, stack, category)

                if stack.equipped then
                    if not equippedCells then equippedCells = {} end
                    table.insert(equippedCells, cell)
                elseif putHotbarInEquipped and cell:isInHotbar() then
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

    local maxWidth = self.native.width - 2 * minXPadding
    local gridWidth = math.floor(maxWidth / M.ItemIcon.cellSize)
    if getSpecificPlayer(self.native.player):getJoypadBind() ~= -1 then
        gridWidth = math.min(maxColumns, gridWidth)
    end

    self.grid:set(groups, gridWidth)

    -- Make sure it's an integer to avoid half-pixel renders
    self.xPadding = math.floor(0.49 + (self.native:getWidth() - self.grid.width) / 2)

    -- If hoveredCell is has not been forwarded (by GridCell.new)
    if self.hoveredCell == prevHovered then
        self.hoveredCell = nil
    end
    if not self.hoveredCell and prevRow and prevCol then
        self.hoveredCell = self.grid:getCellAt(prevRow, prevCol)
    end
    -- NB: doController check if current pane is *active*
    if self.native.doController and not self.hoveredCell then
        self.hoveredCell = self.grid:getCellAt(1, 1)
    end

    if self.hoveredCell then
        self.native.mouseOverOption = self.hoveredCell.index
        self.native.joyselection = self.hoveredCell.index - 1
    end

    self.native:setScrollHeight(2 * minYPadding + self.grid.height)
    self.native.vscroll:setHeight(self.native:getHeight())
    self.native:updateScrollbars()
end

function Pane:syncMouse()
    if not self.native.doController then
        local hoveredCell = self.grid:hitTest(
            self.native:getMouseX() - self.xPadding,
            self.native:getMouseY() - self.yPadding
        )
        if hoveredCell then
            self.hoveredCell = hoveredCell
            self.native.mouseOverOption = self.hoveredCell.index
        else
            self.hoveredCell = nil
            self.native.mouseOverOption = 0
        end
    end
end

function Pane:joypadSelect(hoveredCell)
    if hoveredCell then
        self.hoveredCell = hoveredCell
        self.native.mouseOverOption = hoveredCell.index
        -- joyselection index starts at zero for some reason
        self.native.joyselection = hoveredCell.index - 1
        return true
    end
end

function Pane:joypadRight()
    return self:joypadSelect(self.grid:getCellRight(self.hoveredCell))
end

function Pane:joypadLeft()
    return self:joypadSelect(self.grid:getCellLeft(self.hoveredCell))
end

function Pane:joypadDown()
    return self:joypadSelect(self.grid:getCellDown(self.hoveredCell))
end

function Pane:joypadUp()
    return self:joypadSelect(self.grid:getCellUp(self.hoveredCell))
end

function Pane:isDragging()
    return self.mouseDown and self.native.dragging ~= nil and self.native.dragStarted
        and math.abs(getMouseX() - self.mouseDown.x) + math.abs(getMouseY() - self.mouseDown.y) > 6
end

function Pane:render()
    local isDragging = self:isDragging()
    local yOffset = minYPadding

    for g, group in ipairs(self.grid.cells) do
        local groupHeight = minYPadding * 2 + M.ItemIcon.cellSize * math.ceil(#group / self.grid.gridWidth)

        -- Make held items view stand out
        if #self.grid.cells > 1 and g == 1 and self.native.parent.onCharacter then
            self.native:drawRect(
                1, 1,
                self.native.width - 2, groupHeight - 1,
                0.5, 0, 0, 0)
        end

        for i, cell in ipairs(group) do
            if not (cell:isSelected() and isDragging) then
                local x = self.xPadding + ((i - 1) % self.grid.gridWidth) * M.ItemIcon.cellSize
                local y = yOffset + math.floor((i - 1) / self.grid.gridWidth) * M.ItemIcon.cellSize
                cell:render(x, y)
            end
        end

        yOffset = yOffset + groupHeight

        if #group > 0 and g < #self.grid.cells and #self.grid.cells[g + 1] > 0 then
            self.native:drawRect(1, yOffset - minYPadding, self.native.width - 2, 1, 0.2, 1, 1, 1)
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

function Pane:desiredWidth()
    return self.native.parent:getWidth() - self.native.parent.buttonSize
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
function Pane.stubContextMenuXY(calcXY, cb, ...)
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
function Pane:_stubMouse(x, y)
    if self.native.mouseOverOption or (x and y) then
        if x and y then
            self.fakeX = x
            self.fakeY = y
        end
        self.native.getMouseX = self._mouseStubX
        self.native.getMouseY = self._mouseStubY
        return true
    end
end

function Pane:_restoreMouse()
    self.native.getMouseX = ISUIElement.getMouseX
    self.native.getMouseY = ISUIElement.getMouseY
    self.fakeX = nil
    self.fakeY = nil
end

---@param native IconsInventory_ISInventoryPaneOverride
function Pane._mouseStubX(native)
    local mod = native._IconsInventory
    return mod.fakeX or native.column2 + 1 -- To the right of collapse area
end

---@param native IconsInventory_ISInventoryPaneOverride
function Pane._mouseStubY(native)
    local mod = native._IconsInventory
    return mod.fakeY or native.headerHgt + (native.mouseOverOption - 1) * native.itemHgt + 2
end
