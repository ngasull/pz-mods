require "TimedActions/ISInventoryTransferAction"

---@type table<InventoryItem, { dest: ItemContainer, src: ItemContainer }>?
local queuedTransfers

local function removeFinishedTransfers()
    local remaining = 0
    if queuedTransfers then
        for item, v in pairs(queuedTransfers) do
            if item:getJobDelta() > 0 or item:getContainer() == v.dest or item:getContainer() ~= v.src then
                queuedTransfers[item] = nil
            else
                remaining = remaining + 1
            end
        end
    end
    if remaining == 0 then
        queuedTransfers = nil
        Events.OnTick.Remove(removeFinishedTransfers)
    end
end

local Action = {}

---@param item InventoryItem
Action.isQueuedForTransfer = function(item)
    return not not (queuedTransfers and queuedTransfers[item])
end

---@param action ISBaseTimedAction
local function cancelAction(action)
    if queuedTransfers and action.Type == "ISInventoryTransferAction" then
        ---@cast action +ISInventoryTransferAction
        queuedTransfers[action.item] = nil
        if action.queueList then
            for _, qi in ipairs(action.queueList) do
                for _, item in ipairs(qi.items) do
                    queuedTransfers[item] = nil
                end
            end
        end
    end
end

---@class ISTimedActionQueue
local QueueVanilla = {}

---@class ISTimedActionQueue
local QueueOverride = {}

function QueueOverride.add(action)
    -- Kind of manual instanceof (the lattern not working here for some reason)
    if action.Type == "ISInventoryTransferAction" then
        ---@cast action +ISInventoryTransferAction

        if not queuedTransfers then
            queuedTransfers = {}
            Events.OnTick.Add(removeFinishedTransfers)
        end

        queuedTransfers[action.item] = {
            dest = action.destContainer,
            src = action.srcContainer,
        }
    end
    return QueueVanilla.add(action)
end

function QueueOverride:removeFromQueue(action)
    cancelAction(action)
    return QueueVanilla.removeFromQueue(self, action)
end

function QueueOverride:clearQueue()
    for _, action in ipairs(self.queue) do
        cancelAction(action)
    end
    return QueueVanilla.clearQueue(self)
end

function QueueOverride:cancelQueue()
    for _, action in ipairs(self.queue) do
        cancelAction(action)
    end
    return QueueVanilla.cancelQueue(self)
end

---@class ISInventoryTransferAction
local ActionVanilla = {}

---@class ISInventoryTransferAction
local ActionOverride = {}

function ActionOverride:perform()
    if queuedTransfers then
        queuedTransfers[self.item] = nil
    end
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
end

Action._clean = function()
    for k, v in pairs(QueueVanilla) do
        ISTimedActionQueue[k] = v
    end
    for k, v in pairs(ActionVanilla) do
        ISInventoryTransferAction[k] = v
    end
end

local Prev = require("IconsInventory/Action")
if Prev then Prev._clean() end
install()

return Action
