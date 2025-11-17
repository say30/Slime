--[[
    FusionHandler.lua
    Gestion des fusions côté serveur (hardcore)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Modules
local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))
local FusionConfig = require(ReplicatedStorage.Modules.Shared:WaitForChild("FusionConfig"))
local SlimeConfig = require(ReplicatedStorage.Modules.Shared:WaitForChild("SlimeConfig"))
local SlimeCalculator = require(ReplicatedStorage.Modules.Shared:WaitForChild("SlimeCalculator"))

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local StartFusionEvent = RemoteEvents:WaitForChild("StartFusionEvent")
local ClaimFusionResultEvent = RemoteEvents:WaitForChild("ClaimFusionResultEvent")
local SkipFusionTimerEvent = RemoteEvents:WaitForChild("SkipFusionTimerEvent")

print("[FusionHandler] ✅ Service initialisé")

-- ============================================
-- 🔍 VALIDATION DES SLIMES
-- ============================================

local function validateSlimes(player, slotIndices)
	local inventory = DataStoreManager.GetInventory(player)
	local slimes = {}

	for _, index in ipairs(slotIndices) do
		local item = inventory.Items[index]

		if not item then
			return false, "Slot " .. index .. " vide"
		end

		if item.type ~= "slime" then
			return false, "Le slot " .. index .. " n'est pas un slime"
		end

		table.insert(slimes, {
			index = index,
			data = item
		})
	end

	return true, slimes
end

-- ============================================
-- ⚡ DÉMARRER UNE FUSION
-- ============================================

StartFusionEvent.OnServerEvent:Connect(function(player, fusionType, slotIndices, catalystIndex)
	print("[Fusion] 🎯 Demande de fusion de", player.Name, "- Type:", fusionType)

	-- Vérifier si une fusion est déjà en cours
	if DataStoreManager.GetActiveFusion(player) then
		warn("[Fusion] ❌ Une fusion est déjà en cours")
		return
	end

	-- Valider les slimes
	local success, slimes = validateSlimes(player, slotIndices)
	if not success then
		warn("[Fusion] ❌ Validation échouée:", slimes)
		return
	end

	-- Valider selon le type de fusion
	local isValid, errorOrType

	if fusionType == "Fusion2" then
		if #slimes ~= 2 then
			warn("[Fusion] ❌ Fusion à 2 nécessite exactement 2 slimes")
			return
		end

		isValid, errorOrType = FusionConfig:ValidateFusion2(slimes[1].data, slimes[2].data)

		if not isValid then
			warn("[Fusion] ❌ Validation Fusion2:", errorOrType)
			return
		end

	elseif fusionType == "Fusion3" then
		if #slimes ~= 3 then
			warn("[Fusion] ❌ Fusion à 3 nécessite exactement 3 slimes")
			return
		end

		isValid, errorOrType = FusionConfig:ValidateFusion3(slimes[1].data, slimes[2].data, slimes[3].data)

		if not isValid then
			warn("[Fusion] ❌ Validation Fusion3:", errorOrType)
			return
		end
	else
		warn("[Fusion] ❌ Type de fusion invalide:", fusionType)
		return
	end

	-- Récupérer le catalyseur (optionnel)
	local catalyst = nil
	local catalystBonus = 0

	if catalystIndex then
		local inventory = DataStoreManager.GetInventory(player)
		local catalystItem = inventory.Items[catalystIndex]

		if catalystItem and catalystItem.type == "catalyst" then
			catalyst = {
				index = catalystIndex,
				type = catalystItem.catalystType
			}
			catalystBonus = FusionConfig:GetCatalystBonus(catalystItem.catalystType)
			print("[Fusion] ⚡ Catalyseur détecté:", catalystItem.catalystType, "- Bonus:", catalystBonus .. "%")
		end
	end

	-- Calculer les coûts
	local costs, timer, chance
	local slime1 = slimes[1].data

	if fusionType == "Fusion2" then
		costs = FusionConfig:CalculateFusion2Cost(slime1.rarity, slime1.sizeName, slime1.state or "Aucun")
		timer = FusionConfig:CalculateFusion2Timer(slime1.rarity, slime1.sizeName, slime1.state or "Aucun")
		chance = FusionConfig:CalculateFusion2Chance(slime1.rarity, slime1.sizeName, catalystBonus)
	else
		costs = FusionConfig:CalculateFusion3Cost(slime1.rarity, slime1.sizeName)
		timer = FusionConfig:CalculateFusion3Timer(slime1.rarity, slime1.sizeName)
		chance = FusionConfig:CalculateFusion3Chance(errorOrType, slime1.rarity, slime1.sizeName, catalystBonus)
	end

	print("[Fusion] 💰 Coûts - Gélatine:", costs.gelatin, "Essence:", costs.essence)
	print("[Fusion] ⏱️ Timer:", timer, "secondes")
	print("[Fusion] 🎲 Chance:", chance .. "%")

	-- Vérifier les ressources
	local currentGelatin = DataStoreManager.GetGelatine(player)
	local currentEssence = DataStoreManager.GetEssence(player)

	if currentGelatin < costs.gelatin then
		warn("[Fusion] ❌ Gélatine insuffisante:", currentGelatin, "/", costs.gelatin)
		return
	end

	if currentEssence < costs.essence then
		warn("[Fusion] ❌ Essence insuffisante:", currentEssence, "/", costs.essence)
		return
	end

	-- Retirer les ressources
	DataStoreManager.RemoveGelatine(player, costs.gelatin)
	DataStoreManager.RemoveEssence(player, costs.essence)

	print("[Fusion] 💸 Ressources retirées")

	-- Retirer les slimes de l'inventaire (en ordre inverse pour éviter les décalages d'index)
	table.sort(slotIndices, function(a, b) return a > b end)

	local removedSlimes = {}
	for _, index in ipairs(slotIndices) do
		local slimeData = DataStoreManager.RemoveFromInventory(player, index)
		if slimeData then
			table.insert(removedSlimes, slimeData)
		end
	end

	print("[Fusion] 🗑️ Slimes retirés de l'inventaire:", #removedSlimes)

	-- Consommer le catalyseur
	if catalyst then
		DataStoreManager.RemoveFromInventory(player, catalyst.index)
		print("[Fusion] ⚡ Catalyseur consommé:", catalyst.type)
	end

	-- Créer la fusion active
	local fusionData = {
		type = fusionType,
		fusionSubType = errorOrType,  -- Pour Fusion3: "Mood", "Rarity" ou "Size"
		slimes = removedSlimes,
		catalyst = catalyst,
		startTime = os.time(),
		duration = timer,
		chance = chance,
		costs = costs
	}

	local fusionId = DataStoreManager.CreateActiveFusion(player, fusionData)

	print("[Fusion] ✅ Fusion lancée - ID:", fusionId, "- Fin dans", timer, "secondes")
end)

