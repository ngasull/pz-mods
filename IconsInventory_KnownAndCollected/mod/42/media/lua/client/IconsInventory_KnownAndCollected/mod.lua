require("KnownAndCollected")
local kAC = _G.KnownAndCollected
if kAC._IconsInventory_clean then kAC._IconsInventory_clean() end

local Cell = require("IconsInventory/Cell")
local Cell_renderDetails = Cell.renderDetails
kAC._IconsInventory_clean = function()
    Cell.renderDetails = Cell_renderDetails
end

local function KAC_getPrintMediaTitle(item)
    if not item then return nil end
    if item:hasModData() then
        local md = item:getModData()
        local pm = md and md.printMedia
        if pm and pm.title then
            return tostring(pm.title)
        end
    end
    return nil
end

function Cell:renderDetails()
    local res = Cell_renderDetails(self)

    local player = self.player
    kAC:init(player)
    if kAC.allowRender then
        local ui = self.pane;

        local isCollectedMedia = kAC.isCollectedMedia
        local isCollected = kAC.isCollected
        local isKnownMap = kAC.isKnownMap
        local isKnownPrintMedia = kAC.isKnownPrintMedia
        local recordedMedia = getZomboidRadio():getRecordedMedia()
        local item = self.item
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
        local title = ""
        local isStack = self:isCategory()

        if item and item.isRecordedMedia and item:isRecordedMedia() then
            local mediaId = item:getMediaData():getId()
            if not isCollectedMedia(kAC, mediaId) then
                unCollected = true
            end
            if not recordedMedia:hasListenedToAll(player, item:getMediaData()) then
                --unKnown = true
                local isSkillLine = kAC:isSkillMedia(mediaId)
                if isSkillLine then
                    unKnown = true
                else
                    unPlayed = true
                end
            end
        elseif instanceof(item, 'Literature') then
            local _type = item:getFullType()
            local skillBook = SkillBook[item:getSkillTrained()]
            local recipes = item.getLearnedRecipes and item:getLearnedRecipes()
            local pmTitle = KAC_getPrintMediaTitle(item)
            if skillBook then
                local maxTrained = item:getMaxLevelTrained()
                local minTrained = item:getLvlSkillTrained()

                local playerSkillLevel = player:getPerkLevel(skillBook.perk) + 1

                if not isCollected(kAC, _type) then
                    unCollected = true
                end

                local pages = item:getNumberOfPages()
                local readPages = pages > 0 and player:getAlreadyReadPages(_type) or false
                if readPages and readPages ~= pages and maxTrained >= playerSkillLevel then
                    if minTrained > playerSkillLevel then
                        unKnownUnavailable = true
                    elseif readPages > 0 then
                        unKnownUnfinished = true
                    else
                        unKnown = true
                    end
                end
            elseif recipes then
                if not isCollected(kAC, _type) then
                    unCollected = true
                end
                if not player:getAlreadyReadBook():contains(_type) or not player:getKnownRecipes():containsAll(recipes) then
                    unKnown = true
                end
            elseif pmTitle then
                if not isCollected(kAC, pmTitle) then
                    unCollected = true
                end
                if not isKnownPrintMedia(kAC, pmTitle) then
                    unKnownFlier = true
                end
            else
                title = item:hasModData() and item:getModData().literatureTitle
                unKnownEntertainment = title and not player:isLiteratureRead(title)

                if title and not isCollected(kAC, title) then
                    unCollected = true
                end
                --only photos
                --item:hasTag("Picturebook") and not item::hasTag("Picture")
            end
        elseif item and item.IsMap and item:IsMap() then
            isMap = true
            local _type = item:getFullType()
            if not isCollected(kAC, _type) then
                unCollected = true
            end
            if not isKnownMap(kAC, _type) then
                unKnownMap = true
            end
        end

        if isMap and isStack then
            -- because map use same name and stack together we've to check them all
            local _typeFolded = nil
            for n, map in ipairs(self.stack.items) do
                if n > 1 then -- skip first?
                    _typeFolded = map:getFullType()
                    if isCollected(kAC, _typeFolded) then
                        unCollected = false
                    else
                        unCollectedStack = true
                    end
                    if not isKnownMap(kAC, _typeFolded) then
                        unKnownMapStack = true
                    end
                end
            end
        end

        if unCollected or unKnown or unKnownUnfinished or unPlayed or unKnownUnavailable or unKnownMap or unCollectedStack or unKnownMapStack or isMap or unKnownFlier or unKnownEntertainment then
            local tS = 11                 -- kac icons size
            local texDYE = Cell.size - tS -- end
            local texDYM = texDYE         -- Cell.size / 2 - tSH + 1 -- middle
            local texOffsetY = self.y

            if unCollected then
                if not (isMap and isStack) or self:isCollapsed() then
                    local centerX = self.x + Cell.size - tS / 2
                    local centerY = texOffsetY + texDYM + tS / 2
                    ui:DrawTextureAngle(kAC.textures.collected, centerX + ui:getXScroll(), centerY + ui:getYScroll(), -90)
                end
            elseif unCollectedStack then
                if self:isCollapsed() then
                    local centerX = self.x + Cell.size - tS / 2
                    local centerY = texOffsetY + texDYM + tS / 2
                    ui:DrawTextureAngle(kAC.textures.collectedFolded, centerX + ui:getXScroll(),
                        centerY + ui:getYScroll(), -90)
                    self.padSubIcon = self.padSubIcon + 4 -- Hint into nudging stack size number
                end
            end

            if not isStack then
                if unKnown then
                    self:renderSubIcon(kAC.textures.unknown)
                elseif unKnownUnfinished then
                    self:renderSubIcon(kAC.textures.unKnownUnfinished)
                elseif unKnownUnavailable then
                    self:renderSubIcon(kAC.textures.unavailable)
                elseif unPlayed then
                    self:renderSubIcon(kAC.textures.media)
                elseif unKnownMap then
                    self:renderSubIcon(kAC.textures.unKnownMap)
                elseif unKnownMapStack then
                    self:renderSubIcon(kAC.textures.unKnownMapFolded)
                elseif unKnownFlier then
                    self:renderSubIcon(kAC.textures.unKnownFlier)
                elseif unKnownEntertainment then
                    self:renderSubIcon(kAC.textures.unKnownEntertainment)
                end
            end
        end
    end

    return res
end
