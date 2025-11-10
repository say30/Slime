local HttpService = game:GetService("HttpService")

local Economy = require(script.Parent:WaitForChild("Economy"))
local SlimeCatalog = require(script.Parent:WaitForChild("SlimeCatalog"))
local Shop = require(script.Parent:WaitForChild("Shop"))

local FusionSystem = {}

local TWO_WAY_BASE_CHANCE = 0.18
local THREE_WAY_SUCCESS = {
    mutate = 0.12,
    corrupt = 0.09,
    purify = 0.08,
    crystallize = 0.05,
}

local FAILURE_DESTROY_CHANCE = 0.65

local rarityRaisePenalty = {0.0, 0.02, 0.04, 0.06, 0.09, 0.12, 0.16, 0.21, 0.27, 0.34, 0.42, 0.52}

local catalystBoost = {
    rarity = 0.1,
    state = 0.15,
    omni = 0.2,
}

local function rollChance(baseChance, modifier)
    local finalChance = math.clamp(baseChance + (modifier or 0), 0, 0.95)
    return math.random() < finalChance, finalChance
end

local function removeSlimeFromProfile(profile, slimeId)
    return profile.Inventory:removeSlime(slimeId)
end

local function applyCatalystModifier(catalyst, target)
    if not catalyst then
        return 0
    end

    if catalyst.type == target or catalyst.type == "omni" then
        return catalystBoost[catalyst.type]
    end
    return 0
end

function FusionSystem.attemptFusion(profile, params)
    local mode = params.mode
    local catalyst = params.catalystId and Shop.consumeCatalyst(profile, params.catalystId)
    if mode == "two" then
        return FusionSystem.doTwoWay(profile, params, catalyst)
    elseif mode == "three" then
        return FusionSystem.doThreeWay(profile, params, catalyst)
    end

    return false, "INVALID_MODE"
end

function FusionSystem.doTwoWay(profile, params, catalyst)
    local a = removeSlimeFromProfile(profile, params.slimeA)
    local b = removeSlimeFromProfile(profile, params.slimeB)
    if not a or not b then
        return false, "MISSING_SLIME"
    end

    local modifier = applyCatalystModifier(catalyst, "rarity")
    modifier = modifier - rarityRaisePenalty[a.Rarity]

    local success, chance = rollChance(TWO_WAY_BASE_CHANCE, modifier)
    if success then
        a.Rarity = math.clamp(a.Rarity + 1, 1, 12)
        profile.Inventory:addSlime(a)
        return true, {
            result = "SUCCESS",
            chance = chance,
            slime = a,
        }
    end

    if math.random() < FAILURE_DESTROY_CHANCE then
        local essence = Economy.getFusionEssenceReward(a.Rarity, true)
        profile.Currency:Deposit(nil, essence)
        return true, {
            result = "DESTROYED",
            chance = chance,
            essence = essence,
        }
    end

    profile.Inventory:addSlime(a)
    profile.Inventory:addSlime(b)
    return true, {
        result = "FAILED",
        chance = chance,
    }
end

function FusionSystem.doThreeWay(profile, params, catalyst)
    local slimes = {}
    for _, slimeId in ipairs(params.slimes) do
        local slime = removeSlimeFromProfile(profile, slimeId)
        if not slime then
            return false, "MISSING_SLIME"
        end
        table.insert(slimes, slime)
    end

    local targetState = params.state
    local modifier = applyCatalystModifier(catalyst, "state")
    modifier = modifier + (params.intent == "crystallize" and 0.05 or 0)

    local baseChance = THREE_WAY_SUCCESS[params.intent] or 0.05
    local totalRarity = 0
    for _, slime in ipairs(slimes) do
        totalRarity = totalRarity + slime.Rarity
        modifier = modifier - rarityRaisePenalty[slime.Rarity]
    end

    local success, chance = rollChance(baseChance, modifier)
    if success then
        local template = SlimeCatalog.getStateTemplate(targetState)
        local archetype = SlimeCatalog.mergeSlimes(slimes, template)
        archetype.Id = HttpService:GenerateGUID(false)
        profile.Inventory:addSlime(archetype)
        return true, {
            result = "SUCCESS",
            chance = chance,
            slime = archetype,
        }
    end

    local essence = 0
    for _, slime in ipairs(slimes) do
        essence = essence + Economy.getFusionEssenceReward(slime.Rarity, true)
    end
    profile.Currency:Deposit(nil, essence)

    return true, {
        result = "FAILURE",
        chance = chance,
        essence = essence,
    }
end

return FusionSystem
