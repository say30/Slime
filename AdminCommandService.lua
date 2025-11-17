-- ServerScriptService/Systems/AdminCommandService.lua
-- ============================================
-- 🖥️ SERVICE D'EXÉCUTION DES COMMANDES ADMIN - VERSION CORRIGÉE
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("AdminConfig"))
local adminCommand = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminCommand")

-- Services optionnels (si ils existent)
local DataStoreManager = ServerScriptService:FindFirstChild("DataStoreManager")
if not DataStoreManager then
	DataStoreManager = ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("DataStoreManager")
end

if DataStoreManager then
	DataStoreManager = require(DataStoreManager)
	print("[AdminCommandService] ✅ DataStoreManager chargé")
else
	warn("[AdminCommandService] ⚠️ DataStoreManager introuvable")
end

print("[AdminCommandService] 🚀 Service démarré")

-- ============================================
-- 📨 FONCTION : ENVOYER UN MESSAGE AU CLIENT
-- ============================================
local function sendLog(player, messageType, message, color)
	adminCommand:FireClient(player, messageType, message, color)
end

-- ============================================
-- 🔍 FONCTION : TROUVER UN JOUEUR PAR NOM
-- ============================================
local function findPlayer(name)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():find(name:lower(), 1, true) then
			return player
		end
	end
	return nil
end

-- ============================================
-- 🎯 COMMANDES IMPLÉMENTÉES
-- ============================================
local Commands = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📂 CATÉGORIE : JOUEURS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands.GiveGelatine = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local amount = args[2] or 1000000

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		DataStoreManager.AddGelatine(targetPlayer, amount)
		sendLog(admin, "Success", string.format("✅ %d gélatine donnée à %s", amount, targetPlayer.Name))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

Commands.GiveEssence = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local amount = args[2] or 10000

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		DataStoreManager.AddEssence(targetPlayer, amount)
		sendLog(admin, "Success", string.format("✅ %d essence donnée à %s", amount, targetPlayer.Name))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

Commands.TeleportToBase = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local baseNum = args[2] or 1

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	local base = workspace:FindFirstChild("Base") and workspace.Base:FindFirstChild("Base " .. baseNum)
	if not base then
		sendLog(admin, "Error", "Base " .. baseNum .. " introuvable")
		return
	end

	local home = base:FindFirstChild("structure base home", true)
	if home and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		targetPlayer.Character.HumanoidRootPart.CFrame = home.CFrame + Vector3.new(0, 3, 0)
		sendLog(admin, "Success", string.format("✅ %s téléporté à Base %d", targetPlayer.Name, baseNum))
	else
		sendLog(admin, "Error", "Impossible de téléporter")
	end
end

Commands.TeleportToMe = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if admin.Character and admin.Character:FindFirstChild("HumanoidRootPart") and
		targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		targetPlayer.Character.HumanoidRootPart.CFrame = admin.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
		sendLog(admin, "Success", string.format("✅ %s téléporté vers toi", targetPlayer.Name))
	else
		sendLog(admin, "Error", "Impossible de téléporter")
	end
end

Commands.TeleportMeTo = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if admin.Character and admin.Character:FindFirstChild("HumanoidRootPart") and
		targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		admin.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
		sendLog(admin, "Success", string.format("✅ Téléporté vers %s", targetPlayer.Name))
	else
		sendLog(admin, "Error", "Impossible de téléporter")
	end
end

Commands.ViewStats = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		local gelatine = DataStoreManager.GetGelatine(targetPlayer)
		local essence = DataStoreManager.GetEssence(targetPlayer)
		local total = DataStoreManager.GetTotalCollected(targetPlayer)

		sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(255, 255, 100))
		sendLog(admin, "Log", string.format("📊 STATS DE %s", targetPlayer.Name:upper()), Color3.fromRGB(255, 255, 100))
		sendLog(admin, "Log", string.format("💰 Gélatine: %d", gelatine), Color3.fromRGB(200, 200, 200))
		sendLog(admin, "Log", string.format("✨ Essence: %d", essence), Color3.fromRGB(200, 200, 200))
		sendLog(admin, "Log", string.format("📈 Total: %d", total), Color3.fromRGB(200, 200, 200))
		sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(255, 255, 100))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

