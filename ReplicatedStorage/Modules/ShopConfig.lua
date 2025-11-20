-- ========================================
-- SLIME RUSH - SHOP CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/ShopConfig
-- ========================================

local ShopConfig = {}

-- ========================================
-- SETTINGS
-- ========================================
ShopConfig.Settings = {
    ResetHour = 0, -- Reset à 00h00 UTC
    DailyRotationCount = 8, -- 6-8 items affichés par jour
    CooldownsResetOnServerRestart = false
}

-- ========================================
-- AMÉLIORATIONS TEMPORAIRES (Gélatine/Essence)
-- ========================================
ShopConfig.TemporaryBoosts = {
    -- AUTO-COLLECT
    {
        ID = "AutoCollect30",
        Name = "Collecte Automatique",
        Description = "Collecte auto à distance infinie pendant 30 min",
        Duration = 1800, -- 30 min en secondes
        CostGelatin = 5000000,
        CostEssence = 2500,
        Cooldown = 7200, -- 2h
        Category = "AutoCollect"
    },
    {
        ID = "AutoCollect60",
        Name = "Collecte Automatique (1h)",
        Description = "Collecte auto à distance infinie pendant 1h",
        Duration = 3600,
        CostGelatin = 15000000,
        CostEssence = 7500,
        Cooldown = 10800, -- 3h
        Category = "AutoCollect"
    },
    {
        ID = "AutoCollect180",
        Name = "Collecte Automatique (3h)",
        Description = "Collecte auto à distance infinie pendant 3h",
        Duration = 10800,
        CostGelatin = 80000000,
        CostEssence = 40000,
        Cooldown = 21600, -- 6h
        Category = "AutoCollect"
    },

    -- PRODUCTION BOOST
    {
        ID = "Production50_30",
        Name = "Boost Production +50%",
        Description = "+50% production pendant 30 min",
        Duration = 1800,
        CostGelatin = 8000000,
        CostEssence = 4000,
        Cooldown = 7200,
        Multiplier = 1.5,
        Category = "Production"
    },
    {
        ID = "Production100_60",
        Name = "Boost Production +100%",
        Description = "+100% production pendant 1h",
        Duration = 3600,
        CostGelatin = 30000000,
        CostEssence = 15000,
        Cooldown = 14400, -- 4h
        Multiplier = 2.0,
        Category = "Production"
    },
    {
        ID = "Production200_30",
        Name = "Boost Production +200%",
        Description = "+200% production pendant 30 min",
        Duration = 1800,
        CostGelatin = 100000000,
        CostEssence = 50000,
        Cooldown = 21600, -- 6h
        Multiplier = 3.0,
        Category = "Production"
    },

    -- SPAWN BOOSTS
    {
        ID = "RarityBoost15",
        Name = "Boost Rareté",
        Description = "Augmente chances raretés hautes pendant 15 min",
        Duration = 900,
        CostGelatin = 20000000,
        CostEssence = 10000,
        Cooldown = 14400,
        Effect = "RarityBoost",
        Category = "Spawn"
    },
    {
        ID = "SizeBoost15",
        Name = "Boost Taille",
        Description = "Augmente chances tailles hautes pendant 15 min",
        Duration = 900,
        CostGelatin = 18000000,
        CostEssence = 9000,
        Cooldown = 14400,
        Effect = "SizeBoost",
        Category = "Spawn"
    },
    {
        ID = "ForceMood10",
        Name = "Force Spawn Mood",
        Description = "Force un mood spécifique pendant 10 min",
        Duration = 600,
        CostGelatin = 25000000,
        CostEssence = 12500,
        Cooldown = 21600,
        Effect = "ForceMood",
        Category = "Spawn",
        RequiresSelection = true -- Joueur choisit le mood
    }
}

-- ========================================
-- AMÉLIORATIONS PERMANENTES (Gélatine/Essence)
-- ========================================
ShopConfig.PermanentUpgrades = {
    {
        ID = "ShopDiscount25",
        Name = "Réduction Prix Shop -25%",
        Description = "Tous les prix du shop -25% (permanent)",
        CostGelatin = 500000000,
        CostEssence = 250000,
        Effect = "ShopDiscount",
        Value = 0.25
    },
    {
        ID = "FusionDiscount20",
        Name = "Réduction Prix Fusion -20%",
        Description = "Tous les coûts de fusion -20% (permanent)",
        CostGelatin = 400000000,
        CostEssence = 200000,
        Effect = "FusionDiscount",
        Value = 0.20
    },
    {
        ID = "EssenceBoost50",
        Name = "Boost Essence +50%",
        Description = "+50% essence récupérée lors des échecs (permanent)",
        CostGelatin = 600000000,
        CostEssence = 300000,
        Effect = "EssenceRecovery",
        Value = 0.50
    }
}

