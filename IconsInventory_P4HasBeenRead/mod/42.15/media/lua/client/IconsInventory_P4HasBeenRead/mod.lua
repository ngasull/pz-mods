local Cell = require("IconsInventory/Cell")

if not _IconsInventory_P4HasBeenRead then _IconsInventory_P4HasBeenRead = {} end
local P4HasBeenRead = _IconsInventory_P4HasBeenRead

-- [NOTICE]
-- The source code below is the basicaly same as the P4HasBeenRead code for Build 42.15.
-- Would love to see them expose a modders API but copying/pastadapting is required so far.P4HasBeenRead.textureBookNR = getTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNR = getTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNC = getTexture("media/ui/P4HasBeenRead_Book_NC.png")
P4HasBeenRead.textureBookAR = getTexture("media/ui/P4HasBeenRead_Book_AR.png")
P4HasBeenRead.textureBookSMM = getTexture("media/ui/P4HasBeenRead_Book_SM_Marked.png")
P4HasBeenRead.textureBookSMU = getTexture("media/ui/P4HasBeenRead_Book_SM_Unmarked.png")
P4HasBeenRead.textureBookCT = getTexture("media/ui/P4HasBeenRead_Book_CT.png")

P4HasBeenRead.notReadTexture = nil
P4HasBeenRead.notCompletedTexture = nil
P4HasBeenRead.alreadyReadTexture = nil
P4HasBeenRead.markedTexture = nil
P4HasBeenRead.unmarkedTexture = nil
P4HasBeenRead.currentTargetTexture = nil
P4HasBeenRead.hasVisibleTextures = false
P4HasBeenRead.hasStatusTextures = false

P4HasBeenRead.Messages_ToDoAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoAutoMark")
P4HasBeenRead.Messages_ToDoNotAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoNotAutoMark")
P4HasBeenRead.ContextMenu_ToDoAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoAutoMark")
P4HasBeenRead.ContextMenu_ToDoNotAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoNotAutoMark")

P4HasBeenRead.effectiveCodes = { "CRP", "COO", "FRM", "DOC", "ELC", "MTL", "MEC", "TAI", "FIS", "TRA", "FOR", "HUS",
    "FKN", "BLA", "POT", "RCP", "BAA", "BUA", "SBU", "LBA", "SBA", "SPE", "AIM", "REL", "SPR", "LFT", "NIM", "SNE" }
P4HasBeenRead.effectiveMedias = {}

P4HasBeenRead.useMarking = false
P4HasBeenRead.targetOptions = {}

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4HasBeenRead.options = {
    EnableTargets = nil,
    ShowMarks = nil,
    ShowCT = nil,
    ShowSM = nil,
    AutoMark = nil,
}
P4HasBeenRead.getModData = function(player)
    local modData = player:getModData()
    if not modData.P4HasBeenRead then
        modData.P4HasBeenRead = {}
        modData.P4HasBeenRead.doNotAutoMark = false
    end
    if not modData.P4HasBeenRead.markedMap then
        modData.P4HasBeenRead.markedMap = {}
    end
    return modData.P4HasBeenRead
end

P4HasBeenRead.marked = function(type, player, noTransmit)
    P4HasBeenRead.getModData(player).markedMap[type] = true
    if not noTransmit then
        player:transmitModData()
    end
end

P4HasBeenRead.markedAll = function(types, player)
    for i, v in ipairs(types) do
        P4HasBeenRead.marked(v, player, true)
    end
    player:transmitModData()
end

P4HasBeenRead.unmarked = function(type, player, noTransmit)
    P4HasBeenRead.getModData(player).markedMap[type] = nil
    if not noTransmit then
        player:transmitModData()
    end
end

P4HasBeenRead.unmarkedAll = function(types, player)
    for i, v in ipairs(types) do
        P4HasBeenRead.unmarked(v, player, true)
    end
    player:transmitModData()
end

P4HasBeenRead.toggleDoNotAutoMark = function(player)
    local modData = P4HasBeenRead.getModData(player)
    modData.doNotAutoMark = not modData.doNotAutoMark
    player:transmitModData()
    if modData.doNotAutoMark then
        P4HasBeenRead.showInfo(player, P4HasBeenRead.Messages_ToDoNotAutoMark)
    else
        P4HasBeenRead.showInfo(player, P4HasBeenRead.Messages_ToDoAutoMark)
    end
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4HasBeenRead.OnInitRecordedMedia = function(_rc)
    for id, media in pairs(RecMedia) do
        local isEffective = false
        for _, line in ipairs(media.lines) do
            if line.codes ~= "BOR-1" then -- Hack for performance
                for _, code in ipairs(P4HasBeenRead.effectiveCodes) do
                    if string.find(line.codes, code) then
                        isEffective = true
                        break
                    end
                end
            end
            if isEffective then
                break
            end
        end
        if isEffective then
            P4HasBeenRead.effectiveMedias[id] = true
        end
    end
