--[[
    DataStoreManager.lua
    VERSION AVEC INVENTAIRE 2 ONGLETS + ACCUMULATION OFFLINE
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataStore = DataStoreService:GetDataStore("SlimeRushData_V1")
local playerData = {} -- Cache en mémoire

local DataStoreManager = {}

-- ============================================
-- 📋 DONNÉES PAR DÉFAUT
-- ============================================
local DEFAULT_DATA = {
	Gelatin = 100,
	Essence = 0,
	TotalGelatinCollected = 0,
	AccumulatedGelatin = 0,
	LastCollectionTime = os.time(),
	BaseLevel = 0,
	ProductionUpgradeLevel = 0,
	InventoryUpgradeLevel = 0,
	RebirthCount = 0,
	RebirthMultiplier = 1.0,
	PlacedSlimes = {},
	Inventory = {
		Items = {}, -- ✅ NOUVEAU : Slimes + Objets
		MaxSlots = 20
	},
	SlimeDex = {},
	ActiveContracts = {
		dailyContracts = {}, -- Les 3 contrats du jour
		lastReset = 0, -- Timestamp du dernier reset
		progress = {} -- Progression de chaque contrat
	},
	ActiveBoosts = {},
	Statistics = {
		TotalSlimesPurchased = 0,
		TotalFusionsAttempted = 0,
		TotalFusionsSuccess = 0,
		TotalSlimesSold = 0,
		TotalUpgradesBought = 0,
		TotalBasesLiked = 0,
		PlayTimeSeconds = 0
	},
	LikesGiven = {},
	ActiveFusions = {}, -- Structure: {fusionId, type, slimes, catalyst, startTime, duration, etc.}
	LastSaveTime = os.time()
}

-- ============================================
-- 🔄 HELPER - Deep Copy
-- ============================================
local function DeepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- ============================================
-- 🔄 HELPER - Deep Merge
-- ============================================
local function DeepMerge(default, saved)
	local merged = {}
	for key, defaultValue in pairs(default) do
		if saved[key] ~= nil then
			if type(defaultValue) == "table" and type(saved[key]) == "table" then
				merged[key] = DeepMerge(defaultValue, saved[key])
			else
				merged[key] = saved[key]
			end
		else
			merged[key] = defaultValue
		end
	end
	for key, savedValue in pairs(saved) do
		if merged[key] == nil then
			merged[key] = savedValue
		end
	end
	return merged
end

-- ============================================
-- 📥 CHARGEMENT DES DONNÉES
-- ============================================
function DataStoreManager:LoadPlayerData(player)
	local userId = player.UserId
	local success, data
	local attempts = 0
	local maxAttempts = 3

	print("[DataStore] 🔍 Chargement pour", player.Name, "- UserId:", userId)

	repeat
		attempts = attempts + 1
		success, data = pcall(function()
			return PlayerDataStore:GetAsync("Player_" .. userId)
		end)

		if not success then
			warn("[DataStore] Échec chargement (tentative " .. attempts .. "/3)")
			if attempts < maxAttempts then
				task.wait(2 ^ attempts)
			end
		end
	until success or attempts >= maxAttempts

	local finalData

	if success and data then
		print("[DataStore] ✅ Données existantes trouvées")
		finalData = DeepMerge(DEFAULT_DATA, data)

		if finalData.Gelatin == 0 then
			warn("[DataStore] ⚠️ Gélatine à 0 détectée - Reset à 100")
			finalData.Gelatin = 100
		end

		-- ✅ Migration ancien système vers nouveau
		if finalData.Inventory and finalData.Inventory.Slimes and not finalData.Inventory.Items then
			print("[DataStore] 🔄 Migration inventaire vers nouveau système")
			finalData.Inventory.Items = {}
			for _, slime in ipairs(finalData.Inventory.Slimes) do
				slime.type = "slime"
				table.insert(finalData.Inventory.Items, slime)
			end
			finalData.Inventory.Slimes = nil
		end
	else
		print("[DataStore] ⚠️ Nouvelles données créées")
		finalData = DeepCopy(DEFAULT_DATA)
	end

	-- ✅ INITIALISER LE CACHE
	playerData[userId] = {
		gelatine = finalData.Gelatin or 100,
		essence = finalData.Essence or 0,
		totalCollected = finalData.TotalGelatinCollected or 0,
		pods = finalData.PlacedSlimes or {},
		accumulatedGelatin = finalData.AccumulatedGelatin or 0,
		lastCollectionTime = finalData.LastCollectionTime or os.time(),
		inventory = {
			Items = finalData.Inventory and finalData.Inventory.Items or {},
			MaxSlots = finalData.Inventory and finalData.Inventory.MaxSlots or 20
		},
		contracts = {
			dailyContracts = finalData.ActiveContracts and finalData.ActiveContracts.dailyContracts or {},
			lastReset = finalData.ActiveContracts and finalData.ActiveContracts.lastReset or 0,
			progress = finalData.ActiveContracts and finalData.ActiveContracts.progress or {}
		},
		activeFusion = finalData.ActiveFusion
	}

	print("[DataStore] 💾 Cache initialisé pour UserId:", userId)
	print("[DataStore] 💰 Gélatine:", playerData[userId].gelatine)
	print("[DataStore] ✨ Essence:", playerData[userId].essence)
	print("[DataStore] 📊 Total:", playerData[userId].totalCollected)
	print("[DataStore] 💧 Accumulé:", playerData[userId].accumulatedGelatin)
	print("[DataStore] 🎒 Inventaire:", #playerData[userId].inventory.Items, "/", playerData[userId].inventory.MaxSlots)

	task.wait(0.5)
	DataStoreManager.SyncCurrency(player)

	return finalData
end

-- ============================================
-- 💾 SAUVEGARDE DES DONNÉES
-- ============================================
function DataStoreManager:SavePlayerData(player, data)
	local userId = player.UserId
	local success
	local attempts = 0
	local maxAttempts = 3

	if not data then
		data = DeepCopy(DEFAULT_DATA)
	end

	-- ✅ SYNCHRONISER LE CACHE
	if playerData[userId] then
		data.Gelatin = playerData[userId].gelatine
		data.Essence = playerData[userId].essence
		data.TotalGelatinCollected = playerData[userId].totalCollected
		data.PlacedSlimes = playerData[userId].pods
		data.AccumulatedGelatin = playerData[userId].accumulatedGelatin
		data.LastCollectionTime = playerData[userId].lastCollectionTime
		data.Inventory = {
			Items = playerData[userId].inventory.Items or {},
			MaxSlots = playerData[userId].inventory.MaxSlots or 20
		}
		data.ActiveContracts = {
			dailyContracts = playerData[userId].contracts.dailyContracts or {},
			lastReset = playerData[userId].contracts.lastReset or 0,
			progress = playerData[userId].contracts.progress or {}
		}
		data.ActiveFusion = playerData[userId].activeFusion
	end

	data.LastSaveTime = os.time()

	repeat
		attempts = attempts + 1
		success = pcall(function()
			PlayerDataStore:SetAsync("Player_" .. userId, data)
		end)

		if not success then
			warn("[DataStore] Échec sauvegarde (tentative " .. attempts .. "/3)")
			if attempts < maxAttempts then
				task.wait(2 ^ attempts)
			end
		end
	until success or attempts >= maxAttempts

	if success then
		print("[DataStore] ✅ Données sauvegardées pour " .. player.Name)
		return true
	else
		warn("[DataStore] ❌ ÉCHEC CRITIQUE sauvegarde")
		return false
	end
end

-- ============================================
-- 🔄 INITIALISATION
-- ============================================
function DataStoreManager.InitializePlayerData(player)
	local userId = player.UserId

	if playerData[userId] then
		print("[DataStore] ⚠️ Cache déjà existant pour", player.Name)
		return
	end

	print("[DataStore] 🔄 Initialisation manuelle du cache pour", player.Name)

	playerData[userId] = {
		gelatine = 100,
		essence = 0,
		totalCollected = 0,
		pods = {},
		accumulatedGelatin = 0,
		lastCollectionTime = os.time(),
		inventory = {
			Items = {},
			MaxSlots = 20
		},
		contracts = {
			dailyContracts = {},
			lastReset = 0,
			progress = {}
		},
		activeFusion = nil
	}

	DataStoreManager.SyncCurrency(player)
end

-- ============================================
-- 💰 GESTION DE LA GÉLATINE
-- ============================================
function DataStoreManager.GetGelatine(player)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ CACHE NON INITIALISÉ ! Initialisation forcée...")
		DataStoreManager.InitializePlayerData(player)
	end

	return playerData[userId].gelatine or 0
end

function DataStoreManager.AddGelatine(player, amount)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ Cache non initialisé dans AddGelatine")
		return false
	end

	playerData[userId].gelatine = (playerData[userId].gelatine or 0) + amount
	playerData[userId].totalCollected = (playerData[userId].totalCollected or 0) + amount

	print("[DataStore] ➕ Ajout", amount, "gélatine - Total:", playerData[userId].gelatine)

	DataStoreManager.SyncCurrency(player)
	return true
end

function DataStoreManager.RemoveGelatine(player, amount)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ Cache non initialisé dans RemoveGelatine")
		return false
	end

	local current = playerData[userId].gelatine or 0

	if current < amount then
		warn("[DataStore] ❌ Gélatine insuffisante -", current, "/", amount)
		return false
	end

	playerData[userId].gelatine = current - amount
	DataStoreManager.SyncCurrency(player)
	return true
end

function DataStoreManager.SetGelatine(player, amount)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ Cache non initialisé dans SetGelatine")
		return false
	end

	playerData[userId].gelatine = amount
	print("[DataStore] 🔧 Gélatine définie à:", amount)

	DataStoreManager.SyncCurrency(player)
	return true
end

-- ============================================
-- ✨ GESTION DE L'ESSENCE
-- ============================================
function DataStoreManager.GetEssence(player)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].essence or 0
end

function DataStoreManager.AddEssence(player, amount)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].essence = (playerData[player.UserId].essence or 0) + amount
	DataStoreManager.SyncCurrency(player)
	return true
end

function DataStoreManager.RemoveEssence(player, amount)
	if not playerData[player.UserId] then return false end
	local current = playerData[player.UserId].essence or 0
	if current < amount then return false end
	playerData[player.UserId].essence = current - amount
	DataStoreManager.SyncCurrency(player)
	return true
end

function DataStoreManager.SetEssence(player, amount)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ Cache non initialisé dans SetEssence")
		return false
	end

	playerData[userId].essence = amount
	print("[DataStore] 🔧 Essence définie à:", amount)

	DataStoreManager.SyncCurrency(player)
	return true
end

-- ============================================
-- 📊 TOTAL RÉCOLTÉ
-- ============================================
function DataStoreManager.GetTotalCollected(player)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].totalCollected or 0
end

