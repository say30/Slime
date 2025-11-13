-- ========================================
-- SLIME RUSH - MAIN SERVER
-- Script (Serveur)
-- Localisation: ServerScriptService/MainServer
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[MainServer] 🚀 Démarrage Slime Rush Server...")

-- ========================================
-- MODULES
-- ========================================
local DataStoreManager = require(script.Parent.DataStoreManager)
local BaseManager = require(script.Parent.BaseManager)
local ProductionManager = require(script.Parent.ProductionManager)
local FusionHandler = require(script.Parent.FusionHandler)
local ContractManager = require(script.Parent.ContractManager)
local ShopManager = require(script.Parent.ShopManager)
local RebirthHandler = require(script.Parent.RebirthHandler)
local EventManager = require(script.Parent.EventManager)

-- ========================================
-- REMOTE EVENTS
-- ========================================
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = RemoteEvents

-- ========================================
-- ÉVÉNEMENTS JOUEUR
-- ========================================

Players.PlayerAdded:Connect(function(player)
    print(string.format("[MainServer] 👤 %s a rejoint le serveur", player.Name))

    -- 1. Charger données
    local playerData = DataStoreManager.LoadData(player)

    -- 2. Assigner base
    local baseIndex = BaseManager.AssignBaseToPlayer(player)

    if not baseIndex then
        -- Serveur plein → Téléporter vers autre serveur
        warn(string.format("[MainServer] ⚠️ Serveur plein, téléportation de %s...", player.Name))
        local ServerMatchmaking = require(script.Parent.ServerMatchmaking)
        ServerMatchmaking.TeleportToAvailableServer(player)
        return
    end

    -- 3. Setup hitbox collection
    ProductionManager.SetupCollectionHitbox(player, baseIndex)

    -- 4. Démarrer production
    ProductionManager.StartProduction(player)

    -- 5. Initialiser contrats
    ContractManager.InitializeContracts(player)

    -- 6. Initialiser shop
    ShopManager.InitializeShop(player)

    -- 7. Envoyer données au client
    local getPlayerDataFunc = RemoteFunctions:FindFirstChild("GetPlayerData")
    if getPlayerDataFunc then
        getPlayerDataFunc.OnServerInvoke = function(requestingPlayer)
            if requestingPlayer == player then
                return DataStoreManager.GetPlayerData(player)
            end
        end
    end

    print(string.format("[MainServer] ✅ %s initialisé (Base %d)", player.Name, baseIndex))
end)

Players.PlayerRemoving:Connect(function(player)
    print(string.format("[MainServer] 👋 %s quitte le serveur", player.Name))

    -- Arrêter production
    ProductionManager.StopProduction(player)

    -- Sauvegarder (géré par DataStoreManager)
    -- Libérer base (géré par BaseManager)
end)

-- ========================================
-- REMOTE EVENTS HANDLERS
-- ========================================

-- ACHAT SLIME
RemoteEvents.PurchaseSlime.OnServerEvent:Connect(function(player, slimeData)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
    local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

    -- Vérifier coût
    local cost = SlimeConfig.GetCost(slimeData.Size, slimeData.Rarity)
    if playerData.Gelatin < cost then
        warn(string.format("[MainServer] ❌ %s n'a pas assez de gélatine", player.Name))
        return
    end

    -- Vérifier pod disponible
    local availablePod = BaseManager.GetAvailablePod(player)
    if not availablePod then
        warn(string.format("[MainServer] ⚠️ Aucun pod disponible pour %s", player.Name))
        -- Notifier client
        RemoteEvents.PurchaseSlime:FireClient(player, false, "Aucun pod disponible")
        return
    end

    -- Déduire coût
    playerData.Gelatin = playerData.Gelatin - cost

    -- Ajouter au SlimeDex
    local DataManager = require(ReplicatedStorage.Modules.DataManager)
    DataManager.AddToSlimeDex(playerData, slimeData.Mood, slimeData.Rarity, slimeData.Size, slimeData.State)

    -- Placer sur pod
    DataManager.PlaceSlimeOnPod(playerData, availablePod, slimeData)

    -- Mettre à jour
    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Créer slime serveur
    local SlimeSpawner = require(script.Parent.SlimeSpawner)
    local baseIndex = BaseManager.GetPlayerBase(player)
    local base = game.Workspace.Base:FindFirstChild("Base " .. baseIndex)
    if base then
        local podsSlimeFolder = base:FindFirstChild("PodsSlime")
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. availablePod)
        if pod then
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, availablePod)
        end
    end

    -- Mettre à jour contrat
    ContractManager.UpdateProgress(player, "Purchase", 1)

    -- Notifier client succès
    RemoteEvents.PurchaseSlime:FireClient(player, true, "Slime acheté !")

    print(string.format("[MainServer] ✅ %s a acheté un slime (Pod %d)", player.Name, availablePod))
end)

-- FUSION SLIMES
RemoteEvents.FuseSlimes.OnServerEvent:Connect(function(player, fusionType, slime1, slime2, slime3, catalystsUsed)
    FusionHandler.ProcessFusion(player, fusionType, slime1, slime2, slime3, catalystsUsed)
end)

