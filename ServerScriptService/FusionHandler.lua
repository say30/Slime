-- ========================================
-- SLIME RUSH - FUSION HANDLER
-- Script (Serveur)
-- Localisation: ServerScriptService/FusionHandler
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FusionConfig = require(ReplicatedStorage.Modules.FusionConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)
local ContractManager = require(script.Parent.ContractManager)

local FusionHandler = {}

-- ========================================
-- PROCESSUS FUSION
-- ========================================

function FusionHandler.ProcessFusion(player, fusionType, slime1, slime2, slime3, catalystsUsed)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    print(string.format("[FusionHandler] 🔀 %s tente fusion %s", player.Name, fusionType))

    -- Vérifier timer
    local now = tick()
    local timeSinceLastFusion = now - playerData.LastFusionTime

    if timeSinceLastFusion < FusionConfig.FusionTimer.Cooldown then
        local remainingTime = FusionConfig.FusionTimer.Cooldown - timeSinceLastFusion
        warn(string.format("[FusionHandler] ⏱️ %s doit attendre %.0fs", player.Name, remainingTime))
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Timer actif", remainingTime)
        return
    end

    -- Vérifier slimes dans inventaire
    if not FusionHandler.ValidateSlimesInInventory(playerData, slime1, slime2, slime3) then
        warn("[FusionHandler] ❌ Slimes non trouvés dans inventaire")
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Slimes invalides")
        return
    end

    -- Calculer coût
    local cost = FusionConfig.GetFusionCost(fusionType, slime1, slime2, slime3)

    -- Appliquer réduction si achetée
    if playerData.PermanentUpgrades and playerData.PermanentUpgrades.FusionDiscount20 then
        cost.Gelatin = math.floor(cost.Gelatin * 0.8)
        cost.Essence = math.floor(cost.Essence * 0.8)
    end

    -- Vérifier ressources
    if playerData.Gelatin < cost.Gelatin or playerData.Essence < cost.Essence then
        warn(string.format("[FusionHandler] ❌ %s n'a pas assez de ressources", player.Name))
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Ressources insuffisantes")
        return
    end

    -- Validation fusion
    if fusionType == "Fusion2" and not FusionConfig.ValidateFusion2(slime1, slime2) then
        warn("[FusionHandler] ❌ Fusion2 invalide (slimes non identiques)")
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Slimes doivent être identiques")
        return
    end

    if fusionType == "Fusion3" and not FusionConfig.DetectFusion3Type(slime1, slime2, slime3) then
        warn("[FusionHandler] ❌ Fusion3 invalide (combinaison incorrecte)")
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Combinaison invalide")
        return
    end

    -- Déduire coût
    playerData.Gelatin = playerData.Gelatin - cost.Gelatin
    playerData.Essence = playerData.Essence - cost.Essence

    -- Calculer succès
    local baseChance = fusionType == "Fusion2" and FusionConfig.Fusion2Probabilities.BaseSuccess or 0.35
    local finalChance, targetState, stabilityActive = FusionConfig.ApplyLocalCatalysts(baseChance, catalystsUsed or {})

    local rand = math.random()
    local success = rand <= finalChance

    -- Consommer catalyseurs
    for catalystType, _ in pairs(catalystsUsed or {}) do
        DataManager.UseCatalyst(playerData, catalystType, 1)
    end

    -- Retirer slimes parents de l'inventaire (sauf si stabilité et échec)
    if success or not stabilityActive then
        DataManager.RemoveFromInventory(playerData, slime1.UniqueID)
        DataManager.RemoveFromInventory(playerData, slime2.UniqueID)
        if slime3 then
            DataManager.RemoveFromInventory(playerData, slime3.UniqueID)
        end
    end

    -- Créer résultat
    local result = FusionConfig.CreateResultSlime(fusionType, {slime1, slime2, slime3}, success, targetState)

    if success then
        -- Ajouter slime résultat à l'inventaire
        DataManager.AddToInventory(playerData, result.Slime)

        -- Ajouter au SlimeDex
        DataManager.AddToSlimeDex(playerData, result.Slime.Mood, result.Slime.Rarity, result.Slime.Size, result.Slime.State)

        -- Mettre à jour streak
        playerData.ContractProgress.FusionStreak = (playerData.ContractProgress.FusionStreak or 0) + 1

        print(string.format("[FusionHandler] ✅ %s fusion réussie !", player.Name))

        -- Contrats
        ContractManager.UpdateProgress(player, "FusionSuccess", 1)
        ContractManager.UpdateProgress(player, "FusionAttempt", 1)

        -- Notifier client
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, true, "Fusion réussie !", result.Slime)
    else
        -- Échec : récupérer essence
        local essenceRecovered = result.EssenceRecovered

        -- Appliquer bonus si acheté
        if playerData.PermanentUpgrades and playerData.PermanentUpgrades.EssenceBoost50 then
            essenceRecovered = math.floor(essenceRecovered * 1.5)
        end

        playerData.Essence = playerData.Essence + essenceRecovered

        -- Reset streak
        playerData.ContractProgress.FusionStreak = 0

        print(string.format("[FusionHandler] ❌ %s fusion échouée (récupéré %d essence)", player.Name, essenceRecovered))

        -- Contrats
        ContractManager.UpdateProgress(player, "FusionFail", 1)
        ContractManager.UpdateProgress(player, "FusionAttempt", 1)

        -- Notifier client
        ReplicatedStorage.RemoteEvents.FuseSlimes:FireClient(player, false, "Fusion échouée", essenceRecovered)
    end

    -- Mettre à jour timer
    playerData.LastFusionTime = now

    -- Sauvegarder
    DataStoreManager.UpdatePlayerData(player, playerData)