end
Events.OnInitRecordedMedia.Add(P4HasBeenRead.OnInitRecordedMedia)

P4HasBeenRead.initTextures = function()
    local options = PZAPI.ModOptions:getOptions("P4HasBeenRead")
    if options then
        P4HasBeenRead.options.EnableTargets = options:getOption("EnableTargets") ---@type umbrella.ModOptions.MultipleTickBox
        P4HasBeenRead.options.ShowMarks = options:getOption("ShowMarks") ---@type umbrella.ModOptions.MultipleTickBox
        P4HasBeenRead.options.ShowCT = options:getOption("ShowCT") ---@type umbrella.ModOptions.TickBox
        P4HasBeenRead.options.ShowSM = options:getOption("ShowSM") ---@type umbrella.ModOptions.MultipleTickBox
        P4HasBeenRead.options.AutoMark = options:getOption("AutoMark") ---@type umbrella.ModOptions.TickBox

        if not (P4HasBeenRead.options.EnableTargets and P4HasBeenRead.options.ShowMarks and P4HasBeenRead.options.ShowCT
                and P4HasBeenRead.options.ShowSM and P4HasBeenRead.options.AutoMark) then
            return
        end

        P4HasBeenRead.isInstalled = true

        P4HasBeenRead.notReadTexture = nil
        if P4HasBeenRead.options.ShowMarks:getValue(1) then
            P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
        end
        P4HasBeenRead.notCompletedTexture = nil
        if P4HasBeenRead.options.ShowMarks:getValue(2) then
            P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
        end
        P4HasBeenRead.alreadyReadTexture = nil
        if P4HasBeenRead.options.ShowMarks:getValue(3) then
            P4HasBeenRead.alreadyReadTexture = P4HasBeenRead.textureBookAR
        end
        P4HasBeenRead.currentTargetTexture = nil
        if P4HasBeenRead.options.ShowCT.value then
            P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT
        end
        P4HasBeenRead.markedTexture = nil
        if P4HasBeenRead.options.ShowSM:getValue(1) then
            P4HasBeenRead.markedTexture = P4HasBeenRead.textureBookSMM
        end
        P4HasBeenRead.unmarkedTexture = nil
        if P4HasBeenRead.options.ShowSM:getValue(2) then
            P4HasBeenRead.unmarkedTexture = P4HasBeenRead.textureBookSMU
        end
        P4HasBeenRead.useMarking = P4HasBeenRead.options.ShowSM:getValue(1) or P4HasBeenRead.options.ShowSM:getValue(2)
        P4HasBeenRead.hasStatusTextures = P4HasBeenRead.notReadTexture ~= nil or P4HasBeenRead.notCompletedTexture ~= nil or
            P4HasBeenRead.alreadyReadTexture ~= nil
        P4HasBeenRead.hasVisibleTextures = P4HasBeenRead.hasStatusTextures or P4HasBeenRead.currentTargetTexture ~= nil or
            P4HasBeenRead.markedTexture ~= nil or P4HasBeenRead.unmarkedTexture ~= nil
        for i = 1, 9 do
            P4HasBeenRead.targetOptions[i] = P4HasBeenRead.options.EnableTargets:getValue(i)
        end
    end
end

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

