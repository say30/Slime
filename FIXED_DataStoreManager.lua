-- ========================================
-- SLIME RUSH - DATASTORE MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/DataStoreManager
-- ========================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ReplicatedStorage.Modules.DataManager)

-- ========================================
-- CONFIGURATION
-- ========================================
local DATA_STORE_NAME = "SlimeRushData_V1"
local AUTO_SAVE_INTERVAL = 300
local MAX_RETRY_ATTEMPTS = 3
local RETRY_DELAY = 2

local PlayerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
local DataStoreManager = {}

local PlayerDataCache = {}
local SaveQueue = {}

-- ========================================
-- FONCTIONS INTERNES
-- ========================================

local function RetryOperation(operation, maxRetries)
    for attempt = 1, maxRetries do
        local success, result = pcall(operation)
        if success then
            return true, result
        else
            warn(string.format("[DataStore] Tentative %d/%d échouée: %s", attempt, maxRetries, tostring(result)))
            if attempt < maxRetries then
                wait(RETRY_DELAY * attempt)
            end
        end
    end
    return false, nil
end

-- ========================================
-- CHARGEMENT DONNÉES
-- ========================================

function DataStoreManager.LoadData(player)
    local userId = "Player_" .. player.UserId

    print(string.format("[DataStore] Chargement données pour %s (UserID: %d)", player.Name, player.UserId))

    local success, data = RetryOperation(function()
        return PlayerDataStore:GetAsync(userId)
    end, MAX_RETRY_ATTEMPTS)

    if success then
        if data then
            data = DataManager.MergeData(data)

            if DataManager.ValidateData(data) then
                PlayerDataCache[player.UserId] = data
                print(string.format("[DataStore] ✅ Données chargées pour %s", player.Name))
                return data
            else
                warn(string.format("[DataStore] ⚠️ Données corrompues pour %s", player.Name))
                local newData = DataManager.CreateNewPlayerData()
                PlayerDataCache[player.UserId] = newData
                return newData
            end
        else
            print(string.format("[DataStore] 🆕 Nouveau joueur: %s", player.Name))
            local newData = DataManager.CreateNewPlayerData()
            PlayerDataCache[player.UserId] = newData
            return newData
        end
    else
        warn(string.format("[DataStore] ❌ Échec chargement pour %s", player.Name))
        local tempData = DataManager.CreateNewPlayerData()
        PlayerDataCache[player.UserId] = tempData
        return tempData
    end
end

-- ========================================
-- SAUVEGARDE DONNÉES
-- ========================================

function DataStoreManager.SaveData(player, forceImmediate)
    if not player or not player:IsDescendantOf(Players) then
        return false
    end

    local data = PlayerDataCache[player.UserId]
    if not data then
        warn(string.format("[DataStore] ⚠️ Aucune donnée pour %s", player.Name))
        return false
    end

    DataManager.UpdatePlayTime(data)
    local cleanedData = DataManager.CleanData(data)

    if forceImmediate then
        local userId = "Player_" .. player.UserId

        local success, err = RetryOperation(function()
            PlayerDataStore:SetAsync(userId, cleanedData)
        end, MAX_RETRY_ATTEMPTS)

        if success then
            print(string.format("[DataStore] ✅ Sauvegarde réussie pour %s", player.Name))
            return true
        else
            warn(string.format("[DataStore] ❌ Échec sauvegarde pour %s", player.Name))
            return false
        end
    else
        SaveQueue[player.UserId] = {
            Player = player,
            Data = cleanedData,
            Timestamp = tick()
        }
        return true
    end
end

function DataStoreManager.GetPlayerData(player)
    return PlayerDataCache[player.UserId]
end

function DataStoreManager.UpdatePlayerData(player, updatedData)
    if PlayerDataCache[player.UserId] then
        PlayerDataCache[player.UserId] = updatedData
        return true
    end
    return false
end

-- ========================================
-- AUTO-SAVE
-- ========================================

local function ProcessSaveQueue()
    for userId, saveData in pairs(SaveQueue) do
        local player = saveData.Player
        if player and player:IsDescendantOf(Players) then
            local success = DataStoreManager.SaveData(player, true)
            if success then
                SaveQueue[userId] = nil
            end
        else
            SaveQueue[userId] = nil
        end
    end
end

spawn(function()
    while true do
        wait(AUTO_SAVE_INTERVAL)
        print("[DataStore] 🔄 Auto-save...")
        ProcessSaveQueue()

        for _, player in ipairs(Players:GetPlayers()) do
            DataStoreManager.SaveData(player, false)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print(string.format("[DataStore] 👋 Sauvegarde finale pour %s", player.Name))
    DataStoreManager.SaveData(player, true)
    PlayerDataCache[player.UserId] = nil
end)

game:BindToClose(function()
    print("[DataStore] 🛑 Fermeture serveur...")

    for _, player in ipairs(Players:GetPlayers()) do
        DataStoreManager.SaveData(player, true)
    end

    wait(2)
    print("[DataStore] ✅ Sauvegardes terminées")
end)

return DataStoreManager
