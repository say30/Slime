-- ========================================
-- SLIME RUSH - ECONOMY CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/EconomyConfig
-- ========================================

local EconomyConfig = {}

-- ========================================
-- RESSOURCES DE DÉPART
-- ========================================
EconomyConfig.StartingResources = {
    Gelatin = 100,
    Essence = 0,
    GelatinLifetime = 0
}

-- ========================================
-- UPGRADE BASE (Déblocage PodsSlime)
-- ========================================
EconomyConfig.BaseUpgrades = {
    {PodsUnlocked = {11, 12}, Cost = 3500000, RequiredLevel = 0},
    {PodsUnlocked = {13, 14}, Cost = 25000000, RequiredLevel = 1},
    {PodsUnlocked = {15, 16}, Cost = 180000000, RequiredLevel = 2},
    {PodsUnlocked = {17, 18}, Cost = 1250000000, RequiredLevel = 3},
    {PodsUnlocked = {19, 20}, Cost = 9000000000, RequiredLevel = 4},
    {PodsUnlocked = {21, 22}, Cost = 70000000000, RequiredLevel = 5}
}

-- ========================================
-- UPGRADE PRODUCTION PERMANENTE
-- ========================================
EconomyConfig.ProductionUpgrades = {
    {Bonus = 0.02, CostGelatin = 10000000, CostEssence = 5000},
    {Bonus = 0.04, CostGelatin = 50000000, CostEssence = 25000},
    {Bonus = 0.06, CostGelatin = 250000000, CostEssence = 125000},
    {Bonus = 0.08, CostGelatin = 1200000000, CostEssence = 600000},
    {Bonus = 0.10, CostGelatin = 6000000000, CostEssence = 3000000},
    {Bonus = 0.12, CostGelatin = 30000000000, CostEssence = 15000000},
    {Bonus = 0.15, CostGelatin = 150000000000, CostEssence = 75000000},
    {Bonus = 0.18, CostGelatin = 750000000000, CostEssence = 375000000},
    {Bonus = 0.22, CostGelatin = 4000000000000, CostEssence = 2000000000},
    {Bonus = 0.25, CostGelatin = 20000000000000, CostEssence = 10000000000}
}

-- Calcul bonus cumulé
function EconomyConfig.GetProductionBonus(level)
    local totalBonus = 0
    for i = 1, math.min(level, #EconomyConfig.ProductionUpgrades) do
        totalBonus = totalBonus + EconomyConfig.ProductionUpgrades[i].Bonus
    end
    return totalBonus
end

-- ========================================
-- UPGRADE INVENTAIRE
-- ========================================
EconomyConfig.InventoryUpgrades = {
    {StartSlots = 20, AddSlots = 0, CostGelatin = 0, CostEssence = 0}, -- Départ
    {StartSlots = 20, AddSlots = 10, CostGelatin = 500000, CostEssence = 100},
    {StartSlots = 30, AddSlots = 10, CostGelatin = 2500000, CostEssence = 500},
    {StartSlots = 40, AddSlots = 10, CostGelatin = 12000000, CostEssence = 2500},
    {StartSlots = 50, AddSlots = 15, CostGelatin = 60000000, CostEssence = 12000},
    {StartSlots = 65, AddSlots = 15, CostGelatin = 300000000, CostEssence = 60000},
    {StartSlots = 80, AddSlots = 20, CostGelatin = 1500000000, CostEssence = 300000},
    {StartSlots = 100, AddSlots = 20, CostGelatin = 8000000000, CostEssence = 1500000},
    {StartSlots = 120, AddSlots = 30, CostGelatin = 50000000000, CostEssence = 10000000}
}

function EconomyConfig.GetInventorySlots(level)
    if level == 0 then return 20 end
    local upgrade = EconomyConfig.InventoryUpgrades[level + 1]
    return upgrade and upgrade.StartSlots or 150
end

-- ========================================
-- REBIRTH (Système de Sacrifice)
-- ========================================
EconomyConfig.Rebirths = {
    {
        Level = 1,
        CostGelatin = 100000000000,
        CostEssence = 50000000,
        Multiplier = 1.25,
        RequiredSlimes = {
            Count = 10,
            Criteria = "10 moods différents, taille ≥ Petit"
        }
    },
    {
        Level = 2,
        CostGelatin = 1000000000000,
        CostEssence = 500000000,
        Multiplier = 1.5,
        RequiredSlimes = {
            Count = 25,
            Criteria = "Tous moods, raretés ≥ Rare"
        }
    },
    {
        Level = 3,
        CostGelatin = 15000000000000,
        CostEssence = 7500000000,
        Multiplier = 1.75,
        RequiredSlimes = {
            Count = 50,
            Criteria = "Toutes tailles, raretés ≥ Épique"
        }
    },
    {
        Level = 4,
        CostGelatin = 250000000000000,
        CostEssence = 125000000000,
        Multiplier = 2,
        RequiredSlimes = {
            Count = 100,
            Criteria = "5 de chaque état, raretés ≥ Légendaire"
        }
    },
    {
        Level = 5,
        CostGelatin = 5000000000000000,
        CostEssence = 2500000000000,
        Multiplier = 2.5,
        RequiredSlimes = {
            Count = 200,
            Criteria = "Mix total, raretés ≥ Mythique"
        }
    }
}

-- Calcul multiplicateur cumulé
function EconomyConfig.GetRebirthMultiplier(level)
    local totalMult = 1
    for i = 1, math.min(level, #EconomyConfig.Rebirths) do
        totalMult = totalMult * EconomyConfig.Rebirths[i].Multiplier
    end
    return totalMult
end

-- ========================================
-- VENTE DE SLIMES
-- ========================================
function EconomyConfig.GetSellValue(production)
    -- Retourne 110% de ce qui serait perdu en fusion échec
    -- Production × 80 (coût) × 0.2 (récup échec) × 1.1
    return math.floor(production * 80 * 0.2 * 1.1)
end

function EconomyConfig.GetSellEssence(production)
    -- Essence proportionnelle
    return math.floor(production * 10 * 0.2 * 1.1)
end

-- ========================================
-- PRODUCTION SETTINGS
-- ========================================
EconomyConfig.ProductionSettings = {
    UpdateInterval = 1, -- Mise à jour toutes les secondes
    CollectionRadius = 10, -- Rayon hitbox pour collecter
    AutoCollectDistance = math.huge -- Infini si amélioration active
}

-- ========================================
-- PODS SLIME
-- ========================================
EconomyConfig.PodSettings = {
    TotalPods = 22,
    DefaultUnlocked = 10,
    ProximityPromptDistance = 8
}

function EconomyConfig.GetUnlockedPods(baseLevel)
    local unlocked = EconomyConfig.PodSettings.DefaultUnlocked
    for i = 1, baseLevel do
        if EconomyConfig.BaseUpgrades[i] then
            unlocked = unlocked + #EconomyConfig.BaseUpgrades[i].PodsUnlocked
        end
    end
    return unlocked
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Format nombres (123456789 → "123.4M")
function EconomyConfig.FormatNumber(num)
    if num >= 1e15 then
        return string.format("%.2fQa", num / 1e15)
    elseif num >= 1e12 then
        return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

-- Peut se permettre achat ?
function EconomyConfig.CanAfford(playerData, costGelatin, costEssence)
    return playerData.Gelatin >= costGelatin and playerData.Essence >= costEssence
end

return EconomyConfig
