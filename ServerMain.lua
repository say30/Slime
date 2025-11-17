--[[
    ServerMain.lua
    VERSION AVEC ACCUMULATION OFFLINE
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local workspace = game:GetService("Workspace")

-- Modules
local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))
local BaseManager = require(script.Parent.BaseManager)

-- Stockage
local PlayerData = {}
local playerToBase = {}

-- ============================================
-- 🎮 INITIALISATION
-- ============================================
print("[ServerMain] 🚀 Démarrage du serveur...")

BaseManager:Initialize()

if not workspace:FindFirstChild("PlayerInfo") then
	local folder = Instance.new("Folder")
	folder.Name = "PlayerInfo"
	folder.Parent = workspace
end

print("[ServerMain] ✅ Serveur initialisé")

-- ============================================
-- 📍 TÉLÉPORTATION
-- ============================================
local function teleportToBase(player, baseNumber)
	local base = workspace.Base:FindFirstChild("Base " .. baseNumber)
	if not base then return end

	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		local tries = 0
		while not hrp and tries < 60 do
			hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then break end
			tries = tries + 1
			task.wait(0.05)
		end
	end
	local home = base:FindFirstChild("structure base home", true)

	if hrp and home and home:IsA("BasePart") then
		hrp.CFrame = CFrame.new(home.Position + Vector3.new(0, 3, 0))
		print("[ServerMain] ✅ " .. player.Name .. " téléporté à Base " .. baseNumber)
	end
end

local function onCharacterAdded(player)
	local baseNumber = playerToBase[player]
	if baseNumber then
		teleportToBase(player, baseNumber)
	end
end

-- ============================================
-- 👤 CONNEXION JOUEUR
-- ============================================
Players.PlayerAdded:Connect(function(player)
	print("[ServerMain] 👋 " .. player.Name .. " se connecte...")

	-- 1. Assigner base
	local baseNumber = BaseManager:AssignBase(player)

	if not baseNumber then
		player:Kick("Serveur plein - Reconnectez-vous")
		return
	end

	playerToBase[player] = baseNumber

	-- 2. Charger données
	local data = DataStoreManager:LoadPlayerData(player)
	PlayerData[player] = data

	-- 3. Connecter CharacterAdded
	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)

	if player.Character then
		onCharacterAdded(player)
	end

	-- 4. CRÉER STRUCTURE PLAYERINFO
	local playerInfoFolder = workspace.PlayerInfo:FindFirstChild(player.Name)
	if not playerInfoFolder then
		playerInfoFolder = Instance.new("Folder")
		playerInfoFolder.Name = player.Name
		playerInfoFolder.Parent = workspace.PlayerInfo

		-- ✅ Attribute BaseNumber
		playerInfoFolder:SetAttribute("BaseNumber", baseNumber)

		-- NumberValues pour les ressources
		local gelatinValue = Instance.new("NumberValue")
		gelatinValue.Name = "CurrentGelatin"
		gelatinValue.Value = data.Gelatin or 0
		gelatinValue.Parent = playerInfoFolder

		local essenceValue = Instance.new("NumberValue")
		essenceValue.Name = "CurrentEssence"
		essenceValue.Value = data.Essence or 0
		essenceValue.Parent = playerInfoFolder

		local productionValue = Instance.new("NumberValue")
		productionValue.Name = "ProductionRate"
		productionValue.Value = 0
		productionValue.Parent = playerInfoFolder

		-- ✅ NOUVEAU : Accumulateur dans PlayerInfo
		local accumulatedValue = Instance.new("NumberValue")
		accumulatedValue.Name = "AccumulatedGelatin"
		accumulatedValue.Value = data.AccumulatedGelatin or 0
		accumulatedValue.Parent = playerInfoFolder

		-- Dossiers pour les slimes
		local localSlimesFolder = Instance.new("Folder")
		localSlimesFolder.Name = "LocalSlimes"
		localSlimesFolder.Parent = playerInfoFolder

		local serverSlimesFolder = Instance.new("Folder")
		serverSlimesFolder.Name = "ServerSlimes"
		serverSlimesFolder.Parent = playerInfoFolder

		print("[ServerMain] 📊 PlayerInfo créé pour " .. player.Name)
	end

	-- 5. INITIALISER DATASTOREMANAGER
	DataStoreManager.InitializePlayerData(player)

	print("[ServerMain] ✅ " .. player.Name .. " connecté à Base " .. baseNumber)
end)

-- ============================================
-- 👋 DÉCONNEXION
-- ============================================
Players.PlayerRemoving:Connect(function(player)
	print("[ServerMain] 👋 " .. player.Name .. " se déconnecte...")

	local data = PlayerData[player]
	if data then
		DataStoreManager:SavePlayerData(player, data)
	end

	DataStoreManager.CleanupPlayerData(player)

	BaseManager:FreeBase(player)

	local playerInfoFolder = workspace.PlayerInfo:FindFirstChild(player.Name)
	if playerInfoFolder then
		playerInfoFolder:Destroy()
	end

	PlayerData[player] = nil
	playerToBase[player] = nil

	print("[ServerMain] ✅ " .. player.Name .. " déconnecté")
end)

-- ============================================
-- 💾 AUTO-SAVE
-- ============================================
task.spawn(function()
	while true do
		task.wait(300)
		print("[ServerMain] 💾 Auto-save...")
		for player, data in pairs(PlayerData) do
			if player and player.Parent then
				DataStoreManager:SavePlayerData(player, data)
			end
		end
		print("[ServerMain] ✅ Auto-save terminé")
	end
end)

-- ============================================
-- 🔧 FONCTIONS GLOBALES
-- ============================================
_G.GetPlayerData = function(player) 
	return PlayerData[player] 
end

_G.GetPlayerBaseNumber = function(player) 
	return playerToBase[player] 
end

_G.GetPlayerInfoFolder = function(player)
	return workspace.PlayerInfo:FindFirstChild(player.Name)
end

_G.GetPlayerLocalSlimesFolder = function(player)
	local info = workspace.PlayerInfo:FindFirstChild(player.Name)
	return info and info:FindFirstChild("LocalSlimes")
end

_G.GetPlayerServerSlimesFolder = function(player)
	local info = workspace.PlayerInfo:FindFirstChild(player.Name)
	return info and info:FindFirstChild("ServerSlimes")
end

_G.PlayerData = PlayerData

_G.UpdatePlayerResource = function(player, resourceType, amount)
	local data = PlayerData[player]
	if not data then return false end

	if resourceType == "Gelatin" then
		data.Gelatin = amount
		local folder = workspace.PlayerInfo:FindFirstChild(player.Name)
		if folder and folder:FindFirstChild("CurrentGelatin") then
			folder.CurrentGelatin.Value = amount
		end
	elseif resourceType == "Essence" then
		data.Essence = amount
		local folder = workspace.PlayerInfo:FindFirstChild(player.Name)
		if folder and folder:FindFirstChild("CurrentEssence") then
			folder.CurrentEssence.Value = amount
		end
	end
	return true
end

print("[ServerMain] ✅ Tous les systèmes opérationnels")
