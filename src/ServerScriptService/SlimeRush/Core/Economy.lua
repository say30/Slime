local Economy = {}
Economy.__index = Economy

local rarityCost = {100, 220, 480, 1020, 2100, 4200, 8400, 14000, 22000, 34000, 50000, 72000}
local moodPremium = {0, 0.05, 0.07, 0.09, 0.12, 0.15, 0.18, 0.22, 0.26, 0.31, 0.37, 0.44}
local sizeMultiplier = {0.8, 1.0, 1.3, 1.7, 2.2}
local statePremium = {0.0, 0.15, 0.35, 0.65, 1.1}

local fusionEssencePayout = {4, 8, 16, 28, 44, 64, 88, 116, 148, 184, 224, 268}

function Economy.newWallet(initialGelatin, initialEssence)
    local wallet = setmetatable({
        Gelatin = initialGelatin or 0,
        Essence = initialEssence or 0,
    }, Economy)

    return wallet
end

function Economy:Deposit(gelatin, essence)
    if gelatin then
        self.Gelatin = self.Gelatin + gelatin
    end
    if essence then
        self.Essence = self.Essence + essence
    end
end

function Economy:CanAfford(gelatin, essence)
    gelatin = gelatin or 0
    essence = essence or 0
    if self.Gelatin < gelatin then
        return false
    end
    if self.Essence < essence then
        return false
    end
    return true
end

function Economy:Withdraw(gelatin, essence)
    if not self:CanAfford(gelatin, essence) then
        return false
    end

    self.Gelatin = self.Gelatin - (gelatin or 0)
    self.Essence = self.Essence - (essence or 0)
    return true
end

function Economy.calculateSlimeCost(archetype)
    local base = rarityCost[archetype.Rarity]
    local mood = base * moodPremium[archetype.Mood]
    local size = sizeMultiplier[archetype.Size]
    local state = base * statePremium[archetype.State]
    return math.floor((base + mood + state) * size)
end

function Economy.getFusionEssenceReward(rarity, failed)
    local base = fusionEssencePayout[rarity]
    if failed then
        return math.floor(base * 1.15)
    end
    return base
end

return Economy
