-- ========================================
-- SLIME RUSH - EVENT CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/EventConfig
-- ========================================

local EventConfig = {}

-- ========================================
-- SETTINGS
-- ========================================
EventConfig.Settings = {
    Frequency = 10800, -- Toutes les 3 heures (en secondes)
    Duration = 900, -- 15 minutes
    WarningTime = 120, -- Notification 2 min avant
    ServerWideNotification = true
}

-- ========================================
-- POOL D'ÉVÉNEMENTS
-- ========================================
EventConfig.EventPool = {
    {
        ID = "TitanRain",
        Name = "Pluie de Titans",
        Description = "Uniquement des slimes Titan spawn !",
        Duration = 900,
        Rarity = "Common",
        Effect = {
            Type = "ForceSize",
            Value = 5 -- Titan
        },
        Icon = "🦖"
    },
    {
        ID = "LegendaryInvasion",
        Name = "Invasion Légendaire",
        Description = "Raretés Légendaire+ uniquement !",
        Duration = 900,
        Rarity = "Rare",
        Effect = {
            Type = "ForceRarityMin",
            Value = 6 -- Légendaire minimum
        },
        Icon = "⭐"
    },
    {
        ID = "MoodFestival",
        Name = "Festival des Moods",
        Description = "Un mood spécifique spawn 100% !",
        Duration = 900,
        Rarity = "Common",
        Effect = {
            Type = "ForceMood",
            Value = nil -- Déterminé aléatoirement au lancement
        },
        Icon = "🎭"
    },
    {
        ID = "AbyssOpen",
        Name = "Abysse Ouvert",
        Description = "Chances Abyssal/Prismatique/Oméga ×5 !",
        Duration = 900,
        Rarity = "VeryRare",
        Effect = {
            Type = "RarityBoostHigh",
            Multiplier = 5
        },
        Icon = "🌌"
    },
    {
        ID = "WildStates",
        Name = "États Sauvages",
        Description = "Slimes spawn AVEC des états ! (UNIQUE)",
        Duration = 900,
        Rarity = "UltraRare",
        Effect = {
            Type = "EnableStates",
            StateProbability = 0.3 -- 30% chance état
        },
        Icon = "💫"
    },
    {
        ID = "DoubleProduction",
        Name = "Heure Dorée",
        Description = "Production ×2 pour tous les slimes !",
        Duration = 900,
        Rarity = "Common",
        Effect = {
            Type = "ProductionMultiplier",
            Multiplier = 2
        },
        Icon = "💰"
    },
    {
        ID = "BlessedFusion",
        Name = "Fusion Bénie",
        Description = "Toutes fusions +25% chance de succès !",
        Duration = 900,
        Rarity = "Rare",
        Effect = {
            Type = "FusionBonus",
            Bonus = 0.25
        },
        Icon = "✨"
    },
    {
        ID = "Rainbow",
        Name = "Arc-en-Ciel",
        Description = "Tous les moods spawn équitablement !",
        Duration = 900,
        Rarity = "Common",
        Effect = {
            Type = "MoodBalance"
        },
        Icon = "🌈"
    },
    {
        ID = "MicroMadness",
        Name = "Folie Micro",
        Description = "Uniquement Micro, mais raretés ×10 !",
        Duration = 900,
        Rarity = "Rare",
        Effect = {
            Type = "SizeRarityTrade",
            ForceSize = 1, -- Micro
            RarityMultiplier = 10
        },
        Icon = "🔬"
    },
    {
        ID = "Jackpot",
        Name = "Jackpot Cosmique",
        Description = "1 slime Oméga Titan garanti spawn !",
        Duration = 900,
        Rarity = "Legendary",
        Effect = {
            Type = "GuaranteedSpawn",
            Rarity = 12, -- Oméga
            Size = 5 -- Titan
        },
        Icon = "🎰"
    }
}

-- ========================================
-- PROBABILITÉS ÉVÉNEMENTS
-- ========================================
EventConfig.EventRarities = {
    Common = 0.50, -- 50%
    Rare = 0.30, -- 30%
    VeryRare = 0.12, -- 12%
    UltraRare = 0.06, -- 6%
    Legendary = 0.02 -- 2%
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Sélectionner événement aléatoire
function EventConfig.SelectRandomEvent(seed)
    math.randomseed(seed or tick())

    -- Déterminer rareté
    local rand = math.random()
    local cumulative = 0
    local selectedRarity = "Common"

    for rarity, prob in pairs(EventConfig.EventRarities) do
        cumulative = cumulative + prob
        if rand <= cumulative then
            selectedRarity = rarity
            break
        end
    end

    -- Pool événements avec cette rareté
    local pool = {}
    for _, event in ipairs(EventConfig.EventPool) do
        if event.Rarity == selectedRarity then
            table.insert(pool, event)
        end
    end

    if #pool == 0 then
        return EventConfig.EventPool[1] -- Fallback
    end

    -- Sélectionner aléatoirement
    return pool[math.random(1, #pool)]
end

-- Calculer prochain événement
function EventConfig.GetNextEventTime(lastEventTime)
    return lastEventTime + EventConfig.Settings.Frequency
end

-- Vérifier si événement actif
function EventConfig.IsEventActive(eventStartTime)
    local now = tick()
    local elapsed = now - eventStartTime
    return elapsed >= 0 and elapsed < EventConfig.Settings.Duration
end

-- Obtenir temps restant événement
function EventConfig.GetTimeRemaining(eventStartTime)
    local now = tick()
    local elapsed = now - eventStartTime
    local remaining = EventConfig.Settings.Duration - elapsed
    return math.max(0, remaining)
end

return EventConfig
