--[[
    SlimeProductionService.lua
    VERSION AVEC ACCUMULATION OFFLINE (MAX 5H)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)
local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))

print("[SlimeProductionService] 🚀 Démarrage du service...")

-- ============================================
-- ⏱️ CONSTANTES
-- ============================================
local MAX_OFFLINE_TIME = 5 * 60 * 60 -- 5 heures en secondes

-- ============================================
-- 📊 CALCULER LA PRODUCTION TOTALE
-- ============================================
local function calculateTotalProduction(player)
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return 0 end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return 0 end

	local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
	if not serverSlimesFolder then return 0 end

	local totalProduction = 0
	for _, slime in ipairs(serverSlimesFolder:GetChildren()) do
		if slime:IsA("Model") then
			local production = slime:GetAttribute("Production") or 0
			totalProduction = totalProduction + production
		end
	end

	return math.floor(totalProduction)
end

-- ============================================
-- 📊 METTRE À JOUR L'AFFICHAGE
-- ============================================
local function updateCollectorDisplay(player, accumulated, productionRate)
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return end

	local baseNumber = playerFolder:GetAttribute("BaseNumber")
	if not baseNumber then return end

	local base = Workspace.Base:FindFirstChild("Base " .. baseNumber)
	if not base then return end

	local recolte = base:FindFirstChild("Recolte")
	if not recolte then return end

	local main = recolte:FindFirstChild("Main")
	if not main then return end

	local collectorGui = main:FindFirstChild("CollectorGui")
	if not collectorGui then return end

	-- Mettre à jour SR_CollectLabel (gélatine accumulée)
	local collectLabel = collectorGui:FindFirstChild("SR_CollectLabel")
	if collectLabel and collectLabel:IsA("TextLabel") then
		collectLabel.Text = FormatNumbers:Format(math.floor(accumulated))
	end

	-- Mettre à jour SR_RateLabel (production/s)
	local rateLabel = collectorGui:FindFirstChild("SR_RateLabel")
	if rateLabel and rateLabel:IsA("TextLabel") then
		rateLabel.Text = FormatNumbers:Format(productionRate) .. "/s"
	end
end

-- ============================================
-- 💰 CALCULER L'ACCUMULATION OFFLINE
-- ============================================
local function calculateOfflineProduction(player)
	local lastTime = DataStoreManager.GetLastCollectionTime(player)
	local currentTime = os.time()
	local elapsedTime = currentTime - lastTime

	-- Limiter à 5 heures maximum
	if elapsedTime > MAX_OFFLINE_TIME then
		elapsedTime = MAX_OFFLINE_TIME
	end

	-- Calculer la production pendant l'absence
	local productionRate = calculateTotalProduction(player)
	local offlineProduction = productionRate * elapsedTime

	return math.floor(offlineProduction), elapsedTime
end

-- ============================================
-- 🎮 INITIALISER JOUEUR
-- ============================================
local function initializePlayer(player)
	-- Attendre que PlayerInfo soit créé
	task.wait(1)

	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return end

	-- Calculer la production offline
	local offlineProd, offlineTime = calculateOfflineProduction(player)

	if offlineProd > 0 and offlineTime > 0 then
		-- Ajouter à l'accumulateur
		DataStoreManager.AddToAccumulated(player, offlineProd)

		-- Mettre à jour le NumberValue
		local accumulatedValue = playerFolder:FindFirstChild("AccumulatedGelatin")
		if accumulatedValue then
			accumulatedValue.Value = DataStoreManager.GetAccumulatedGelatin(player)
		end

		-- Afficher le message au joueur
		local hours = math.floor(offlineTime / 3600)
		local minutes = math.floor((offlineTime % 3600) / 60)

		print(string.format("[Production] 💰 %s était absent %dh%dm - Produit : %d gélatine", 
			player.Name, hours, minutes, offlineProd))
	end

	-- Mettre à jour le temps
	DataStoreManager.UpdateLastCollectionTime(player)

	-- Afficher initial
	local productionRate = calculateTotalProduction(player)
	local accumulated = DataStoreManager.GetAccumulatedGelatin(player)
	updateCollectorDisplay(player, accumulated, productionRate)
end

-- ============================================
-- ⏱️ BOUCLE DE PRODUCTION
-- ============================================
task.spawn(function()
	while true do
		task.wait(1) -- Toutes les 1 seconde

		for _, player in ipairs(Players:GetPlayers()) do
			local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
			if not PlayerInfo then continue end

			local playerFolder = PlayerInfo:FindFirstChild(player.Name)
			if not playerFolder then continue end

			-- Calculer production
			local totalProduction = calculateTotalProduction(player)
			if totalProduction <= 0 then continue end

			-- ✅ ACCUMULER DANS PLAYERINFO (pas dans Base)
			DataStoreManager.AddToAccumulated(player, totalProduction)

			-- Mettre à jour le NumberValue
			local accumulatedValue = playerFolder:FindFirstChild("AccumulatedGelatin")
			if accumulatedValue then
				accumulatedValue.Value = DataStoreManager.GetAccumulatedGelatin(player)
			end

			-- Mettre à jour l'affichage
			local accumulated = DataStoreManager.GetAccumulatedGelatin(player)
			updateCollectorDisplay(player, accumulated, totalProduction)
		end
	end
end)

-- ============================================
-- 👤 CONNEXION JOUEUR
-- ============================================
Players.PlayerAdded:Connect(function(player)
	initializePlayer(player)
end)

print("[SlimeProductionService] ✅ Service chargé")
