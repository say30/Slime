-- ========================================
-- SLIME RUSH - FUSION CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/FusionConfig
-- ========================================

local FusionConfig = {}

-- ========================================
-- COÛT FUSION
-- ========================================
FusionConfig.BaseCosts = {
    Fusion2 = {
        Gelatin = 1000,
        Essence = 150
    },
    Fusion3 = {
        Gelatin = 2500,
        Essence = 400
    }
}

-- Multiplicateurs de coût
FusionConfig.CostMultipliers = {
    Size = {1, 2, 4, 8, 15}, -- Micro, Petit, Moyen, Grand, Titan
    Rarity = {1, 2, 4, 8, 15, 30, 60, 120, 250, 500, 1000, 2000}, -- Commun → Oméga
    State = {1, 3, 5, 8, 12, 20} -- Aucun, Pur, Muté, Fusionné, Cristallisé, Corrompu
}

-- Calcul coût fusion
function FusionConfig.GetFusionCost(fusionType, slime1, slime2, slime3)
    local baseCost = FusionConfig.BaseCosts[fusionType]

    -- Calculer multiplicateur moyen des slimes
    local totalMult = 0
    local slimes = {slime1, slime2}
    if slime3 then table.insert(slimes, slime3) end

    for _, slime in ipairs(slimes) do
        local sizeMult = FusionConfig.CostMultipliers.Size[slime.Size]
        local rarityMult = FusionConfig.CostMultipliers.Rarity[slime.Rarity]
        local stateMult = FusionConfig.CostMultipliers.State[slime.State]

        totalMult = totalMult + (sizeMult * rarityMult * stateMult)
    end

    local avgMult = totalMult / #slimes

    -- Fusion3 coûte 2.5× plus
    if fusionType == "Fusion3" then
        avgMult = avgMult * 2.5
    end

    return {
        Gelatin = math.floor(baseCost.Gelatin * avgMult),
        Essence = math.floor(baseCost.Essence * avgMult)
    }
end

-- ========================================
-- PROBABILITÉS FUSION À 2 (États)
-- ========================================
FusionConfig.Fusion2Probabilities = {
    BaseSuccess = 0.35, -- 35% de base
    BaseFailure = 0.65  -- 65% destruction
}

-- États possibles (équiprobables si succès)
FusionConfig.PossibleStates = {2, 3, 4, 5, 6} -- Pur, Muté, Fusionné, Cristallisé, Corrompu

-- Validation fusion 2 : 2 slimes identiques requis
function FusionConfig.ValidateFusion2(slime1, slime2)
    return slime1.Mood == slime2.Mood
        and slime1.Rarity == slime2.Rarity
        and slime1.Size == slime2.Size
end

-- ========================================
-- PROBABILITÉS FUSION À 3 (Amélioration)
-- ========================================

-- Type détecté automatiquement
function FusionConfig.DetectFusion3Type(slime1, slime2, slime3)
    -- 3 tailles identiques → Amélioration taille
    if slime1.Size == slime2.Size and slime2.Size == slime3.Size then
        return "Size"
    end

    -- 3 raretés identiques → Amélioration rareté
    if slime1.Rarity == slime2.Rarity and slime2.Rarity == slime3.Rarity then
        return "Rarity"
    end

    -- 2 moods identiques → Amélioration mood
    local moodCounts = {}
    for _, slime in ipairs({slime1, slime2, slime3}) do
        moodCounts[slime.Mood] = (moodCounts[slime.Mood] or 0) + 1
    end

    for mood, count in pairs(moodCounts) do
        if count >= 2 then
            return "Mood", mood
        end
    end

    return nil -- Combinaison invalide
end

-- Probabilités amélioration taille
FusionConfig.SizeUpgradeProbability = 0.35 -- 35%

-- Probabilités amélioration rareté (décroissance)
FusionConfig.RarityUpgradeProbabilities = {
    0.30, -- Commun → Vibrant
    0.25, -- Vibrant → Rare
    0.20, -- Rare → Arcane
    0.15, -- Arcane → Épique
    0.10, -- Épique → Légendaire
    0.07, -- Légendaire → Mythique
    0.05, -- Mythique → Occulte
    0.03, -- Occulte → Céleste
    0.02, -- Céleste → Abyssal
    0.01, -- Abyssal → Prismatique
    0.005 -- Prismatique → Oméga
}

-- Probabilité amélioration mood
FusionConfig.MoodUpgradeProbability = 0.40 -- 40%