-- ============================================
-- 🎁 CLAIM RÉSULTAT
-- ============================================

ClaimFusionResultEvent.OnServerEvent:Connect(function(player)
	print("[Fusion] 🎁 Demande de claim résultat de", player.Name)

	local fusion = DataStoreManager.GetActiveFusion(player)

	if not fusion then
		warn("[Fusion] ❌ Aucune fusion active")
		return
	end

	-- Vérifier si la fusion est terminée
	if not DataStoreManager.IsFusionComplete(player) then
		local remaining = DataStoreManager.GetFusionTimeRemaining(player)
		warn("[Fusion] ❌ Fusion pas encore terminée - Reste:", remaining, "secondes")
		return
	end

	-- Calculer le résultat
	local roll = math.random(1, 100)
	local success = roll <= fusion.chance

	print("[Fusion] 🎲 Roll:", roll, "/ Chance:", fusion.chance, "→", success and "✅ SUCCÈS" or "❌ ÉCHEC")

	if success then
		-- ✅ SUCCÈS - Créer le nouveau slime
		local baseSlime = fusion.slimes[1]
		local newSlime = {
			type = "slime",
			mood = baseSlime.mood,
			rarity = baseSlime.rarity,
			sizeName = baseSlime.sizeName,
			state = baseSlime.state or "Aucun",
			storedAt = os.time()
		}

		if fusion.type == "Fusion2" then
			-- Améliorer l'état
			newSlime.state = FusionConfig:GetNextState(baseSlime.state or "Aucun")
			print("[Fusion] ✅ Nouvel état:", newSlime.state)

		elseif fusion.type == "Fusion3" then
			if fusion.fusionSubType == "Mood" then
				-- Mood aléatoire
				local moods = SlimeConfig.Moods
				newSlime.mood = moods[math.random(1, #moods)].Name
				print("[Fusion] ✅ Nouveau mood:", newSlime.mood)

			elseif fusion.fusionSubType == "Rarity" then
				-- Rareté supérieure
				local rarities = SlimeConfig.Rarities
				for i, r in ipairs(rarities) do
					if r.Name == baseSlime.rarity then
						newSlime.rarity = rarities[math.min(i + 1, #rarities)].Name
						break
					end
				end
				print("[Fusion] ✅ Nouvelle rareté:", newSlime.rarity)

			elseif fusion.fusionSubType == "Size" then
				-- Taille supérieure
				local sizes = SlimeConfig.Sizes
				for i, s in ipairs(sizes) do
					if s.Name == baseSlime.sizeName then
						newSlime.sizeName = sizes[math.min(i + 1, #sizes)].Name
						break
					end
				end
				print("[Fusion] ✅ Nouvelle taille:", newSlime.sizeName)
			end
		end

		-- Recalculer production et coût
		newSlime.production = SlimeCalculator:CalculateProduction(
			newSlime.mood, 
			newSlime.rarity, 
			newSlime.sizeName, 
			newSlime.state
		)
		newSlime.cost = SlimeCalculator:CalculateCost(
			newSlime.production, 
			newSlime.mood, 
			newSlime.rarity, 
			newSlime.sizeName, 
			newSlime.state
		)

		-- Ajouter à l'inventaire
		DataStoreManager.AddToInventory(player, newSlime)

		print("[Fusion] ✅ Nouveau slime ajouté:", newSlime.mood, newSlime.sizeName, newSlime.rarity, newSlime.state)

	else
		-- ❌ ÉCHEC - Compensation
		local totalValue = 0
		for _, slime in ipairs(fusion.slimes) do
			totalValue = totalValue + (slime.cost or 0)
		end

		local compensation = FusionConfig:CalculateFailCompensation(totalValue)

		DataStoreManager.AddGelatine(player, compensation.gelatin)
		DataStoreManager.AddEssence(player, compensation.essence)

		print("[Fusion] 💔 Compensation - Gélatine:", compensation.gelatin, "Essence:", compensation.essence)
	end

	-- Supprimer la fusion active
	DataStoreManager.RemoveActiveFusion(player)

	-- ✅ ENVOYER LE RÉSULTAT AU CLIENT
	local FusionResultEvent = RemoteEvents:FindFirstChild("FusionResultEvent")

	if FusionResultEvent then
		if success then
			FusionResultEvent:FireClient(player, true, newSlime)
		else
			FusionResultEvent:FireClient(player, false, compensation)
		end
	end

	-- Mettre à jour l'inventaire client
	local RequestInventoryEvent = RemoteEvents:FindFirstChild("RequestInventoryEvent")
	if RequestInventoryEvent then
		local inventory = DataStoreManager.GetInventory(player)
		RequestInventoryEvent:FireClient(player, inventory)
	end

	print("[Fusion] ✅ Résultat traité et envoyé au client")
end)


-- ============================================
-- ⏱️ MISE À JOUR DES TIMERS DE FUSION
-- ============================================

task.spawn(function()
	while true do
		task.wait(1)

		for _, player in ipairs(Players:GetPlayers()) do
			local fusion = DataStoreManager.GetActiveFusion(player)

			if fusion then
				local elapsed = os.time() - fusion.startTime
				local remaining = math.max(fusion.duration - elapsed, 0)

				-- Mettre à jour l'attribut pour le client
				local PlayerInfo = workspace:FindFirstChild("PlayerInfo")
				if PlayerInfo then
					local playerFolder = PlayerInfo:FindFirstChild(player.Name)
					if playerFolder then
						playerFolder:SetAttribute("FusionTimeRemaining", remaining)
						playerFolder:SetAttribute("FusionTotalDuration", fusion.duration)
					end
				end
			else
				-- Pas de fusion, retirer les attributs
				local PlayerInfo = workspace:FindFirstChild("PlayerInfo")
				if PlayerInfo then
					local playerFolder = PlayerInfo:FindFirstChild(player.Name)
					if playerFolder then
						playerFolder:SetAttribute("FusionTimeRemaining", nil)
						playerFolder:SetAttribute("FusionTotalDuration", nil)
					end
				end
			end
		end
	end
end)

print("[FusionHandler] ⏱️ Boucle de mise à jour des timers lancée")

-- ============================================
-- ⏭️ SKIP TIMER (ROBUX)
-- ============================================

SkipFusionTimerEvent.OnServerEvent:Connect(function(player)
	print("[Fusion] ⏭️ Demande de skip timer de", player.Name)

	local fusion = DataStoreManager.GetActiveFusion(player)

	if not fusion then
		warn("[Fusion] ❌ Aucune fusion active")
		return
	end

	-- Calculer le coût en Robux
	local remaining = DataStoreManager.GetFusionTimeRemaining(player)
	local robuxCost = FusionConfig:CalculateSkipCost(remaining)

	print("[Fusion] 💎 Coût skip:", robuxCost, "Robux pour", remaining, "secondes")

	-- Prompt achat Robux
	local success, result = pcall(function()
		MarketplaceService:PromptProductPurchase(player, robuxCost)  -- TODO: Créer un Developer Product
	end)

	if success then
		-- Le processus de paiement sera géré par ProcessReceipt
		print("[Fusion] 💎 Prompt Robux affiché")
	else
		warn("[Fusion] ❌ Erreur prompt Robux:", result)
	end
end)

print("[FusionHandler] ✅ Service chargé")
