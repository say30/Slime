-- ========================================
-- SLIME RUSH - PRODUCTION MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/ProductionManager
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)

local ProductionManager = {}

-- ========================================
-- CONFIGURATION
-- ========================================
local UPDATE_INTERVAL = 1 -- Mise à jour production toutes les secondes
local ProductionLoops = {} -- {[UserId] = loop}

-- ========================================
-- DÉMARRER PRODUCTION POUR JOUEUR
-- ========================================

function ProductionManager.StartProduction(player)
    if ProductionLoops[player.UserId] then
        return -- Déjà démarré
    end

    print(string.format("[Production] ▶️ Démarrage production pour %s", player.Name))

    ProductionLoops[player.UserId] = true

    spawn(function()
        while ProductionLoops[player.UserId] and player:IsDescendantOf(Players) do
            wait(UPDATE_INTERVAL)

            local playerData = DataStoreManager.GetPlayerData(player)
            if not playerData then continue end

            -- Calculer production totale
            local totalProduction = ProductionManager.CalculateTotalProduction(playerData)

            -- Ajouter à la production accumulée
            for podIndex, slimeData in pairs(playerData.PlacedSlimes) do
                local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)

                -- Appliquer bonus production upgrades
                local productionBonus = EconomyConfig.GetProductionBonus(playerData.ProductionUpgradeLevel)
                production = production * (1 + productionBonus)

                -- Appliquer bonus rebirth
                local rebirthMultiplier = EconomyConfig.GetRebirthMultiplier(playerData.RebirthLevel)
                production = production * rebirthMultiplier

                -- Appliquer boosts actifs
                local hasProductionBoost, _ = DataManager.HasActiveBoost(playerData, "Production")
                if hasProductionBoost then
                    -- Trouver multiplicateur du boost
                    for _, boost in ipairs(playerData.ActiveBoosts) do
                        if boost.Type:find("Production") and boost.EndTime > tick() then
                            -- Extraire multiplicateur du nom (ex: "Production100_60" → 2.0)
                            if boost.Type:find("100") then
                                production = production * 2
                            elseif boost.Type:find("200") then
                                production = production * 3
                            elseif boost.Type:find("50") then
                                production = production * 1.5
                            end
                            break
                        end
                    end
                end

                -- Ajouter à accumulé
                playerData.AccumulatedProduction[podIndex] = (playerData.AccumulatedProduction[podIndex] or 0) + production
            end

            -- Mettre à jour données
            DataStoreManager.UpdatePlayerData(player, playerData)

            -- Mettre à jour affichage (optionnel : via RemoteEvent)
            ProductionManager.UpdateProductionDisplay(player)
        end
    end)
end

-- ========================================
-- ARRÊTER PRODUCTION
-- ========================================

function ProductionManager.StopProduction(player)
    ProductionLoops[player.UserId] = nil
    print(string.format("[Production] ⏸️ Arrêt production pour %s", player.Name))
end

-- ========================================
-- CALCULER PRODUCTION TOTALE
-- ========================================

function ProductionManager.CalculateTotalProduction(playerData)
    local total = 0

    for _, slimeData in pairs(playerData.PlacedSlimes) do
        local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)

        -- Appliquer bonus
        local productionBonus = EconomyConfig.GetProductionBonus(playerData.ProductionUpgradeLevel)
        production = production * (1 + productionBonus)

        local rebirthMultiplier = EconomyConfig.GetRebirthMultiplier(playerData.RebirthLevel)
        production = production * rebirthMultiplier

        total = total + production
    end

    return total
end

-- ========================================
-- COLLECTER DEPUIS POD
-- ========================================