-- ========================================
-- CATALYSEURS
-- ========================================
FusionConfig.Catalysts = {
    Stability = {
        Name = "Stabilité",
        Effect = "Ne détruit pas les slimes en cas d'échec",
        Stackable = false,
        Type = "OneTime" -- Consommé à l'utilisation
    },
    Chance10 = {
        Name = "Chance +10%",
        Effect = "+10% chance de succès",
        Bonus = 0.10,
        Stackable = true
    },
    Chance25 = {
        Name = "Chance +25%",
        Effect = "+25% chance de succès",
        Bonus = 0.25,
        Stackable = true
    },
    StatePure = {Name = "État Pur Ciblé", TargetState = 2},
    StateMuted = {Name = "État Muté Ciblé", TargetState = 3},
    StateFused = {Name = "État Fusionné Ciblé", TargetState = 4},
    StateCrystallized = {Name = "État Cristallisé Ciblé", TargetState = 5},
    StateCorrupted = {Name = "État Corrompu Ciblé", TargetState = 6},
    Guaranteed100 = {
        Name = "Pack Fusion 100%",
        Effect = "Garantit le succès de la fusion",
        Bonus = 1.0 -- +100%
    }
}

-- Appliquer catalyseurs
function FusionConfig.ApplyLocalCatalysts(baseChance, catalystsUsed)
    local finalChance = baseChance
    local targetState = nil
    local stabilityActive = false

    for catalystType, _ in pairs(catalystsUsed) do
        local catalyst = FusionConfig.Catalysts[catalystType]

        if catalyst.Bonus then
            finalChance = math.min(1, finalChance + catalyst.Bonus)
        end

        if catalyst.TargetState then
            targetState = catalyst.TargetState
        end

        if catalystType == "Stability" then
            stabilityActive = true
        end
    end

    return finalChance, targetState, stabilityActive
end

-- ========================================
-- TIMER FUSION
-- ========================================
FusionConfig.FusionTimer = {
    Cooldown = 30, -- 30 secondes entre fusions
    VIPSkipsPerDay = 5, -- VIP = 5 skips gratuits/jour
    SkipCostGelatin = 5000000, -- 5M gélatine
    SkipCostEssence = 2500, -- 2.5K essence
    SkipCostRobux = 50 -- 50 Robux pour 10 skips
}

-- ========================================
-- RÉCUPÉRATION EN CAS D'ÉCHEC
-- ========================================
FusionConfig.FailureRecovery = {
    EssencePercent = 0.20 -- 20% du coût en essence récupéré
}

function FusionConfig.GetFailureRecovery(fusionCost)
    return math.floor(fusionCost.Essence * FusionConfig.FailureRecovery.EssencePercent)
end

-- ========================================
-- RÉSULTAT FUSION
-- ========================================

-- Créer slime résultat
function FusionConfig.CreateResultSlime(fusionType, slimes, success, targetState)
    local result = {
        Success = success,
        Slime = nil,
        EssenceRecovered = 0
    }

    if not success then
        -- Échec : retourner essence
        local cost = FusionConfig.GetFusionCost(fusionType, slimes[1], slimes[2], slimes[3])
        result.EssenceRecovered = FusionConfig.GetFailureRecovery(cost)
        return result
    end

    -- Succès
    if fusionType == "Fusion2" then
        -- Copier slime parent
        result.Slime = {
            Mood = slimes[1].Mood,
            Rarity = slimes[1].Rarity,
            Size = slimes[1].Size,
            State = targetState or FusionConfig.PossibleStates[math.random(#FusionConfig.PossibleStates)],
            UniqueID = game:GetService("HttpService"):GenerateGUID(false)
        }
    elseif fusionType == "Fusion3" then
        local fusionSubType, moodTarget = FusionConfig.DetectFusion3Type(slimes[1], slimes[2], slimes[3])

        result.Slime = {
            Mood = slimes[1].Mood,
            Rarity = slimes[1].Rarity,
            Size = slimes[1].Size,
            State = slimes[1].State,
            UniqueID = game:GetService("HttpService"):GenerateGUID(false)
        }

        if fusionSubType == "Size" then
            result.Slime.Size = math.min(5, slimes[1].Size + 1) -- Max Titan
        elseif fusionSubType == "Rarity" then
            result.Slime.Rarity = math.min(12, slimes[1].Rarity + 1) -- Max Oméga
        elseif fusionSubType == "Mood" then
            result.Slime.Mood = moodTarget
        end
    end

    return result
end

return FusionConfig