Commands.ResetData = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		-- Réinitialiser à 100 gélatine
		DataStoreManager.SetGelatine(targetPlayer, 100)
		DataStoreManager.SetEssence(targetPlayer, 0)
		DataStoreManager.SetTotalGelatine(targetPlayer, 0)
		DataStoreManager.ClearAllPods(targetPlayer)
		sendLog(admin, "Success", string.format("✅ Données de %s réinitialisées", targetPlayer.Name))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

Commands.KickPlayer = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	targetPlayer:Kick("Éjecté par un administrateur")
	sendLog(admin, "Success", string.format("✅ %s a été éjecté", targetPlayer.Name))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📂 CATÉGORIE : SLIMES (VERSION CORRIGÉE)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands.SpawnCustomSlime = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local mood = args[2] or "Joyeux"
	local rarity = args[3] or "Commun"
	local size = args[4] or "Petit"
	local state = args[5] or "Normal"

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Slime %s %s %s créé pour %s", mood, size, rarity, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction spawn custom à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.SpawnRandomSlime = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Slime aléatoire créé pour %s", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction spawn random à implémenter", Color3.fromRGB(255, 200, 100))
end

-- ✅ CORRECTION : Supprimer slimes visuels + DataStore
Commands.ClearPlayerSlimes = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	local playerInfo = workspace:FindFirstChild("PlayerInfo")
	if playerInfo then
		local playerFolder = playerInfo:FindFirstChild(targetPlayer.Name)
		if playerFolder then
			-- Supprimer les slimes visuels
			local serverSlimes = playerFolder:FindFirstChild("ServerSlimes")
			local count = 0
			if serverSlimes then
				count = #serverSlimes:GetChildren()
				serverSlimes:ClearAllChildren()
			end

			-- ✅ Supprimer aussi du DataStore
			if DataStoreManager and DataStoreManager.ClearAllPods then
				DataStoreManager.ClearAllPods(targetPlayer)
				sendLog(admin, "Success", string.format("✅ %d slimes supprimés (visuel + sauvegarde) pour %s", count, targetPlayer.Name))
			else
				sendLog(admin, "Success", string.format("✅ %d slimes supprimés visuellement pour %s", count, targetPlayer.Name))
				sendLog(admin, "Log", "⚠️ Données DataStore non supprimées", Color3.fromRGB(255, 200, 100))
			end
		end
	end
end

-- ✅ CORRECTION : Supprimer tous les slimes visuels + DataStore
Commands.ClearAllSlimes = function(admin, args)
	local totalCount = 0
	local playerInfo = workspace:FindFirstChild("PlayerInfo")

	if playerInfo then
		for _, playerFolder in ipairs(playerInfo:GetChildren()) do
			-- Supprimer les slimes visuels
			local serverSlimes = playerFolder:FindFirstChild("ServerSlimes")
			if serverSlimes then
				totalCount = totalCount + #serverSlimes:GetChildren()
				serverSlimes:ClearAllChildren()
			end

			-- ✅ Supprimer aussi du DataStore pour chaque joueur
			local player = Players:FindFirstChild(playerFolder.Name)
			if player and DataStoreManager and DataStoreManager.ClearAllPods then
				DataStoreManager.ClearAllPods(player)
			end
		end
	end

	sendLog(admin, "Success", string.format("✅ %d slimes supprimés du serveur (visuel + sauvegarde)", totalCount))
end

