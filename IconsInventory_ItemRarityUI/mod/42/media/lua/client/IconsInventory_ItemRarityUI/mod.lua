require("ISUI/ISInventoryPane")
local Cell = require("IconsInventory/Cell")
local IconsPane = require("IconsInventory/IconsPane")

local rarityBg = getTexture("media/ui/IconsInventory_ItemRarityUI/rarity-bg.png")

local vanilla_sortOptions = IconsPane.sortOptions
IconsPane.sortOptions = {}
for _, o in ipairs(vanilla_sortOptions) do
    table.insert(IconsPane.sortOptions, o)
end
table.insert(IconsPane.sortOptions, {
    func = ISInventoryPane.itemSortByRarityInc,
    text = ItemRarityUI.getText("Rarity"),
})

---@class IconsInventory_ItemRarityUI_Cell: IconsInventory_Cell
local vanilla = {}

---@class IconsInventory_ItemRarityUI_CellOverride: IconsInventory_ItemRarityUI_Cell
local Override = {}

function Override:renderBackground()
    local drewColoredBg = vanilla.renderBackground(self)

    if not drewColoredBg then
        if not ItemRarityUI.dataLoaded then
            ItemRarityUI.loadRarityData()
        end

        local color = ItemRarityUI.getColor(self.item:getFullType())

        if color ~= ItemRarityUI.rarityTiers.common.color and color ~= ItemRarityUI.rarityTiers.unknown.color then
            self.pane:drawTextureTiledX(rarityBg, self.x, self.y,
                self.size, self.size, color.r, color.g, color.b, 0.2)
            self.pane:drawRectBorder(self.x, self.y,
                self.size, self.size, 0.04, color.r, color.g, color.b)
            drewColoredBg = true
        end
    end

    return drewColoredBg
end

function Override:_IconsInventory_ItemRarityUI_clean()
    IconsPane.sortOptions = vanilla_sortOptions
    for k, v in pairs(vanilla) do
        Cell[k] = v
    end
end

if Cell._IconsInventory_ItemRarityUI_clean then
    Cell._IconsInventory_ItemRarityUI_clean()
end

for k, v in pairs(Override) do
    vanilla[k] = Cell[k]
    Cell[k] = v
end
