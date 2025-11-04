-- from: ServerScriptService.SlimeRush.CollectionService

-- ServerScriptService/SlimeRush/CollectionService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local M = {}

-- {[userId]: {discovered = {[moodIndex][rarityIndex] = true}}}
local playerCollections = {}

local function getCollection(player)
	if not playerCollections[player.UserId] then
		playerCollections[player.UserId] = {
			discovered = {},
			totalDiscovered = 0,
		}
	end
	return playerCollections[player.UserId]
end

function M.DiscoverSlime(player, mood, rarity, size)
	local col = getCollection(player)
	if not col.discovered[mood] then
		col.discovered[mood] = {}
	end
	if not col.discovered[mood][rarity] then
		col.discovered[mood][rarity] = true
		col.totalDiscovered = col.totalDiscovered + 1
		return true, "Slime découvert!"
	end
	return false, "Déjà découvert"
end

function M.GetDiscovered(player)
	return getCollection(player).discovered
end

function M.GetTotalDiscovered(player)
	return getCollection(player).totalDiscovered
end

function M.GetCompletion(player)
	-- 12 moods × 12 rarities × 5 sizes = 720 combinaisons
	-- Sans states pour le slimedex basique
	local total = getCollection(player).totalDiscovered
	local max = 720
	return (total / max) * 100
end

-- Remotes
local remotes = RS:WaitForChild("Remotes")
local getSlimeDexRemote = remotes:WaitForChild("GetSlimeDex")

getSlimeDexRemote.OnServerInvoke = function(player)
	return {
		discovered = M.GetDiscovered(player),
		total = M.GetTotalDiscovered(player),
		completion = M.GetCompletion(player),
	}
end

Players.PlayerRemoving:Connect(function(player)
	playerCollections[player.UserId] = nil
end)

return M
