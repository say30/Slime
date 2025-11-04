-- from: ServerScriptService.ContractService

-- ServerScriptService/ContractService.lua (NEW)
-- Contrats quotidiens avec essence rewards
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local Balance = require(RS:WaitForChild("Modules"):WaitForChild("GameBalance"))
local Economy = require(script.Parent:WaitForChild("EconomyService"))

local Remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder", RS)
local ContractEvent = Remotes:FindFirstChild("ContractEvent") or Instance.new("RemoteEvent", Remotes)
ContractEvent.Name = "ContractEvent"

local M = {}

-- ========================================
-- CONTRACT DEFINITIONS
-- ========================================

local ContractTypes = {
	{
		id = "harvest_500",
		name = "Harvest Master",
		description = "Collecte 500 Gélatine",
		target = 500,
		metric = "Wallet",  -- Track Wallet change
		essenceReward = 3,
		gelReward = 100,
	},
	{
		id = "fusion_3",
		name = "Fusionist",
		description = "Fusionne 3 slimes",
		target = 3,
		metric = "Fusions",
		essenceReward = 5,
		gelReward = 0,
	},
	{
		id = "purchase_10",
		name = "Big Spender",
		description = "Achète 10 slimes",
		target = 10,
		metric = "Purchases",
		essenceReward = 4,
		gelReward = 200,
	},
	{
		id = "discover_5",
		name = "Collector",
		description = "Découvre 5 nouveaux slimes",
		target = 5,
		metric = "Discoveries",
		essenceReward = 2,
		gelReward = 50,
	},
	{
		id = "upgrade_2",
		name = "Upgrade Spender",
		description = "Améliore 2 aspects de ta base",
		target = 2,
		metric = "Upgrades",
		essenceReward = 4,
		gelReward = 150,
	},
}

-- État des contrats par joueur
local PlayerContracts = {}

local function getPlayerContracts(player)
	if not PlayerContracts[player] then
		PlayerContracts[player] = {
			daily = {},
			progress = {},
			completed = {},
		}
	end
	return PlayerContracts[player]
end

local function generateDailyContracts(player)
	local contracts = getPlayerContracts(player)
	contracts.daily = {}
	contracts.progress = {}

	-- Sélectionne 5 contrats aléatoires
	for i=1, 5 do
		local contract = ContractTypes[math.random(1, #ContractTypes)]
		table.insert(contracts.daily, contract.id)
		contracts.progress[contract.id] = 0
	end

	-- Enregistre le jour de génération
	contracts.generatedAt = os.time()
	return contracts.daily
end

local function isContractDayExpired(player)
	local contracts = getPlayerContracts(player)
	if not contracts.generatedAt then return true end

	local now = os.time()
	local daySeconds = 86400
	return (now - contracts.generatedAt) >= daySeconds
end

local function completeContract(player, contractId)
	local contracts = getPlayerContracts(player)

	-- Trouve le contrat
	local contract = nil
	for _, c in ipairs(ContractTypes) do
		if c.id == contractId then
			contract = c
			break
		end
	end

	if not contract then return false, "Contrat introuvable" end

	-- Vérifier qu'il est complété
	if (contracts.progress[contractId] or 0) < contract.target then
		return false, "Contrat non complété"
	end

	-- Vérifier si déjà complété
	if contracts.completed[contractId] then
		return false, "Contrat déjà complété aujourd'hui"
	end

	-- Rewards
	Economy.AddEssence(player, contract.essenceReward)
	if contract.gelReward > 0 then
		Economy.AddWallet(player, contract.gelReward)
	end

	contracts.completed[contractId] = true
	return true, contract.essenceReward
end

-- ========================================
-- PUBLIC API
-- ========================================

function M.GetContracts(player)
	if isContractDayExpired(player) then
		generateDailyContracts(player)
	end

	local contracts = getPlayerContracts(player)
	local result = {}

	for _, contractId in ipairs(contracts.daily) do
		local contract = nil
		for _, c in ipairs(ContractTypes) do
			if c.id == contractId then
				contract = c
				break
			end
		end

		if contract then
			table.insert(result, {
				id = contract.id,
				name = contract.name,
				description = contract.description,
				target = contract.target,
				progress = contracts.progress[contractId] or 0,
				essence = contract.essenceReward,
				completed = contracts.completed[contractId] or false,
			})
		end
	end

	return result
end

function M.IncrementProgress(player, metric, amount)
	-- Appeler depuis d'autres services (EconomyService, etc)
	local contracts = getPlayerContracts(player)

	for _, contractId in ipairs(contracts.daily) do
		local contract = nil
		for _, c in ipairs(ContractTypes) do
			if c.id == contractId then
				contract = c
				break
			end
		end

		if contract and contract.metric == metric then
			contracts.progress[contractId] = (contracts.progress[contractId] or 0) + (amount or 1)
		end
	end
end

function M.CompleteContract(player, contractId)
	return completeContract(player, contractId)
end

-- RemoteEvent listener
local ContractFunc = Remotes:FindFirstChild("ContractFunc") or Instance.new("RemoteFunction", Remotes)
ContractFunc.Name = "ContractFunc"

ContractFunc.OnServerInvoke = function(player, action, ...)
	if action == "getContracts" then
		return M.GetContracts(player)
	elseif action == "completeContract" then
		return M.CompleteContract(player, ...)
	end
end

-- Housekeeping: Clear contracts on player leaving
Players.PlayerRemoving:Connect(function(p)
	PlayerContracts[p] = nil
end)

return M
