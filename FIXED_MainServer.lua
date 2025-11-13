-- ========================================
-- SLIME RUSH - MAIN SERVER (CORRIGÉ)
-- Script (Serveur)
-- Localisation: ServerScriptService/MainServer
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[MainServer] 🚀 Démarrage Slime Rush Server...")

-- ========================================
-- MODULES (CHEMINS CORRIGÉS)
-- ========================================
local DataStoreManager = require(script.Parent.DataStoreManager)
local BaseManager = require(script.Parent.BaseManager)
local ProductionManager = require(script.Parent.ProductionManager)
local FusionHandler = require(script.Parent.FusionHandler)
local ContractManager = require(script.Parent.ContractManager)
local ShopManager = require(script.Parent.ShopManager)
local RebirthHandler = require(script.Parent.RebirthHandler)
local EventManager = require(script.Parent.EventManager)

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

-- ========================================
-- REMOTE EVENTS
-- ========================================
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ========================================
-- ÉVÉNEMENTS JOUEUR
-- ========================================

Players.PlayerAdded:Connect(function(player)
    print(string.format("[MainServer] 👤 %s a rejoint", player.Name))

    local playerData = DataStoreManager.LoadData(player)
    local baseIndex = BaseManager.AssignBaseToPlayer(player)

    if not baseIndex then
        warn(string.format("[MainServer] ⚠️ Serveur plein pour %s", player.Name))
        local ServerMatchmaking = require(script.Parent.ServerMatchmaking)
        ServerMatchmaking.TeleportToAvailableServer(player)
        return
    end

    ProductionManager.SetupCollectionHitbox(player, baseIndex)
    ProductionManager.StartProduction(player)
    ContractManager.InitializeContracts(player)
    ShopManager.InitializeShop(player)

    print(string.format("[MainServer] ✅ %s initialisé (Base %d)", player.Name, baseIndex))
end)

Players.PlayerRemoving:Connect(function(player)
    print(string.format("[MainServer] 👋 %s quitte", player.Name))
    ProductionManager.StopProduction(player)
end)

-- ========================================
-- REMOTE EVENTS HANDLERS
-- ========================================

RemoteEvents.PurchaseSlime.OnServerEvent:Connect(function(player, slimeData)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local cost = SlimeConfig.GetCost(slimeData.Size, slimeData.Rarity)
    if playerData.Gelatin < cost then
        RemoteEvents.PurchaseSlime:FireClient(player, false, "Pas assez de gélatine")
        return
    end

    local availablePod = BaseManager.GetAvailablePod(player)
    if not availablePod then
        RemoteEvents.PurchaseSlime:FireClient(player, false, "Aucun pod disponible")
        return
    end

    playerData.Gelatin = playerData.Gelatin - cost

    local DataManager = require(ReplicatedStorage.Modules.DataManager)
    DataManager.AddToSlimeDex(playerData, slimeData.Mood, slimeData.Rarity, slimeData.Size, slimeData.State)
    DataManager.PlaceSlimeOnPod(playerData, availablePod, slimeData)

    DataStoreManager.UpdatePlayerData(player, playerData)

    local SlimeSpawner = require(script.Parent.SlimeSpawner)
    local baseIndex = BaseManager.GetPlayerBase(player)
    local base = workspace.Base:FindFirstChild("Base " .. baseIndex)
    if base then
        local podsSlimeFolder = base:FindFirstChild("PodsSlime")
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. availablePod)
        if pod then
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, availablePod)
        end
    end

    ContractManager.UpdateProgress(player, "Purchase", 1)
    RemoteEvents.PurchaseSlime:FireClient(player, true, "Slime acheté !")

    print(string.format("[MainServer] ✅ %s a acheté slime (Pod %d)", player.Name, availablePod))
end)