function DataStoreManager.GetTotalGelatine(player)
	return DataStoreManager.GetTotalCollected(player)
end

function DataStoreManager.SetTotalGelatine(player, amount)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ❌ Cache non initialisé dans SetTotalGelatine")
		return false
	end

	playerData[userId].totalCollected = amount
	print("[DataStore] 🔧 Total récolté défini à:", amount)

	DataStoreManager.SyncCurrency(player)
	return true
end

-- ============================================
-- 💰 GESTION DE L'ACCUMULATION
-- ============================================
function DataStoreManager.GetAccumulatedGelatin(player)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].accumulatedGelatin or 0
end

function DataStoreManager.SetAccumulatedGelatin(player, amount)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].accumulatedGelatin = amount
	return true
end

function DataStoreManager.AddToAccumulated(player, amount)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].accumulatedGelatin = (playerData[player.UserId].accumulatedGelatin or 0) + amount
	return true
end

function DataStoreManager.GetLastCollectionTime(player)
	if not playerData[player.UserId] then return os.time() end
	return playerData[player.UserId].lastCollectionTime or os.time()
end

function DataStoreManager.UpdateLastCollectionTime(player)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].lastCollectionTime = os.time()
	return true
end

-- ============================================
-- 🏠 GESTION DES PODS
-- ============================================
function DataStoreManager.GetPods(player)
	if not playerData[player.UserId] then return {} end
	return playerData[player.UserId].pods or {}
