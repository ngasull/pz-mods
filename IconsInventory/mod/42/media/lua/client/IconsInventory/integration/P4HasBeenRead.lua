local mod = require("IconsInventory/mod")
local ItemIcon = require("IconsInventory/ItemIcon")

-- [NOTICE]
-- The source code below is the basicaly same as the P4HasBeenRead code for Build 42.15.
-- Would love to see them expose a modders API but copying/pastadapting is required so far.

local P4HasBeenRead = {}

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

P4HasBeenRead.effectiveCodes = { "CRP", "COO", "FRM", "DOC", "ELC", "MTL", "MEC", "TAI", "FIS", "TRA", "FOR", "HUS",
    "FKN", "BLA", "POT", "RCP", "BAA", "BUA", "SBU", "LBA", "SBA", "SPE", "AIM", "REL", "SPR", "LFT", "NIM", "SNE" }
P4HasBeenRead.effectiveMedias = {}

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

-- *****************************************************************************
-- * Textures
-- *****************************************************************************

P4HasBeenRead.textureBookNR = tryGetTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNC = tryGetTexture("media/ui/P4HasBeenRead_Book_NC.png")
P4HasBeenRead.textureBookAR = tryGetTexture("media/ui/P4HasBeenRead_Book_AR.png")
P4HasBeenRead.textureBookSMM = tryGetTexture("media/ui/P4HasBeenRead_Book_SM_Marked.png")
P4HasBeenRead.textureBookSMU = tryGetTexture("media/ui/P4HasBeenRead_Book_SM_Unmarked.png")
P4HasBeenRead.textureBookCT = tryGetTexture("media/ui/P4HasBeenRead_Book_CT.png")

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
    end
end

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

P4HasBeenRead.setTextures = function(player, item)
    local type = P4HasBeenRead.getFullType(item)

    local recordedMedia = getZomboidRadio():getRecordedMedia()
    local readMap = P4HasBeenRead.modData.readMap
    local markedMap = P4HasBeenRead.modData.markedMap

    local statusTexture = nil
    local selfMarkingTexture = nil
    local currentTargetTexture = nil
    if item:getCategory() == "Literature" then
        if P4HasBeenRead.isTargetLiterature(item) then
            local skillBook = SkillBook[item:getSkillTrained()]
            if skillBook then
                if P4HasBeenRead.options.EnableTargets:getValue(1) then
                    local perkLevel = player:getPerkLevel(skillBook.perk)
                    local minLevel = item:getLvlSkillTrained()
                    local maxLevel = item:getMaxLevelTrained()
                    if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
                        currentTargetTexture = P4HasBeenRead.currentTargetTexture
                    end
                    local readPages = player:getAlreadyReadPages(item:getFullType())
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
            elseif item:getLearnedRecipes() and not item:getLearnedRecipes():isEmpty() then
                if P4HasBeenRead.options.EnableTargets:getValue(2) then
                    if player:getKnownRecipes():containsAll(item:getLearnedRecipes()) then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                end
            elseif item:getFullType() == "Base.Flier" then
                if P4HasBeenRead.options.EnableTargets:getValue(4) then
                    if readMap[type] then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                end
            elseif item:getFullType() == "Base.Brochure" then
                if P4HasBeenRead.options.EnableTargets:getValue(5) then
                    if readMap[type] then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                end
            else
                if P4HasBeenRead.options.EnableTargets:getValue(6) then
                    if readMap[type] then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                end
            end
            if markedMap[type] then
                if P4HasBeenRead.options.ShowSM:getValue(1) then
                    selfMarkingTexture = P4HasBeenRead.markedTexture
                end
            else
                if P4HasBeenRead.options.ShowSM:getValue(2) then
                    selfMarkingTexture = P4HasBeenRead.unmarkedTexture
                end
            end
        end
    elseif instanceof(item, "MapItem") then
        local mapId = item:getMapID()
        if mapId then
            if P4HasBeenRead.options.EnableTargets:getValue(3) then
                if readMap[mapId] then
                    statusTexture = P4HasBeenRead.alreadyReadTexture
                else
                    statusTexture = P4HasBeenRead.notReadTexture
                end
            end
            if markedMap[mapId] then
                if P4HasBeenRead.options.ShowSM:getValue(1) then
                    selfMarkingTexture = P4HasBeenRead.markedTexture
                end
            else
                if P4HasBeenRead.options.ShowSM:getValue(2) then
                    selfMarkingTexture = P4HasBeenRead.unmarkedTexture
                end
            end
        end
    elseif recordedMedia then
        local mediaData = item:getMediaData()
        if mediaData then
            local isTarget = false
            local index = mediaData:getIndex()
            local category = mediaData:getCategory()
            if P4HasBeenRead.options.EnableTargets:getValue(7) and category == "CDs" then
                isTarget = true
            elseif P4HasBeenRead.options.EnableTargets:getValue(8) and category == "Retail-VHS" then
                isTarget = true
            elseif P4HasBeenRead.options.EnableTargets:getValue(9) and category == "Home-VHS" then
                isTarget = true
            end
            if isTarget then
                if P4HasBeenRead.effectiveMedias[mediaData:getId()] then
                    currentTargetTexture = P4HasBeenRead.currentTargetTexture
                end
                statusTexture = P4HasBeenRead.recordedMediaResult[index]
                if statusTexture then
                    if statusTexture == "mynil" then
                        statusTexture = nil
                    end
                else
                    if recordedMedia:hasListenedToAll(player, mediaData) then
                        statusTexture = P4HasBeenRead.alreadyReadTexture
                    else
                        statusTexture = P4HasBeenRead.notReadTexture
                    end
                    if statusTexture then
                        P4HasBeenRead.recordedMediaResult[index] = statusTexture
                    else
                        P4HasBeenRead.recordedMediaResult[index] = "mynil"
                    end
                end
            end
            if markedMap["Base.RM-" .. index] then
                if P4HasBeenRead.options.ShowSM:getValue(1) then
                    selfMarkingTexture = P4HasBeenRead.markedTexture
                end
            else
                if P4HasBeenRead.options.ShowSM:getValue(2) then
                    selfMarkingTexture = P4HasBeenRead.unmarkedTexture
                end
            end
        end
    end
    P4HasBeenRead.status = statusTexture
    P4HasBeenRead.marking = selfMarkingTexture
    P4HasBeenRead.current = currentTargetTexture
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

