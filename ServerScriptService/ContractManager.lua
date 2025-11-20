-- ========================================
-- SLIME RUSH - CONTRACT MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/ContractManager
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ContractConfig = require(ReplicatedStorage.Modules.ContractConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)

local ContractManager = {}

-- ========================================
-- INITIALISER CONTRATS JOUEUR
-- ========================================

function ContractManager.InitializeContracts(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Vérifier reset journalier
    local nextReset = ContractConfig.GetNextResetTime()
    if os.time() >= playerData.LastContractReset + 86400 then
        -- Générer nouveaux contrats
        local contractCount = ContractConfig.Settings.DailyContracts
        if playerData.Gamepasses and playerData.Gamepasses.VIPPremium then
            contractCount = contractCount + ContractConfig.Settings.VIPBonus
        end

        local selectedIDs = ContractConfig.GenerateDailyContracts(contractCount, os.time())

        playerData.DailyContracts = {}
        for _, id in ipairs(selectedIDs) do
            table.insert(playerData.DailyContracts, {
                ID = id,
                Progress = 0,
                Claimed = false
            })
        end

        playerData.LastContractReset = os.time()

        DataStoreManager.UpdatePlayerData(player, playerData)

        print(string.format("[ContractManager] 🔄 Contrats réinitialisés pour %s", player.Name))
    end
end

-- ========================================
-- METTRE À JOUR PROGRESSION
-- ========================================

function ContractManager.UpdateProgress(player, progressType, amount)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Mettre à jour stats tracking
    if progressType == "Purchase" then
        playerData.ContractProgress.TotalPurchased = (playerData.ContractProgress.TotalPurchased or 0) + amount
    elseif progressType == "FusionSuccess" then
        playerData.ContractProgress.TotalFusionSuccess = (playerData.ContractProgress.TotalFusionSuccess or 0) + amount
    elseif progressType == "FusionAttempt" then
        playerData.ContractProgress.TotalFusionAttempts = (playerData.ContractProgress.TotalFusionAttempts or 0) + amount
    elseif progressType == "FusionFail" then
        playerData.ContractProgress.TotalFusionFail = (playerData.ContractProgress.TotalFusionFail or 0) + amount
    elseif progressType == "Collect" then
        playerData.ContractProgress.TotalCollected = (playerData.ContractProgress.TotalCollected or 0) + amount
    elseif progressType == "Sell" then
        playerData.ContractProgress.TotalSold = (playerData.ContractProgress.TotalSold or 0) + amount
    elseif progressType == "LikeBases" then
        playerData.ContractProgress.TotalLikes = (playerData.ContractProgress.TotalLikes or 0) + amount
    end

    -- Vérifier contrats actifs
    for _, contract in ipairs(playerData.DailyContracts) do
        if not contract.Claimed then
            local contractData = ContractConfig.GetContract(contract.ID)
            if contractData and contractData.Type == progressType then
                contract.Progress = math.min(contractData.Goal, contract.Progress + amount)
            end
        end
    end

    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Notifier client
    ReplicatedStorage.RemoteEvents.UpdateContractProgress:FireClient(player, playerData.DailyContracts)
end

-- ========================================
-- RÉCLAMER RÉCOMPENSE
-- ========================================

function ContractManager.ClaimReward(player, contractID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Trouver contrat
    for _, contract in ipairs(playerData.DailyContracts) do
        if contract.ID == contractID and not contract.Claimed then
            local contractData = ContractConfig.GetContract(contractID)
            if not contractData then return end

            -- Vérifier completion
            if contract.Progress >= contractData.Goal then
                -- Donner récompenses
                playerData.Gelatin = playerData.Gelatin + (contractData.Rewards.Gelatin or 0)
                playerData.Essence = playerData.Essence + (contractData.Rewards.Essence or 0)

                if contractData.Rewards.Catalyst then
                    DataManager.AddCatalyst(playerData, contractData.Rewards.Catalyst, 1)
                end

                -- Marquer comme réclamé
                contract.Claimed = true

                DataStoreManager.UpdatePlayerData(player, playerData)

                -- Notifier client
                ReplicatedStorage.RemoteEvents.ClaimContract:FireClient(player, true, contractData.Rewards)

                print(string.format("[ContractManager] ✅ %s a réclamé contrat %d", player.Name, contractID))
            end
        end
    end
end

return ContractManager
