--[[
    ContractManager.lua
    Gestion des contrats quotidiens
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Modules
local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))
local ContractConfig = require(ReplicatedStorage.Modules.Shared:WaitForChild("ContractConfig"))

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestContractsEvent = RemoteEvents:WaitForChild("RequestContractsEvent")
local ClaimContractRewardEvent = RemoteEvents:WaitForChild("ClaimContractRewardEvent")
local UpdateContractProgressEvent = RemoteEvents:WaitForChild("UpdateContractProgressEvent")

print("[ContractManager] ✅ Service initialisé")

-- ============================================
-- 🔁 MISE À JOUR DE LA PROGRESSION
-- ============================================

local function updateContractProgress(player, eventType, data)
        local activeContracts = DataStoreManager.GetActiveContracts(player)
        if not activeContracts or #activeContracts == 0 then return end

        local payload = data or {}

        for _, contractId in ipairs(activeContracts) do
                local contractConfig = ContractConfig:GetContractById(contractId.id or contractId)
                if contractConfig then
                        local objective = contractConfig.objective or {}

                        if contractConfig.type == "BuySlimes" and eventType == "BuySlime" then
                                DataStoreManager.IncrementContractProgress(player, contractConfig.id, payload.count or 1)
                        elseif contractConfig.type == "BuyRarity" and eventType == "BuySlime" then
                                if payload.rarity == objective.target then
                                        DataStoreManager.IncrementContractProgress(player, contractConfig.id, 1)
                                end
                        elseif contractConfig.type == "BuySize" and eventType == "BuySlime" then
                                if payload.size == objective.target then
                                        DataStoreManager.IncrementContractProgress(player, contractConfig.id, 1)
                                end
                        elseif contractConfig.type == "CollectGelatin" and eventType == "CollectGelatin" then
                                if payload.amount and payload.amount > 0 then
                                        local current = DataStoreManager.GetContractProgress(player, contractConfig.id)
                                        DataStoreManager.UpdateContractProgress(player, contractConfig.id, current + payload.amount)
                                end
                        elseif contractConfig.type == "SellSlimes" and eventType == "SellSlime" then
                                DataStoreManager.IncrementContractProgress(player, contractConfig.id, payload.count or 1)
                        elseif contractConfig.type == "SellValue" and eventType == "SellValue" then
                                if payload.value and payload.value > 0 then
                                        local current = DataStoreManager.GetContractProgress(player, contractConfig.id)
                                        DataStoreManager.UpdateContractProgress(player, contractConfig.id, current + payload.value)
                                end
                        elseif contractConfig.type == "PodsSlimes" and eventType == "PodsSlimes" then
                                if payload.count then
                                        local current = DataStoreManager.GetContractProgress(player, contractConfig.id)
                                        if payload.count > current then
                                                DataStoreManager.UpdateContractProgress(player, contractConfig.id, payload.count)
                                        end
                                end
                        elseif contractConfig.type == "FuseState" and eventType == "FuseState" then
                                if payload.state and payload.state == objective.target then
                                        DataStoreManager.UpdateContractProgress(player, contractConfig.id, 1)
                                end
                        end
                end
        end
end

-- ============================================
-- 🎲 SÉLECTION DES CONTRATS QUOTIDIENS
-- ============================================

local function selectDailyContracts()
	-- Sélectionner 1 facile, 1 moyen, 1 difficile
	local easyContract = ContractConfig:GetRandomContract("Easy")
	local mediumContract = ContractConfig:GetRandomContract("Medium")
	local hardContract = ContractConfig:GetRandomContract("Hard")

	local selected = {}
	if easyContract then table.insert(selected, easyContract) end
	if mediumContract then table.insert(selected, mediumContract) end
	if hardContract then table.insert(selected, hardContract) end

	return selected
end

-- ============================================
-- 📊 CALCUL DES RÉCOMPENSES DYNAMIQUES
-- ============================================