end

-- ========================================
-- VALIDER SLIMES DANS INVENTAIRE
-- ========================================

function FusionHandler.ValidateSlimesInInventory(playerData, slime1, slime2, slime3)
    local foundCount = 0
    local toFind = {slime1.UniqueID, slime2.UniqueID}
    if slime3 then table.insert(toFind, slime3.UniqueID) end

    for _, slime in ipairs(playerData.Inventory) do
        for _, id in ipairs(toFind) do
            if slime.UniqueID == id then
                foundCount = foundCount + 1
                break
            end
        end
    end

    return foundCount == #toFind
end

-- ========================================
-- SKIP TIMER
-- ========================================

function FusionHandler.SkipTimer(player, method)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    if method == "VIP" then
        -- Vérifier skips disponibles
        if playerData.FusionSkipsAvailable > 0 then
            playerData.FusionSkipsAvailable = playerData.FusionSkipsAvailable - 1
            playerData.LastFusionTime = 0

            DataStoreManager.UpdatePlayerData(player, playerData)

            ReplicatedStorage.RemoteEvents.SkipFusionTimer:FireClient(player, true, "Timer skip utilisé !")
        else
            ReplicatedStorage.RemoteEvents.SkipFusionTimer:FireClient(player, false, "Aucun skip disponible")
        end
    elseif method == "Gelatin" then
        local ShopConfig = require(ReplicatedStorage.Modules.ShopConfig)
        local cost = ShopConfig.SkipTimer.Gelatin

        if playerData.Gelatin >= cost.CostGelatin and playerData.Essence >= cost.CostEssence then
            playerData.Gelatin = playerData.Gelatin - cost.CostGelatin
            playerData.Essence = playerData.Essence - cost.CostEssence
            playerData.LastFusionTime = 0

            DataStoreManager.UpdatePlayerData(player, playerData)

            ReplicatedStorage.RemoteEvents.SkipFusionTimer:FireClient(player, true, "Timer skip acheté !")
        else
            ReplicatedStorage.RemoteEvents.SkipFusionTimer:FireClient(player, false, "Ressources insuffisantes")
        end
    end
end

-- ========================================
-- RESET SKIPS VIP QUOTIDIEN
-- ========================================

spawn(function()
    while true do
        wait(86400) -- 24h
        for _, player in ipairs(Players:GetPlayers()) do
            local playerData = DataStoreManager.GetPlayerData(player)
            if playerData and playerData.Gamepasses and playerData.Gamepasses.VIPPremium then
                playerData.FusionSkipsAvailable = FusionConfig.FusionTimer.VIPSkipsPerDay
                DataStoreManager.UpdatePlayerData(player, playerData)
            end
        end
    end
end)

return FusionHandler