-- ========================================
-- CATALYSEURS (Toujours disponibles)
-- ========================================
ShopConfig.Catalysts = {
    {
        ID = "CatalystStability",
        Name = "Catalyseur de Stabilité",
        Description = "Ne détruit pas les slimes en cas d'échec (1 charge)",
        CostGelatin = 50000000,
        CostEssence = 25000,
        Type = "Stability"
    },
    {
        ID = "CatalystChance10",
        Name = "Catalyseur Chance +10%",
        Description = "+10% chance de succès fusion",
        CostGelatin = 15000000,
        CostEssence = 7500,
        Type = "Chance10"
    },
    {
        ID = "CatalystChance25",
        Name = "Catalyseur Chance +25%",
        Description = "+25% chance de succès fusion",
        CostGelatin = 60000000,
        CostEssence = 30000,
        Type = "Chance25"
    },
    {
        ID = "CatalystStatePure",
        Name = "Catalyseur État Pur",
        Description = "Force l'état Pur si fusion réussie",
        CostGelatin = 100000000,
        CostEssence = 50000,
        Type = "StatePure"
    },
    {
        ID = "CatalystStateMuted",
        Name = "Catalyseur État Muté",
        Description = "Force l'état Muté si fusion réussie",
        CostGelatin = 100000000,
        CostEssence = 50000,
        Type = "StateMuted"
    },
    {
        ID = "CatalystStateFused",
        Name = "Catalyseur État Fusionné",
        Description = "Force l'état Fusionné si fusion réussie",
        CostGelatin = 100000000,
        CostEssence = 50000,
        Type = "StateFused"
    },
    {
        ID = "CatalystStateCrystallized",
        Name = "Catalyseur État Cristallisé",
        Description = "Force l'état Cristallisé si fusion réussie",
        CostGelatin = 100000000,
        CostEssence = 50000,
        Type = "StateCrystallized"
    },
    {
        ID = "CatalystStateCorrupted",
        Name = "Catalyseur État Corrompu",
        Description = "Force l'état Corrompu si fusion réussie",
        CostGelatin = 100000000,
        CostEssence = 50000,
        Type = "StateCorrupted"
    },
    {
        ID = "CatalystGuaranteed",
        Name = "Pack Fusion 100%",
        Description = "Garantit le succès de la fusion",
        CostGelatin = 1000000000,
        CostEssence = 500000,
        Type = "Guaranteed100"
    }
}

-- ========================================
-- AMÉLIORATIONS ROBUX (Permanentes)
-- ========================================
ShopConfig.RobuxUpgrades = {
    {
        ID = "TeleportFast",
        Name = "Téléportation Rapide",
        Description = "TP vers base + 2 points personnalisés",
        Price = 299,
        Type = "Teleport"
    },
    {
        ID = "BlackList",
        Name = "Liste Plateau Noir",
        Description = "Liste déroulante des slimes sur plateau (temps réel)",
        Price = 399,
        Type = "BlackList"
    },
    {
        ID = "RarityAlert",
        Name = "Alerte Rareté",
        Description = "Effet visuel sur slimes rareté ≥ Légendaire",
        Price = 499,
        Type = "RarityAlert"
    },
    {
        ID = "BoostPanel",
        Name = "Panel Activation Boosts",
        Description = "Toggle ON/OFF pour boosts actifs",
        Price = 199,
        Type = "BoostPanel"
    },
    {
        ID = "VIPPack",
        Name = "Pack VIP",
        Description = "TOUTES les améliorations ci-dessus + bonus secret",
        Price = 999,
        Type = "VIPPack"
    }
}

-- ========================================
-- SKIP TIMER FUSION
-- ========================================
ShopConfig.SkipTimer = {
    Gelatin = {
        CostGelatin = 5000000,
        CostEssence = 2500,
        Skips = 1
    },
    Robux = {
        Price = 50,
        Skips = 10
    }
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Génération rotation journalière
function ShopConfig.GenerateDailyRotation(seed)
    math.randomseed(seed or tick())

    local selected = {}
    local pool = {}

    -- Copier pool boosts temporaires
    for _, boost in ipairs(ShopConfig.TemporaryBoosts) do
        table.insert(pool, boost)
    end

    -- Sélectionner 6-8 items
    local count = math.random(6, 8)
    for i = 1, math.min(count, #pool) do
        local index = math.random(1, #pool)
        table.insert(selected, pool[index])
        table.remove(pool, index)
    end

    return selected
end

-- Appliquer réduction si achetée
function ShopConfig.ApplyDiscount(baseCost, playerData)
    local discount = 0

    if playerData.PermanentUpgrades and playerData.PermanentUpgrades.ShopDiscount25 then
        discount = 0.25
    end

    return {
        Gelatin = math.floor(baseCost.Gelatin * (1 - discount)),
        Essence = math.floor(baseCost.Essence * (1 - discount))
    }
end

-- Calculer prochain reset
function ShopConfig.GetNextResetTime()
    local now = os.time()
    local nowUTC = os.date("!*t", now)

    local secondsSinceMidnight = nowUTC.hour * 3600 + nowUTC.min * 60 + nowUTC.sec
    local secondsUntilMidnight = 86400 - secondsSinceMidnight

    return now + secondsUntilMidnight
end

return ShopConfig
