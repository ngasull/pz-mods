local M = require("IconsInventory/mod")

local minXPadding = 16
local yPadding = 8

local pt = getTextManager():getFontHeight(UIFont.Small) + 1

---@class IconsInventory_Pane
---@field page ISInventoryPage
---@field native IconsInventory_ISInventoryPaneOverride
---@field grid IconsInventory_GridLayout<IconsInventory_Cell>
---@field focusedCell? IconsInventory_Cell
---@field prevContainer? ItemContainer
---@field expanded table<string, boolean>
---@field pool IconsInventory_CellPool
---@field mouseDown? { x: integer, y: integer }
---@field _fakeX? number
---@field _fakeY? number
---@field _cancelMouseUp? true
local Pane = {}
Pane.__index = Pane
M.Pane = Pane

-- Relies on page override
---@param native IconsInventory_ISInventoryPaneOverride
function Pane.new(native)
    local self = setmetatable({}, Pane)
    self.native = native
    self.page = native.parent
    self.grid = M.GridLayout.new(yPadding * 2)
    self.yPadding = yPadding
    self.expanded = {}
    self.pool = M.CellPool:new()
    return self
end

---@param stack ContextMenuItemStack
function Pane.isCollapsable(stack)
    local stackSize = #stack.items - 1
    return not stack.equipped and not stack.inHotbar and M.option.alwaysCollapseOver:getValue() > 1 and (
        stackSize > M.option.alwaysCollapseOver:getValue()
        or stackSize > 1 and stack.weight / stackSize < M.option.collapseItemsUnder:getValue()
    )
end

function Pane:refreshContainer()
    if self.native.inventory ~= self.prevContainer then
        self.prevContainer = self.native.inventory
        table.wipe(self.expanded)
    end

    self._dirty = true
end

function Pane:refresh()
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

        if category:isCollapsed() or Pane.isCollapsable(stack) then
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

    local maxWidth = self.native.width - 2 * minXPadding
    local gridWidth = math.floor(maxWidth / M.ItemIcon.cellSize)
    if getSpecificPlayer(self.native.player):getJoypadBind() ~= -1 then
        gridWidth = math.min(M.option.maxJoypadColumns:getValue(), gridWidth) ---@cast gridWidth integer
    end

    self.grid:set(groups, gridWidth)
    -- Make sure it's an integer to avoid half-pixel renders
    self.grid.x = math.floor(0.49 + (self.native:getWidth() - self.grid.width) / 2)
    self.grid.y = self.native.headerHgt + yPadding

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

    self.native:setScrollHeight(2 * yPadding + self.grid.height)
    self.native.vscroll:setHeight(self.native:getHeight())
    self.native:updateScrollbars()
end

---@param focusedCell IconsInventory_Cell?
function Pane:setFocusedCell(focusedCell)
    self.focusedCell = focusedCell
    self.native.joyselection = focusedCell and focusedCell.index - 1 or nil
end

function Pane:isDragging()
    return self.mouseDown and self.native.dragging ~= nil and self.native.dragStarted
        and math.abs(getMouseX() - self.mouseDown.x) + math.abs(getMouseY() - self.mouseDown.y) > 6
end

function Pane:render()
    local isDragging = self:isDragging()
    local yOffset = self.grid.y

    for g, group in ipairs(self.grid.cells) do
        local groupHeight = yPadding * 2 + M.ItemIcon.cellSize * math.ceil(#group / self.grid.gridWidth)

        -- Make held items view stand out
        if #self.grid.cells > 1 and g == 1 and self.native.parent.onCharacter then
            self.native:drawRect(
                1, self.grid.y - yPadding,
                self.native:getWidth() - 2, groupHeight - 1,
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
            self.native:drawRect(1, yOffset - yPadding, self.native.width - 2, 1, 0.2, 1, 1, 1)
        end
    end

    -- Draw static header above drawable area for mods (ie: BetterContainers) pushing down the grid (clipped by stencil otherwise)
    if self.native.headerHgt > 0 then
        self.native:drawRect(1, -self.native:getYScroll(),
            self.native.width - 2, self.native.headerHgt,
            1, 0, 0, 0)
        self.native:drawRect(
            1, self.native.headerHgt - self.native:getYScroll(),
            self.native.width - 2, 1,
            0.2, 1, 1, 1)
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
    local containersWidth = self.native.parent.buttonSize
    return self.native.parent:getWidth() - containersWidth
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
function Pane:stubMouse(x, y)
    self._fakeX = x
    self._fakeY = y
    self.native.getMouseX = self._mouseStubX
    self.native.getMouseY = self._mouseStubY
    return self.focusedCell or (x and y)
end

function Pane:restoreMouse()
    self.native.getMouseX = ISUIElement.getMouseX
    self.native.getMouseY = ISUIElement.getMouseY
    self._fakeX = nil
    self._fakeY = nil
end

---@param native IconsInventory_ISInventoryPaneOverride
function Pane._mouseStubX(native)
    local mod = native._IconsInventory
    if mod._fakeX then
        return mod._fakeX
    elseif mod.focusedCell then
        return native.column2 + 1 -- To the right of collapse area
    else
        return -1
    end
end

---@param native IconsInventory_ISInventoryPaneOverride
function Pane._mouseStubY(native)
    local mod = native._IconsInventory
    if mod._fakeY then
        return mod._fakeY
    elseif mod.focusedCell then
        return native.headerHgt + (mod.focusedCell.index - 1) * native.itemHgt + 2
    else
        return -1
    end
end