function ProductionManager.CollectFromPod(player, podIndex)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return false end

    local accumulated = playerData.AccumulatedProduction[podIndex]
    if not accumulated or accumulated <= 0 then
        return false
    end

    -- Ajouter à gélatine joueur
    playerData.Gelatin = playerData.Gelatin + accumulated
    playerData.GelatinLifetime = playerData.GelatinLifetime + accumulated

    -- Reset accumulé
    playerData.AccumulatedProduction[podIndex] = 0

    -- Mettre à jour
    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Notifier client
    local updateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("UpdatePlayerData")
    if updateEvent then
        updateEvent:FireClient(player, playerData)
    end

    print(string.format("[Production] 💧 %s a collecté %.0f gélatine (Pod %d)", player.Name, accumulated, podIndex))

    -- Mettre à jour contrat
    local ContractManager = require(script.Parent.ContractManager)
    ContractManager.UpdateProgress(player, "Collect", accumulated)

    return true
end

-- ========================================
-- COLLECTER TOUTE LA BASE
-- ========================================

function ProductionManager.CollectAll(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return 0 end

    local totalCollected = 0

    for podIndex, accumulated in pairs(playerData.AccumulatedProduction) do
        if accumulated > 0 then
            totalCollected = totalCollected + accumulated
            playerData.AccumulatedProduction[podIndex] = 0
        end
    end

    if totalCollected > 0 then
        playerData.Gelatin = playerData.Gelatin + totalCollected
        playerData.GelatinLifetime = playerData.GelatinLifetime + totalCollected

        DataStoreManager.UpdatePlayerData(player, playerData)

        -- Notifier client
        local updateEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("UpdatePlayerData")
        if updateEvent then
            updateEvent:FireClient(player, playerData)
        end

        print(string.format("[Production] 💧 %s a collecté %.0f gélatine (TOTAL)", player.Name, totalCollected))

        -- Mettre à jour contrat
        local ContractManager = require(script.Parent.ContractManager)
        ContractManager.UpdateProgress(player, "Collect", totalCollected)
    end

    return totalCollected
end

-- ========================================
-- MISE À JOUR AFFICHAGE PRODUCTION
-- ========================================

function ProductionManager.UpdateProductionDisplay(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local BaseManager = require(script.Parent.BaseManager)
    local baseIndex = BaseManager.GetPlayerBase(player)
    if not baseIndex then return end

    local base = game.Workspace.Base:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local recolte = base:FindFirstChild("Recolte")
    if not recolte then return end

    -- Mettre à jour SR_CollectLabel (total accumulé)
    local totalAccumulated = 0
    for _, amount in pairs(playerData.AccumulatedProduction) do
        totalAccumulated = totalAccumulated + amount
    end

    local collectLabel = recolte.Main.CollectorGui:FindFirstChild("SR_CollectLabel")
    if collectLabel then
        collectLabel.Text = EconomyConfig.FormatNumber(totalAccumulated)
    end

    -- Mettre à jour SR_RateLabel (production/s)
    local productionRate = ProductionManager.CalculateTotalProduction(playerData)

    local rateLabel = recolte.Main.CollectorGui:FindFirstChild("SR_RateLabel")
    if rateLabel then
        rateLabel.Text = string.format("%s/s", EconomyConfig.FormatNumber(productionRate))
    end
end

-- ========================================
-- COLLECTER VIA HITBOX
-- ========================================

function ProductionManager.SetupCollectionHitbox(player, baseIndex)
    local base = game.Workspace.Base:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local recolte = base:FindFirstChild("Recolte")
    if not recolte then return end

    local hitbox = recolte:FindFirstChild("Hitbox")
    if not hitbox then return end

    -- Connecter détection
    hitbox.Touched:Connect(function(hit)
        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            local touchedPlayer = game.Players:GetPlayerFromCharacter(character)

            if touchedPlayer == player then
                -- Collecter toute la production
                ProductionManager.CollectAll(player)
            end
        end
    end)
end

-- ========================================
-- ÉVÉNEMENTS
-- ========================================

Players.PlayerRemoving:Connect(function(player)
    ProductionManager.StopProduction(player)
end)

return ProductionManager