P4HasBeenRead.setTextures = function(player, item, markedMap, recordedMedia, recordedMediaResult)
    local statusTexture = nil
    local selfMarkingTexture = nil
    local currentTargetTexture = nil
    if item:getCategory() == "Literature" then
        if P4HasBeenRead.isTargetLiterature(item) then
            local type = P4HasBeenRead.getFullType(item)
            local fullType = item:getFullType()
            local skillBook = SkillBook[item:getSkillTrained()]
            if skillBook then
                if P4HasBeenRead.targetOptions[1] and (P4HasBeenRead.hasStatusTextures or P4HasBeenRead.currentTargetTexture) then
                    local perkLevel = player:getPerkLevel(skillBook.perk)
                    local minLevel = item:getLvlSkillTrained()
                    local maxLevel = item:getMaxLevelTrained()
                    if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
                        currentTargetTexture = P4HasBeenRead.currentTargetTexture
                    end
                    if P4HasBeenRead.hasStatusTextures then
                        local readPages = player:getAlreadyReadPages(fullType)
                        if readPages >= item:getNumberOfPages() then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        elseif perkLevel >= maxLevel then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        elseif readPages > 0 then
                            statusTexture = P4HasBeenRead.notCompletedTexture
                        else
                            statusTexture = P4HasBeenRead.notReadTexture
                        end
                    end
                end
            else
                local learnedRecipes = item:getLearnedRecipes()
                if learnedRecipes and not learnedRecipes:isEmpty() then
                    if P4HasBeenRead.targetOptions[2] and P4HasBeenRead.hasStatusTextures then
                        if player:getKnownRecipes():containsAll(learnedRecipes) then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        else
                            statusTexture = P4HasBeenRead.notReadTexture
                        end
                    end
                elseif fullType == "Base.Flier" then
                    if P4HasBeenRead.targetOptions[4] and P4HasBeenRead.hasStatusTextures then
                        if P4HasBeenRead.isLiteratureRead(player, item) then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        else
                            statusTexture = P4HasBeenRead.notReadTexture
                        end
                    end
                elseif fullType == "Base.Brochure" then
                    if P4HasBeenRead.targetOptions[5] and P4HasBeenRead.hasStatusTextures then
                        if P4HasBeenRead.isLiteratureRead(player, item) then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        else
                            statusTexture = P4HasBeenRead.notReadTexture
                        end
                    end
                elseif P4HasBeenRead.targetOptions[6] and P4HasBeenRead.hasStatusTextures then
                    if P4HasBeenRead.isLiteratureRead(player, item) then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                end
            end
            if markedMap[type] then
                selfMarkingTexture = P4HasBeenRead.markedTexture
            else
                selfMarkingTexture = P4HasBeenRead.unmarkedTexture
            end
        end
    elseif instanceof(item, "MapItem") then
        local mapId = item:getMapID()
        if mapId then
            if P4HasBeenRead.targetOptions[3] and P4HasBeenRead.hasStatusTextures then
                if player:hasReadMap(item) then
                    statusTexture = P4HasBeenRead.alreadyReadTexture
                else
                    statusTexture = P4HasBeenRead.notReadTexture
                end
            end
            if markedMap[mapId] then
                selfMarkingTexture = P4HasBeenRead.markedTexture
            else
                selfMarkingTexture = P4HasBeenRead.unmarkedTexture
            end
        end
    elseif recordedMedia then
        local mediaData = item:getMediaData()
        if mediaData then
            local isTarget = false
            local index = mediaData:getIndex()
            local category = mediaData:getCategory()
            if P4HasBeenRead.targetOptions[7] and category == "CDs" then
                isTarget = true
            elseif P4HasBeenRead.targetOptions[8] and category == "Retail-VHS" then
                isTarget = true
            elseif P4HasBeenRead.targetOptions[9] and category == "Home-VHS" then
                isTarget = true
            end
            if isTarget then
                if P4HasBeenRead.currentTargetTexture and P4HasBeenRead.effectiveMedias[mediaData:getId()] then
                    currentTargetTexture = P4HasBeenRead.currentTargetTexture
                end
                if P4HasBeenRead.hasStatusTextures then
                    local cachedTexture = recordedMediaResult[index]
                    if cachedTexture ~= nil then
                        statusTexture = cachedTexture or nil
                    else
                        if recordedMedia:hasListenedToAll(player, mediaData) then
                            statusTexture = P4HasBeenRead.alreadyReadTexture
                        else
                            statusTexture = P4HasBeenRead.notReadTexture
                        end
                        recordedMediaResult[index] = statusTexture or false
                    end
                end
            end
            if markedMap["Base.RM-" .. index] then
                selfMarkingTexture = P4HasBeenRead.markedTexture
            else
                selfMarkingTexture = P4HasBeenRead.unmarkedTexture
            end
        end
    end
    return statusTexture, selfMarkingTexture, currentTargetTexture
end

P4HasBeenRead.isTargetLiterature = function(item)
    local isTarget = false
    local modData = item:getModData()
    if SkillBook[item:getSkillTrained()] then
        isTarget = true
    elseif item:getLearnedRecipes() and not item:getLearnedRecipes():isEmpty() then
        isTarget = true
    elseif item:getFullType() == "Base.Flier" or item:getFullType() == "Base.Brochure" then
        isTarget = true
    elseif modData then
        if modData.literatureTitle then
            isTarget = true
        elseif modData.printMedia then
            isTarget = true
        end
    end
    return isTarget
