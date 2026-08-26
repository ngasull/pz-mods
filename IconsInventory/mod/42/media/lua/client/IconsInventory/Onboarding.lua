local mod = require("IconsInventory/mod")

---@class IconsInventory_Onboarding: ISCollapsableWindowJoypad
---@field player IsoPlayer
local Onboarding = ISCollapsableWindowJoypad:derive("IconsInventory_Onboarding")
Onboarding.__index = Onboarding

---@param player IsoPlayer
function Onboarding.showIfShould(player)
    if not Onboarding.instance and not mod.data.onboardingSeen then
        local w, h = 550 * mod.getBaseScaling(), 250 * mod.getBaseScaling()
        local x = 100 * mod.getBaseScaling()
        local y = (getCore():getScreenHeight() - h) / 4
        local self = setmetatable(ISCollapsableWindowJoypad:new(x, y, w, h), Onboarding) ---@cast self -ISCollapsableWindowJoypad
        self.resizable = true
        self.player = player
        self:initialise()
        self:instantiate()
        self:addToUIManager()
        Onboarding.instance = self
    end
end

function Onboarding:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)

    local buttonHeight = 30 * mod.getBaseScaling()
    local padding = 20 * mod.getBaseScaling()

    self:setTitle(getText("UI_IconsInventory_Onboarding_title"))

    local body = ISRichTextPanel:new(
        padding, self:titleBarHeight(),
        self.width - padding,
        self.height - self:titleBarHeight() - self.resizeWidget.height - buttonHeight - padding
    )
    self.body = body
    body.marginLeft = 0
    body.anchorLeft = true
    body.anchorRight = true
    body.anchorBottom = true
    body:initialise();
    body.autosetheight = false;
    body.clip = true
    body.background = false;
    self:addChild(body);
    body:addScrollBars();
    body.text = getText("UI_IconsInventory_Onboarding_body")
    body:paginate();

    local accept = ISButton:new(
        padding,
        self.height - self.resizeWidget.height - buttonHeight - padding / 2,
        (self.width - 2.5 * padding) / 2, buttonHeight,
        getText("UI_IconsInventory_Onboarding_enable"),
        self,
        function(button) self:close() end
    )
    accept:setAnchorsTBLR(false, true, false, true)
    accept:enableAcceptColor()
    self:addChild(accept)

    local refuse = ISButton:new(
        1.5 * padding + (self.width - 2.5 * padding) / 2,
        self.height - self.resizeWidget.height - buttonHeight - padding / 2,
        (self.width - 2.5 * padding) / 2, buttonHeight,
        getText("UI_IconsInventory_Onboarding_reject"),
        self,
        function(button)
            mod.option.enableSmartDrag:setValue(false)
            mod.option.enableSmartScroll:setValue(false)
            mod.option.clickSend:setValue(mod.option.clickSend_off)
            PZAPI.ModOptions:save()
            self:close()
        end
    )
    refuse:setAnchorsTBLR(false, true, false, true)
    refuse:enableCancelColor()
    self:addChild(refuse)

    -- Do after laying everything out: anchors react to setHeight
    local scrollDiff = body:getScrollHeight() - body:getScrollAreaHeight()
    if scrollDiff > 0 then
        self:setHeight(self.height + scrollDiff)
    end

    -- Joypad control
    self:insertNewLineOfButtons(accept, refuse)
end

function Onboarding:close()
    self:setVisible(false)
    self:removeFromUIManager()
    Onboarding.instance = nil
    mod.data.onboardingSeen = true
    mod.meta:save()
end

local Prev = isDebugEnabled() and require("IconsInventory/Onboarding")
if Prev then
    Onboarding.showIfShould(getPlayer())
end

return Onboarding