end

function DataStoreManager.AddPod(player, podData)
	if not playerData[player.UserId] then return false end
	if not playerData[player.UserId].pods then
		playerData[player.UserId].pods = {}
	end
	table.insert(playerData[player.UserId].pods, podData)
	print("[DataStore] ✅ Pod ajouté:", podData.baseName, podData.podNumber)
	return true
end

function DataStoreManager.RemovePod(player, baseName, podNumber)
	if not playerData[player.UserId] or not playerData[player.UserId].pods then return false end
	for i, pod in ipairs(playerData[player.UserId].pods) do
		if pod.baseName == baseName and pod.podNumber == podNumber then
			table.remove(playerData[player.UserId].pods, i)
			print("[DataStore] ✅ Pod retiré:", baseName, podNumber)
			return true
		end
	end
	return false
end

function DataStoreManager.ClearAllPods(player)
	local userId = player.UserId

	if not playerData[userId] then
		warn("[DataStore] ⚠️ Pas de cache pour", player.Name)
		return false
	end

	playerData[userId].pods = {}
	print("[DataStore] 🗑️ Tous les pods supprimés pour", player.Name)

	DataStoreManager:SavePlayerData(player)
	return true
end

-- ============================================
-- 🎒 GESTION DE L'INVENTAIRE (VERSION 2 ONGLETS)
-- ============================================

