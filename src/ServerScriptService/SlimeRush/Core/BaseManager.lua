local CollectionService = game:GetService("CollectionService")

local Economy = require(script.Parent:WaitForChild("Economy"))

local BaseManager = {}

local MAX_FREE_PODS = 10
local TOTAL_PODS = 22
local FUTURE_PODS = {23, 24}

local BaseTemplateTag = "SlimeRushBase"
local PodAttachmentName = "PodSlot"

local BASE_UPGRADES = {
    {level = 1, podsUnlocked = 2, gelatinCost = 1500, essenceCost = 10},
    {level = 2, podsUnlocked = 4, gelatinCost = 6000, essenceCost = 40},
    {level = 3, podsUnlocked = 6, gelatinCost = 24000, essenceCost = 120},
}

local occupiedBases = {}

local function findAvailableBase()
    local bases = CollectionService:GetTagged(BaseTemplateTag)
    for _, baseModel in ipairs(bases) do
        if not occupiedBases[baseModel] then
            return baseModel
        end
    end
    return nil
end

local function getPodAttachments(baseModel)
    local attachments = {}
    for _, descendant in ipairs(baseModel:GetDescendants()) do
        if descendant.Name == PodAttachmentName and descendant:IsA("Attachment") then
            table.insert(attachments, descendant)
        end
    end

    table.sort(attachments, function(a, b)
        return tonumber(a:GetAttribute("Index")) < tonumber(b:GetAttribute("Index"))
    end)
    return attachments
end

function BaseManager.assignBase(player)
    local baseModel = findAvailableBase()
    if not baseModel then
        error("No free base model available. Ensure enough bases are tagged with " .. BaseTemplateTag)
    end

    occupiedBases[baseModel] = player
    baseModel:SetAttribute("OwnerUserId", player.UserId)

    local pods = {}
    local attachments = getPodAttachments(baseModel)
    for index, attachment in ipairs(attachments) do
        pods[index] = {
            Attachment = attachment,
            SlimeId = nil,
            SlimeData = nil,
            Locked = index > MAX_FREE_PODS,
        }
    end

    return {
        Model = baseModel,
        Pods = pods,
        Level = 0,
        UnlockProgress = 0,
    }
end

function BaseManager.releaseBase(profile)
    local base = profile and profile.Base
    if not base or not base.Model then
        return
    end

    occupiedBases[base.Model] = nil
    base.Model:SetAttribute("OwnerUserId", nil)
    for _, pod in ipairs(base.Pods or {}) do
        if pod.SlimeData then
            local ok = profile.Inventory:addSlime(pod.SlimeData)
            if not ok then
                local essence = Economy.getFusionEssenceReward(pod.SlimeData.Rarity, true)
                profile.Currency:Deposit(nil, essence)
            end
        end
        pod.SlimeId = nil
        pod.SlimeData = nil
        pod.Locked = true
    end
    profile.Base = nil
end

local function getUnlockedPodCount(base)
    local unlocked = 0
    for _, pod in ipairs(base.Pods) do
        if not pod.Locked then
            unlocked = unlocked + 1
        end
    end
    return unlocked
end

function BaseManager.placeSlime(profile, slimeId, podIndex)
    local base = profile.Base
    local pod = base.Pods[podIndex]
    if not pod or pod.Locked then
        return false, "LOCKED"
    end

    if slimeId == nil then
        if not pod.SlimeId then
            return false, "EMPTY"
        end

        local ok, reason = profile.Inventory:addSlime(pod.SlimeData)
        if not ok then
            return false, reason
        end
        pod.SlimeId = nil
        pod.SlimeData = nil
        return true, "RETURNED"
    end

    if pod.SlimeId == slimeId then
        return true, "UNCHANGED"
    end

    local slime = profile.Inventory:removeSlime(slimeId)
    if not slime then
        return false, "NOT_IN_INVENTORY"
    end

    if pod.SlimeData then
        local ok = profile.Inventory:addSlime(pod.SlimeData)
        if not ok then
            local restored = profile.Inventory:addSlime(slime)
            if not restored then
                warn("Failed to restore slime to inventory after placement rollback")
            end
            return false, "INVENTORY_FULL"
        end
    end

    pod.SlimeId = slime.Id
    pod.SlimeData = slime
    -- Attach server-side slime instance creation hook here.
    return true, slime
end

local function unlockNextPods(base, count)
    local unlocked = 0
    for _, pod in ipairs(base.Pods) do
        if pod.Locked then
            pod.Locked = false
            unlocked = unlocked + 1
            if unlocked >= count then
                break
            end
        end
    end
    return unlocked
end

function BaseManager.upgradeBase(base, wallet)
    local nextUpgrade = BASE_UPGRADES[base.Level + 1]
    if not nextUpgrade then
        return false, "MAX_LEVEL"
    end

    if not wallet:CanAfford(nextUpgrade.gelatinCost, nextUpgrade.essenceCost) then
        return false, "INSUFFICIENT_FUNDS"
    end

    wallet:Withdraw(nextUpgrade.gelatinCost, nextUpgrade.essenceCost)
    base.Level = base.Level + 1
    base.UnlockProgress = base.UnlockProgress + unlockNextPods(base, nextUpgrade.podsUnlocked)

    return true, {
        level = base.Level,
        unlockedPods = getUnlockedPodCount(base),
    }
end

function BaseManager.getTotalPods()
    return TOTAL_PODS
end

function BaseManager.getFuturePods()
    return FUTURE_PODS
end

return BaseManager
