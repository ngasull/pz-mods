require "TimedActions/ISInventoryTransferAction"

local M = require("IconsInventory/mod")

---@type table<InventoryItem, ISInventoryTransferAction>
local queuedTransfers = setmetatable({}, { __mode = "kv" })

---@param item InventoryItem
M.isQueuedForTransfer = function(item)
    local action = queuedTransfers[item]
    if not action then return false end
    if item:getJobDelta() > 0 then
        queuedTransfers[item] = nil
        return false
    end
    return true
end

---@class IconsInventory_ISTimedActionQueue: ISTimedActionQueue
local QueueVanilla = {}

---@class IconsInventory_ISTimedActionQueueOverride: IconsInventory_ISTimedActionQueue
local QueueOverride = {}

function QueueOverride.add(action)
    -- Kind of manual instanceof (the lattern not working here for some reason)
    if action.Type == "ISInventoryTransferAction" then
        queuedTransfers[action.item] = action
    end
    return QueueVanilla.add(action)
end

function QueueOverride:removeFromQueue(action)
    if action.Type == "ISInventoryTransferAction" then
        queuedTransfers[action.item] = nil
    end
    return QueueVanilla.removeFromQueue(self, action)
end

function QueueOverride:clearQueue()
    for _, action in ipairs(self.queue) do
        if action.Type == "ISInventoryTransferAction" then
            queuedTransfers[action.item] = nil
        end
    end
    return QueueVanilla.clearQueue(self)
end

function QueueOverride:cancelQueue()
    for _, action in ipairs(self.queue) do
        if action.Type == "ISInventoryTransferAction" then
            queuedTransfers[action.item] = nil
        end
    end
    return QueueVanilla.cancelQueue(self)
end

---@class IconsInventory_ISInventoryTransferAction: ISInventoryTransferAction
local ActionVanilla = {}

---@class IconsInventory_ISInventoryTransferActionOverride: IconsInventory_ISInventoryTransferAction
local ActionOverride = {}

function ActionOverride:perform()
    queuedTransfers[self.item] = nil
    return ActionVanilla.perform(self)
end

local function install()
    for k, v in pairs(QueueOverride) do
        QueueVanilla[k] = ISTimedActionQueue[k]
        ISTimedActionQueue[k] = v
    end
    for k, v in pairs(ActionOverride) do
        ActionVanilla[k] = ISInventoryTransferAction[k]
        ISInventoryTransferAction[k] = v
    end

    M.cleanAction = function()
        for k, v in pairs(QueueVanilla) do
            ISTimedActionQueue[k] = v
        end
        for k, v in pairs(ActionVanilla) do
            ISInventoryTransferAction[k] = v
        end
    end
end

if M.cleanAction then M.cleanAction() end
install()
