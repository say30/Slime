--[[
    ProximityPromptService.lua
    VERSION 2 ONGLETS - Appel direct au stockage
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))

-- Remote pour notifier le client
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestInventoryEvent = RemoteEvents:WaitForChild("RequestInventoryEvent")

print("[ProximityPrompt] ✅ Service initialisé")

-- ============================================
-- 🎒 FONCTION DE STOCKAGE (DIRECTE)
-- ============================================
local function storeSlime(player, slimeModel)
	if not slimeModel or not slimeModel:IsA("Model") then
		warn("[ProximityPrompt] ❌ Modèle invalide")
		return
	end

	-- Vérifier que c'est bien le slime du joueur
	local owner = slimeModel:GetAttribute("Owner")
	if owner ~= player.Name then
		warn("[ProximityPrompt] ❌ Ce n'est pas votre slime")
		return
	end

	-- ✅ EXTRAIRE TOUTES LES DONNÉES AVEC COST
	local slimeData = {
		type = "slime", -- ✅ NOUVEAU
		mood = slimeModel:GetAttribute("Mood"),
		sizeName = slimeModel:GetAttribute("Size"),
		rarity = slimeModel:GetAttribute("Rarity"),
		production = slimeModel:GetAttribute("Production"),
		cost = slimeModel:GetAttribute("Cost") or 0, -- ✅ IMPORTANT
		state = slimeModel:GetAttribute("State") or "Aucun",
		storedAt = os.time()
	}

	print("[ProximityPrompt] 📊 Données extraites - Cost:", slimeData.cost)

	-- Sauvegarder le pod number avant de le retirer
	local podNumber = slimeModel:GetAttribute("PodNumber")
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	local playerFolder = PlayerInfo and PlayerInfo:FindFirstChild(player.Name)
	local baseNumber = playerFolder and playerFolder:GetAttribute("BaseNumber")

	-- Ajouter à l'inventaire
	local success = DataStoreManager.AddToInventory(player, slimeData)

	if success then
		-- Retirer du pod
		if baseNumber and podNumber then
			local baseName = "Base " .. baseNumber
			DataStoreManager.RemovePod(player, baseName, podNumber)
		end

		-- Détruire le modèle 3D
		slimeModel:Destroy()

		-- Envoyer l'inventaire mis à jour au client
		local inventory = DataStoreManager.GetInventory(player)
		RequestInventoryEvent:FireClient(player, inventory)

		print("[ProximityPrompt] ✅", player.Name, "a stocké:", slimeData.mood, slimeData.sizeName, "- Cost:", slimeData.cost)
	else
		warn("[ProximityPrompt] ❌ Échec du stockage (inventaire plein ?)")
	end
end

-- ============================================
-- 🔧 CRÉER UN PROXIMITY PROMPT
-- ============================================
local function createProximityPrompt(slimeModel, player)
	-- Vérifier si le prompt existe déjà
	if slimeModel:FindFirstChild("StorePrompt") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StorePrompt"
	prompt.ActionText = "Stocker dans l'inventaire"
	prompt.ObjectText = slimeModel.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0.5

	-- Trouver la partie principale du slime
	local primaryPart = slimeModel.PrimaryPart or slimeModel:FindFirstChildWhichIsA("BasePart")
	if primaryPart then
		prompt.Parent = primaryPart
	else
		warn("[ProximityPrompt] ⚠️ Pas de BasePart trouvée pour", slimeModel.Name)
		return
	end

	-- Appel direct à la fonction de stockage
	prompt.Triggered:Connect(function(playerWhoTriggered)
		-- Vérifier que c'est le propriétaire
		local owner = slimeModel:GetAttribute("Owner")
		if owner ~= playerWhoTriggered.Name then
			warn("[ProximityPrompt] ❌ Ce n'est pas votre slime")
			return
		end

		-- Appeler directement la fonction de stockage
		storeSlime(playerWhoTriggered, slimeModel)
	end)

	print("[ProximityPrompt] ✅ Prompt ajouté sur", slimeModel.Name)
end

-- ============================================
-- 🔄 SURVEILLER LES NOUVEAUX SLIMES
-- ============================================
local function monitorPlayerSlimes(player)
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then
		warn("[ProximityPrompt] ⚠️ PlayerInfo introuvable")
		return
	end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then
		warn("[ProximityPrompt] ⚠️ Dossier joueur introuvable")
		return
	end

	local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
	if not serverSlimesFolder then
		warn("[ProximityPrompt] ⚠️ ServerSlimes introuvable")
		return
	end

	-- Ajouter des prompts aux slimes existants
	for _, slime in ipairs(serverSlimesFolder:GetChildren()) do
		if slime:IsA("Model") then
			createProximityPrompt(slime, player)
		end
	end

	-- Surveiller les nouveaux slimes
	serverSlimesFolder.ChildAdded:Connect(function(slime)
		if slime:IsA("Model") then
			task.wait(0.1) -- Attendre que le slime soit complètement chargé
			createProximityPrompt(slime, player)
		end
	end)

	print("[ProximityPrompt] 🔍 Surveillance active pour", player.Name)
end

-- ============================================
-- 🎮 ÉVÉNEMENTS JOUEURS
-- ============================================
Players.PlayerAdded:Connect(function(player)
	-- Attendre que tout soit chargé
	task.wait(5)
	monitorPlayerSlimes(player)
end)

-- Pour les joueurs déjà connectés
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(5)
		monitorPlayerSlimes(player)
	end)
end

print("[ProximityPromptService] ✅ Service chargé")
