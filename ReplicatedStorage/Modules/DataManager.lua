-- ========================================
-- SLIME RUSH - DATA MANAGER
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/DataManager
-- ========================================

local DataManager = {}

local EconomyConfig = require(script.Parent.EconomyConfig)

-- ========================================
-- STRUCTURE DE DONNÉES PAR DÉFAUT
-- ========================================
DataManager.DefaultData = {
    -- Ressources
    Gelatin = EconomyConfig.StartingResources.Gelatin,
    Essence = EconomyConfig.StartingResources.Essence,
    GelatinLifetime = EconomyConfig.StartingResources.GelatinLifetime,

    -- Upgrades Base
    BaseLevel = 0, -- 0 = 10 PodsSlime débloqués
    ProductionUpgradeLevel = 0,
    InventoryUpgradeLevel = 0,

    -- Rebirth
    RebirthLevel = 0,

    -- Inventaire Slimes
    Inventory = {
        -- Structure: {Mood, Rarity, Size, State, UniqueID}
    },

    -- Catalyseurs
    Catalysts = {
        Stability = 0,
        Chance10 = 0,
        Chance25 = 0,
        StatePure = 0,
        StateMuted = 0,
        StateFused = 0,
        StateCrystallized = 0,
        StateCorrupted = 0,
        Guaranteed100 = 0
    },

    -- Slimes Placés sur PodsSlime (serveur)
    PlacedSlimes = {
        -- [PodIndex] = {Mood, Rarity, Size, State, UniqueID}
    },

    -- Production accumulée (non collectée)
    AccumulatedProduction = {
        -- [PodIndex] = amount
    },

    -- Contrats Journaliers
    DailyContracts = {
        -- {ID, Progress, Claimed}
    },
    LastContractReset = os.time(),
    ContractProgress = {
        -- Stats pour tracking contrats
        TotalPurchased = 0,
        TotalFusionAttempts = 0,
        TotalFusionSuccess = 0,
        TotalFusionFail = 0,
        TotalCollected = 0,
        TotalSold = 0,
        TotalLikes = 0,
        SessionPlayTime = 0,
        FusionStreak = 0
    },

    -- SlimeDex (Codex)
    SlimeDex = {
        -- ["MoodID_RarityID_SizeID_StateID"] = true
    },

    -- Shop
    ShopCooldowns = {
        -- ["ItemID"] = timestamp
    },
    LastShopReset = os.time(),
    PermanentUpgrades = {
        ShopDiscount25 = false,
        FusionDiscount20 = false,
        EssenceBoost50 = false
    },

    -- Améliorations Robux
    RobuxUpgrades = {
        TeleportFast = false,
        BlackList = false,
        RarityAlert = false,
        BoostPanel = false,
        VIPPack = false
    },

    -- Gamepasses
    Gamepasses = {
        VIPPremium = false,
        AutoFusion = false,
        MegaInventory = false,
        DoubleRebirth = false
    },

    -- Boosts Actifs
    ActiveBoosts = {
        -- {Type, EndTime}
    },

    -- Fusion
    LastFusionTime = 0,
    FusionSkipsAvailable = 0, -- VIP skips gratuits/jour
    LastFusionSkipReset = os.time(),

    -- Base assignée (matchmaking)
    AssignedBaseIndex = nil, -- 1-8

    -- Timestamps
    LastJoinTime = os.time(),
    TotalPlayTime = 0
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Créer nouvelle donnée joueur
function DataManager.CreateNewPlayerData()
    local newData = {}
    for key, value in pairs(DataManager.DefaultData) do
        if type(value) == "table" then
            newData[key] = {}
            for k, v in pairs(value) do
                newData[key][k] = v
            end
        else
            newData[key] = value
        end
    end
    return newData
end

-- Fusionner données (pour updates après patches)
function DataManager.MergeData(savedData)
    local mergedData = DataManager.CreateNewPlayerData()

    for key, value in pairs(savedData) do
        if mergedData[key] ~= nil then
            mergedData[key] = value
        end
    end

    return mergedData
end

-- Valider intégrité données
function DataManager.ValidateData(data)
    if not data then return false end

    -- Vérifications basiques
    if type(data.Gelatin) ~= "number" then return false end
    if type(data.Essence) ~= "number" then return false end
    if type(data.Inventory) ~= "table" then return false end
    if type(data.PlacedSlimes) ~= "table" then return false end

    return true
end

-- Nettoyer données avant sauvegarde
function DataManager.CleanData(data)
    -- Supprimer timestamps obsolètes, vérifier intégrité
    local cleaned = {}

    for key, value in pairs(data) do
        if DataManager.DefaultData[key] ~= nil then
            cleaned[key] = value
        end
    end

    return cleaned
end

-- Ajouter slime à l'inventaire
function DataManager.AddToInventory(data, slime)
    if not slime or not slime.UniqueID then return false end

    table.insert(data.Inventory, {
        Mood = slime.Mood,
        Rarity = slime.Rarity,
        Size = slime.Size,
        State = slime.State,
        UniqueID = slime.UniqueID
    })

    return true
end

-- Retirer slime de l'inventaire
function DataManager.RemoveFromInventory(data, uniqueID)
    for i, slime in ipairs(data.Inventory) do
        if slime.UniqueID == uniqueID then
            table.remove(data.Inventory, i)
            return true
        end
    end
    return false
end

-- Placer slime sur pod
function DataManager.PlaceSlimeOnPod(data, podIndex, slime)
    if podIndex < 1 or podIndex > 22 then return false end
    if data.PlacedSlimes[podIndex] ~= nil then return false end -- Déjà occupé

    data.PlacedSlimes[podIndex] = {
        Mood = slime.Mood,
        Rarity = slime.Rarity,
        Size = slime.Size,
        State = slime.State,
        UniqueID = slime.UniqueID
    }

    data.AccumulatedProduction[podIndex] = 0

    return true
end

-- Retirer slime d'un pod
function DataManager.RemoveSlimeFromPod(data, podIndex)
    if not data.PlacedSlimes[podIndex] then return nil end

    local slime = data.PlacedSlimes[podIndex]
    data.PlacedSlimes[podIndex] = nil
    data.AccumulatedProduction[podIndex] = nil

    return slime
end

-- Ajouter au SlimeDex
function DataManager.AddToSlimeDex(data, mood, rarity, size, state)
    local SlimeConfig = require(script.Parent.SlimeConfig)
    local key = SlimeConfig.GetSlimeDexKey(mood, rarity, size, state)

    if not data.SlimeDex[key] then
        data.SlimeDex[key] = true
        return true -- Nouvelle découverte
    end

    return false
end

-- Compter SlimeDex
function DataManager.CountSlimeDex(data)
    local count = 0
    for _ in pairs(data.SlimeDex) do
        count = count + 1
    end
    return count
end

-- Ajouter catalyseur
function DataManager.AddCatalyst(data, catalystType, amount)
    amount = amount or 1
    if data.Catalysts[catalystType] then
        data.Catalysts[catalystType] = data.Catalysts[catalystType] + amount
        return true
    end
    return false
end

-- Utiliser catalyseur
function DataManager.UseCatalyst(data, catalystType, amount)
    amount = amount or 1
    if data.Catalysts[catalystType] and data.Catalysts[catalystType] >= amount then
        data.Catalysts[catalystType] = data.Catalysts[catalystType] - amount
        return true
    end
    return false
end

-- Vérifier cooldown shop
function DataManager.IsShopItemOnCooldown(data, itemID)
    if not data.ShopCooldowns[itemID] then return false end

    local now = os.time()
    return now < data.ShopCooldowns[itemID]
end

-- Définir cooldown shop
function DataManager.SetShopCooldown(data, itemID, cooldownSeconds)
    data.ShopCooldowns[itemID] = os.time() + cooldownSeconds
end

-- Ajouter boost actif
function DataManager.AddActiveBoost(data, boostType, duration)
    table.insert(data.ActiveBoosts, {
        Type = boostType,
        EndTime = tick() + duration
    })
end

-- Nettoyer boosts expirés
function DataManager.CleanExpiredBoosts(data)
    local now = tick()
    for i = #data.ActiveBoosts, 1, -1 do
        if data.ActiveBoosts[i].EndTime < now then
            table.remove(data.ActiveBoosts, i)
        end
    end
end

-- Vérifier si boost actif
function DataManager.HasActiveBoost(data, boostType)
    local now = tick()
    for _, boost in ipairs(data.ActiveBoosts) do
        if boost.Type == boostType and boost.EndTime > now then
            return true, boost.EndTime - now
        end
    end
    return false, 0
end

-- Mettre à jour temps de jeu
function DataManager.UpdatePlayTime(data)
    local now = os.time()
    local sessionTime = now - data.LastJoinTime
    data.TotalPlayTime = data.TotalPlayTime + sessionTime
    data.LastJoinTime = now
end

return DataManager
