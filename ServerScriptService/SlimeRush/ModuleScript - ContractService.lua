-- from: ServerScriptService.SlimeRush.ContractService

-- ServerScriptService/SlimeRush/ContractService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local M = {}

-- {[userId]: {contracts = {}, completedToday = {}}}
local playerContracts = {}

local function getContracts(player)
	if not playerContracts[player.UserId] then
		playerContracts[player.UserId] = {
			contracts = {
				{id=1, name="Easy", desc="Collecte 500 Gel", reward=50, difficulty="easy"},
				{id=2, name="Normal", desc="Fusion 2 slimes", reward=100, difficulty="normal"},
				{id=3, name="Hard", desc="Obtiens état Fusionné", reward=200, difficulty="hard"},
			},
			completedToday = {},
			lastReset = os.time(),
		}
	end
	return playerContracts[player.UserId]
end

function M.GetContracts(player)
	return getContracts(player).contracts
end

function M.CompleteContract(player, contractId)
	local data = getContracts(player)
	if data.completedToday[contractId] then
		return false, "Contrat déjà complété"
	end

	-- Trouver le contrat
	local contract = nil
	for _, c in ipairs(data.contracts) do
		if c.id == contractId then
			contract = c
			break
		end
	end

	if not contract then
		return false, "Contrat introuvable"
	end

	data.completedToday[contractId] = true
	return true, contract.reward
end

function M.HasCompletedContract(player, contractId)
	local data = getContracts(player)
	return data.completedToday[contractId] or false
end

-- Remotes
local remotes = RS:WaitForChild("Remotes")
local getContractsRemote = remotes:WaitForChild("GetContracts")
local completeRemote = remotes:WaitForChild("CompleteContract")

getContractsRemote.OnServerInvoke = function(player)
	return M.GetContracts(player)
end

completeRemote.OnServerInvoke = function(player, contractId)
	return M.CompleteContract(player, contractId)
end

Players.PlayerRemoving:Connect(function(player)
	playerContracts[player.UserId] = nil
end)

return M