Commands.ListPlayerSlimes = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	local playerInfo = workspace:FindFirstChild("PlayerInfo")
	if playerInfo then
		local playerFolder = playerInfo:FindFirstChild(targetPlayer.Name)
		if playerFolder then
			local serverSlimes = playerFolder:FindFirstChild("ServerSlimes")
			if serverSlimes then
				local slimes = serverSlimes:GetChildren()
				sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(100, 200, 255))
				sendLog(admin, "Log", string.format("📋 SLIMES DE %s (%d)", targetPlayer.Name:upper(), #slimes), Color3.fromRGB(100, 200, 255))

				for i, slime in ipairs(slimes) do
					if slime:IsA("Model") then
						sendLog(admin, "Log", string.format("%d. %s (Pod %d)", i, slime.Name, slime:GetAttribute("PodNumber") or 0), Color3.fromRGB(200, 200, 200))
					end
				end

				sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(100, 200, 255))
			else
				sendLog(admin, "Log", "Aucun slime trouvé")
			end
		end
	end
end

Commands.FillAllPods = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Tous les pods de %s remplis", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction fill pods à implémenter", Color3.fromRGB(255, 200, 100))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📂 CATÉGORIE : ÉCONOMIE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands.UnlockPods = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local count = math.clamp(args[2] or 22, 1, 22)

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ %d pods débloqués pour %s", count, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction unlock pods à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.SetProduction = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local multiplier = args[2] or 10

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Multiplicateur de production ×%d pour %s", multiplier, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction set production à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.GiveCatalyseurMineur = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local quantity = args[2] or 10

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ %d catalyseurs mineurs donnés à %s", quantity, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction give catalyseur à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.GiveCatalyseurStable = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local quantity = args[2] or 5

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ %d catalyseurs stables donnés à %s", quantity, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction give catalyseur à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.GiveCatalyseurParfait = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local quantity = args[2] or 1

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ %d catalyseurs parfaits donnés à %s", quantity, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction give catalyseur à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.SetRebirthLevel = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local level = args[2] or 10

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Niveau rebirth %d pour %s", level, targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction set rebirth à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.MaxInventory = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Inventaire max pour %s", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction max inventory à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.MaxAllResources = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		DataStoreManager.SetGelatine(targetPlayer, 999999999999)
		DataStoreManager.SetEssence(targetPlayer, 999999999)
		sendLog(admin, "Success", string.format("✅ Ressources maximisées pour %s", targetPlayer.Name))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📂 CATÉGORIE : DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands.PrintPlayerData = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager then
		local gelatine = DataStoreManager.GetGelatine(targetPlayer)
		local essence = DataStoreManager.GetEssence(targetPlayer)
		local total = DataStoreManager.GetTotalCollected(targetPlayer)

		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print(string.format("📊 DATA DE %s", targetPlayer.Name:upper()))
		print(string.format("💰 Gélatine: %d", gelatine))
		print(string.format("✨ Essence: %d", essence))
		print(string.format("📈 Total: %d", total))
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

		sendLog(admin, "Success", string.format("✅ Données de %s affichées dans la console", targetPlayer.Name))
	else
		sendLog(admin, "Error", "DataStoreManager introuvable")
	end
end

Commands.PrintServerStats = function(admin, args)
	local playerCount = #Players:GetPlayers()
	local memory = game:GetService("Stats"):GetTotalMemoryUsageMb()

	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("📊 STATS DU SERVEUR")
	print(string.format("👥 Joueurs connectés: %d", playerCount))
	print(string.format("💾 Mémoire utilisée: %.2f MB", memory))
	print(string.format("⏱️ Uptime: %d secondes", math.floor(os.clock())))
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(100, 255, 100))
	sendLog(admin, "Log", "📊 STATS DU SERVEUR", Color3.fromRGB(100, 255, 100))
	sendLog(admin, "Log", string.format("👥 Joueurs: %d", playerCount), Color3.fromRGB(200, 200, 200))
	sendLog(admin, "Log", string.format("💾 Mémoire: %.2f MB", memory), Color3.fromRGB(200, 200, 200))
	sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(100, 255, 100))
end

Commands.ListAllBases = function(admin, args)
	local playerInfo = workspace:FindFirstChild("PlayerInfo")

	if not playerInfo then
		sendLog(admin, "Error", "PlayerInfo introuvable")
		return
	end

	sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(255, 200, 100))
	sendLog(admin, "Log", "🏠 ATTRIBUTION DES BASES", Color3.fromRGB(255, 200, 100))

	for i = 1, 8 do
		local baseAssigned = false
		for _, playerFolder in ipairs(playerInfo:GetChildren()) do
			local baseAttr = playerFolder:GetAttribute("BaseNumber")
			if baseAttr == i then
				sendLog(admin, "Log", string.format("Base %d: %s", i, playerFolder.Name), Color3.fromRGB(200, 200, 200))
				baseAssigned = true
				break
			end
		end

		if not baseAssigned then
			sendLog(admin, "Log", string.format("Base %d: LIBRE", i), Color3.fromRGB(150, 150, 150))
		end
	end

	sendLog(admin, "Log", "━━━━━━━━━━━━━━━━━━━━━━", Color3.fromRGB(255, 200, 100))
end