local function calculateTarget(player)
	-- Récupérer les données du joueur
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return 50000 end -- Default 50K

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return 50000 end

	-- Récupérer BaseLevel
	local baseLevel = 0
	if _G.GetPlayerData then
		local data = _G.GetPlayerData(player)
		if data then
			baseLevel = data.BaseLevel or 0
		end
	end

	-- Récupérer RebirthCount
	local rebirthCount = 0
	if _G.GetPlayerData then
		local data = _G.GetPlayerData(player)
		if data then
			rebirthCount = data.RebirthCount or 0
		end
	end

	-- Récupérer Production totale
	local productionValue = playerFolder:FindFirstChild("ProductionRate")
	local totalProduction = productionValue and productionValue.Value or 1

	-- ✅ NOUVELLE FORMULE ÉQUILIBRÉE
	local productionTarget = totalProduction * 3600 * 2  -- 2h de production
	local baseBonus = baseLevel * 500000                 -- 500K par niveau (réduit de 10M!)
	local rebirthBonus = rebirthCount * 2000000          -- 2M par rebirth (réduit de 25M!)

	-- Le target est principalement la production + bonus
	local target = productionTarget + baseBonus + rebirthBonus

	-- Minimum absolu : 50K (pour éviter 0)
	target = math.max(target, 50000)

	print("[ContractManager] 🎯 Target calculé pour", player.Name, ":", target)
	print("  - Production/s:", totalProduction, "→ 2h =", productionTarget)
	print("  - BaseLevel:", baseLevel, "→ bonus =", baseBonus)
	print("  - Rebirth:", rebirthCount, "→ bonus =", rebirthBonus)
	print("  - TOTAL TARGET:", target)

	return target
end

local function calculateRewards(player, contractData)
	local target = calculateTarget(player)

	local gelatin = math.floor(target * contractData.rewards.gelatinPercent)
	local essence = math.floor(target * contractData.rewards.essencePercent)

	return {
		gelatin = gelatin,
		essence = essence,
		catalysts = contractData.rewards.catalysts or {}
	}
end

-- ============================================
-- 🔄 INITIALISATION DES CONTRATS POUR UN JOUEUR
-- ============================================

