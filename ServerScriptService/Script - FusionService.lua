-- from: ServerScriptService.FusionService

-- ServerScriptService/FusionService.lua (NEW)
-- Gère les fusions de slimes + récompenses essence
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WS      = game:GetService("Workspace")

local Balance = require(RS:WaitForChild("Modules"):WaitForChild("GameBalance"))
local Economy = require(script.Parent:WaitForChild("EconomyService"))

local OwnedFolder = WS:FindFirstChild("OwnedSlimes") or Instance.new("Folder", WS)
local Remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder", RS)

local FusionEvent = Remotes:FindFirstChild("FusionEvent") or Instance.new("RemoteFunction", Remotes)
FusionEvent.Name = "FusionEvent"

local M = {}

-- ========================================
-- FUSION LOGIC
-- ========================================

-- Résultat possible après fusion
local function rollFusionResult(slimeCount, inputRarities)
	-- Si 5x rareté identique = résultat garanti meilleur
	local allSame = true
	if slimeCount > 1 then
		for i=2, slimeCount do
			if inputRarities[i] ~= inputRarities[1] then
				allSame = false
				break
			end
		end
	end

	if allSame and slimeCount >= 5 then
		-- Fusion guaranteed: 5x Commun→Rare, 5x Rare→Epic, etc
		local inputRarity = inputRarities[1]
		if inputRarity >= 1 and inputRarity <= 10 then
			return { success = true, rarity = math.min(inputRarity + 1, 12) }
		end
	end

	-- Standard roll: 70% common, 20% rare, 8% epic, 2% legendary
	local roll = math.random(100)
	if roll <= 70 then
		return { success = true, rarity = 1 }  -- Commun
	elseif roll <= 90 then
		return { success = true, rarity = 3 }  -- Rare
	elseif roll <= 98 then
		return { success = true, rarity = 5 }  -- Epic
	else
		return { success = true, rarity = 6 }  -- Legendaire
	end
end

-- Essence rewards après fusion
local function computeEssenceReward(fusionResult, inputCount)
	if not fusionResult.success then
		-- Fusion failed = consolation prize
		return Balance.EssenceRewards.FusionFail  -- 5 essence
	end

	-- Fusion success
	if fusionResult.rarity == 6 then
		-- Legendaire = bonus essence
		return Balance.EssenceRewards.FusionSuccess * 3  -- 3 essence
	elseif fusionResult.rarity >= 5 then
		-- Epic+ = 2x essence
		return Balance.EssenceRewards.FusionSuccess * 2
	else
		-- Common/Rare = normal
		return Balance.EssenceRewards.FusionSuccess  -- 1 essence
	end
end

-- ========================================
-- API
-- ========================================

function M.AttemptFusion(player, slimeIds)
	if not player or not slimeIds or #slimeIds < 2 then
		return false, "Au moins 2 slimes requis"
	end

	if #slimeIds > 5 then
		return false, "Maximum 5 slimes"
	end

	-- Vérifier que tous les slimes appartiennent au joueur
	local slimes = {}
	local rarities = {}

	for _, id in ipairs(slimeIds) do
		local slime = OwnedFolder:FindFirstChild(id)
		if not slime or slime:IsA("Model") == false then
			return false, "Slime introuvable"
		end
		if (slime:GetAttribute("OwnerUserId") or 0) ~= player.UserId then
			return false, "Ce slime ne t'appartient pas"
		end

		table.insert(slimes, slime)
		table.insert(rarities, slime:GetAttribute("RarityIndex") or 1)
	end

	-- Calcul coûts fusion
	local fusionCost = 100 * #slimes  -- 200 pour 2 slimes, etc
	if not Economy.TryPurchase(player, fusionCost) then
		return false, "Pas assez de gélatine (coût: "..fusionCost..")"
	end

	-- Roll résultat
	local result = rollFusionResult(#slimes, rarities)

	-- Compute essence reward
	local essenceReward = computeEssenceReward(result, #slimes)

	-- Détruire les slimes consommés
	for _, slime in ipairs(slimes) do
		slime:Destroy()
	end

	-- Ajouter essence
	Economy.AddEssence(player, essenceReward)

	return true, {
		success = result.success,
		rarity = result.rarity,
		rarityName = Balance.Rarities[result.rarity] or "?",
		essenceGained = essenceReward,
	}
end

-- RemoteFunction listener
FusionEvent.OnServerInvoke = function(player, slimeIds)
	return M.AttemptFusion(player, slimeIds)
end

return M