end

P4HasBeenRead.isLiteratureRead = function(player, item)
    local modData = item:getModData()
    if modData.literatureTitle then
        return player:getReadLiterature():containsKey(modData.literatureTitle)
    elseif modData.printMedia and modData.printMedia.id then
        return player:isPrintMediaRead(modData.printMedia.id)
    end
    return false
end

P4HasBeenRead.getFullType = function(item)
    local type = item:getFullType()
    local modData = item:getModData()
    if type == "Base.RecipeClipping" or type == "Base.SewingPattern" or (string.find(type, "Schematic", 1, true) and item:getDisplayCategory() == "RecipeResource") then
        type = P4HasBeenRead.getRecipeResourceFullType(item, type)
    end
    if modData then
        if modData.literatureTitle then
            type = modData.literatureTitle
        elseif modData.printMedia and modData.printMedia.id then
            type = modData.printMedia.id
        end
    end
    return type
end

P4HasBeenRead.getRecipeResourceFullType = function(item, type)
    local recipes = item:getLearnedRecipes()
    if recipes:isEmpty() then
        return type
    elseif recipes:size() == 1 then
        return type .. "|" .. recipes:get(0)
    else
        local temp = {}
        for i = 0, recipes:size() - 1 do
            temp[#temp + 1] = recipes:get(i)
        end
        table.sort(temp)

        local last = nil
        local j = 1
        for i = 1, #temp do
            local v = temp[i]
            if v ~= last then
                temp[j] = v
                j = j + 1
                last = v
            end
        end
        for k = j, #temp do
            temp[k] = nil
        end

        return type .. "|" .. table.concat(temp, "|")
    end
end

P4HasBeenRead.showInfo = function(player, message)
    player:Say(message, 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
end

local Cell_renderDetails = Cell.renderDetails

function Cell:renderDetails()
    Cell_renderDetails(self)
    if P4HasBeenRead.isInstalled then
        if not P4HasBeenRead.modData then
            P4HasBeenRead.modData = self.player:getModData().P4HasBeenRead
            P4HasBeenRead.doNotAutoMark = P4HasBeenRead.modData.doNotAutoMark
        end

        local modData = P4HasBeenRead.getModData(self.player)
        local markedMap = modData.markedMap
        local recordedMedia = getZomboidRadio():getRecordedMedia()
        local recordedMediaResult = {}
        local statusTexture, selfMarkingTexture, currentTargetTexture = P4HasBeenRead.setTextures(
            self.player, self.item, markedMap, recordedMedia, recordedMediaResult)

        local tex = self.item:getTex()
        if tex ~= nil then
            local halfPadding = Cell.padding / 2
            local scaling = Cell.scaling == 2 and 1.5 or 1 -- Looks really ugly when scaled x2
            if statusTexture and statusTexture ~= P4HasBeenRead.notCompletedTexture then
                self.pane:drawTextureScaled(statusTexture,
                    self.x + halfPadding, self.y + Cell.size - halfPadding - 16 * scaling,
                    statusTexture:getWidth() * scaling,
                    statusTexture:getHeight() * scaling,
                    1, 1, 1, 1)
            end
            if selfMarkingTexture then
                self.pane:drawTextureScaled(selfMarkingTexture,
                    self.x + halfPadding + 10 * scaling, self.y + Cell.size - halfPadding - 10 * scaling,
                    selfMarkingTexture:getWidth() * scaling,
                    selfMarkingTexture:getHeight() * scaling,
                    1, 1, 1, 1)
            end
            if currentTargetTexture then
                self.pane:drawTextureScaled(currentTargetTexture,
                    self.x + halfPadding, self.y + halfPadding,
                    currentTargetTexture:getWidth() * scaling,
                    currentTargetTexture:getHeight() * scaling,
                    1, 1, 1, 1)
            end
        end
    end
end

local MainOptions_apply = MainOptions.apply
function MainOptions:apply(closeAfter)
    MainOptions_apply(self, closeAfter)
    P4HasBeenRead.initTextures()
end

if P4HasBeenRead._clean then P4HasBeenRead._clean() end
function P4HasBeenRead._clean()
    Cell.renderDetails = Cell_renderDetails
end

-- Extras
P4HasBeenRead.initTextures()
Events.OnGameStart.Add(P4HasBeenRead.initTextures)

return P4HasBeenRead
