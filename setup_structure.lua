-- ========================================
-- SLIME RUSH - SETUP STRUCTURE COMPLÈTE
-- À exécuter dans Command Bar (Studio)
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

print("🚀 Démarrage setup Slime Rush...")

-- ========================================
-- 1. REPLICATED STORAGE
-- ========================================

-- Modules folder
local modulesFolder = ReplicatedStorage:FindFirstChild("Modules") or Instance.new("Folder")
modulesFolder.Name = "Modules"
modulesFolder.Parent = ReplicatedStorage

-- RemoteEvents folder
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder")
remoteFolder.Name = "RemoteEvents"
remoteFolder.Parent = ReplicatedStorage

-- Liste des RemoteEvents
local remoteEvents = {
    "PurchaseSlime",
    "CollectGelatin",
    "FuseSlimes",
    "PlaceSlime",
    "SellSlime",
    "BuyShopItem",
    "ClaimContract",
    "LikeBase",
    "BuyUpgrade",
    "ActivateBoost",
    "UpdateSlimeDex",
    "DoRebirth",
    "SkipFusionTimer",
    "RequestSlimeList",
    "RequestBaseTP",
    "UpdateContractProgress"
}

for _, eventName in ipairs(remoteEvents) do
    if not remoteFolder:FindFirstChild(eventName) then
        local re = Instance.new("RemoteEvent")
        re.Name = eventName
        re.Parent = remoteFolder
        print("✓ RemoteEvent créé:", eventName)
    end
end

-- RemoteFunctions
local remoteFunctions = {
    "GetPlayerData",
    "GetShopItems",
    "GetContracts",
    "GetSlimeDex"
}

for _, funcName in ipairs(remoteFunctions) do
    if not remoteFolder:FindFirstChild(funcName) then
        local rf = Instance.new("RemoteFunction")
        rf.Name = funcName
        rf.Parent = remoteFolder
        print("✓ RemoteFunction créée:", funcName)
    end
end

-- ========================================
-- 2. WORKSPACE
-- ========================================

-- LocalSlimes folder (pour slimes locaux par joueur)
local localSlimesFolder = Workspace:FindFirstChild("LocalSlimes") or Instance.new("Folder")
localSlimesFolder.Name = "LocalSlimes"
localSlimesFolder.Parent = Workspace
print("✓ Dossier LocalSlimes créé")

-- PlayerBases folder (pour slimes serveur par base)
local playerBasesFolder = Workspace:FindFirstChild("PlayerBases") or Instance.new("Folder")
playerBasesFolder.Name = "PlayerBases"
playerBasesFolder.Parent = Workspace
print("✓ Dossier PlayerBases créé")

-- ========================================
-- 3. SERVER SCRIPT SERVICE
-- ========================================

-- Vérifier que les scripts existent (on ne crée que le dossier structure)
local serverScriptsNeeded = {
    "MainServer",
    "BaseManager",
    "SlimeSpawner",
    "ProductionManager",
    "DataStoreManager",
    "ShopManager",
    "ContractManager",
    "FusionHandler",
    "RebirthHandler",
    "EventManager",
    "ServerMatchmaking"
}

print("📋 Scripts serveur requis:", #serverScriptsNeeded)

-- ========================================
-- 4. STARTER PLAYER
-- ========================================

local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then
    starterPlayerScripts = Instance.new("Folder")
    starterPlayerScripts.Name = "StarterPlayerScripts"
    starterPlayerScripts.Parent = StarterPlayer
end

print("✓ StarterPlayerScripts prêt")

-- ========================================
-- 5. STARTER GUI
-- ========================================

-- Créer structure UI folders
local uiFolders = {
    "MainHUD",
    "FusionUI",
    "InventoryUI",
    "ShopUI",
    "ContractUI",
    "UpgradeUI",
    "SlimeDexUI",
    "NotificationUI"
}

for _, folderName in ipairs(uiFolders) do
    if not StarterGui:FindFirstChild(folderName) then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = folderName
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = StarterGui
        print("✓ ScreenGui créé:", folderName)
    end
end

-- ========================================
-- 6. VALIDATION WORKSPACE EXISTANT
-- ========================================

-- Vérifier structure Base
local baseFolder = Workspace:FindFirstChild("Base")
if baseFolder then
    print("✓ Dossier Base trouvé")
    for i = 1, 8 do
        local base = baseFolder:FindFirstChild("Base " .. i)
        if base then
            -- Vérifier sous-structures
            local podsSlime = base:FindFirstChild("PodsSlime")
            local panneau = base:FindFirstChild("Panneau")
            local recolte = base:FindFirstChild("Recolte")
            local structure = base:FindFirstChild("structure base home")

            if podsSlime and panneau and recolte and structure then
                print("✓ Base " .. i .. " - Structure complète")
            else
                warn("⚠ Base " .. i .. " - Structure incomplète")
            end
        end
    end
else
    warn("⚠ Dossier Base non trouvé dans Workspace")
end

-- Vérifier DropPlate
if Workspace:FindFirstChild("DropPlate") then
    print("✓ DropPlate trouvé")
else
    warn("⚠ DropPlate non trouvé")
end

-- Vérifier MapCenter
if Workspace:FindFirstChild("MapCenter") then
    print("✓ MapCenter trouvé")
else
    warn("⚠ MapCenter non trouvé")
end

-- Vérifier Slimes
if ReplicatedStorage:FindFirstChild("Slimes") then
    print("✓ Dossier Slimes trouvé")
else
    warn("⚠ Dossier Slimes non trouvé dans ReplicatedStorage")
end

print("✅ Setup structure terminé !")
print("📝 Prochaine étape : Créer les scripts ModuleScript et Scripts")