P4HasBeenRead.getFullType = function(item)
    local type = item:getFullType()
    local modData = item:getModData()
    if type == "Base.RecipeClipping" or type == "Base.SewingPattern" or (string.find(type, "Schematic", 1, true) and item:getDisplayCategory() == "RecipeResource") then
        type = P4HasBeenRead.getRecipeResourceFullType(item, type)
    end
    if modData then
        if modData.literatureTitle then
            type = modData.literatureTitle
        elseif modData.printMedia then
            type = modData.printMedia
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

---@param cell IconsInventory_Cell
---@param xoff number
---@param yoff number
function P4HasBeenRead.renderdetails(cell, xoff, yoff)
    if P4HasBeenRead.isInstalled then
        if not P4HasBeenRead.modData then
            P4HasBeenRead.modData = cell.player:getModData().P4HasBeenRead
            P4HasBeenRead.doNotAutoMark = P4HasBeenRead.modData.doNotAutoMark
        end

        P4HasBeenRead.recordedMediaResult = {}
        P4HasBeenRead.setTextures(cell.player, cell.item)

        local tex = cell.item:getTex()
        if tex ~= nil then
            local halfPadding = ItemIcon.padding / 2
            local scaling = ItemIcon.scaling == 2 and 1.5 or 1 -- Looks really ugly when scaled x2
            if P4HasBeenRead.status and P4HasBeenRead.status ~= P4HasBeenRead.notCompletedTexture then
                cell.pane:drawTextureScaled(P4HasBeenRead.status,
                    xoff + halfPadding, yoff + ItemIcon.cellSize - halfPadding - 16 * scaling,
                    P4HasBeenRead.status:getWidth() * scaling,
                    P4HasBeenRead.status:getHeight() * scaling,
                    1, 1, 1, 1)
            end
            if P4HasBeenRead.marking then
                cell.pane:drawTextureScaled(P4HasBeenRead.marking,
                    xoff + halfPadding + 10 * scaling, yoff + ItemIcon.cellSize - halfPadding - 10 * scaling,
                    P4HasBeenRead.marking:getWidth() * scaling,
                    P4HasBeenRead.marking:getHeight() * scaling,
                    1, 1, 1, 1)
            end
            if P4HasBeenRead.current then
                cell.pane:drawTextureScaled(P4HasBeenRead.current,
                    xoff + halfPadding, yoff + halfPadding,
                    P4HasBeenRead.current:getWidth() * scaling,
                    P4HasBeenRead.current:getHeight() * scaling,
                    1, 1, 1, 1)
            end
        end
    end
end

-- Extras
P4HasBeenRead.initTextures()
Events.OnGameStart.Add(P4HasBeenRead.initTextures)
mod.addApply(P4HasBeenRead.initTextures)

return P4HasBeenRead
