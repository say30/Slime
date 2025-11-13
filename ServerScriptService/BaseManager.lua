-- ========================================
-- SLIME RUSH - BASE MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/BaseManager
-- ========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

local BaseManager = {}

-- ========================================
-- CONFIGURATION
-- ========================================
local BASE_FOLDER = Workspace:WaitForChild("Base")
local TOTAL_BASES = 8
local BasesAssignments = {} -- {[BaseIndex] = Player}
local PlayerBases = {} -- {[UserId] = BaseIndex}

-- ========================================
-- ATTRIBUTION BASE
-- ========================================

function BaseManager.AssignBaseToPlayer(player)
    -- Vérifier si déjà assigné
    if PlayerBases[player.UserId] then
        print(string.format("[BaseManager] %s a déjà une base: Base %d", player.Name, PlayerBases[player.UserId]))
        return PlayerBases[player.UserId]
    end

    -- Trouver base libre
    for i = 1, TOTAL_BASES do
        if not BasesAssignments[i] then
            -- Base libre trouvée
            BasesAssignments[i] = player
            PlayerBases[player.UserId] = i

            print(string.format("[BaseManager] ✅ %s assigné à Base %d", player.Name, i))

            -- Mettre à jour panneau
            BaseManager.UpdateBasePanneau(i, player)

            -- Initialiser production
            BaseManager.InitializeBaseProduction(i, player)

            return i
        end
    end

    -- Aucune base disponible (serveur plein)
    warn(string.format("[BaseManager] ⚠️ Aucune base disponible pour %s", player.Name))
    return nil
end

-- ========================================
-- LIBÉRER BASE
-- ========================================

function BaseManager.ReleaseBase(player)
    local baseIndex = PlayerBases[player.UserId]

    if baseIndex then
        BasesAssignments[baseIndex] = nil
        PlayerBases[player.UserId] = nil

        print(string.format("[BaseManager] 🔓 Base %d libérée (joueur: %s)", baseIndex, player.Name))

        -- Nettoyer panneau
        BaseManager.ClearBasePanneau(baseIndex)

        -- Nettoyer slimes
        BaseManager.ClearBaseSlimes(baseIndex)
    end
end

-- ========================================
-- MISE À JOUR PANNEAU
-- ========================================

function BaseManager.UpdateBasePanneau(baseIndex, player)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local panneau = base:FindFirstChild("Panneau")
    if not panneau then return end

    local titleLabel = panneau:FindFirstChild("Part"):FindFirstChild("SurfaceGui"):FindFirstChild("MainFrame"):FindFirstChild("TitleLabel")

    if titleLabel then
        titleLabel.Text = string.format("Base de %s", player.Name)
    end
end

function BaseManager.ClearBasePanneau(baseIndex)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local panneau = base:FindFirstChild("Panneau")
    if not panneau then return end

    local titleLabel = panneau:FindFirstChild("Part"):FindFirstChild("SurfaceGui"):FindFirstChild("MainFrame"):FindFirstChild("TitleLabel")
    local likeCount = panneau:FindFirstChild("Part"):FindFirstChild("SurfaceGui"):FindFirstChild("MainFrame"):FindFirstChild("LikeContainer"):FindFirstChild("LikeCount")

    if titleLabel then
        titleLabel.Text = "Base Libre"
    end

    if likeCount then
        likeCount.Text = "0"
    end
end

-- ========================================
-- INITIALISATION PRODUCTION
-- ========================================

function BaseManager.InitializeBaseProduction(baseIndex, player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Créer dossier PlayerBases pour ce joueur
    local playerBasesFolder = Workspace:FindFirstChild("PlayerBases")
    if not playerBasesFolder then
        playerBasesFolder = Instance.new("Folder")
        playerBasesFolder.Name = "PlayerBases"
        playerBasesFolder.Parent = Workspace
    end

    local playerFolder = playerBasesFolder:FindFirstChild("Player_" .. player.UserId)
    if not playerFolder then
        playerFolder = Instance.new("Folder")
        playerFolder.Name = "Player_" .. player.UserId
        playerFolder.Parent = playerBasesFolder
    end

    -- Recréer slimes depuis données
    BaseManager.LoadPlacedSlimes(baseIndex, player)
end

-- ========================================
-- CHARGER SLIMES PLACÉS
-- ========================================

function BaseManager.LoadPlacedSlimes(baseIndex, player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData or not playerData.PlacedSlimes then return end

    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local podsSlimeFolder = base:FindFirstChild("PodsSlime")
    if not podsSlimeFolder then return end

    -- Pour chaque slime placé dans les données
    for podIndex, slimeData in pairs(playerData.PlacedSlimes) do
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. podIndex)
        if pod then
            -- Appeler SlimeSpawner pour créer le slime serveur
            local SlimeSpawner = require(script.Parent.SlimeSpawner)
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, podIndex)
        end
    end

    print(string.format("[BaseManager] ✅ Slimes chargés pour %s (Base %d)", player.Name, baseIndex))
end

-- ========================================
-- NETTOYER SLIMES BASE
-- ========================================

function BaseManager.ClearBaseSlimes(baseIndex)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local podsSlimeFolder = base:FindFirstChild("PodsSlime")
    if not podsSlimeFolder then return end

    -- Supprimer tous les slimes dans les pods
    for _, pod in ipairs(podsSlimeFolder:GetChildren()) do
        for _, child in ipairs(pod:GetChildren()) do
            if child:IsA("Model") and child.Name:find("Slime") then
                child:Destroy()
            end
        end
    end
end

-- ========================================
-- OBTENIR BASE D'UN JOUEUR
-- ========================================

function BaseManager.GetPlayerBase(player)
    return PlayerBases[player.UserId]
end

-- ========================================
-- OBTENIR JOUEUR D'UNE BASE
-- ========================================

function BaseManager.GetBaseOwner(baseIndex)
    return BasesAssignments[baseIndex]
end

-- ========================================
-- VÉRIFIER PODS DISPONIBLES
-- ========================================

function BaseManager.GetAvailablePod(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return nil end

    local unlockedPods = EconomyConfig.GetUnlockedPods(playerData.BaseLevel)

    -- Chercher premier pod libre
    for i = 1, unlockedPods do
        if not playerData.PlacedSlimes[i] then
            return i
        end
    end

    return nil -- Aucun pod disponible
end

-- ========================================
-- OBTENIR BASE INDEX PAR POSITION
-- ========================================

function BaseManager.GetBaseIndexFromPosition(position)
    -- Trouve la base la plus proche d'une position
    local closestBase = nil
    local closestDistance = math.huge

    for i = 1, TOTAL_BASES do
        local base = BASE_FOLDER:FindFirstChild("Base " .. i)
        if base then
            local basePos = base:GetPivot().Position
            local distance = (basePos - position).Magnitude

            if distance < closestDistance then
                closestDistance = distance
                closestBase = i
            end
        end
    end

    return closestBase
end

-- ========================================
-- ÉVÉNEMENTS
-- ========================================

-- Libérer base à la déconnexion
Players.PlayerRemoving:Connect(function(player)
    BaseManager.ReleaseBase(player)
end)

-- ========================================
-- EXPORT
-- ========================================

return BaseManager
