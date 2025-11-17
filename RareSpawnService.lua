--[[
    RareSpawnService.lua
    VERSION CORRIGÉE - Rareté différente à chaque spawn
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local RareSpawnAnnouncementEvent = RemoteEvents:WaitForChild("RareSpawnAnnouncementEvent")
local RareSpawnReadyEvent = RemoteEvents:WaitForChild("RareSpawnReadyEvent")
local UpdateRareTimerEvent = RemoteEvents:WaitForChild("UpdateRareTimerEvent")
local GetRareRarityFunc = RemoteFunctions:WaitForChild("GetCurrentRareRarityFunc")

-- ✅ CORRECTION : 10 minutes = 600 secondes
local RARE_SPAWN_INTERVAL = 1800 -- 10 minutes en secondes
local ANNOUNCEMENT_TIME = 30
local SPAWN_DURATION = 120 -- disponibilité Slime

-- ============================================
-- 🎲 RARETÉS ÉLIGIBLES AVEC PROBABILITÉS
-- ============================================
local ELIGIBLE_RARITIES = {
	{Name = "Épique", Weight = 40},         -- 40%
	{Name = "Légendaire", Weight = 30},     -- 30%
	{Name = "Mythique", Weight = 15},       -- 15%
	{Name = "Occulte", Weight = 8},         -- 8%
	{Name = "Céleste", Weight = 4},         -- 4%
	{Name = "Abyssal", Weight = 2},         -- 2%
	{Name = "Prismatique", Weight = 0.8},   -- 0.8%
	{Name = "Oméga", Weight = 0.2}          -- 0.2%
}

local nextRareSpawnTime = 0
local currentRareRarity = nil
local rareSpawnActive = false
local announcementMade = false
local lastChosenRarity = nil -- ✅ NOUVEAU : Pour éviter les répétitions

-- ============================================
-- 🎲 CHOISIR RARETÉ AVEC POIDS (SANS RÉPÉTITION)
-- ============================================
local function chooseWeightedRareRarity()
	local maxAttempts = 10 -- Éviter boucle infinie
	local attempts = 0
	local chosenRarity

	repeat
		attempts = attempts + 1

		local totalWeight = 0
		for _, rarity in ipairs(ELIGIBLE_RARITIES) do
			totalWeight = totalWeight + rarity.Weight
		end

		local random = math.random() * totalWeight
		local currentWeight = 0

		for _, rarity in ipairs(ELIGIBLE_RARITIES) do
			currentWeight = currentWeight + rarity.Weight
			if random <= currentWeight then
				chosenRarity = SlimeConfig:GetRarityByName(rarity.Name)
				break
			end
		end

		-- ✅ Si c'est la première fois OU si différent de la dernière, accepter
		if not lastChosenRarity or chosenRarity.Name ~= lastChosenRarity.Name then
			break
		end

		-- ✅ Sinon, réessayer (maximum 10 fois)
	until attempts >= maxAttempts

	-- ✅ Mémoriser pour la prochaine fois
	lastChosenRarity = chosenRarity

	print("[RareSpawn] 🎲 Nouvelle rareté choisie:", chosenRarity.Name, "(tentative", attempts .. ")")

	return chosenRarity
end

-- ============================================
-- 📢 ANNONCER LE SPAWN (30s avant)
-- ============================================
local function announceNextRareSpawn()
	if announcementMade then return end
	announcementMade = true

	print("[RareSpawn] 📢 Annonce du spawn:", currentRareRarity.Name)

	for _, player in ipairs(Players:GetPlayers()) do
		RareSpawnAnnouncementEvent:FireClient(player, {
			rarityName = currentRareRarity.Name,
			rarityColor = currentRareRarity.Color,
			timeUntilSpawn = ANNOUNCEMENT_TIME
		})
	end
end

-- ============================================
-- ✨ ACTIVER LE SPAWN
-- ============================================
local function activateRareSpawn()
	rareSpawnActive = true

	print("[RareSpawn] ✨ Spawn activé:", currentRareRarity.Name, "- Disponible pendant", SPAWN_DURATION, "secondes")

	for _, player in ipairs(Players:GetPlayers()) do
		RareSpawnReadyEvent:FireClient(player, {
			rarityName = currentRareRarity.Name,
			rarityColor = currentRareRarity.Color
		})
	end

	-- ✅ CORRECTION : Désactiver le spawn après SPAWN_DURATION
	task.delay(SPAWN_DURATION, function()
		if rareSpawnActive then
			rareSpawnActive = false
			print("[RareSpawn] ⏱️ Spawn expiré (non collecté)")
		end
	end)
end

-- ============================================
-- 📡 REMOTE FUNCTION (Quand le joueur collecte)
-- ============================================
GetRareRarityFunc.OnServerInvoke = function(player)
	if rareSpawnActive and currentRareRarity then
		print("[RareSpawn] ✅", player.Name, "a collecté le spawn rare:", currentRareRarity.Name)

		-- ✅ Désactiver immédiatement
		rareSpawnActive = false

		local rarityToReturn = {
			Name = currentRareRarity.Name,
			Color = currentRareRarity.Color,
			Multiplier = currentRareRarity.Multiplier
		}

		-- ✅ CORRECTION : Choisir IMMÉDIATEMENT la prochaine rareté
		currentRareRarity = chooseWeightedRareRarity()
		announcementMade = false

		-- ✅ Programmer le prochain spawn pour dans 10 minutes
		nextRareSpawnTime = os.time() + RARE_SPAWN_INTERVAL

		print("[RareSpawn] 🔄 Prochain spawn:", currentRareRarity.Name, "dans", RARE_SPAWN_INTERVAL, "secondes")

		return rarityToReturn
	end
	return nil
end

-- ============================================
-- ⏱️ BOUCLE PRINCIPALE
-- ============================================
task.spawn(function()
	-- Attendre 10 secondes au démarrage
	task.wait(10)

	-- ✅ Choisir la PREMIÈRE rareté
	currentRareRarity = chooseWeightedRareRarity()
	nextRareSpawnTime = os.time() + RARE_SPAWN_INTERVAL

	print("[RareSpawn] 🚀 Service démarré - Premier spawn:", currentRareRarity.Name, "dans", RARE_SPAWN_INTERVAL, "secondes")

	while true do
		local now = os.time()
		local timeRemaining = nextRareSpawnTime - now

		-- Envoyer le timer à tous les joueurs
		for _, player in ipairs(Players:GetPlayers()) do
			UpdateRareTimerEvent:FireClient(player, {
				rarityName = currentRareRarity.Name,
				rarityColor = currentRareRarity.Color,
				timeRemaining = math.max(0, timeRemaining),
				shouldReveal = timeRemaining <= ANNOUNCEMENT_TIME
			})
		end

		-- ✅ Annoncer 30s avant
		if timeRemaining <= ANNOUNCEMENT_TIME and timeRemaining > 0 then
			announceNextRareSpawn()
		end

		-- ✅ Activer le spawn quand le timer atteint 0
		if timeRemaining <= 0 and not rareSpawnActive then
			activateRareSpawn()
		end

		task.wait(1)
	end
end)

print("[RareSpawnService] ✅ Service chargé")