-- Récupérer l'inventaire complet
function DataStoreManager.GetInventory(player)
	if not playerData[player.UserId] then 
		return {Items = {}, MaxSlots = 20} 
	end

	if not playerData[player.UserId].inventory then
		playerData[player.UserId].inventory = {Items = {}, MaxSlots = 20}
	end

	return playerData[player.UserId].inventory
end

-- Ajouter un item (slime ou objet)
function DataStoreManager.AddToInventory(player, itemData)
	local userId = player.UserId
	if not playerData[userId] then return false end

	if not playerData[userId].inventory then
		playerData[userId].inventory = {Items = {}, MaxSlots = 20}
	end

	local inventory = playerData[userId].inventory

	if not inventory.MaxSlots then
		inventory.MaxSlots = 20
	end

	if not inventory.Items then
		inventory.Items = {}
	end

	-- Vérifier si l'inventaire est plein
	if #inventory.Items >= inventory.MaxSlots then
		warn("[DataStore] ❌ Inventaire plein")
		return false
	end

	-- Ajouter le type si pas présent
	if not itemData.type then
		itemData.type = "slime"
	end

	table.insert(inventory.Items, itemData)

	local itemName = itemData.type == "slime" and (itemData.mood .. " " .. itemData.sizeName) or itemData.catalystType
	print("[DataStore] 🎒 Item ajouté à l'inventaire:", itemName)

	return true
end

-- Retirer un item par index
function DataStoreManager.RemoveFromInventory(player, slotIndex)
	local userId = player.UserId
	if not playerData[userId] or not playerData[userId].inventory then return nil end

	local inventory = playerData[userId].inventory
	if slotIndex < 1 or slotIndex > #inventory.Items then return nil end

	local itemData = table.remove(inventory.Items, slotIndex)

	local itemName = itemData.type == "slime" and (itemData.mood .. " " .. itemData.sizeName) or (itemData.catalystType or "item")
	print("[DataStore] 🗑️ Item retiré de l'inventaire:", itemName)

	-- ✅ RÉORGANISER AUTOMATIQUEMENT
	DataStoreManager.CompactInventory(player)

	return itemData
end

-- Compacter l'inventaire (enlever les trous)
function DataStoreManager.CompactInventory(player)
	local userId = player.UserId
	if not playerData[userId] or not playerData[userId].inventory then return false end

	local inventory = playerData[userId].inventory
	local compactedItems = {}

	for _, item in ipairs(inventory.Items) do
		if item then
			table.insert(compactedItems, item)
		end
	end

	inventory.Items = compactedItems

	print("[DataStore] 🔄 Inventaire réorganisé -", #compactedItems, "items")
	return true
end

-- Obtenir le nombre total d'items
function DataStoreManager.GetInventoryCount(player)
	local inventory = DataStoreManager.GetInventory(player)
	return #inventory.Items
end

-- Obtenir le nombre de slimes uniquement
function DataStoreManager.GetSlimeCount(player)
	local inventory = DataStoreManager.GetInventory(player)
	local count = 0
	for _, item in ipairs(inventory.Items) do
		if item.type == "slime" then
			count = count + 1
		end
	end
	return count
end

-- Obtenir le nombre d'objets uniquement
function DataStoreManager.GetObjectCount(player)
	local inventory = DataStoreManager.GetInventory(player)
	local count = 0
	for _, item in ipairs(inventory.Items) do
		if item.type ~= "slime" then
			count = count + 1
		end
	end
	return count
end

-- Obtenir les slots max
function DataStoreManager.GetMaxSlots(player)
	local inventory = DataStoreManager.GetInventory(player)
	return inventory.MaxSlots or 20
end

-- ============================================
-- 🔄 SYNCHRONISER L'UI CLIENT
-- ============================================
function DataStoreManager.SyncCurrency(player)
	if not playerData[player.UserId] then return end

	local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not RemoteEvents then return end

	local UpdateCurrencyEvent = RemoteEvents:FindFirstChild("UpdateCurrencyEvent")

	if UpdateCurrencyEvent then
		UpdateCurrencyEvent:FireClient(player, {
			gelatine = playerData[player.UserId].gelatine or 0,
			essence = playerData[player.UserId].essence or 0,
			totalCollected = playerData[player.UserId].totalCollected or 0
		})
	end
end

-- ============================================
-- 📋 GESTION DES CONTRATS
-- ============================================

-- Obtenir les contrats actifs
function DataStoreManager.GetActiveContracts(player)
	if not playerData[player.UserId] then return {} end
	return playerData[player.UserId].contracts.dailyContracts or {}
end

-- Définir les contrats du jour
function DataStoreManager.SetDailyContracts(player, contracts)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].contracts.dailyContracts = contracts
	playerData[player.UserId].contracts.lastReset = os.time()
	print("[DataStore] 📋 Contrats quotidiens définis pour", player.Name)
	return true