Commands.CheckDataStore = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ DataStore OK pour %s", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction check datastore à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.ForceSave = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if DataStoreManager and DataStoreManager.SavePlayerData then
		DataStoreManager:SavePlayerData(targetPlayer)
		sendLog(admin, "Success", string.format("✅ Données de %s sauvegardées", targetPlayer.Name))
	else
		sendLog(admin, "Error", "Fonction SavePlayerData introuvable")
	end
end

Commands.ReloadData = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Données de %s rechargées", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction reload data à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.ClearCache = function(admin, args)
	sendLog(admin, "Success", "✅ Cache serveur vidé")
	sendLog(admin, "Log", "⚠️ Fonction clear cache à implémenter", Color3.fromRGB(255, 200, 100))
end

Commands.TestNotification = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Notification test envoyée à %s", targetPlayer.Name))
	-- Envoyer aussi au joueur cible
	sendLog(targetPlayer, "Log", "🔔 Ceci est une notification test !", Color3.fromRGB(255, 255, 100))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📂 CATÉGORIE : UTILITAIRES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands.ToggleGodMode = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local currentGodMode = targetPlayer:GetAttribute("GodMode") or false
			targetPlayer:SetAttribute("GodMode", not currentGodMode)

			if not currentGodMode then
				humanoid.MaxHealth = math.huge
				humanoid.Health = math.huge
				sendLog(admin, "Success", string.format("✅ God Mode ACTIVÉ pour %s", targetPlayer.Name))
			else
				humanoid.MaxHealth = 100
				humanoid.Health = 100
				sendLog(admin, "Success", string.format("✅ God Mode DÉSACTIVÉ pour %s", targetPlayer.Name))
			end
		end
	end
end

Commands.SetWalkspeed = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local speed = args[2] or 100

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speed
			sendLog(admin, "Success", string.format("✅ Vitesse %d pour %s", speed, targetPlayer.Name))
		end
	end
end

Commands.SetJumpPower = function(admin, args)
	local targetPlayer = findPlayer(args[1])
	local power = args[2] or 100

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = power
			sendLog(admin, "Success", string.format("✅ Jump Power %d pour %s", power, targetPlayer.Name))
		end
	end
end

Commands.ToggleNoclip = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Noclip toggle pour %s", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction noclip à implémenter côté client", Color3.fromRGB(255, 200, 100))
end

Commands.ToggleFly = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	sendLog(admin, "Success", string.format("✅ Fly toggle pour %s", targetPlayer.Name))
	sendLog(admin, "Log", "⚠️ Fonction fly à implémenter côté client", Color3.fromRGB(255, 200, 100))
end

Commands.ResetCharacter = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if targetPlayer.Character then
		targetPlayer.Character:BreakJoints()
		sendLog(admin, "Success", string.format("✅ %s réinitialisé", targetPlayer.Name))
	end
end

Commands.HealPlayer = function(admin, args)
	local targetPlayer = findPlayer(args[1])

	if not targetPlayer then
		sendLog(admin, "Error", "Joueur introuvable: " .. tostring(args[1]))
		return
	end

	if targetPlayer.Character then
		local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			sendLog(admin, "Success", string.format("✅ %s soigné", targetPlayer.Name))
		end
	end
end

Commands.RespawnAll = function(admin, args)
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			player.Character:BreakJoints()
			count = count + 1
		end
	end
	sendLog(admin, "Success", string.format("✅ %d joueurs respawn", count))
end

-- ============================================
-- 📡 RÉCEPTION DES COMMANDES
-- ============================================
adminCommand.OnServerEvent:Connect(function(player, commandName, args)
	-- Vérifier les permissions
	if not AdminConfig:IsAdmin(player.UserId) then
		warn(string.format("[AdminCommandService] ❌ %s n'est pas admin", player.Name))
		return
	end

	-- Vérifier que la commande existe
	if not Commands[commandName] then
		sendLog(player, "Error", "Commande inconnue: " .. commandName)
		warn(string.format("[AdminCommandService] ❌ Commande inconnue: %s", commandName))
		return
	end

	-- Exécuter la commande
	print(string.format("[AdminCommandService] ⚡ %s exécute: %s", player.Name, commandName))
	local success, err = pcall(function()
		Commands[commandName](player, args)
	end)

	if not success then
		sendLog(player, "Error", "Erreur: " .. tostring(err))
		warn(string.format("[AdminCommandService] ❌ Erreur: %s", tostring(err)))
	end
end)

print("[AdminCommandService] ✅ Service opérationnel")
