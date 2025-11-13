-- ========================================
-- SLIME RUSH - CONTRACT CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/ContractConfig
-- ========================================

local ContractConfig = {}

-- ========================================
-- SETTINGS
-- ========================================
ContractConfig.Settings = {
    DailyContracts = 3, -- 3 contrats/jour (4 si VIP)
    VIPBonus = 1, -- +1 contrat si VIP
    ResetHour = 0, -- Reset à 00h00 UTC
    RotationPoolSize = 40 -- 40 contrats dans le pool
}

-- ========================================
-- POOL DE 40 CONTRATS
-- ========================================
ContractConfig.ContractPool = {
    -- COLLECTEURS
    {
        ID = 1,
        Name = "Collectionneur Débutant",
        Description = "Acheter 5 slimes",
        Type = "Purchase",
        Goal = 5,
        Rewards = {Gelatin = 50000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 2,
        Name = "Collectionneur Intermédiaire",
        Description = "Acheter 15 slimes",
        Type = "Purchase",
        Goal = 15,
        Rewards = {Gelatin = 200000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 3,
        Name = "Collectionneur Expert",
        Description = "Acheter 50 slimes",
        Type = "Purchase",
        Goal = 50,
        Rewards = {Gelatin = 1500000, Essence = 0, Catalyst = nil}
    },

    -- FUSIONNEURS
    {
        ID = 4,
        Name = "Fusionneur Novice",
        Description = "Réussir 3 fusions",
        Type = "FusionSuccess",
        Goal = 3,
        Rewards = {Gelatin = 100000, Essence = 500, Catalyst = nil}
    },
    {
        ID = 5,
        Name = "Fusionneur Maître",
        Description = "Réussir 10 fusions",
        Type = "FusionSuccess",
        Goal = 10,
        Rewards = {Gelatin = 800000, Essence = 5000, Catalyst = nil}
    },
    {
        ID = 6,
        Name = "Alchimiste Fou",
        Description = "Tenter 20 fusions (succès ou échec)",
        Type = "FusionAttempt",
        Goal = 20,
        Rewards = {Gelatin = 500000, Essence = 2000, Catalyst = nil}
    },

    -- RÉCOLTEURS
    {
        ID = 7,
        Name = "Récolteur Actif",
        Description = "Collecter 500,000 gélatine",
        Type = "Collect",
        Goal = 500000,
        Rewards = {Gelatin = 150000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 8,
        Name = "Récolteur Hardcore",
        Description = "Collecter 5,000,000 gélatine",
        Type = "Collect",
        Goal = 5000000,
        Rewards = {Gelatin = 2000000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 9,
        Name = "Magnat de la Gélatine",
        Description = "Collecter 50,000,000 gélatine",
        Type = "Collect",
        Goal = 50000000,
        Rewards = {Gelatin = 20000000, Essence = 10000, Catalyst = nil}
    },

    -- CHASSEURS DE RARETÉS
    {
        ID = 10,
        Name = "Chasseur de Raretés",
        Description = "Obtenir 1 slime Légendaire ou supérieur",
        Type = "ObtainRarity",
        Goal = 6, -- Index rareté Légendaire
        Rewards = {Gelatin = 500000, Essence = 0, Catalyst = "Chance10"}
    },
    {
        ID = 11,
        Name = "Collectionneur Mythique",
        Description = "Obtenir 1 slime Mythique ou supérieur",
        Type = "ObtainRarity",
        Goal = 7, -- Mythique
        Rewards = {Gelatin = 2000000, Essence = 5000, Catalyst = "Chance25"}
    },
    {
        ID = 12,
        Name = "Chercheur d'Oméga",
        Description = "Obtenir 1 slime Oméga",
        Type = "ObtainRarity",
        Goal = 12, -- Oméga
        Rewards = {Gelatin = 50000000, Essence = 25000, Catalyst = "Guaranteed100"}
    },

    -- MAÎTRES DES MOODS
    {
        ID = 13,
        Name = "Maître des Moods",
        Description = "Obtenir 1 slime de chaque mood (12 total)",
        Type = "MoodCollection",
        Goal = 12,
        Rewards = {Gelatin = 1200000, Essence = 10000, Catalyst = nil}
    },
    {
        ID = 14,
        Name = "Arc-en-Ciel",
        Description = "Posséder simultanément 12 moods différents",
        Type = "MoodSimultaneous",
        Goal = 12,
        Rewards = {Gelatin = 3000000, Essence = 15000, Catalyst = nil}
    },

    -- TITANS
    {
        ID = 15,
        Name = "Titan Hunter",
        Description = "Obtenir 1 slime Titan",
        Type = "ObtainSize",
        Goal = 5, -- Titan
        Rewards = {Gelatin = 800000, Essence = 0, Catalyst = "StatePure"}
    },
    {
        ID = 16,
        Name = "Armée de Titans",
        Description = "Posséder 5 slimes Titan simultanément",
        Type = "SizeSimultaneous",
        Goal = 5,
        Rewards = {Gelatin = 5000000, Essence = 20000, Catalyst = "StateFused"}
    },

    -- TEMPS
    {
        ID = 17,
        Name = "Patience Récompensée",
        Description = "Rester connecté 1 heure",
        Type = "PlayTime",
        Goal = 3600, -- secondes
        Rewards = {Gelatin = 300000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 18,
        Name = "Marathon",
        Description = "Rester connecté 3 heures",
        Type = "PlayTime",
        Goal = 10800,
        Rewards = {Gelatin = 1500000, Essence = 7500, Catalyst = nil}
    },
    {
        ID = 19,
        Name = "Dévouement Total",
        Description = "Rester connecté 6 heures",
        Type = "PlayTime",
        Goal = 21600,
        Rewards = {Gelatin = 10000000, Essence = 50000, Catalyst = "Stability"}
    },

    -- SOCIAL
    {
        ID = 20,
        Name = "Social Butterfly",
        Description = "Liker 10 bases",
        Type = "LikeBases",
        Goal = 10,
        Rewards = {Gelatin = 100000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 21,
        Name = "Critique d'Art",
        Description = "Liker 50 bases",
        Type = "LikeBases",
        Goal = 50,
        Rewards = {Gelatin = 600000, Essence = 0, Catalyst = nil}
    },

    -- VENDEURS
    {
        ID = 22,
        Name = "Vendeur Opportuniste",
        Description = "Vendre 10 slimes",
        Type = "Sell",
        Goal = 10,
        Rewards = {Gelatin = 250000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 23,
        Name = "Liquidation Totale",
        Description = "Vendre 30 slimes",
        Type = "Sell",
        Goal = 30,
        Rewards = {Gelatin = 1000000, Essence = 5000, Catalyst = nil}
    },

    -- BASE
    {
        ID = 24,
        Name = "Slots Pleins",
        Description = "Remplir 10 PodsSlime",
        Type = "FillPods",
        Goal = 10,
        Rewards = {Gelatin = 400000, Essence = 0, Catalyst = nil}
    },
    {
        ID = 25,
        Name = "Base Complète",
        Description = "Remplir 22 PodsSlime",
        Type = "FillPods",
        Goal = 22,
        Rewards = {Gelatin = 5000000, Essence = 25000, Catalyst = nil}
    },

    -- ÉTATS
    {
        ID = 26,
        Name = "État Recherché",
        Description = "Obtenir 1 slime avec un état (Pur, Muté, etc.)",
        Type = "ObtainState",
        Goal = 1,
        Rewards = {Gelatin = 1500000, Essence = 0, Catalyst = "Stability"}
    },
    {
        ID = 27,
        Name = "Collection d'États",
        Description = "Obtenir 1 slime de chaque état (5 total)",
        Type = "StateCollection",
        Goal = 5,
        Rewards = {Gelatin = 10000000, Essence = 0, Catalyst = "Guaranteed100"}
    },
    {
        ID = 28,
        Name = "Corrompu Maître",
        Description = "Obtenir 1 slime Corrompu",
        Type = "ObtainSpecificState",
        Goal = 6, -- Corrompu
        Rewards = {Gelatin = 5000000, Essence = 25000, Catalyst = "StateCorrupted"}
    },

    -- UPGRADES
    {
        ID = 29,
        Name = "Amélioration",
        Description = "Acheter 1 upgrade de base",
        Type = "BuyBaseUpgrade",
        Goal = 1,
        Rewards = {Gelatin = 1000000, Essence = 5000, Catalyst = nil}
    },
    {
        ID = 30,
        Name = "Investisseur",
        Description = "Acheter 3 upgrades de production",
        Type = "BuyProductionUpgrade",
        Goal = 3,
        Rewards = {Gelatin = 5000000, Essence = 25000, Catalyst = nil}
    },

    -- SLIMEDEX
    {
        ID = 31,
        Name = "Explorateur Novice",
        Description = "Découvrir 50 variétés dans le SlimeDex",
        Type = "SlimeDexCount",
        Goal = 50,
        Rewards = {Gelatin = 500000, Essence = 2500, Catalyst = nil}
    },
    {
        ID = 32,
        Name = "Explorateur Expert",
        Description = "Découvrir 200 variétés dans le SlimeDex",
        Type = "SlimeDexCount",
        Goal = 200,
        Rewards = {Gelatin = 5000000, Essence = 25000, Catalyst = "Chance25"}
    },
    {
        ID = 33,
        Name = "Maître Pokédex",
        Description = "Découvrir 1000 variétés dans le SlimeDex",
        Type = "SlimeDexCount",
        Goal = 1000,
        Rewards = {Gelatin = 100000000, Essence = 500000, Catalyst = "Guaranteed100"}
    },

    -- PRODUCTION
    {
        ID = 34,
        Name = "Producteur Débutant",
        Description = "Atteindre 1000 gélatine/s de production",
        Type = "ProductionRate",
        Goal = 1000,
        Rewards = {Gelatin = 1000000, Essence = 5000, Catalyst = nil}
    },
    {
        ID = 35,
        Name = "Producteur Industriel",
        Description = "Atteindre 100,000 gélatine/s de production",
        Type = "ProductionRate",
        Goal = 100000,
        Rewards = {Gelatin = 50000000, Essence = 250000, Catalyst = nil}
    },

    -- SHOP
    {
        ID = 36,
        Name = "Consommateur",
        Description = "Acheter 5 items dans le shop",
        Type = "ShopPurchase",
        Goal = 5,
        Rewards = {Gelatin = 800000, Essence = 4000, Catalyst = nil}
    },
    {
        ID = 37,
        Name = "Acheteur Compulsif",
        Description = "Acheter 20 items dans le shop",
        Type = "ShopPurchase",
        Goal = 20,
        Rewards = {Gelatin = 10000000, Essence = 50000, Catalyst = "Chance25"}
    },

    -- CHALLENGES
    {
        ID = 38,
        Name = "Chanceux du Jour",
        Description = "Réussir 5 fusions d'affilée",
        Type = "FusionStreak",
        Goal = 5,
        Rewards = {Gelatin = 5000000, Essence = 25000, Catalyst = "Guaranteed100"}
    },
    {
        ID = 39,
        Name = "Malchanceux Persévérant",
        Description = "Échouer 10 fusions",
        Type = "FusionFail",
        Goal = 10,
        Rewards = {Gelatin = 2000000, Essence = 10000, Catalyst = "Stability"}
    },
    {
        ID = 40,
        Name = "Perfectionniste",
        Description = "Remplir tous les PodsSlime avec raretés ≥ Épique",
        Type = "PerfectBase",
        Goal = 22,
        Rewards = {Gelatin = 100000000, Essence = 500000, Catalyst = "Guaranteed100"}
    }
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Obtenir contrat par ID
function ContractConfig.GetContract(id)
    for _, contract in ipairs(ContractConfig.ContractPool) do
        if contract.ID == id then
            return contract
        end
    end
    return nil
end

-- Générer contrats journaliers aléatoires
function ContractConfig.GenerateDailyContracts(count, seed)
    math.randomseed(seed or tick())

    local selected = {}
    local pool = {}

    -- Copier pool
    for _, contract in ipairs(ContractConfig.ContractPool) do
        table.insert(pool, contract.ID)
    end

    -- Sélectionner aléatoirement
    for i = 1, math.min(count, #pool) do
        local index = math.random(1, #pool)
        table.insert(selected, pool[index])
        table.remove(pool, index)
    end

    return selected
end

-- Vérifier si contrat est complété
function ContractConfig.IsContractComplete(contract, progress)
    return progress >= contract.Goal
end

-- Calculer reset timestamp (prochain 00h00 UTC)
function ContractConfig.GetNextResetTime()
    local now = os.time()
    local nowUTC = os.date("!*t", now)

    -- Secondes depuis minuit
    local secondsSinceMidnight = nowUTC.hour * 3600 + nowUTC.min * 60 + nowUTC.sec

    -- Secondes jusqu'au prochain minuit
    local secondsUntilMidnight = 86400 - secondsSinceMidnight

    return now + secondsUntilMidnight
end

return ContractConfig