end

-- Obtenir la progression d'un contrat
function DataStoreManager.GetContractProgress(player, contractId)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].contracts.progress[contractId] or 0
end

-- Mettre à jour la progression d'un contrat
function DataStoreManager.UpdateContractProgress(player, contractId, progress)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].contracts.progress[contractId] = progress
	print("[DataStore] 📊 Progression contrat", contractId, ":", progress)
	return true
end

-- Incrémenter la progression d'un contrat
function DataStoreManager.IncrementContractProgress(player, contractId, amount)
if not playerData[player.UserId] then return false end
local current = playerData[player.UserId].contracts.progress[contractId] or 0
local newValue = current + (amount or 1)
playerData[player.UserId].contracts.progress[contractId] = newValue
print("[DataStore] ➕ Progression contrat", contractId, ":", current, "→", newValue)
return newValue
end

-- Réinitialiser un contrat (après claim)
function DataStoreManager.ResetContract(player, contractId)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].contracts.progress[contractId] = nil
	print("[DataStore] 🔄 Contrat réinitialisé:", contractId)
	return true
end

-- Obtenir le timestamp du dernier reset
function DataStoreManager.GetLastContractReset(player)
	if not playerData[player.UserId] then return 0 end
	return playerData[player.UserId].contracts.lastReset or 0
end

-- Réinitialiser tous les contrats (nouveau jour)
function DataStoreManager.ResetAllContracts(player)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].contracts.dailyContracts = {}
	playerData[player.UserId].contracts.progress = {}
	playerData[player.UserId].contracts.lastReset = os.time()
	print("[DataStore] 🔄 Tous les contrats réinitialisés pour", player.Name)
	return true
end

-- ============================================
-- ⚡ GESTION DES FUSIONS ACTIVES
-- ============================================

-- Créer une nouvelle fusion active
function DataStoreManager.CreateActiveFusion(player, fusionData)
	if not playerData[player.UserId] then return false end

	-- Générer un ID unique
	local fusionId = "fusion_" .. player.UserId .. "_" .. os.time()

	fusionData.fusionId = fusionId
	fusionData.startTime = os.time()

	-- Ajouter aux fusions actives (on garde juste une fusion à la fois pour l'instant)
	playerData[player.UserId].activeFusion = fusionData

	print("[DataStore] ⚡ Fusion créée:", fusionId, "- Type:", fusionData.type, "- Durée:", fusionData.duration .. "s")

	return fusionId
end

-- Récupérer la fusion active
function DataStoreManager.GetActiveFusion(player)
	if not playerData[player.UserId] then return nil end
	return playerData[player.UserId].activeFusion
end

-- Vérifier si une fusion est terminée
function DataStoreManager.IsFusionComplete(player)
	local fusion = DataStoreManager.GetActiveFusion(player)
	if not fusion then return false end

	local elapsed = os.time() - fusion.startTime
	return elapsed >= fusion.duration
end

-- Obtenir le temps restant
function DataStoreManager.GetFusionTimeRemaining(player)
	local fusion = DataStoreManager.GetActiveFusion(player)
	if not fusion then return 0 end

	local elapsed = os.time() - fusion.startTime
	local remaining = math.max(fusion.duration - elapsed, 0)

	return remaining
end

-- Supprimer la fusion active
function DataStoreManager.RemoveActiveFusion(player)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].activeFusion = nil
	print("[DataStore] 🗑️ Fusion supprimée pour", player.Name)
	return true
end

-- Sauvegarder la fusion dans le cache
function DataStoreManager.SaveActiveFusion(player, fusion)
	if not playerData[player.UserId] then return false end
	playerData[player.UserId].activeFusion = fusion
	return true
end
-- ============================================
-- 🗑️ NETTOYAGE
-- ============================================
function DataStoreManager.CleanupPlayerData(player)
	playerData[player.UserId] = nil
	print("[DataStore] 🗑️ Cache nettoyé pour", player.Name)
end

print("[DataStoreManager] ✅ Module chargé (VERSION 2 ONGLETS + INVENTAIRE)")

return DataStoreManager
