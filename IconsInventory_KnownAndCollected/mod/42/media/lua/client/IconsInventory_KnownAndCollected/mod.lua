require("KnownAndCollected")

if KnownAndCollected._IconsInventory_clean then KnownAndCollected._IconsInventory_clean() end

local texture = require("IconsInventory/util/texture")
local Cell = require("IconsInventory/Cell")
local Cell_render = Cell.render
KnownAndCollected._IconsInventory_clean = function()
    Cell.render = Cell_render
end

---@param self IconsInventory_Cell
local function render(self)
    local player = self.player
    KnownAndCollected:init(player)
    if KnownAndCollected.allowRender then
        local ui = self.pane;
        local item = self.item
        local isStack = self:isCategory()

        local isCollected = KnownAndCollected.isCollected
        --
        local recordedMedia = getZomboidRadio():getRecordedMedia()

        local unPlayed = false
        local unCollected = false
        local unCollectedStack = false
        local unKnown = false
        local unKnownUnavailable = false
        local unKnownUnfinished = false
        local isMap = false
        local unKnownMap = false
        local unKnownFlier = false
        local unKnownMapStack = false
        local unKnownEntertainment = false
        local unKnownRecipe = false
        local iconUnKnownResearch = false
        local isValidAsCollected = false

        if item:isRecordedMedia() then
            local mediaId = item:getMediaData():getId()
            if not recordedMedia:hasListenedToAll(player, item:getMediaData()) then
                local isSkillLine = KnownAndCollected:isSkillMedia(mediaId)
                if isSkillLine then
                    isValidAsCollected = KnownAndCollected.trackSkillMediaCollected:getValue()
                    unKnown = true
                else
                    isValidAsCollected = KnownAndCollected.trackMediaCollected:getValue()
                    unPlayed = true
                end
            end
        elseif instanceof(item, 'Literature') then
            local skillBook = SkillBook[item:getSkillTrained()]

            if skillBook then
                isValidAsCollected = KnownAndCollected.trackSkillBookCollected:getValue()
                local maxTrained = item:getMaxLevelTrained()
                local minTrained = item:getLvlSkillTrained()
                local playerSkillLevel = player:getPerkLevel(skillBook.perk) + 1
                local pages = item:getNumberOfPages()
                local readPages = pages > 0 and player:getAlreadyReadPages(item:getFullType()) or false

                if readPages and readPages ~= pages and maxTrained >= playerSkillLevel then
                    if minTrained > playerSkillLevel then
                        unKnownUnavailable = true
                    elseif readPages > 0 then
                        unKnownUnfinished = true
                    else
                        unKnown = true
                    end
                end
            else
                local recipes = item:getLearnedRecipes() ~= nil and item:getLearnedRecipes()
                if recipes then
                    isValidAsCollected = KnownAndCollected.trackRecipeCollected:getValue()
                    unKnownRecipe = not player:getAlreadyReadBook():contains(item:getFullType()) or
                        (item:getLearnedRecipes() ~= nil and not player:getKnownRecipes():containsAll(recipes))
                else
                    local modData = item:getModData()
                    local printMediaTitle = modData and modData.printMedia and modData.printMedia.title
                    if printMediaTitle then
                        isValidAsCollected = KnownAndCollected.trackPrintMediaCollected:getValue()
                        unKnownFlier = not player:isLiteratureRead(printMediaTitle)
                    else
                        local literatureTitle = modData and modData.literatureTitle
                        if literatureTitle then
                            isValidAsCollected = KnownAndCollected.trackEntertainmentLiteratureCollected:getValue()
                            unKnownEntertainment = literatureTitle and type(literatureTitle) == "string" and
                                not player:isLiteratureRead(literatureTitle)
                        else
                            isValidAsCollected = KnownAndCollected.trackAllCollected:getValue()
                        end
                    end
                end
            end
        elseif item:IsMap() then
            isMap = true
            isValidAsCollected = KnownAndCollected.trackMapCollected:getValue()
            unKnownMap = not player:hasReadMap(item)
        else
            if KnownAndCollected.trackAllResearchAble:getValue() then
                isValidAsCollected = KnownAndCollected.trackAllCollected:getValue()
                local scriptItem = item:getScriptItem()
                if scriptItem then
                    if scriptItem:hasResearchableRecipes() then
                        iconUnKnownResearch = item:getScriptItem() and
                            item:getScriptItem():getResearchableRecipes(player, true):size() > 0
                    end
                end
            end
        end

        if isValidAsCollected then
            if not isCollected(KnownAndCollected, KnownAndCollected.getUniqueId(item)) then
                unCollected = true
            end
        end

        if unCollected or unKnown or unKnownUnfinished or unPlayed or unKnownUnavailable or unKnownMap or unCollectedStack or unKnownMapStack or isMap or unKnownFlier or unKnownEntertainment then
            local scaling = 0.5 + Cell.scaling * 0.5 -- Looks really ugly when too upscaled

            if unCollected then
                if not (isMap and isStack) or self:isCollapsed() then
                    local s = KnownAndCollected.textures.collected:getWidth() * scaling
                    local centerX = self.x + Cell.size + 2 - s / 2
                    local centerY = self.y + Cell.size + 2 - s / 2
                    texture.drawAngle(ui, KnownAndCollected.textures.collected, centerX, centerY, -90, s, s)
                end
            elseif unCollectedStack then
                if self:isCollapsed() then
                    local s = KnownAndCollected.textures.collectedFolded:getWidth() * scaling
                    local centerX = self.x + Cell.size + 2 - s / 2
                    local centerY = self.y + Cell.size + 2 - s / 2
                    texture.drawAngle(ui, KnownAndCollected.textures.collectedFolded, centerX, centerY, -90, s, s)
                end
            end

            if not isStack then
                if unKnown then
                    self:renderSubIcon(KnownAndCollected.textures.unknown)
                elseif unKnownUnfinished then
                    self:renderSubIcon(KnownAndCollected.textures.unKnownUnfinished)
                elseif unKnownUnavailable then
                    self:renderSubIcon(KnownAndCollected.textures.unavailable)
                elseif unPlayed then
                    self:renderSubIcon(KnownAndCollected.textures.media)
                elseif unKnownMap then
                    self:renderSubIcon(KnownAndCollected.textures.unKnownMap)
                elseif unKnownMapStack then
                    self:renderSubIcon(KnownAndCollected.textures.unKnownMapFolded)
                elseif unKnownFlier then
                    self:renderSubIcon(KnownAndCollected.textures.unKnownFlier)
                elseif unKnownEntertainment then
                    self:renderSubIcon(KnownAndCollected.textures.unKnownEntertainment)
                end
            end
        end
    end
end

function Cell:render()
    local res = Cell_render(self)
    local ok, err = pcall(render, self)
    if not ok then print("Error in IconsInventory_KnownAndCollected: ", err) end
    return res
end