-- PLACER SLIME
RemoteEvents.PlaceSlime.OnServerEvent:Connect(function(player, slimeUniqueID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local DataManager = require(ReplicatedStorage.Modules.DataManager)

    -- Trouver slime dans inventaire
    local slimeData = nil
    for _, slime in ipairs(playerData.Inventory) do
        if slime.UniqueID == slimeUniqueID then
            slimeData = slime
            break
        end
    end

    if not slimeData then return end

    -- Vérifier pod disponible
    local availablePod = BaseManager.GetAvailablePod(player)
    if not availablePod then
        RemoteEvents.PlaceSlime:FireClient(player, false, "Aucun pod disponible")
        return
    end

    -- Retirer de l'inventaire
    DataManager.RemoveFromInventory(playerData, slimeUniqueID)

    -- Placer sur pod
    DataManager.PlaceSlimeOnPod(playerData, availablePod, slimeData)

    -- Mettre à jour
    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Créer slime serveur
    local SlimeSpawner = require(script.Parent.SlimeSpawner)
    local baseIndex = BaseManager.GetPlayerBase(player)
    local base = game.Workspace.Base:FindFirstChild("Base " .. baseIndex)
    if base then
        local podsSlimeFolder = base:FindFirstChild("PodsSlime")
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. availablePod)
        if pod then
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, availablePod)
        end
    end

    RemoteEvents.PlaceSlime:FireClient(player, true, "Slime placé !")
end)

-- VENDRE SLIME
RemoteEvents.SellSlime.OnServerEvent:Connect(function(player, slimeUniqueID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local DataManager = require(ReplicatedStorage.Modules.DataManager)
    local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)
    local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)

    -- Trouver slime
    local slimeData = nil
    for _, slime in ipairs(playerData.Inventory) do
        if slime.UniqueID == slimeUniqueID then
            slimeData = slime
            break
        end
    end

    if not slimeData then return end

    -- Calculer valeur vente
    local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)
    local gelatinValue = EconomyConfig.GetSellValue(production)
    local essenceValue = EconomyConfig.GetSellEssence(production)

    -- Ajouter ressources
    playerData.Gelatin = playerData.Gelatin + gelatinValue
    playerData.Essence = playerData.Essence + essenceValue

    -- Retirer slime
    DataManager.RemoveFromInventory(playerData, slimeUniqueID)

    -- Mettre à jour
    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Mettre à jour contrat
    ContractManager.UpdateProgress(player, "Sell", 1)

    RemoteEvents.SellSlime:FireClient(player, true, gelatinValue, essenceValue)

    print(string.format("[MainServer] 💰 %s a vendu un slime", player.Name))
end)

-- ACHETER UPGRADE
RemoteEvents.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeType, upgradeLevel)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

    if upgradeType == "Base" then
        local upgrade = EconomyConfig.BaseUpgrades[upgradeLevel + 1]
        if not upgrade then return end

        if playerData.Gelatin >= upgrade.Cost then
            playerData.Gelatin = playerData.Gelatin - upgrade.Cost
            playerData.BaseLevel = playerData.BaseLevel + 1

            DataStoreManager.UpdatePlayerData(player, playerData)

            RemoteEvents.BuyUpgrade:FireClient(player, true, "Upgrade Base acheté !")

            -- Mettre à jour contrat
            ContractManager.UpdateProgress(player, "BuyBaseUpgrade", 1)
        end
    elseif upgradeType == "Production" then
        local upgrade = EconomyConfig.ProductionUpgrades[upgradeLevel + 1]
        if not upgrade then return end

        if playerData.Gelatin >= upgrade.CostGelatin and playerData.Essence >= upgrade.CostEssence then
            playerData.Gelatin = playerData.Gelatin - upgrade.CostGelatin
            playerData.Essence = playerData.Essence - upgrade.CostEssence
            playerData.ProductionUpgradeLevel = playerData.ProductionUpgradeLevel + 1

            DataStoreManager.UpdatePlayerData(player, playerData)

            RemoteEvents.BuyUpgrade:FireClient(player, true, "Upgrade Production acheté !")

            ContractManager.UpdateProgress(player, "BuyProductionUpgrade", 1)
        end
    elseif upgradeType == "Inventory" then
        local upgrade = EconomyConfig.InventoryUpgrades[upgradeLevel + 2]
        if not upgrade then return end

        if playerData.Gelatin >= upgrade.CostGelatin and playerData.Essence >= upgrade.CostEssence then
            playerData.Gelatin = playerData.Gelatin - upgrade.CostGelatin
            playerData.Essence = playerData.Essence - upgrade.CostEssence
            playerData.InventoryUpgradeLevel = playerData.InventoryUpgradeLevel + 1

            DataStoreManager.UpdatePlayerData(player, playerData)

            RemoteEvents.BuyUpgrade:FireClient(player, true, "Upgrade Inventaire acheté !")
        end
    end
end)

-- LIKER BASE
RemoteEvents.LikeBase.OnServerEvent:Connect(function(player, targetBaseIndex)
    -- TODO: Implémenter système de likes
    ContractManager.UpdateProgress(player, "LikeBases", 1)
end)

-- ACHETER SHOP ITEM
RemoteEvents.BuyShopItem.OnServerEvent:Connect(function(player, itemID)
    ShopManager.PurchaseItem(player, itemID)
end)

-- RÉCLAMER CONTRAT
RemoteEvents.ClaimContract.OnServerEvent:Connect(function(player, contractID)
    ContractManager.ClaimReward(player, contractID)
end)

-- REBIRTH
RemoteEvents.DoRebirth.OnServerEvent:Connect(function(player, sacrificedSlimes)
    RebirthHandler.ProcessRebirth(player, sacrificedSlimes)
end)

-- SKIP FUSION TIMER
RemoteEvents.SkipFusionTimer.OnServerEvent:Connect(function(player, method)
    FusionHandler.SkipTimer(player, method)
end)

-- ========================================
-- INITIALISATION ÉVÉNEMENTS
-- ========================================

EventManager.Initialize()

print("[MainServer] ✅ Serveur Slime Rush opérationnel !")
