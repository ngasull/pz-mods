---@class ISPlayerDataObject
local vanilla = {}

---@class ISPlayerDataObject
local Override = {}

function Override:placeInventoryScreens(...)
    local playerID, totalPlayers, mouse = ...
    local res = vanilla.placeInventoryScreens(self, ...)

    if not mouse then
        -- Customize dimensions before ISInventoryPage:createChildren, otherwise the UI manager's mouse events are de-sync'd from them
        pcall(function()
            local x = getPlayerScreenLeft(playerID)
            local y = getPlayerScreenTop(playerID)
            local w = getPlayerScreenWidth(playerID)
            local h = getPlayerScreenHeight(playerID)

            -- Expected vanilla values
            local x1 = x;
            local y1 = y + (h / 2);
            local w1 = (w / 2);
            local h1 = (h / 2);
            local x2 = x1 + w1;

            -- Ensure we're vanilla to prevent mod conflict
            if self.x1 == x1 and self.y1 == y1 and self.w1 == w1 and self.h1 == h1 and self.x2 == x2 then
                local cw = math.floor(getCore():getScreenWidth() / 4)
                local ch = math.floor(h / 3)
                local cy = h - ch
                self.w1 = cw;
                self.w2 = cw;
                self.h1 = ch;
                self.h2 = ch;
                self.x1 = x + w1 - cw
                self.x2 = self.x1 + self.w1
                self.y1 = cy;
                self.y2 = cy;
            end
        end)
    end

    return res
end

-- Install --
local Prev = isDebugEnabled() and require("IconsInventory/ISPlayerDataObject")
for k in pairs(Override) do
    if not Prev then
        vanilla[k] = ISPlayerDataObject[k]
        ISPlayerDataObject[k] =
            isDebugEnabled() and function(...) return Override[k](...) end
            or Override[k]
    else
        vanilla[k] = Prev._vanilla[k]
    end
end

Override._vanilla = vanilla
return Override