local function initializePlayerContracts(player)
	task.wait(2) -- Attendre que tout soit chargé

	local lastReset = DataStoreManager.GetLastContractReset(player)
	local now = os.time()

	-- Vérifier si un nouveau jour (reset à minuit UTC)
	local lastResetDate = os.date("!*t", lastReset)
	local nowDate = os.date("!*t", now)

	local needsReset = (lastResetDate.year ~= nowDate.year) or 
		(lastResetDate.yday ~= nowDate.yday) or
		(lastReset == 0)

	if needsReset then
		print("[ContractManager] 🔄 Nouveau jour détecté pour", player.Name, "- Reset des contrats")

		-- Réinitialiser tous les contrats
		DataStoreManager.ResetAllContracts(player)

		-- Sélectionner 3 nouveaux contrats
		local dailyContracts = selectDailyContracts()
		DataStoreManager.SetDailyContracts(player, dailyContracts)

		print("[ContractManager] ✅", #dailyContracts, "contrats assignés à", player.Name)
	else
		print("[ContractManager] ℹ️ Contrats déjà initialisés pour", player.Name)
	end
end

-- ============================================
-- 📨 ENVOYER LES CONTRATS AU CLIENT
-- ============================================

RequestContractsEvent.OnServerEvent:Connect(function(player)
	local activeContracts = DataStoreManager.GetActiveContracts(player)

	-- Préparer les données avec progression et récompenses
	local contractsData = {}

	for _, contractId in ipairs(activeContracts) do
		local contractConfig = ContractConfig:GetContractById(contractId.id or contractId)

		if contractConfig then
			local progress = DataStoreManager.GetContractProgress(player, contractConfig.id)
			local rewards = calculateRewards(player, contractConfig)

			table.insert(contractsData, {
				id = contractConfig.id,
				tier = contractConfig.tier,
				type = contractConfig.type,
				objective = contractConfig.objective,
				progress = progress,
				rewards = rewards
			})
		end
	end

	RequestContractsEvent:FireClient(player, contractsData)
	print("[ContractManager] 📤 Contrats envoyés à", player.Name, "-", #contractsData, "contrats")
end)

-- ============================================
-- 🎁 CLAIM RÉCOMPENSE
-- ============================================

ClaimContractRewardEvent.OnServerEvent:Connect(function(player, contractId)
	print("[ContractManager] 🎁 Demande de claim pour", player.Name, "-", contractId)

	local contractConfig = ContractConfig:GetContractById(contractId)
	if not contractConfig then
		warn("[ContractManager] ❌ Contrat introuvable:", contractId)
		return
	end

	local progress = DataStoreManager.GetContractProgress(player, contractId)
	local target = contractConfig.objective.target

	-- Vérifier si le contrat est complété
	local isCompleted = false

	if contractConfig.type == "CollectGelatin" then
		-- Target en heures de production
		local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
		local playerFolder = PlayerInfo and PlayerInfo:FindFirstChild(player.Name)
		local productionValue = playerFolder and playerFolder:FindFirstChild("ProductionRate")
		local totalProduction = productionValue and productionValue.Value or 1

		local targetGelatin = totalProduction * 3600 * target
		isCompleted = progress >= targetGelatin
	elseif contractConfig.type == "SellValue" then
		-- Target en % du target principal
		local mainTarget = calculateTarget(player)
		local targetValue = mainTarget * target
		isCompleted = progress >= targetValue
	elseif contractConfig.type == "ReachProduction" then
		-- Target en % d'augmentation de production
		isCompleted = progress >= target
	elseif contractConfig.type == "FuseState" then
		-- Fusion d'un état spécifique (1 suffit)
		isCompleted = progress >= 1
	elseif contractConfig.type == "BuyRarity" or contractConfig.type == "BuySize" then
		-- Acheter X slimes d'une rareté/taille
		local count = contractConfig.objective.count or 1
		isCompleted = progress >= count
	else
		-- Pour tous les autres (objectifs simples)
		isCompleted = progress >= target
	end

	if not isCompleted then
		warn("[ContractManager] ❌ Contrat non complété:", contractId, "-", progress, "/", target)
		return
	end

	-- Calculer les récompenses
	local rewards = calculateRewards(player, contractConfig)

	-- Donner les récompenses
	if rewards.gelatin > 0 then
		DataStoreManager.AddGelatine(player, rewards.gelatin)
		print("[ContractManager] 💰 Gélatine donnée:", rewards.gelatin)
	end

	if rewards.essence > 0 then
		DataStoreManager.AddEssence(player, rewards.essence)
		print("[ContractManager] ✨ Essence donnée:", rewards.essence)
	end

	if rewards.catalysts and #rewards.catalysts > 0 then
		for _, catalyst in ipairs(rewards.catalysts) do
			-- Ajouter le catalyseur à l'inventaire
			local catalystData = {
				type = "catalyst",
				catalystType = catalyst.type,
				quantity = catalyst.quantity
			}
			DataStoreManager.AddToInventory(player, catalystData)
			print("[ContractManager] ⚡ Catalyseur donné:", catalyst.type, "x", catalyst.quantity)
		end
	end

	-- Réinitialiser le contrat
	DataStoreManager.ResetContract(player, contractId)

	print("[ContractManager] ✅ Récompenses données à", player.Name)

	-- Renvoyer les contrats mis à jour
	RequestContractsEvent:FireServer()
end)

-- ============================================
-- 🎮 ÉVÉNEMENTS JOUEURS
-- ============================================

Players.PlayerAdded:Connect(function(player)
        initializePlayerContracts(player)
end)

-- Pour les joueurs déjà connectés
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		initializePlayerContracts(player)
	end)
end

-- Rendre accessible aux autres services
_G.UpdateContractProgress = updateContractProgress

print("[ContractManager] ✅ Service chargé")
