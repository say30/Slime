-- from: ServerScriptService.SlimeRush.BaseUpgradeService

-- ServerScriptService/SlimeRush/BaseUpgradeService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local M = {}

-- {[userId]: {podSlots = 10, inventorySlots = 25, productionBoost = 1.0}}
local playerUpgrades = {}

local function getUpgrades(player)
	if not playerUpgrades[player.UserId] then
		playerUpgrades[player.UserId] = {
			podSlots = 10,
			inventorySlots = 25,
			productionBoost = 1.0,
		}
	end
	return playerUpgrades[player.UserId]
end

function M.GetUpgrades(player)
	return getUpgrades(player)
end

function M.GetProductionMultiplier(player)
	return getUpgrades(player).productionBoost
end

function M.UpgradePods(player)
	local upg = getUpgrades(player)
	if upg.podSlots >= 22 then
		return false, "Pods déjà maxed"
	end
	upg.podSlots = upg.podSlots + 2
	return true, "Pods upgradés: " .. upg.podSlots
end

function M.UpgradeInventory(player)
	local upg = getUpgrades(player)
	if upg.inventorySlots >= 50 then
		return false, "Inventaire maxed"
	end
	upg.inventorySlots = upg.inventorySlots + 5
	return true, "Inventaire: " .. upg.inventorySlots
end

function M.UpgradeProduction(player)
	local upg = getUpgrades(player)
	upg.productionBoost = upg.productionBoost * 1.1
	return true, "Production: x" .. string.format("%.2f", upg.productionBoost)
end

-- Remotes
local remotes = RS:WaitForChild("Remotes")
local getUpgradesRemote = remotes:WaitForChild("GetUpgrades")
local buyUpgradeRemote = remotes:WaitForChild("BuyUpgrade")

getUpgradesRemote.OnServerInvoke = function(player)
	return M.GetUpgrades(player)
end

buyUpgradeRemote.OnServerInvoke = function(player, upgradeType)
	if upgradeType == "pods" then
		return M.UpgradePods(player)
	elseif upgradeType == "inventory" then
		return M.UpgradeInventory(player)
	elseif upgradeType == "production" then
		return M.UpgradeProduction(player)
	end
	return false, "Type invalide"
end

Players.PlayerRemoving:Connect(function(player)
	playerUpgrades[player.UserId] = nil
end)

return M