RemoteEvents.FuseSlimes.OnServerEvent:Connect(function(player, fusionType, slime1, slime2, slime3, catalystsUsed)
    FusionHandler.ProcessFusion(player, fusionType, slime1, slime2, slime3, catalystsUsed)
end)

RemoteEvents.PlaceSlime.OnServerEvent:Connect(function(player, slimeUniqueID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local DataManager = require(ReplicatedStorage.Modules.DataManager)
    local slimeData = nil
    for _, slime in ipairs(playerData.Inventory) do
        if slime.UniqueID == slimeUniqueID then
            slimeData = slime
            break
        end
    end

    if not slimeData then return end

    local availablePod = BaseManager.GetAvailablePod(player)
    if not availablePod then
        RemoteEvents.PlaceSlime:FireClient(player, false, "Aucun pod disponible")
        return
    end

    DataManager.RemoveFromInventory(playerData, slimeUniqueID)
    DataManager.PlaceSlimeOnPod(playerData, availablePod, slimeData)
    DataStoreManager.UpdatePlayerData(player, playerData)

    local SlimeSpawner = require(script.Parent.SlimeSpawner)
    local baseIndex = BaseManager.GetPlayerBase(player)
    local base = workspace.Base:FindFirstChild("Base " .. baseIndex)
    if base then
        local podsSlimeFolder = base:FindFirstChild("PodsSlime")
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. availablePod)
        if pod then
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, availablePod)
        end
    end

    RemoteEvents.PlaceSlime:FireClient(player, true, "Slime placé !")
end)

RemoteEvents.SellSlime.OnServerEvent:Connect(function(player, slimeUniqueID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local DataManager = require(ReplicatedStorage.Modules.DataManager)
    local slimeData = nil
    for _, slime in ipairs(playerData.Inventory) do
        if slime.UniqueID == slimeUniqueID then
            slimeData = slime
            break
        end
    end

    if not slimeData then return end

    local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)
    local gelatinValue = EconomyConfig.GetSellValue(production)
    local essenceValue = EconomyConfig.GetSellEssence(production)

    playerData.Gelatin = playerData.Gelatin + gelatinValue
    playerData.Essence = playerData.Essence + essenceValue

    DataManager.RemoveFromInventory(playerData, slimeUniqueID)
    DataStoreManager.UpdatePlayerData(player, playerData)

    ContractManager.UpdateProgress(player, "Sell", 1)
    RemoteEvents.SellSlime:FireClient(player, true, gelatinValue, essenceValue)
end)

RemoteEvents.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeType, upgradeLevel)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    if upgradeType == "Base" then
        local upgrade = EconomyConfig.BaseUpgrades[upgradeLevel + 1]
        if not upgrade then return end

        if playerData.Gelatin >= upgrade.Cost then
            playerData.Gelatin = playerData.Gelatin - upgrade.Cost
            playerData.BaseLevel = playerData.BaseLevel + 1
            DataStoreManager.UpdatePlayerData(player, playerData)
            RemoteEvents.BuyUpgrade:FireClient(player, true, "Upgrade Base acheté !")
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

RemoteEvents.LikeBase.OnServerEvent:Connect(function(player, targetBaseIndex)
    ContractManager.UpdateProgress(player, "LikeBases", 1)
end)

RemoteEvents.BuyShopItem.OnServerEvent:Connect(function(player, itemID)
    ShopManager.PurchaseItem(player, itemID)
end)

RemoteEvents.ClaimContract.OnServerEvent:Connect(function(player, contractID)
    ContractManager.ClaimReward(player, contractID)
end)

RemoteEvents.DoRebirth.OnServerEvent:Connect(function(player, sacrificedSlimes)
    RebirthHandler.ProcessRebirth(player, sacrificedSlimes)
end)

RemoteEvents.SkipFusionTimer.OnServerEvent:Connect(function(player, method)
    FusionHandler.SkipTimer(player, method)
end)

EventManager.Initialize()

print("[MainServer] ✅ Serveur opérationnel !")
