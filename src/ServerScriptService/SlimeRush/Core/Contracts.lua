local HttpService = game:GetService("HttpService")

local Economy = require(script.Parent:WaitForChild("Economy"))
local SlimeCatalog = require(script.Parent:WaitForChild("SlimeCatalog"))

local Contracts = {}

local CONTRACT_TIERS = {
    easy = {
        requirements = {minRarity = 1, maxRarity = 4, quantity = {2, 3}},
        rewards = {gelatin = {600, 900}, essence = {0, 2}},
    },
    medium = {
        requirements = {minRarity = 3, maxRarity = 7, quantity = {3, 5}},
        rewards = {gelatin = {1800, 3600}, essence = {4, 8}},
    },
    hard = {
        requirements = {minRarity = 6, maxRarity = 12, quantity = {4, 7}},
        rewards = {gelatin = {5400, 9600}, essence = {12, 26}},
    },
}

local function randomInRange(range)
    return math.random(range[1], range[2])
end

local function makeRequirement(tier)
    local config = CONTRACT_TIERS[tier]
    local quantity = randomInRange(config.requirements.quantity)
    local rarity = randomInRange({config.requirements.minRarity, config.requirements.maxRarity})
    local mood = math.random(1, #SlimeCatalog.Moods)

    return {
        tier = tier,
        quantity = quantity,
        rarity = rarity,
        mood = mood,
    }
end

local function makeReward(tier)
    local config = CONTRACT_TIERS[tier]
    return {
        gelatin = randomInRange(config.rewards.gelatin),
        essence = randomInRange(config.rewards.essence),
    }
end

local function createContract(tier)
    return {
        id = HttpService:GenerateGUID(false),
        tier = tier,
        requirement = makeRequirement(tier),
        reward = makeReward(tier),
        fulfilled = false,
    }
end

function Contracts.generateDailySet(userId)
    local contracts = {}
    contracts[#contracts + 1] = createContract("easy")
    contracts[#contracts + 1] = createContract("medium")
    contracts[#contracts + 1] = createContract("hard")
    return contracts
end

function Contracts.persistContracts(userId, contracts)
    -- Hook up to DataStoreService here.
end

local function getContractById(contracts, contractId)
    for _, contract in ipairs(contracts) do
        if contract.id == contractId then
            return contract
        end
    end
    return nil
end

local function canFulfillContract(inventory, contract)
    local count = 0
    for _, slime in ipairs(inventory.Slimes) do
        if slime.Rarity >= contract.requirement.rarity and slime.Mood == contract.requirement.mood then
            count = count + 1
        end
    end
    return count >= contract.requirement.quantity
end

function Contracts.claimReward(profile, contractId)
    local contract = getContractById(profile.Contracts, contractId)
    if not contract then
        return false, "INVALID_CONTRACT"
    end

    if contract.fulfilled then
        return false, "ALREADY_CLAIMED"
    end

    if not canFulfillContract(profile.Inventory, contract) then
        return false, "REQUIREMENTS_NOT_MET"
    end

    profile.Currency:Deposit(contract.reward.gelatin, contract.reward.essence)
    contract.fulfilled = true

    return true, {
        contractId = contract.id,
        reward = contract.reward,
    }
end

function Contracts.serialize(contracts)
    local payload = {}
    for _, contract in ipairs(contracts) do
        table.insert(payload, {
            id = contract.id,
            tier = contract.tier,
            requirement = contract.requirement,
            reward = contract.reward,
            fulfilled = contract.fulfilled,
        })
    end
    return payload
end

return Contracts
